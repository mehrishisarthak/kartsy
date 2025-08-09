import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/category_products.dart';
import 'package:ecommerce_shop/pages/discover_page.dart';
import 'package:ecommerce_shop/pages/profile.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/services/stream_builders/horizontal_stream_builder.dart';
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
  bool _isLoading = true;

  // Made static const for memory efficiency (compile-time constant)
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
  }

  /// A single, safe function to load all necessary data when the screen starts.
  Future<void> _initializeData() async {
    
      // Run both data loading operations concurrently for speed
      await Future.wait([
        _loadUserData(uid!),
        _loadCartData(uid!),
      ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Loads the user's cart from Firestore and syncs it with the local provider.
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
        };
      }).toList();

      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).setCart(cartItems);
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error loading cart data: $e");
    }
  }

  /// Loads user's name and profile image URL.
  Future<void> _loadUserData(String userId) async {
    final prefs = SharedPreferenceHelper();
    final name = await prefs.getUserName();

    if (name != null && name.trim().isNotEmpty) {
      userName = name.trim().split(' ')[0]; // Show first name
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        userImageUrl = userDoc['Image'] ?? '';
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error loading user image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Top greeting + profile pic ---
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ProfilePage()),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: colorScheme.primary, width: 2),
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: userImageUrl.isNotEmpty
                                    ? Image.network(
                                        userImageUrl,
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person, size: 30),
                                      )
                                    : CircleAvatar(
                                        radius: 25,
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
                      // --- Search TextField ---
                      const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for products',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),

                      const SizedBox(height: 30.0),
                      Text('Categories', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
                                    builder: (context) =>
                                        CategoryProducts(category: categoryName),
                                  ),
                                );
                              },
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  color: isAll ? colorScheme.primary : colorScheme.surface,
                                  border:
                                      Border.all(color: colorScheme.primary, width: 2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: isAll
                                    ? Center(
                                        child: Text(
                                          'All',
                                          style: textTheme.titleMedium?.copyWith(
                                            color: colorScheme.onPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Image.asset(
                                              categoryItem['image']!,
                                              fit: BoxFit.contain),
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
                          Text('Featured Products',
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const DiscoverPage()),
                              );
                            },
                            child: Text(
                              'See All',
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      HorizontalProductsList(
                          stream: FirebaseFirestore.instance
                              .collection('products')
                              .snapshots()),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
