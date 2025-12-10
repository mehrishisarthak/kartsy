import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsKey = GlobalKey();

  // Review Pagination
  final List<DocumentSnapshot> _reviews = [];
  bool _isLoadingReviews = false;
  bool _hasMoreReviews = true;
  DocumentSnapshot? _lastReviewDoc;
  static const int _reviewsPerBatch = 5;

  // 3D Model Caching State
  File? _cachedModelFile;
  bool _isModelCaching = false;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- 1. ROBUST 3D MODEL CACHING ---
  Future<void> _prepareModel(String url) async {
    if (_cachedModelFile != null || _isModelCaching) return;

    setState(() => _isModelCaching = true);

    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      if (mounted) {
        setState(() {
          _cachedModelFile = file;
          _isModelCaching = false;
        });
      }
    } catch (e) {
      debugPrint("Error caching model: $e");
      if (mounted) setState(() => _isModelCaching = false);
    }
  }

  // --- 2. FETCH REVIEWS ---
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

  // --- 3. ADD TO CART ---
  Future<void> _handleAddToCart(Map<String, dynamic> productData) async {
    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      if (userId == null) {
        throw Exception('You must be logged in to add items.');
      }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('products').doc(widget.productId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text("Product not found.")));
        }

        final product = snapshot.data!.data() as Map<String, dynamic>;
        final int inventory = int.tryParse(product['inventory']?.toString() ?? '0') ?? 0;

        List<dynamic> rawImages = product['images'] ?? [];
        if (rawImages.isEmpty && product['Image'] != null) {
          rawImages = [product['Image']];
        }
        final List<String> imageUrls = rawImages.map((e) => e.toString()).toList();

        final String? modelUrl = product['modelUrl'] ?? product['sketchfabUrl'];
        final bool has3DModel = modelUrl != null && modelUrl.isNotEmpty;

        if (has3DModel && _cachedModelFile == null && !_isModelCaching) {
          _prepareModel(modelUrl);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Product Details"),
            centerTitle: true,
            actions: [
              if (has3DModel)
                IconButton(
                  icon: Icon(_show3D ? Icons.image : Icons.view_in_ar),
                  onPressed: _isModelCaching ? null : () => setState(() => _show3D = !_show3D),
                ),
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- MEDIA SECTION ---
                SizedBox(
                  height: 350,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      _show3D && has3DModel
                          ? (_cachedModelFile != null
                              ? ModelViewer(
                                  src: 'file://${_cachedModelFile!.path}',
                                  alt: "A 3D model of ${product['Name']}",
                                  ar: true,
                                  autoRotate: true,
                                  cameraControls: true,
                                  backgroundColor: Colors.white,
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 10),
                                      Text("Downloading 3D Asset..."),
                                    ],
                                  ),
                                ))
                          : _buildImageCarousel(imageUrls),

                      if (_show3D && has3DModel && _cachedModelFile != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Tap AR icon to place in room",
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // --- DETAILS ---
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['Name'] ?? 'No Name',
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₹${product['Price'] ?? '--'}',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSummaryRating(product),
                      const SizedBox(height: 20),
                      Text(
                        'Details',
                        style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product['Description'] ?? "No description provided.",
                        style: textTheme.bodyLarge?.copyWith(color: Colors.grey[700], height: 1.5),
                      ),
                      const SizedBox(height: 30),
                      RepaintBoundary(
                        key: _reviewsKey,
                        child: Text(
                          'Customer Reviews',
                          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildPaginatedReviewList(), // 🔥 FIXED WITH SHIMMER
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, -4))
              ],
            ),
            child: SizedBox(
              height: 55,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: inventory == 0 || _isLoading ? null : () => _handleAddToCart(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: inventory == 0
                      ? Colors.red
                      : (inventory < 10 ? Colors.amber : colorScheme.primary),
                  foregroundColor: inventory == 0 || inventory < 10
                      ? Colors.white
                      : colorScheme.onPrimary,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        inventory == 0
                            ? "Out of Stock"
                            : (inventory < 10 ? "Only ${inventory} left!" : "Add to Cart"),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRating(Map<String, dynamic> product) {
    double rating = (product['averageRating'] as num?)?.toDouble() ?? 0.0;
    int count = (product['reviewCount'] as num?)?.toInt() ?? 0;
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
    if (images.isEmpty) {
      return const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey));
    }

    return Column(
      children: [
        Expanded(
          child: CarouselSlider(
            options: CarouselOptions(
              height: double.infinity,
              viewportFraction: 1.0,
              enableInfiniteScroll: images.length > 1,
              onPageChanged: (index, reason) {
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
                  child: const Icon(Icons.error, color: Colors.grey),
                ),
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

  // 🔥 FIXED: SHIMMER POWERED REVIEWS
  Widget _buildPaginatedReviewList() {
    if (_reviews.isEmpty && !_isLoadingReviews) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.reviews_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                "No reviews yet.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              Text(
                "Be the first to review!",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Existing reviews
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviews.length,
          itemBuilder: (context, index) {
            final data = _reviews[index].data() as Map<String, dynamic>;
            return _buildReviewCard(data);
          },
        ),
        
        // 🔥 SHIMMER + LOAD MORE (Luxury UX)
        if (_hasMoreReviews)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ✨ Shimmer rows during loading
                if (_isLoadingReviews)
                  Column(
                    children: List.generate(3, (index) => _buildReviewShimmer()),
                  ),
                
                // Load More Button
                if (!_isLoadingReviews)
                  TextButton.icon(
                    onPressed: _fetchReviews,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text("Load More Reviews"),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  // ✨ CUSTOM REVIEW SHIMMER ROW
  Widget _buildReviewShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Review content shimmer
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username + stars
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Review text lines
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 200,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
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
        String userImage = "https://firebasestorage.googleapis.com/v0/b/kartsyapp-87532.firebasestorage.app/o/default_profile.png?alt=media&token=d328f93c-400f-4deb-a0e8-014eb2e2b795";
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
