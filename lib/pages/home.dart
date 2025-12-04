import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/category_products.dart';
import 'package:ecommerce_shop/pages/discover_page.dart';
import 'package:ecommerce_shop/pages/product_details.dart'; 
import 'package:ecommerce_shop/pages/profile.dart';
import 'package:ecommerce_shop/pages/seach_page.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/services/shimmer/home_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.userId});

  final String? userId;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? uid;
  String userName = '';
  String userImageUrl = '';
  bool _isPageLoading = true; // For the initial page load

  // --- PAGINATION VARIABLES ---
  final ScrollController _horizontalScrollController = ScrollController();
  List<DocumentSnapshot> _products = [];
  bool _isLoadingMoreProducts = false;
  bool _hasMoreProducts = true;
  DocumentSnapshot? _lastProductDoc;
  
  // INCREASED BATCH SIZE FOR BETTER UX
  static const int _productsPerBatch = 10; 

  static const List<Map<String, String>> categories = [
    {'name': 'All', 'image': ''},
    {'name': 'Headphones', 'image': 'images/products/headphone.png'},
    {'name': 'Laptop', 'image': 'images/products/laptop.png'},
    {'name': 'TV', 'image': 'images/products/tv.png'},
    {'name': 'Watch', 'image': 'images/products/watch.png'},
  ];

  @override
  void initState() {
    super.initState();
    uid = widget.userId;
    _initializeData();

    // Setup listener for horizontal scrolling (Lazy Loading)
    _horizontalScrollController.addListener(() {
      if (_horizontalScrollController.position.pixels >=
          _horizontalScrollController.position.maxScrollExtent - 100) {
        _fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  /// Loads User, Cart, and First Batch of Products concurrently
  Future<void> _initializeData() async {
    await Future.wait([
      _loadUserData(uid!),
      _loadCartData(uid!),
      _fetchProducts(),
    ]);

    if (mounted) {
      setState(() {
        _isPageLoading = false;
      });
    }
  }

  /// Fetches products in batches
  Future<void> _fetchProducts() async {
    if (_isLoadingMoreProducts || !_hasMoreProducts) return;

    if (mounted) setState(() => _isLoadingMoreProducts = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .orderBy('Name') // CRITICAL: Deterministic order for pagination
          .limit(_productsPerBatch);

      if (_lastProductDoc != null) {
        query = query.startAfterDocument(_lastProductDoc!);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.length < _productsPerBatch) {
        _hasMoreProducts = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastProductDoc = querySnapshot.docs.last;
        if (mounted) {
          setState(() {
            _products.addAll(querySnapshot.docs);
          });
        }
      }
    } catch (e) {
      print("Error fetching products: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMoreProducts = false);
    }
  }

  Future<void> _loadCartData(String userId) async {
    try {
      final cartSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      final cartItems = cartSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'Name': data['Name'] ?? 'Unnamed Product',
          'Price': (data['Price'] as num?)?.toDouble() ?? 0.0,
          'quantity': (data['quantity'] as int?) ?? 1,
          'Image': data['Image'] ?? '',
          'adminId': data['adminId'],
          'category': data['category'],
          'description': data['description'],
          'inventory': data['inventory'],
        };
      }).toList();

      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).setCart(cartItems);
      }
    } catch (e) {
      print("Error loading cart data: $e");
    }
  }

  Future<void> _loadUserData(String userId) async {
    final prefs = SharedPreferenceHelper();
    final name = await prefs.getUserName();

    if (name != null && name.trim().isNotEmpty) {
      userName = name.trim().split(' ')[0];
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        userImageUrl = userDoc['Image'] ?? '';
      }
    } catch (e) {
      print("Error loading user image: $e");
    }
  }

  // --- HELPER WIDGET: Rating Row ---
  Widget _buildRatingRow(Map<String, dynamic> data) {
    double rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
    int count = (data['reviewCount'] as num?)?.toInt() ?? 0;

    // Don't show anything if no reviews yet
    if (count == 0) return const SizedBox(height: 5); 

    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 14),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1), // e.g. "4.5"
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          Text(
            " ($count)", // e.g. " (12)"
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // Use Shimmer when loading
      body: _isPageLoading
          ? const HomeScreenShimmer()
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header Section ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hey, $userName!',
                                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              Text('Good day!',
                                  style: textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: uid)));
                            },
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                border: Border.all(color: colorScheme.primary, width: 2),
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: userImageUrl.isNotEmpty
                                    ? Image.network(
                                        userImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person),
                                      )
                                    : CircleAvatar(
                                        backgroundColor: colorScheme.surface,
                                        child: const Icon(Icons.person),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      
                      Text('What are you looking for?',
                          style: textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
                      const SizedBox(height: 10),
                      
                      // --- SEARCH BAR (Navigates to SearchPage) ---
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey[100], 
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 10),
                              Text(
                                "Search for products...",
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30.0),

                      // --- Categories Section ---
                      Text('Categories', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20.0),
                      SizedBox(
                        height: 100,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final categoryItem = categories[index];
                            final isAll = categoryItem['name'] == 'All';
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryProducts(category: categoryItem['name']!),
                                  ),
                                );
                              },
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: isAll ? colorScheme.primary : colorScheme.surface,
                                  border: Border.all(color: colorScheme.primary, width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: isAll
                                    ? Center(
                                        child: Text('All',
                                            style: textTheme.titleMedium?.copyWith(
                                                color: colorScheme.onPrimary, fontWeight: FontWeight.bold)))
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Image.asset(categoryItem['image']!, fit: BoxFit.contain),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30.0),

                      // --- Featured Products Section (Lazy Loaded) ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Featured Products',
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const DiscoverPage()));
                            },
                            child: Text('See All',
                                style: textTheme.titleSmall?.copyWith(
                                    color: colorScheme.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      // Horizontal ListView
                      SizedBox(
                        height: 250, // Increased height slightly to accommodate Rating Row
                        child: _products.isEmpty && !_isPageLoading
                            ? const Center(child: Text("No products found."))
                            : ListView.separated(
                                controller: _horizontalScrollController,
                                scrollDirection: Axis.horizontal,
                                itemCount: _products.length + (_hasMoreProducts ? 1 : 0),
                                separatorBuilder: (context, index) => const SizedBox(width: 15),
                                itemBuilder: (context, index) {
                                  // Loader at the end
                                  if (index == _products.length) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(20.0),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final productData = _products[index].data() as Map<String, dynamic>;

                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(
                                          builder: (context) => ProductDetails(productId: productData['id'])));
                                    },
                                    child: Container(
                                      width: 160,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surface,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Container(
                                                color: Colors.grey[100],
                                                child: Image.network(
                                                  productData['Image'] ?? '',
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, progress) {
                                                    if (progress == null) return child;
                                                    return const Center(child: Icon(Icons.image, color: Colors.grey));
                                                  },
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            productData['Name'] ?? 'No Name',
                                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          // --- ADDED RATING ROW HERE ---
                                          const SizedBox(height: 4),
                                          _buildRatingRow(productData),
                                          
                                          const SizedBox(height: 4),
                                          Text(
                                            "₹${productData['Price']}",
                                            style: textTheme.titleSmall?.copyWith(
                                                color: colorScheme.primary, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}