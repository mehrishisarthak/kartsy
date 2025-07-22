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
  String category = 'All';
  String userName = '';
  String userImageUrl = '';
  bool _isLoading = true; // Add a loading state for initial data fetch

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

  // 1. A single, safe initialization function
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

  // 2. Load cart data with proper error handling
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

  // 3. Simplified user data loading
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
                            child: ClipOval( // Use ClipOval for perfect circles
                              child: userImageUrl.isNotEmpty
                                  ? Image.network(
                                      userImageUrl,
                                      height: 50,
                                      width: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30), // Better fallback
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
                    // ... your TextField ...

                    const SizedBox(height: 30.0),
                    Text('Categories', style: AppWidget.boldTextStyle()),
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
                                      child: Image.asset(categoryItem['image']!, fit: BoxFit.contain, // Use contain for logos
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30.0),
                    // ... your Featured Products Row and StreamBuilder ...
                  ],
                ),
              ),
            ),
    );
  }
}