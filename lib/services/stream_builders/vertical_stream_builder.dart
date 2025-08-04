import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:ecommerce_shop/services/shimmer/product_skelleton_list_vertical.dart';
import 'package:flutter/material.dart';

class VerticalProductsList extends StatelessWidget {
  const VerticalProductsList({super.key, required this.stream});
  final Stream<QuerySnapshot> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Use the vertical skeleton loader
          return const VerticalProductsSkeleton();
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        final products = snapshot.data?.docs ?? [];
        if (products.isEmpty) {
          return const Center(child: Text("No products found"));
        }

        // Configure the ListView for vertical display
        return ListView.separated(
          itemCount: products.length,
          shrinkWrap: true, // Important for nesting in a SingleChildScrollView
          physics: const NeverScrollableScrollPhysics(), // Also for nesting
          padding: const EdgeInsets.symmetric(horizontal: 20),
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final productDoc = products[index];
            final productData = productDoc.data() as Map<String, dynamic>;

            final completeProductData = {
              ...productData,
              'id': productDoc.id,
            };

            // This can be a separate _ProductCard widget if you prefer
            return _buildProductCard(context, completeProductData);
          },
        );
      },
    );
  }

  // This is the card UI from your DiscoverPage, now part of this widget
  Widget _buildProductCard(BuildContext context, Map<String, dynamic> productData) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final name = productData['Name'] ?? 'Unnamed';
    final price = productData['Price'] ?? 0;
    final image = productData['Image'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetails(productData: productData),
          ),
        );
      },
      child: Card(
        // Using Card widget which respects the theme's cardTheme
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                image,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹$price',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
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
  }
}
