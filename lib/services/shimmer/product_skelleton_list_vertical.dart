import 'package:ecommerce_shop/services/shimmer/product_skelleton_vertical.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VerticalProductsSkeleton extends StatelessWidget {
  const VerticalProductsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        itemCount: 5, // Show 5 placeholder cards
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) => const VerticalProductCardSkeleton(),
      ),
    );
  }
}