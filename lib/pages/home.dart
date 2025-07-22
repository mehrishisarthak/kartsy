import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/category_products.dart';
import 'package:ecommerce_shop/pages/discover_page.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:ecommerce_shop/pages/profile.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/widget/support_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? uid;
  String userName = '';
  String userImageUrl = '';
  bool _isLoading = true;

  // Data-driven approach for categories for better scalability
  final List<Map<String, String>> categories = [
    {'name': 'All', 'image': ''},
    {'name': 'Headphones', 'image': 'images/products/headphone.png'},
    {'name': 'Laptop', 'image': 'images/products/laptop.png'},
    {'name': 'TV', 'image': 'images/products/tv.png'},
    {'name': 'Watch', 'image': 'images/products/watch.png'},
  ];

  @override
  void initState() {
    super.initState();
    // Use a single initialization function to avoid race conditions
    _initializeData();
  }

  /// A single, safe initialization function to load all necessary data.
  Future<void> _initializeData() async {
    final prefs = SharedPreferenceHelper();
    uid = await prefs.getUserID();
    
    if (uid != null) {
      // Run both data loading operations concurrently for speed
      await Future.wait([
        _loadUserData(uid!),
        _loadCartData(uid!),
      ]);
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load cart data from Firestore and sync with the local CartProvider.
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
          'name': data['name'] ?? 'Unnamed',
          'price': (data['price'] as num?)?.toDouble() ?? 0.0,
          'quantity': (data['quantity'] as int?) ?? 1,
          'image': data['image'] ?? '',
        };
      }).toList();

      if (mounted) {
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        cartProvider.setCart(cartItems);
      }
    } catch (e) {
      print("Error loading cart data: $e");
      // Optionally show a snackbar for cart loading errors
    }
  }

  /// Load user's name and profile image URL.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView( // Changed to SingleChildScrollView for better layout flexibility
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top greeting + profile pic
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hey, $userName!', style: AppWidget.boldTextStyle()),
                              Text('Good day!', style: AppWidget.lightTextStyle()),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfilePage()),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blue, width: 2),
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: userImageUrl.isNotEmpty
                                    ? Image.network(
                                        userImageUrl,
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30),
                                      )
                                    : const CircleAvatar(
                                        radius: 25,
                                        child: Icon(Icons.person),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20.0),
                      Text('What are you looking for?', style: AppWidget.lightTextStyle()),
                      const SizedBox(height: 10),
                      // --- Search TextField ---
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for products',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: const Color.fromARGB(255, 240, 240, 240),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30.0),
                      Text('Categories', style: AppWidget.boldTextStyle()),
                      const SizedBox(height: 20.0),
                      // --- Categories List ---
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
                                final categoryName = categoryItem['name']!;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CategoryProducts(category: categoryName),
                                  ),
                                );
                              },
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: isAll ? Colors.blue : Colors.transparent,
                                  border: Border.all(color: Colors.blue, width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: isAll
                                    ? Center(
                                        child: Text(
                                          'All',
                                          style: AppWidget.boldTextStyle().copyWith(color: Colors.white, fontSize: 18),
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0), // Add padding for images
                                          child: Image.asset(categoryItem['image']!, fit: BoxFit.contain),
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 30.0),
                      // --- Featured Products Section ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Featured Products', style: AppWidget.boldTextStyle()),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const DiscoverPage()),
                              );
                            },
                            child: Text(
                              'See All',
                              style: AppWidget.lightTextStyle().copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      SizedBox(
                        height: 260,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('products').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return const Center(child: Text("Something went wrong"));
                            }

                            final products = snapshot.data?.docs ?? [];
                            if (products.isEmpty) {
                              return const Center(child: Text("No products found"));
                            }

                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: products.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final product = products[index].data() as Map<String, dynamic>;
                                final name = product['Name'] ?? 'Product';
                                final price = product['Price'] ?? '--';
                                final image = product['Image'] ?? '';

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetails(productData: product),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 160,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(color: Colors.blue.shade200, width: 1.5),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                        )
                                      ]
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        if (image.isNotEmpty)
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                            child: Image.network(
                                              image,
                                              height: 140,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 80),
                                            ),
                                          ),
                                        const Spacer(),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text(
                                            name,
                                            style: AppWidget.boldTextStyle().copyWith(fontSize: 16),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Spacer(),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text(
                                            '₹$price',
                                            style: AppWidget.lightTextStyle().copyWith(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
