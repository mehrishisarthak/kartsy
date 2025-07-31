import 'package:flutter/material.dart';

class VerticalProductCardSkeleton extends StatelessWidget {
  const VerticalProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Placeholder
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          // Text Placeholders
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: double.infinity, color: Colors.grey),
                const SizedBox(height: 8),
                Container(height: 14, width: 100, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}