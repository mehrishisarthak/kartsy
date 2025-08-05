// lib/pages/onboarding_screen.dart (Optimized and Visually Improved)

import 'package:ecommerce_shop/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// No changes needed for the data model
class OnboardingItem {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingItem({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  // 1. We now track the current page index for optimization
  int _currentPageIndex = 0;

  final List<OnboardingItem> _onboardingData = [
    const OnboardingItem(
      imagePath: 'images/shopping1.json',
      title: 'Discover Unique Finds',
      description: 'Explore curated collections and one-of-a-kind items from independent creators.',
    ),
    const OnboardingItem(
      imagePath: 'images/shopping2.json',
      title: 'Shop Your Style',
      description: 'From modern trends to timeless classics, find pieces that truly represent you.',
    ),
    const OnboardingItem(
      imagePath: 'images/shopping3.json',
      title: 'Join the Kartsy Community',
      description: 'Become part of a vibrant community of shoppers and sellers. Your next favorite thing awaits.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToSignup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignupPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We can derive if it's the last page directly in the build method
    final isLastPage = _currentPageIndex == _onboardingData.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _onboardingData.length,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return OnboardingPage(
                item: _onboardingData[index],
                // 2. We pass the active status to each page for performance control
                isActive: index == _currentPageIndex,
              );
            },
          ),
          Positioned(
            bottom: 30.0,
            left: 20.0,
            right: 20.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip Button
                TextButton(
                  onPressed: _navigateToSignup,
                  child: Text('Skip', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                ),
                // Dot Indicator
                SmoothPageIndicator(
                  controller: _controller,
                  count: _onboardingData.length,
                  effect: WormEffect(
                    spacing: 12,
                    dotColor: Colors.grey.shade400,
                    activeDotColor: Theme.of(context).primaryColor,
                  ),
                ),
                // Next/Get Started Button
                SizedBox(
                  width: 80, // Give the button a fixed width
                  child: isLastPage
                      ? TextButton(
                          onPressed: _navigateToSignup,
                          child: Text('Done', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// 3. The OnboardingPage has been completely redesigned for clarity and performance
class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final bool isActive; // New parameter to control animation

  const OnboardingPage({
    super.key,
    required this.item,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    // Get theme colors for adaptability
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final titleStyle = theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold);
    final descriptionStyle = theme.textTheme.bodyLarge;

    return Column(
      children: [
        // Top part for the animation
        Expanded(
          flex: 6, // Give more space to the animation
          child: Container(
            padding: const EdgeInsets.all(32.0),
            child: Lottie.asset(
              item.imagePath,
              // 4. This is the key performance optimization!
              // The animation only plays if the page is active.
              animate: isActive,
            ),
          ),
        ),
        // Bottom part for the text content
        Expanded(
          flex: 4, // Give less space to the text
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            // The solid background guarantees readability
            decoration: BoxDecoration(
              color: backgroundColor,
              // Optional: add a subtle top border
              border: Border(top: BorderSide(color: theme.dividerColor, width: 1.0))
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(textStyle: titleStyle),
                ),
                const SizedBox(height: 16),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(textStyle: descriptionStyle),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}