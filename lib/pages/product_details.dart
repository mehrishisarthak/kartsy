import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

class ProductDetails extends StatefulWidget {
  // We now only need the productId to fetch live data.
  final String productId;
  const ProductDetails({super.key, required this.productId});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsKey = GlobalKey();

  /// Handles adding the product to the cart, managed by the CartProvider.
  Future<void> _handleAddToCart(Map<String, dynamic> productData) async {
    setState(() => _isLoading = true);

    try {
      final userId = await SharedPreferenceHelper().getUserID();
      if (userId == null || userId.isEmpty) {
        throw Exception('User ID not found.');
      }

      if (mounted) {
        await Provider.of<CartProvider>(context, listen: false)
            .addToCart(userId, productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product added to cart successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error adding to cart: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding to cart: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    // Using a StreamBuilder to get live updates for the product data
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading product data."));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Product not found."));
        }

        final product = snapshot.data!.data() as Map<String, dynamic>;
        final int inventory = int.tryParse(product['inventory']?.toString() ?? '0') ?? 0;
        
        return Scaffold(
          // --- AppBar ---
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: colorScheme.primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Product',
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // To balance the back button space
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // --- Body ---
          body: Column(
            children: [
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  product['Image'] ?? '',
                  height: 260,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 80),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 15,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            product['Name'] ?? 'No Name',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            softWrap: true,
                          ),
                          const SizedBox(height: 10),
                          // Price
                          Text(
                            '₹${product['Price'] ?? '--'}',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
        
                          // --- Average Rating Widget ---
                          _buildAverageRatingWidget(product['id']!),
                          const SizedBox(height: 20),
                          
                          // Details heading
                          Text(
                            'Details',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Description
                          Text(
                            product['Description'] ??
                                "No description provided for this product.",
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // --- Reviews Section Heading and List ---
                          RepaintBoundary(
                            key: _reviewsKey,
                            child: Text(
                              'Customer Reviews',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildReviewList(product['id']!),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        
          // --- Bottom Button ---
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              height: 55,
              width: double.infinity,
              child: ElevatedButton(
                // Disable the button if inventory is 0 or if the request is loading
                onPressed: inventory == 0 || _isLoading ? null : () => _handleAddToCart(product),
                style: ElevatedButton.styleFrom(
                  // Set the button color based on inventory count
                  backgroundColor: inventory == 0
                      ? Colors.red // Out of stock
                      : (inventory < 10 ? Colors.amber : colorScheme.primary), // Low stock
                  foregroundColor: inventory == 0 || inventory < 10 ? Colors.black : colorScheme.onPrimary,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: inventory == 0 || inventory < 10 ? Colors.black : colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        // Set the button text based on inventory count
                        inventory == 0
                            ? "Out of Stock"
                            : (inventory < 10
                                ? "Only a few left! Order now!"
                                : "Add to Cart"),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a clickable row displaying the average rating.
  Widget _buildAverageRatingWidget(String productId) {
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(); // No reviews, so show nothing
        }

        final reviews = snapshot.data!.docs;
        double totalRating = 0;
        for (var review in reviews) {
          totalRating += (review.data() as Map)['rating'] as num? ?? 0;
        }
        final averageRating = reviews.isNotEmpty ? totalRating / reviews.length : 0.0;

        return InkWell(
          onTap: () {
            // Scroll to the reviews section when the stars are clicked
            if (_reviewsKey.currentContext != null) {
              Scrollable.ensureVisible(
                _reviewsKey.currentContext!,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                RatingBarIndicator(
                  rating: averageRating,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 18.0,
                  direction: Axis.horizontal,
                ),
                const SizedBox(width: 8),
                Text(
                  '${averageRating.toStringAsFixed(1)}/5 (${reviews.length} reviews)',
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the reviews section, including average rating and user reviews.
  Widget _buildReviewList(String productId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading reviews."));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              "No reviews yet. Be the first to review this product!",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          );
        }

        final reviews = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Prevents nested scrolling issues
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final reviewData = reviews[index].data() as Map<String, dynamic>;
            return _buildReviewCard(reviewData);
          },
        );
      },
    );
  }

  /// Builds a single card for a user's review.
  Widget _buildReviewCard(Map<String, dynamic> reviewData) {
    final textTheme = Theme.of(context).textTheme;
    final rating = (reviewData['rating'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: reviewData['userImage'] != null && reviewData['userImage'].isNotEmpty
                      ? NetworkImage(reviewData['userImage']) as ImageProvider
                      : const AssetImage('lib/assets/images/white.png'), // Default placeholder
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reviewData['userName'] ?? 'Anonymous User',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                RatingBarIndicator(
                  rating: rating,
                  itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 16.0,
                  direction: Axis.horizontal,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              reviewData['reviewText'] ?? '',
              style: textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
