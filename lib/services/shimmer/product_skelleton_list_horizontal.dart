import 'package:ecommerce_shop/services/shimmer/product_skelleton_horizontal.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// This widget will be shown during the loading state.
class FeaturedProductsSkeleton extends StatelessWidget {
  const FeaturedProductsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 5, // Show 5 placeholder cards
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => const ProductCardSkeleton(),
        ),
      ),
    );
  }
}