import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreenShimmer extends StatelessWidget {
  const HomeScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on your Theme
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Light Mode: Grey[300] to Grey[100] matches your #F8F9FB bg
    // Dark Mode: Grey[800] to Grey[700] matches your #121212 bg
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Scaffold(
      body: SafeArea(
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. Header Section (Text + Avatar) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SkeletonBox(width: 120, height: 24), // "Hey, Name!"
                        const SizedBox(height: 8),
                        _SkeletonBox(width: 80, height: 16),  // "Good day!"
                      ],
                    ),
                    const _SkeletonBox(width: 50, height: 50, isCircle: true), // Profile Pic
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // --- 2. Search Bar ---
                const _SkeletonBox(width: double.infinity, height: 50),
                
                const SizedBox(height: 30),

                // --- 3. Categories Section ---
                const _SkeletonBox(width: 100, height: 24), // Title "Categories"
                const SizedBox(height: 20),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    physics: const NeverScrollableScrollPhysics(), // Disable scrolling on shimmer
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      // First item mimics "All" (filled), others mimic images
                      return const _SkeletonBox(width: 100, height: 100);
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // --- 4. Featured Products Section ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _SkeletonBox(width: 150, height: 24), // Title
                    _SkeletonBox(width: 60, height: 16),  // "See All"
                  ],
                ),
                const SizedBox(height: 20),
                
                // Horizontal Product List Shimmer
                SizedBox(
                  height: 240,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    physics: const NeverScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(width: 15),
                    itemBuilder: (_, __) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Placeholder
                          const _SkeletonBox(width: 160, height: 170),
                          const SizedBox(height: 10),
                          // Name Placeholder
                          const _SkeletonBox(width: 140, height: 16),
                          const SizedBox(height: 5),
                          // Price Placeholder
                          const _SkeletonBox(width: 80, height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widget for consistent Rounded Corners (Matches your theme's radius: 12)
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final bool isCircle;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.isCircle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black, // Color doesn't matter here, Shimmer overrides it
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(12),
      ),
    );
  }
}