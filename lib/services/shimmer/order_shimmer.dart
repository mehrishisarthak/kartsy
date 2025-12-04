import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OrdersShimmer extends StatelessWidget {
  const OrdersShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          children: List.generate(3, (index) => _buildShimmerOrderCard()),
        ),
      ),
    );
  }

  Widget _buildShimmerOrderCard() {
    return Container(
      height: 180, // Approximate height of an order card
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (ID and Status)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 100, height: 16, color: Colors.white),
              Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            ],
          ),
          const SizedBox(height: 10),
          Container(width: 150, height: 12, color: Colors.white), // Date
          const SizedBox(height: 20),
          
          // Item Row
          Row(
            children: [
              Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 120, height: 14, color: Colors.white),
                  const SizedBox(height: 5),
                  Container(width: 80, height: 12, color: Colors.white),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}