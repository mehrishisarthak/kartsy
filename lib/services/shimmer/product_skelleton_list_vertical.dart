import 'package:ecommerce_shop/services/shimmer/product_skelleton_vertical.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class VerticalProductsSkeleton extends StatelessWidget {
  const VerticalProductsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define shimmer colors based on the current theme
    final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
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
