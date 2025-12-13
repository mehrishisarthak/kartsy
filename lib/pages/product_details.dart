import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/profile.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/lead_provider.dart';
import 'package:ecommerce_shop/services/shimmer/product_details_shimmer.dart';
import 'package:ecommerce_shop/utils/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ProductDetails extends StatefulWidget {
  final String productId;
  const ProductDetails({super.key, required this.productId});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool _isLoading = false;
  bool _show3D = false;
  int _currentImageIndex = 0;

  // Review Pagination
  final List<DocumentSnapshot> _reviews = [];
  bool _isLoadingReviews = false;
  bool _hasMoreReviews = true;
  DocumentSnapshot? _lastReviewDoc;
  static const int _reviewsPerBatch = 8;

  // Lead Interest State
  bool _isAddingToInterests = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
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
      if (userId == null) throw Exception('You must be logged in to add items.');

      if (mounted) {
        await Provider.of<CartProvider>(context, listen: false)
            .addToCart(userId, productData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Added to cart!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
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
      _showSnackBar("You must be logged in to express interest.", isError: true);
      return;
    }

    final leadsProvider = Provider.of<LeadsProvider>(context, listen: false);
    if (leadsProvider.isProductInInterests(widget.productId)) {
      _showSnackBar("Already in your interests!", isError: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final address = userData?['Address'] as Map<String, dynamic>?;

      if (address == null ||
          (address['state'] as String?)?.isEmpty == true ||
          (address['city'] as String?)?.isEmpty == true ||
          (address['mobile'] as String?)?.isEmpty == true) {
        
        _showSnackBar("Please complete your profile to contact sellers.", isError: true);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => ProfilePage(userId: userId)),
          );
        }
        return;
      }

      if (mounted) {
        _showInterestDialog(context, userId, productData, userData, address);
      }

    } catch (e) {
      _showSnackBar("Error verifying profile: $e", isError: true);
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
    final emailController = TextEditingController(text: userData?['Email'] ?? '');
    
    String rawPhone = address['mobile'] ?? '';
    if (rawPhone.startsWith('+91')) rawPhone = rawPhone.substring(3);
    final phoneController = TextEditingController(text: rawPhone);

    String? selectedCity = address['city'];
    String? selectedState = address['state'];

    final cities = ['Agartala', 'Delhi', 'Mumbai', 'Bangalore', 'Hyderabad', 'Chennai', 'Kolkata', 'Pune', 'Ahmedabad', 'Jaipur', 'Other'];
    final states = ['Tripura', 'Delhi', 'Maharashtra', 'Karnataka', 'Telangana', 'Tamil Nadu', 'West Bengal', 'Uttar Pradesh', 'Gujarat', 'Rajasthan', 'Other'];

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
              Text('Your details will be shared with the seller.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 20),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 12),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCity,
                items: cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => selectedCity = v,
                decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedState,
                items: states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => selectedState = v,
                decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: _isAddingToInterests ? null : () async {
              if (emailController.text.isEmpty || phoneController.text.length != 10) {
                _showSnackBar("Please check email and phone.", isError: true);
                return;
              }
              setState(() => _isAddingToInterests = true);
              try {
                final result = await Provider.of<LeadsProvider>(context, listen: false).addLead(
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
                  _showSnackBar(result, isError: false);
                }
              } catch (e) {
                if (mounted) _showSnackBar("Error: $e", isError: true);
              } finally {
                if (mounted) setState(() => _isAddingToInterests = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600], foregroundColor: Colors.white),
            child: _isAddingToInterests 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("Send to Seller"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('products').doc(widget.productId).snapshots(),
      builder: (context, snapshot) {
        // Use Shimmer when waiting for initial data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ProductDetailsShimmer();
        }
        
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Product not found.")));
        }

        final product = snapshot.data!.data() as Map<String, dynamic>;

        // Data Extraction
        final int inventory = int.tryParse(product['inventory']?.toString() ?? '0') ?? 0;
        List<dynamic> rawImages = product['images'] ?? [];
        if (rawImages.isEmpty && product['Image'] != null) {
          rawImages = [product['Image']];
        }
        final List<String> imageUrls = rawImages.map((e) => e.toString()).toList();

        final String? modelUrl = product['modelUrl'] ?? product['sketchfabUrl'];
        final bool has3DModel = modelUrl != null && modelUrl.isNotEmpty;
        final String? videoUrl = product['videoUrl'];
        final bool hasVideo = videoUrl != null && videoUrl.isNotEmpty;
        final String category = product['category'] ?? '';
        final bool isFurniture = category.toLowerCase() == 'furniture';

        // Overall Ratings Data
        final double averageRating = (product['averageRating'] as num?)?.toDouble() ?? 0.0;
        final int reviewCount = (product['reviewCount'] as num?)?.toInt() ?? 0;

        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                title: const Text("Product Details"),
                centerTitle: true,
                floating: true,
                pinned: true, // Keep app bar visible
                actions: [
                  // 3D Toggle Button - Removed if no model
                  if (has3DModel)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle
                          ),
                          child: Icon(
                            _show3D ? Icons.image : Icons.view_in_ar, 
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        tooltip: _show3D ? "Show Images" : "View in 3D",
                        onPressed: () => setState(() => _show3D = !_show3D),
                      ),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // ✅ 3D MODEL VIEWER (Direct URL - No Local Caching)
                      if (_show3D && has3DModel)
                        ModelViewer(
                          src: modelUrl!, // Pass remote URL directly
                          alt: "A 3D model of ${product['Name']}",
                          ar: true,
                          autoRotate: true,
                          cameraControls: true,
                          backgroundColor: Colors.white,
                          arModes: const ['scene-viewer', 'webxr', 'quick-look'], // Standard AR modes
                        )
                      else
                        _buildImageCarousel(imageUrls),

                      if (_show3D && has3DModel)
                        Positioned(
                          bottom: 20, 
                          left: 0, 
                          right: 0, 
                          child: Center(child: _buildARBadge())
                        ),
                    ],
                  ),
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₹${product['Price'] ?? '--'}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRating(averageRating, reviewCount),
                      const SizedBox(height: 20),
                      Text('Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        product['Description'] ?? "No description provided.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700], height: 1.5),
                      ),
                      if (hasVideo) ...[
                        const SizedBox(height: 30),
                        Text('Product Video', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        ProductVideoPlayer(videoUrl: videoUrl),
                      ],
                      const SizedBox(height: 30),
                      Text('Customer Reviews', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),

                      // Overall Rating Summary Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
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
                                  itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
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
                      ),
                      const SizedBox(height: 20),
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
                          Icon(Icons.reviews_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 8),
                          Text("No reviews yet.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final data = _reviews[index].data() as Map<String, dynamic>;
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
                        Column(children: List.generate(2, (index) => _buildReviewShimmer())),
                      if (_hasMoreReviews && !_isLoadingReviews && _reviews.isNotEmpty)
                        TextButton.icon(
                          onPressed: _fetchReviews,
                          icon: const Icon(Icons.arrow_downward_rounded, size: 18),
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

  // --- Sub-Widgets ---

  Widget _buildARBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.view_in_ar, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text("Tap the AR icon to view in your room", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAddToCartBottomBar(BuildContext context, int inventory, Map<String, dynamic> product) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: inventory == 0 || _isLoading ? null : () => _handleAddToCart(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: inventory == 0 ? Colors.red : (inventory < 10 ? Colors.amber : colorScheme.primary),
              foregroundColor: inventory == 0 || inventory < 10 ? Colors.white : colorScheme.onPrimary,
            ),
            child: _isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    inventory == 0 ? "Out of Stock" : (inventory < 10 ? "Only $inventory left!" : "Add to Cart"),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadGenerationBottomBar(BuildContext context, Map<String, dynamic> product) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: _isAddingToInterests ? null : () => _handleAddToInterests(context, product),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600], foregroundColor: Colors.white),
            child: _isAddingToInterests
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("I'm Interested in This Product", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
          itemCount: 5,
          itemSize: 20.0,
        ),
        const SizedBox(width: 8),
        Text('$rating ($count reviews)', style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) return const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey));
    return Column(
      children: [
        Expanded(
          child: CarouselSlider(
            options: CarouselOptions(
              height: double.infinity,
              viewportFraction: 1.0,
              enableInfiniteScroll: images.length > 1,
              onPageChanged: (index, reason) {
                // Ensure state update doesn't crash if widget disposed
                if (mounted) setState(() => _currentImageIndex = index);
              },
            ),
            items: images.map((url) {
              return CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.grey)),
              );
            }).toList(),
          ),
        ),
        if (images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: images.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(_currentImageIndex == entry.key ? 0.9 : 0.4),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildReviewShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 12),
                  Container(width: double.infinity, height: 16, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 8),
                  Container(width: 200, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> reviewData) {
    final userId = reviewData['userId'];
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
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
                        width: 40, height: 40, fit: BoxFit.cover,
                        placeholder: (context, url) => const CircleAvatar(backgroundColor: Colors.grey),
                        errorWidget: (context, url, error) => const CircleAvatar(child: Icon(Icons.person)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold))),
                    RatingBarIndicator(
                      rating: (reviewData['rating'] as num).toDouble(),
                      itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                      itemCount: 5,
                      itemSize: 16.0,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(reviewData['reviewText'] ?? '', style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- 4. ISOLATED VIDEO PLAYER WIDGET ---
class ProductVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const ProductVideoPlayer({super.key, required this.videoUrl});

  @override
  State<ProductVideoPlayer> createState() => _ProductVideoPlayerState();
}

class _ProductVideoPlayerState extends State<ProductVideoPlayer> {
  late YoutubePlayerController _controller;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    _controller = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(_listener);
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      // Logic for non-fullscreen state updates if needed
    }
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.initialVideoId.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Theme.of(context).primaryColor,
          onReady: () {
            _isPlayerReady = true;
          },
        ),
      ),
    );
  }
}