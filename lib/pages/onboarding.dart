import 'package:ecommerce_shop/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

// Data Model
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
  final VoidCallback? onComplete;

  const OnboardingScreen({super.key, this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
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

  // --- FIXED: Handle onboarding completion with callback OR navigation ---
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    if (!mounted) return;

    // If callback provided (from RootWrapper), use it to rebuild
    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      // Fallback: Navigate to SignupPage (for direct launches)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignupPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                isActive: index == _currentPageIndex,
              );
            },
          ),
          // Navigation Controls
          Positioned(
            bottom: 30.0,
            left: 20.0,
            right: 20.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip Button
                TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // Dot Indicator
                // Dot Indicator
SmoothPageIndicator(
  controller: _controller,
  count: _onboardingData.length,
  effect: WormEffect(
    spacing: 12,
    dotColor: Colors.blue.shade200, // Light blue for inactive dots
    activeDotColor: Colors.blue.shade600, // Kartsy blue for active dot
  ),
),
                // Next/Get Started Button
                SizedBox(
                  width: 80,
                  child: isLastPage
                      ? TextButton(
                          onPressed: _completeOnboarding,
                          child: Text(
                            'Done',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
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

// Visual Page Component
class OnboardingPage extends StatelessWidget {
  final OnboardingItem item;
  final bool isActive;

  const OnboardingPage({
    super.key,
    required this.item,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;

    final titleStyle = GoogleFonts.poppins(
      textStyle: theme.textTheme.headlineSmall,
      fontWeight: FontWeight.bold,
    );

    final descriptionStyle = GoogleFonts.poppins(
      textStyle: theme.textTheme.bodyMedium,
      color: Colors.grey[600],
    );

    return Column(
      children: [
        // Top part for the animation
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(32.0),
            child: Lottie.asset(
              item.imagePath,
              animate: isActive,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.shopping_bag, size: 100, color: Colors.grey[300]);
              },
            ),
          ),
        ),
        // Bottom part for the text content
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            decoration: BoxDecoration(
              color: backgroundColor,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: titleStyle,
                ),
                const SizedBox(height: 16),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: descriptionStyle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
