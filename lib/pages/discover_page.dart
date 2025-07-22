import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:ecommerce_shop/widget/support_widget.dart';
import 'package:flutter/material.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  Widget _buildInfoCard({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppWidget.boldTextStyle().copyWith(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      // 1. The FloatingActionButton has been removed.
      body: Column(
        children: [
          // 🔷 Fixed Header
          Material(
            elevation: 6,
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Padding(
              // Adjusted padding for the new layout
              padding: const EdgeInsets.fromLTRB(20, 45, 20, 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Back button is now here, in the top-left.
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Icon(
                      Icons.arrow_back_ios_new_outlined,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Header text
                  Row(
                    children: [
                      Text('Discover ',
                          style: AppWidget.boldTextStyle().copyWith(
                              fontSize: 40,
                              color: Colors.blue,
                              fontWeight: FontWeight.w900)),
                      Text('Products',
                          style: AppWidget.boldTextStyle().copyWith(fontSize: 40)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('With ',
                          style: AppWidget.boldTextStyle()
                              .copyWith(fontSize: 40, fontWeight: FontWeight.w900)),
                      Text('Kartsy',
                          style: AppWidget.boldTextStyle().copyWith(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.blue)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 🔷 Scrollable Section (Search + Product List)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                // 🔍 Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search products...",
                      prefixIcon: const Icon(Icons.search, color: Colors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      hintStyle: AppWidget.lightTextStyle()
                          .copyWith(color: Colors.grey[600]),
                    ),
                    style: AppWidget.lightTextStyle(),
                    cursorColor: Colors.blue,
                  ),
                ),

                const SizedBox(height: 20),

                // Horizontal Scrollable Message Tiles
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildInfoCard(
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        text: "Kartsy makes it easy",
                        backgroundColor: Colors.blue.shade50,
                        iconColor: Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildInfoCard(
                        icon: Icons.shopping_cart_checkout_rounded,
                        text: "Shop with Kartsy",
                        backgroundColor: Colors.orange.shade50,
                        iconColor: Colors.deepOrange,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🛍️ Products from Firebase
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance.collection('products').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text(
                              'Something went wrong. Please try again later.'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No products found.'));
                    }

                    final products = snapshot.data!.docs;

                    return Column(
                      children: products.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['Name'] ?? 'Unnamed';
                        final price = data['Price'] ?? '0';
                        final image = data['Image'] ?? '';
                        final description =
                            data['Description'] ?? 'No description';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetails(productData: data),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.15),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    image,
                                    height: 120,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      height: 120,
                                      width: 120,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image,
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        softWrap: true,
                                        style: AppWidget.boldTextStyle()
                                            .copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        description,
                                        softWrap: true,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppWidget.lightTextStyle()
                                            .copyWith(
                                          fontSize: 15,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '₹ $price',
                                        style: AppWidget.lightTextStyle()
                                            .copyWith(
                                          fontSize: 17,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}