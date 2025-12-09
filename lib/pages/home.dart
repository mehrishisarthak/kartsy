import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/category_products.dart';
import 'package:ecommerce_shop/pages/discover_page.dart';
import 'package:ecommerce_shop/pages/product_details.dart'; 
import 'package:ecommerce_shop/pages/profile.dart';
import 'package:ecommerce_shop/pages/seach_page.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shimmer/home_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  // We can force this to be non-nullable because RootWrapper guarantees it.
  final String userId; 

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String userName = '';
  String userImageUrl = '';
  bool _isPageLoading = true; 

  // --- PAGINATION VARIABLES ---
  final ScrollController _horizontalScrollController = ScrollController();
  final List<DocumentSnapshot> _products = [];
  bool _isLoadingMoreProducts = false;
  bool _hasMoreProducts = true;
  DocumentSnapshot? _lastProductDoc;
  
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

  Future<void> _initializeData() async {
    await Future.wait([
      _loadUserData(),
      _loadCartData(),
      _fetchProducts(),
    ]);

    if (mounted) {
      setState(() {
        _isPageLoading = false;
      });
    }
  }

  // 1. UPDATED: Fetch Cart Data using widget.userId
  Future<void> _loadCartData() async {
    try {
      final cartSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId) // Use widget.userId directly
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
      debugPrint("Error loading cart data: $e");
    }
  }

  // 2. FIXED: Fetch User Data strictly from Firestore (No SharedPreferences)
  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && mounted) {
        setState(() {
          // Robustly handle missing fields
          final data = userDoc.data();
          String fullName = data?['Name'] ?? 'User';
          userName = fullName.split(' ')[0]; // Get First Name
          userImageUrl = data?['Image'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading user profile: $e");
    }
  }

  Future<void> _fetchProducts() async {
    if (_isLoadingMoreProducts || !_hasMoreProducts) return;

    if (mounted) setState(() => _isLoadingMoreProducts = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('products')
          .orderBy('Name') 
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
      debugPrint("Error fetching products: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMoreProducts = false);
    }
  }

  Widget _buildRatingRow(Map<String, dynamic> data) {
    double rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
    int count = (data['reviewCount'] as num?)?.toInt() ?? 0;

    if (count == 0) return const SizedBox(height: 5); 

    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Row(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
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
                              Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.userId)));
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
                      
                      // --- SEARCH BAR ---
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
                                          child: Image.asset(
                                            categoryItem['image']!, 
                                            fit: BoxFit.contain,
                                            // Handle missing assets gracefully
                                            errorBuilder: (c, e, s) => const Icon(Icons.category),
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 30.0),

                      // --- Featured Products ---
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

                      SizedBox(
                        height: 250, 
                        child: _products.isEmpty && !_isPageLoading
                            ? const Center(child: Text("No products found."))
                            : ListView.separated(
                                controller: _horizontalScrollController,
                                scrollDirection: Axis.horizontal,
                                itemCount: _products.length + (_hasMoreProducts ? 1 : 0),
                                separatorBuilder: (context, index) => const SizedBox(width: 15),
                                itemBuilder: (context, index) {
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