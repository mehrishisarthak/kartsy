import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class RootWrapperLoading extends StatelessWidget {
  const RootWrapperLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withAlpha(25),
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  // Illustration placeholder (top image)
                  const _SkeletonBox(
                    width: double.infinity,
                    height: 200,
                    borderRadius: 24,
                  ),
                  const SizedBox(height: 32),
                  // Title
                  const _SkeletonBox(width: 200, height: 28),
                  const SizedBox(height: 12),
                  // Subtitle
                  const _SkeletonBox(width: 160, height: 18),
                  const SizedBox(height: 32),
                  // Email field
                  const _SkeletonBox(width: double.infinity, height: 56, borderRadius: 16),
                  const SizedBox(height: 16),
                  // Password field
                  const _SkeletonBox(width: double.infinity, height: 56, borderRadius: 16),
                  const SizedBox(height: 24),
                  // Login button
                  const _SkeletonBox(width: double.infinity, height: 56, borderRadius: 20),
                  const SizedBox(height: 24),
                  // Divider
                  Row(
                    children: const [
                      Expanded(child: _SkeletonBox(width: double.infinity, height: 1, borderRadius: 0)),
                      SizedBox(width: 16),
                      _SkeletonBox(width: 40, height: 12, borderRadius: 4),
                      SizedBox(width: 16),
                      Expanded(child: _SkeletonBox(width: double.infinity, height: 1, borderRadius: 0)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Google button
                  const _SkeletonBox(width: double.infinity, height: 56, borderRadius: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
