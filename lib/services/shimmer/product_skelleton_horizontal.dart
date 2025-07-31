// You can add this widget in the same file as your HomeScreen or a new file.

import 'package:flutter/material.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.grey[300],
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
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 5),
                Container(
                  height: 12,
                  width: 100,
                  color: Colors.grey[300],
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
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}