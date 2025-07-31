import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/product_details.dart';
import 'package:ecommerce_shop/services/shimmer/product_skelleton_list_horizontal.dart';
import 'package:ecommerce_shop/widget/support_widget.dart';
import 'package:flutter/material.dart';

class HorizontalProductsList extends StatelessWidget {
  const HorizontalProductsList({super.key, required this.stream});
  final Stream<QuerySnapshot> stream;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: FeaturedProductsSkeleton());
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
              final productDoc = products[index];
              final productData = productDoc.data() as Map<String, dynamic>;

              final completeProductData = {
                ...productData,
                'id': productDoc.id,
              };

              final name = completeProductData['Name'] ?? 'Product';
              final price = completeProductData['Price'] ?? '--';
              final image = completeProductData['Image'] ?? '';

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetails(productData: completeProductData),
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
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
    );
  }
}