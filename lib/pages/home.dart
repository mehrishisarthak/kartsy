import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/category_products.dart';
import 'package:ecommerce_shop/pages/discover_page.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:ecommerce_shop/pages/profile.dart';
import 'package:ecommerce_shop/pages/search_page.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/shimmer/home_shimmer.dart';
import 'package:ecommerce_shop/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // ✅ Added for nicer stars
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- STATE VARIABLES ---
  String userName = '';
  String userImageUrl = '';
  String userCity = 'Jaipur'; // Default fallback
  
  List<DocumentSnapshot> _homeDecorProducts = [];
  List<DocumentSnapshot> _furnitureProducts = [];
  bool _isPageLoading = true;

  // ✅ MODERN CATEGORY CONFIG
  static const List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Furniture', 'icon': Icons.chair_outlined},
    {'name': 'Home Decor', 'icon': Icons.local_florist_outlined},
  ];

  // Carousel Assets
  final List<String> _carouselImages = [
    "images/listings/headphone.png",
    "images/products/laptop.png",
    "images/products/watch.png",
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // --- DATA FETCHING ---

  Future<void> _initializeData() async {
    await _loadUserData();
    
    // Parallel Fetching for Speed
    await Future.wait([
      _loadCartData(), 
      _fetchCategoryProducts('Home Decor'), 
      _fetchCategoryProducts('Furniture'),
    ]);

    if (mounted) {
      setState(() => _isPageLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc.exists && mounted) {
        final data = userDoc.data();
        setState(() {
          String fullName = data?['Name'] ?? 'User';
          userName = fullName.split(' ')[0]; // First Name only
          userImageUrl = data?['Image'] ?? '';
          
          final address = data?['Address'] as Map<String, dynamic>?;
          if (address != null && address['city'] != null) {
            userCity = address['city'];
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    }
  }

  Future<void> _loadCartData() async {
    try {
      final cartSnap = await FirebaseFirestore.instance
          .collection('users').doc(widget.userId).collection('cart').get();
      
      final cartItems = cartSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      
      if (mounted) {
        Provider.of<CartProvider>(context, listen: false).setCart(cartItems);
      }
    } catch (e) {
      debugPrint("Cart load error: $e");
    }
  }

  Future<void> _fetchCategoryProducts(String category) async {
    try {
      Query query;
      // 🛡️ CITY FENCING LOGIC for Furniture
      if (category == 'Furniture') {
        query = FirebaseFirestore.instance
            .collection('cities')
            .doc(userCity)
            .collection('products')
            .where('category', isEqualTo: 'Furniture')
            .limit(10);
      } else {
        query = FirebaseFirestore.instance
            .collection('products')
            .where('category', isEqualTo: category)
            .limit(10);
      }

      final snapshot = await query.get();
      
      if (mounted) {
        setState(() {
          if (category == 'Furniture') {
            _furnitureProducts = snapshot.docs;
          } else {
            _homeDecorProducts = snapshot.docs;
          }
        });
      }
    } catch (e) {
      debugPrint("Fetch error ($category): $e");
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isPageLoading) return const HomeScreenShimmer();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Theme Aware
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // 1. HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getGreeting(), style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('$userName 👋', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: widget.userId))),
                        child: StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
                          builder: (context, snapshot) {
                            String liveImage = userImageUrl;
                            if (snapshot.hasData && snapshot.data!.exists) {
                               liveImage = snapshot.data!.get('Image') ?? userImageUrl;
                            }
                            if (liveImage.isEmpty) liveImage = AppConstants.defaultProfileImage;

                            return CircleAvatar(
                              radius: 24,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              backgroundImage: CachedNetworkImageProvider(liveImage),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. SEARCH BAR
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SearchPage(userCity: userCity)), 
                    ),
                    child: Container(
                      height: 55,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (!isDark) 
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text("Search in $userCity...", style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // 3. JAIPUR BANNER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.orange.shade900.withOpacity(0.2) : Colors.orange.shade50,
                      border: Border.all(color: isDark ? Colors.orange.shade800 : Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Servicing Jaipur Only",
                                style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.orange.shade200 : Colors.orange.shade900),
                              ),
                              Text(
                                "We currently operate exclusively in Jaipur, Rajasthan.",
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.orange.shade100 : Colors.orange.shade800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. CAROUSEL
                CarouselSlider(
                  options: CarouselOptions(
                    height: 160.0,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.85,
                  ),
                  items: _carouselImages.map((imagePath) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),

                // 5. CATEGORIES
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Browse Categories',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final categoryItem = categories[index];
                      final isAll = categoryItem['name'] == 'All';
                      
                      return GestureDetector(
                        onTap: () {
                           if (!isAll) {
                             Navigator.push(context, MaterialPageRoute(
                               builder: (_) => CategoryProducts(
                                 category: categoryItem['name'], 
                                 userCity: userCity
                               )
                             ));
                           } else {
                             Navigator.push(context, MaterialPageRoute(
                               builder: (_) => DiscoverPage(userCity: userCity)
                             ));
                           }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isAll ? colorScheme.primary : (isDark ? colorScheme.surfaceContainerHighest : Colors.white),
                            borderRadius: BorderRadius.circular(25),
                            border: isAll ? null : Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
                            boxShadow: [
                              if (!isAll && !isDark) 
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(categoryItem['icon'], size: 20, color: isAll ? colorScheme.onPrimary : colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                categoryItem['name'],
                                style: TextStyle(
                                  color: isAll ? colorScheme.onPrimary : colorScheme.onSurface, 
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // 6. HOME DECOR FEED
                _buildSectionHeader(
                  title: "Fresh Home Decor", 
                  onTapSeeAll: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CategoryProducts(category: 'Home Decor', userCity: userCity)
                  ))
                ),
                const SizedBox(height: 16),
                _buildProductSlider(_homeDecorProducts, isLeadGen: false),

                const SizedBox(height: 32),

                // 7. FURNITURE FEED
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text("Furniture in $userCity", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CategoryProducts(category: 'Furniture', userCity: userCity)
                        )),
                        child: Text("See All", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildProductSlider(_furnitureProducts, isLeadGen: true),

                const SizedBox(height: 40),

                // 8. BROWSE ALL BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DiscoverPage(userCity: userCity)),
                      ),
                      icon: const Icon(Icons.explore_outlined),
                      label: const Text("Browse All Products"),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionHeader({required String title, required VoidCallback onTapSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          GestureDetector(onTap: onTapSeeAll, child: Text("See All", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildProductSlider(List<DocumentSnapshot> products, {required bool isLeadGen}) {
    if (products.isEmpty) {
      return Container(
        height: 200, margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100], 
          borderRadius: BorderRadius.circular(16)
        ),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(isLeadGen ? Icons.chair_outlined : Icons.inventory_2_outlined, color: Colors.grey[400], size: 40),
          const SizedBox(height: 8),
          Text(isLeadGen ? "No furniture leads nearby." : "New arrivals coming soon!", style: TextStyle(color: Colors.grey[500]))
        ])),
      );
    }
    return SizedBox(
      height: 260, // Slightly increased for ratings
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final data = products[index].data() as Map<String, dynamic>;
          return _buildCard(data, isLeadGen);
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data, bool isLeadGen) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Safety
    double rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
    int reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetails(productId: data['id']))),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white, 
          borderRadius: BorderRadius.circular(16), 
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 15, offset: const Offset(0, 5))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), 
                    child: CachedNetworkImage(
                      imageUrl: data['Image'] ?? '', 
                      width: double.infinity, 
                      height: double.infinity, 
                      fit: BoxFit.cover, 
                      errorWidget: (_, __, ___) => Container(color: Colors.grey[200])
                    )
                  ),
                  if (isLeadGen) Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade700.withOpacity(0.9), borderRadius: BorderRadius.circular(8)), child: const Text("Lead", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
            Expanded(
              flex: 4, 
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data['Name'] ?? 'No Name', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    
                    // ✅ RATING ROW
                    if (reviewCount > 0) 
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: rating,
                            itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 12.0,
                          ),
                          const SizedBox(width: 4),
                          Text("($reviewCount)", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ],
                      ),
                      
                    const SizedBox(height: 6),
                    Text("₹${data['Price']}", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}