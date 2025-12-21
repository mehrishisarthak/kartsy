import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ButtonShimmer extends StatelessWidget {
  const ButtonShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      // ignore: deprecated_member_use
      baseColor: Colors.white.withOpacity(0.2),
      // ignore: deprecated_member_use
      highlightColor: Colors.white.withOpacity(0.9),
      period: const Duration(milliseconds: 1000),
      child: Container(
        height: 12,
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}