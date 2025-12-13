import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:ecommerce_shop/services/shimmer/product_skelleton_list_vertical.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class VerticalProductsList extends StatelessWidget {
  const VerticalProductsList({super.key, required this.stream});
  final Stream<QuerySnapshot> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const VerticalProductsSkeleton();
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }

        final products = snapshot.data?.docs ?? [];
        if (products.isEmpty) {
          return const Center(child: Text("No products found"));
        }

        return ListView.separated(
          itemCount: products.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, index) {
            final productDoc = products[index];
            final productData = productDoc.data() as Map<String, dynamic>;
            return _buildProductCard(context, productData, productDoc.id);
          },
        );
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> productData, String productId) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final name = productData['Name'] ?? 'Unnamed';
    final price = productData['Price'] ?? 0;
    final image = productData['Image'] ?? '';
    
    // ✅ OPTIMIZATION: Read directly from product document
    final double rating = (productData['averageRating'] as num?)?.toDouble() ?? 0.0;
    final int reviewCount = (productData['reviewCount'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetails(productId: productId),
          ),
        );
      },
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
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
            
            // Info Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  // Rating Row (Only show if there are reviews)
                  if (reviewCount > 0) ...[
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 16.0,
                          direction: Axis.horizontal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "($reviewCount)",
                          style: textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Price (Highlighted)
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