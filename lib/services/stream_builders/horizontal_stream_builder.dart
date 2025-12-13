import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:ecommerce_shop/services/shimmer/product_skelleton_list_horizontal.dart';
import 'package:flutter/material.dart';

class HorizontalProductsList extends StatelessWidget {
  const HorizontalProductsList({super.key, required this.stream});
  final Stream<QuerySnapshot> stream;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SizedBox(
      height: 260,
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: FeaturedProductsSkeleton());
          }
          if (snapshot.hasError) return const Center(child: Text("Something went wrong"));

          final products = snapshot.data?.docs ?? [];
          if (products.isEmpty) return const Center(child: Text("No products found"));

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final data = productDoc.data() as Map<String, dynamic>;

              // ✅ Use Cached Data directly
              final double rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
              final int reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetails(productId: productDoc.id))),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border.all(color: colorScheme.primary.withAlpha(30), width: 1),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                        child: Image.network(
                          data['Image'] ?? '',
                          height: 140, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 140, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['Name'] ?? 'Product',
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // ✅ Rating Row
                            if (reviewCount > 0)
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text("$rating", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text(" ($reviewCount)", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              ),
                            const SizedBox(height: 4),
                            Text("₹${data['Price']}", style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}