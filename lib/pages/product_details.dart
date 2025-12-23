import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:ecommerce_shop/pages/profile.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/lead_provider.dart';
import 'package:ecommerce_shop/services/model_viewer.dart';
import 'package:ecommerce_shop/services/product_image_carousel.dart';
import 'package:ecommerce_shop/services/shimmer/button_shimmer.dart';
import 'package:ecommerce_shop/services/shimmer/product_details_shimmer.dart';
import 'package:ecommerce_shop/services/video_player.dart';
import 'package:ecommerce_shop/utils/constants.dart';
import 'package:ecommerce_shop/utils/show_snackbar.dart';
import 'package:ecommerce_shop/widget/review_card_shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:path_provider/path_provider.dart'; // Import Path Provider
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ProductDetails extends StatefulWidget {
  final String productId;
  const ProductDetails({super.key, required this.productId});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  late Stream<DocumentSnapshot> _productStream;
  bool _isLoading = false;
  YoutubePlayerController? _videoController;

  // Review Pagination
  final List<DocumentSnapshot> _reviews = [];
  bool _isLoadingReviews = false;
  bool _hasMoreReviews = true;
  DocumentSnapshot? _lastReviewDoc;
  static const int _reviewsPerBatch = 8;

  // Lead Interest State
  bool _isAddingToInterests = false;

  // --- 3D MODEL DOWNLOAD STATE ---
  bool _isDownloadingModel = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _productStream = FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .snapshots();

    _fetchReviews();
  }

  @override
  void dispose() {
    // --- CRITICAL FIX ---
    // We do NOT dispose or pause _videoController here.
    // The child widget 'ProductVideoPlayer' owns the controller (it creates it in initState)
    // and it handles the dispose() call internally.
    // Calling it here results in a "Double Disposal" crash.
    super.dispose();
  }

  Future<void> _handleDownloadAndOpenModel(
      String modelUrl, String productName) async {
    // 1. Get the directory
    final dir = await getApplicationDocumentsDirectory();
    final fileName = "${widget.productId}_model.glb";
    final savePath = "${dir.path}/$fileName";
    final file = File(savePath);

    // 2. CHECK: Does the file already exist?
    if (await file.exists()) {
      // PROD OPTIMIZATION: Skip download, open immediately
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModelViewerScreen(localFilePath: savePath),
          ),
        );
      }
      return;
    }

    // 3. If not found, start download
    setState(() {
      _isDownloadingModel = true;
      _downloadProgress = 0.0;
    });

    try {
      await Dio().download(
        modelUrl,
        savePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = count / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() => _isDownloadingModel = false);

        // Open Viewer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModelViewerScreen(localFilePath: savePath),
          ),
        );
      }
    } catch (e) {
      // PROD OPTIMIZATION: Delete corrupt/partial file on error
      if (await file.exists()) {
        await file.delete();
      }

      if (mounted) {
        setState(() => _isDownloadingModel = false);
        showCustomSnackBar(
            context, "Failed to download 3D model. Check connection.",
            type: SnackBarType.error);
        debugPrint("Download Error: $e");
      }
    }
  }

  // --- 1. FETCH REVIEWS ---
  Future<void> _fetchReviews() async {
    if (_isLoadingReviews || !_hasMoreReviews) return;
    if (mounted) setState(() => _isLoadingReviews = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .limit(_reviewsPerBatch);

      if (_lastReviewDoc != null) {
        query = query.startAfterDocument(_lastReviewDoc!);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.length < _reviewsPerBatch) _hasMoreReviews = false;

      if (snapshot.docs.isNotEmpty) {
        _lastReviewDoc = snapshot.docs.last;
        if (mounted) setState(() => _reviews.addAll(snapshot.docs));
      }
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  // --- 2. ADD TO CART ---
  Future<void> _handleAddToCart(Map<String, dynamic> productData) async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        showCustomSnackBar(context, "You must be logged in to add items to cart.", type: SnackBarType.error);
        return;
      }

      if (mounted) {
        await Provider.of<CartProvider>(context, listen: false)
            .addToCart(userId, productData);

        if (mounted) {
          showCustomSnackBar(context, "Added to cart!", type: SnackBarType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(context, "Error: ${e.toString()}", type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 3. SMART LEAD GENERATION ---
  Future<void> _handleAddToInterests(
    BuildContext context,
    Map<String, dynamic> productData,
  ) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      showCustomSnackBar(context, "You must be logged in to express interest.",
          type: SnackBarType.error);
      return;
    }

    final leadsProvider = Provider.of<LeadsProvider>(context, listen: false);
    if (leadsProvider.isProductInInterests(widget.productId)) {
      showCustomSnackBar(context, "This item is already in your interest list.",
          type: SnackBarType.info);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final address = userData?['Address'] as Map<String, dynamic>?;

      if (address == null ||
          (address['state'] as String?)?.isEmpty == true ||
          (address['city'] as String?)?.isEmpty == true ||
          (address['mobile'] as String?)?.isEmpty == true) {
        showCustomSnackBar(
            context, "Please complete your profile to contact sellers.",
            type: SnackBarType.error);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => ProfilePage(userId: userId)),
          );
        }
        return;
      }

      if (mounted) {
        _showInterestDialog(context, userId, productData, userData, address);
      }
    } catch (e) {
      showCustomSnackBar(context, "Error verifying profile: $e",
          type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showInterestDialog(
    BuildContext context,
    String userId,
    Map<String, dynamic> productData,
    Map<String, dynamic>? userData,
    Map<String, dynamic> address,
  ) {
    final emailController =
        TextEditingController(text: userData?['Email'] ?? '');
    String rawPhone = address['mobile'] ?? '';
    if (rawPhone.startsWith('+91')) rawPhone = rawPhone.substring(3);
    final phoneController = TextEditingController(text: rawPhone);

    String? selectedCity = address['city'];
    String? selectedState = address['state'];

    final cities = [
      'Agartala',
      'Delhi',
      'Mumbai',
      'Bangalore',
      'Hyderabad',
      'Chennai',
      'Kolkata',
      'Pune',
      'Ahmedabad',
      'Jaipur',
      'Other'
    ];
    final states = [
      'Tripura',
      'Delhi',
      'Maharashtra',
      'Karnataka',
      'Telangana',
      'Tamil Nadu',
      'West Bengal',
      'Uttar Pradesh',
      'Gujarat',
      'Rajasthan',
      'Other'
    ];

    if (!cities.contains(selectedCity)) selectedCity = 'Other';
    if (!states.contains(selectedState)) selectedState = 'Other';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Interest'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your details will be shared with the seller.',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email', prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                      labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCity,
                items: cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => selectedCity = v,
                decoration: const InputDecoration(
                    labelText: 'City', prefixIcon: Icon(Icons.location_city)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedState,
                items: states
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => selectedState = v,
                decoration: const InputDecoration(
                    labelText: 'State', prefixIcon: Icon(Icons.map)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: _isAddingToInterests
                ? null
                : () async {
                    if (emailController.text.isEmpty ||
                        phoneController.text.length != 10) {
                      showCustomSnackBar(
                          context, "Please provide a valid email and phone number.",
                          type: SnackBarType.error);
                      return;
                    }
                    setState(() => _isAddingToInterests = true);
                    try {
                      final result = await Provider.of<LeadsProvider>(context,
                              listen: false)
                          .addLead(
                        userId: userId,
                        productId: widget.productId,
                        productData: productData,
                        userEmail: emailController.text.trim(),
                        userPhone: phoneController.text.trim(),
                        userName: userData?['Name'] ?? 'Customer',
                        userCity: selectedCity!,
                        userState: selectedState!,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        showCustomSnackBar(context, result,
                            type: SnackBarType.success);
                      }
                    } catch (e) {
                      if (mounted)
                        showCustomSnackBar(context, "Error: $e",
                            type: SnackBarType.error);
                    } finally {
                      if (mounted)
                        setState(() => _isAddingToInterests = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white),
            child: _isAddingToInterests
                ? const ButtonShimmer()
                : const Text("Send to Seller"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _productStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ProductDetailsShimmer();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
              body: Center(child: Text("Product not found.")));
        }

        final product = snapshot.data!.data() as Map<String, dynamic>;

        final int inventory =
            int.tryParse(product['inventory']?.toString() ?? '0') ?? 0;
        List<dynamic> rawImages = product['images'] ?? [];
        if (rawImages.isEmpty && product['Image'] != null) {
          rawImages = [product['Image']];
        }
        final List<String> imageUrls =
            rawImages.map((e) => e.toString()).toList();

        final String? videoUrl = product['videoUrl'];
        final bool hasVideo = videoUrl != null && videoUrl.isNotEmpty;
        final String category = product['category'] ?? '';
        final bool isFurniture = category.toLowerCase() == 'furniture';

        // --- NEW: Check for Model URL ---
        final String? modelUrl = product['modelUrl'];
        final bool hasModel = modelUrl != null && modelUrl.isNotEmpty;

        final double averageRating =
            (product['averageRating'] as num?)?.toDouble() ?? 0.0;
        final int reviewCount = (product['reviewCount'] as num?)?.toInt() ?? 0;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                title: const Text("Product Details"),
                centerTitle: true,
                floating: true,
                pinned: true,
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: ProductImagesCarousel(imageUrls: imageUrls),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['Name'] ?? 'No Name',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₹${product['Price'] ?? '--'}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRating(averageRating, reviewCount),

                      // --- NEW: 3D Model Download Button ---
                      if (hasModel) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.view_in_ar,
                                      color: Colors.blue, size: 30),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "View in 3D & AR",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        Text(
                                          _isDownloadingModel
                                              ? "Downloading model..."
                                              : "Visualize this product in your space",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: _isDownloadingModel
                                        ? null
                                        : () => _handleDownloadAndOpenModel(
                                            modelUrl!,
                                            product['Name'] ?? 'Product'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    child: _isDownloadingModel
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2),
                                          )
                                        : const Text("View"),
                                  ),
                                ],
                              ),
                              if (_isDownloadingModel) ...[
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                    value: _downloadProgress,
                                    borderRadius: BorderRadius.circular(4)),
                              ]
                            ],
                          ),
                        ),
                      ],
                      // -------------------------------------

                      const SizedBox(height: 20),
                      Text('Details',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        product['Description'] ?? "No description provided.",
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.grey[700], height: 1.5),
                      ),
                      if (hasVideo) ...[
                        const SizedBox(height: 30),
                        Text('Product Video',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        ProductVideoPlayer(
                          videoUrl: videoUrl,
                          onPlayerCreated: (controller) {
                            _videoController = controller;
                          },
                        ),
                      ],
                      const SizedBox(height: 30),
                      Text('Customer Reviews',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      // ... (Remaining Review Widgets stay exactly the same)
                      _buildReviewSection(context, averageRating, reviewCount),
                    ],
                  ),
                ),
              ),
              if (_reviews.isEmpty && !_isLoadingReviews)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.reviews_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("No reviews yet.",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data =
                          _reviews[index].data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildReviewCard(data),
                      );
                    },
                    childCount: _reviews.length,
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (_isLoadingReviews)
                        Column(
                            children: List.generate(
                                2, (index) => const ReviewCardShimmer())),
                      if (_hasMoreReviews &&
                          !_isLoadingReviews &&
                          _reviews.isNotEmpty)
                        TextButton.icon(
                          onPressed: _fetchReviews,
                          icon: const Icon(Icons.arrow_downward_rounded,
                              size: 18),
                          label: const Text("Load More Reviews"),
                        ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: isFurniture
              ? _buildLeadGenerationBottomBar(context, product)
              : _buildAddToCartBottomBar(context, inventory, product),
        );
      },
    );
  }

  // Extracted Review Section to keep build method clean
  Widget _buildReviewSection(
      BuildContext context, double averageRating, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              RatingBarIndicator(
                rating: averageRating,
                itemBuilder: (context, index) =>
                    const Icon(Icons.star, color: Colors.amber),
                itemCount: 5,
                itemSize: 20.0,
              ),
              const SizedBox(height: 4),
              Text(
                "$reviewCount Ratings",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- EXISTING SUB-WIDGETS (Unchanged logic, just keeping them here) ---

  Widget _buildAddToCartBottomBar(
      BuildContext context, int inventory, Map<String, dynamic> product) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: inventory == 0 || _isLoading
                ? null
                : () => _handleAddToCart(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: inventory == 0
                  ? Colors.red
                  : (inventory < 10 ? Colors.amber : colorScheme.primary),
              foregroundColor: inventory == 0 || inventory < 10
                  ? Colors.white
                  : colorScheme.onPrimary,
            ),
            child: _isLoading
                ? const ButtonShimmer()
                : Text(
                    inventory == 0
                        ? "Out of Stock"
                        : (inventory < 10
                            ? "Only $inventory left!"
                            : "Add to Cart"),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadGenerationBottomBar(
      BuildContext context, Map<String, dynamic> product) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: _isAddingToInterests
                ? null
                : () => _handleAddToInterests(context, product),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white),
            child: _isAddingToInterests
                ? const ButtonShimmer()
                : const Text("I'm Interested in This Product",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRating(double rating, int count) {
    if (count == 0) return const SizedBox();
    return Row(
      children: [
        RatingBarIndicator(
          rating: rating,
          itemBuilder: (context, index) =>
              const Icon(Icons.star, color: Colors.amber),
          itemCount: 5,
          itemSize: 20.0,
        ),
        const SizedBox(width: 8),
        Text('$rating ($count reviews)',
            style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> reviewData) {
    final userId = reviewData['userId'];
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        String userImage = AppConstants.defaultProfileImage;
        String userName = 'Anonymous User';

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          userImage = userData['Image'] ?? userImage;
          userName = userData['Name'] ?? userName;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: userImage,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const CircleAvatar(backgroundColor: Colors.grey),
                        errorWidget: (context, url, error) =>
                            const CircleAvatar(child: Icon(Icons.person)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(userName,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold))),
                    RatingBarIndicator(
                      rating: (reviewData['rating'] as num).toDouble(),
                      itemBuilder: (context, index) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 16.0,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(reviewData['reviewText'] ?? '',
                    style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        );
      },
    );
  }
}