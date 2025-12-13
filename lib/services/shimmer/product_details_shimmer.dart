import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailsShimmer extends StatelessWidget {
  const ProductDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Scaffold(
      appBar: AppBar(
        title: Container(width: 100, height: 20, color: Colors.white),
        centerTitle: true,
      ),
      body: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Image Carousel Placeholder
              Container(
                height: 350,
                width: double.infinity,
                color: Colors.white,
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. Title
                    Container(height: 28, width: 200, color: Colors.white),
                    const SizedBox(height: 10),
                    
                    // 3. Price
                    Container(height: 32, width: 100, color: Colors.white),
                    const SizedBox(height: 10),
                    
                    // 4. Rating Row
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.white, size: 20)),
                        ),
                        const SizedBox(width: 8),
                        Container(height: 14, width: 100, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // 5. Details Header
                    Container(height: 24, width: 80, color: Colors.white),
                    const SizedBox(height: 10),
                    
                    // 6. Description Block
                    Column(
                      children: List.generate(4, (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Container(height: 14, width: double.infinity, color: Colors.white),
                      )),
                    ),
                    const SizedBox(height: 30),

                    // 7. Video Section Placeholder
                    Container(height: 24, width: 120, color: Colors.white),
                    const SizedBox(height: 15),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom Bar Placeholder
      bottomNavigationBar: Container(
        height: 80,
        padding: const EdgeInsets.all(20),
        color: Colors.white,
      ),
    );
  }
}