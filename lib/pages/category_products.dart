import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:ecommerce_shop/services/shimmer/product_skelleton_vertical.dart';
import 'package:flutter/material.dart';

class CategoryProducts extends StatefulWidget {
  final String category;
  final String userCity; // ✅ Critical for Furniture logic

  const CategoryProducts({
    super.key,
    required this.category,
    required this.userCity,
  });

  @override
  State<CategoryProducts> createState() => _CategoryProductsState();
}

class _CategoryProductsState extends State<CategoryProducts> {
  final ScrollController _scrollController = ScrollController();
  
  // State
  final List<DocumentSnapshot> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;
  DocumentSnapshot? _lastDocument;
  static const int _limit = 10;

  @override
  void initState() {
    super.initState();
    _fetchProducts();

    // Pagination Listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) { // Pre-fetch before hitting bottom
        _fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 🔄 Refresh Logic
  Future<void> _onRefresh() async {
    setState(() {
      _products.clear();
      _lastDocument = null;
      _hasMore = true;
      _hasError = false;
    });
    await _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (_isLoading || !_hasMore) return;

    if (mounted) setState(() { 
      _isLoading = true;
      _hasError = false;
    });

    try {
      Query query;

      // 🛡️ LOGIC SPLIT:
      // Furniture = Local City Collection (Lead Gen)
      // Home Decor (and others) = Global Collection (Direct Buy)
      if (widget.category == 'Furniture') {
        query = FirebaseFirestore.instance
            .collection('cities')
            .doc(widget.userCity)
            .collection('products')
            .where('category', isEqualTo: 'Furniture');
      } else {
        query = FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: widget.category);
      }

      // Sorting & Pagination
      query = query.orderBy('Name').limit(_limit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.length < _limit) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        if (mounted) {
          setState(() => _products.addAll(snapshot.docs));
        }
      }
    } catch (e) {
      debugPrint("Error loading category products: $e");
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: _hasError && _products.isEmpty
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: _products.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _products.length + (_hasMore ? 1 : 0), // +1 for loader
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        // Bottom Loader
                        if (index == _products.length) {
                          return const VerticalProductCardSkeleton();
                        }

                        final productData = _products[index].data() as Map<String, dynamic>;
                        return _buildProductCard(productData);
                      },
                    ),
            ),
    );
  }

  // --- UI STATES ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No ${widget.category} items found",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          if (widget.category == 'Furniture')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "in ${widget.userCity}",
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          const Text("Something went wrong"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _onRefresh,
            child: const Text("Retry"),
          )
        ],
      ),
    );
  }

  // --- PRODUCT CARD ---

  Widget _buildProductCard(Map<String, dynamic> productData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetails(productId: productData['id']),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: productData['Image'] ?? '',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[200]),
                errorWidget: (context, url, error) => Container(
                  width: 120, height: 120,
                  color: Colors.grey[100],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productData['Name'] ?? 'No Name',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildRatingRow(productData),
                    const SizedBox(height: 8),
                    Text(
                      "₹${productData['Price']}",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(Map<String, dynamic> data) {
    double rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
    int count = (data['reviewCount'] as num?)?.toInt() ?? 0;

    if (count == 0) return const SizedBox(height: 5);

    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 14),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          " ($count)",
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}