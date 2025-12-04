import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';

class ProductDetails extends StatefulWidget {
  final String productId;
  const ProductDetails({super.key, required this.productId});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  bool _isLoading = false; // For Add to Cart
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _reviewsKey = GlobalKey();

  // --- PAGINATION VARIABLES ---
  List<DocumentSnapshot> _reviews = []; // Stores the loaded reviews
  bool _isLoadingReviews = false; // Shows loader for reviews
  bool _hasMoreReviews = true; // Checks if we reached the end
  DocumentSnapshot? _lastDocument; // The cursor for the next query
  final int _reviewsPerBatch = 5; // How many to load at a time

  @override
  void initState() {
    super.initState();
    // Load the first batch of reviews immediately
    _fetchReviews();
  }

  /// Fetches reviews in batches (Pagination Logic)
  Future<void> _fetchReviews() async {
    if (_isLoadingReviews || !_hasMoreReviews) return;

    setState(() {
      _isLoadingReviews = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .limit(_reviewsPerBatch);

      // If we have loaded data before, start AFTER the last one we saw
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.length < _reviewsPerBatch) {
        _hasMoreReviews = false; // No more docs to load after this
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _reviews.addAll(querySnapshot.docs);
      }
    } catch (e) {
      debugPrint("Error fetching reviews: $e");
    }

    if (mounted) {
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _handleAddToCart(Map<String, dynamic> productData) async {
    setState(() => _isLoading = true);
    try {
      final userId = await SharedPreferenceHelper().getUserID();
      if (userId == null || userId.isEmpty) throw Exception('User ID not found.');

      if (mounted) {
        await Provider.of<CartProvider>(context, listen: false)
            .addToCart(userId, productData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Product added to cart successfully!"),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    return StreamBuilder<DocumentSnapshot>(
      // Keep StreamBuilder for Product Data (Prices change often)
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Product not found."));
        }

        final product = snapshot.data!.data() as Map<String, dynamic>;
        final int inventory = int.tryParse(product['inventory']?.toString() ?? '0') ?? 0;

        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 12, offset: const Offset(0, 4)),
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
                                color: colorScheme.primary, fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                        topRight: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 15, offset: const Offset(0, -6)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0), // Removed bottom padding so list can scroll
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product['Name'] ?? 'No Name',
                              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text('₹${product['Price'] ?? '--'}',
                              style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900, color: colorScheme.primary)),
                          const SizedBox(height: 10),
                          _buildAverageRatingWidget(product['id']!),
                          const SizedBox(height: 20),
                          Text('Details', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Text(
                            product['Description'] ?? "No description provided.",
                            style: textTheme.bodyLarge?.copyWith(color: Colors.grey[700], height: 1.5),
                          ),
                          const SizedBox(height: 30),
                          RepaintBoundary(
                            key: _reviewsKey,
                            child: Text('Customer Reviews',
                                style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 10),
                          
                          // --- REPLACED StreamBuilder WITH PAGINATED LIST ---
                          _buildPaginatedReviewList(),
                          
                          // Padding at bottom for FAB/Button space
                          const SizedBox(height: 80), 
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                 BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, -4)),
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
                  foregroundColor: inventory == 0 || inventory < 10 ? Colors.black : colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        inventory == 0 ? "Out of Stock" : (inventory < 10 ? "Only a few left!" : "Add to Cart"),
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- UPDATED REVIEW LIST LOGIC ---
  Widget _buildPaginatedReviewList() {
    if (_reviews.isEmpty && !_isLoadingReviews) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "No reviews yet. Be the first!",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // Important inside SingleChildScrollView
          itemCount: _reviews.length,
          itemBuilder: (context, index) {
            final reviewData = _reviews[index].data() as Map<String, dynamic>;
            return _buildReviewCard(reviewData);
          },
        ),
        
        // The "Load More" Indicator / Button
        if (_hasMoreReviews)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _isLoadingReviews
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: _fetchReviews,
                    child: const Text("Load More Reviews"),
                  ),
          ),
      ],
    );
  }

  // (This function stays the same as your Reference/Dynamic version)
  Widget _buildReviewCard(Map<String, dynamic> reviewData) {
    final textTheme = Theme.of(context).textTheme;
    final rating = (reviewData['rating'] as num?)?.toDouble() ?? 0.0;
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
                      backgroundImage: NetworkImage(userImage),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(userName,
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                Text(reviewData['reviewText'] ?? '', style: textTheme.bodyLarge),
              ],
            ),
          ),
        );
      },
    );
  }

  // Keep existing average rating widget (It is okay to read all reviews for just the count/rating sum if needed, 
  // or ideally you should store 'averageRating' directly on the product document to save reads)
  Widget _buildAverageRatingWidget(String productId) {
      // (Your existing code here is fine for now, but for scalability, 
      // calculate average rating when ADDING the review and save it to product doc)
      return const SizedBox(); 
  }
}