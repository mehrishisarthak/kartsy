import 'package:flutter/material.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final skeletonColor = theme.brightness == Brightness.light ? Colors.grey[300] : Colors.grey[800];

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
          ),
          const Spacer(),
          // Text line placeholders
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: double.infinity,
                  color: skeletonColor,
                ),
                const SizedBox(height: 5),
                Container(
                  height: 12,
                  width: 100,
                  color: skeletonColor,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
              height: 14,
              width: 60,
              color: skeletonColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
