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
      title: 'Join the virTwirl Community', // Updated text to match branding
      description: 'Become part of a vibrant community of shoppers and sellers. Your next favorite thing awaits.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignupPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLastPage = _currentPageIndex == _onboardingData.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Main PageView Carousel
          // We add padding at the top so the content doesn't overlap the fixed header
          Padding(
            padding: const EdgeInsets.only(top: 60.0), 
            child: PageView.builder(
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
          ),

          // 2. Fixed Branding Header (Top Left)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Row(
                  children: [
                    // Icon Logo (Optional, removed to keep it text-only as requested)
                    // Icon(Icons.view_in_ar_rounded, color: colorScheme.primary, size: 24),
                    // SizedBox(width: 8),
                    
                    // BRANDING TEXT
                    Text(
                      'virTwirl',
                      style: GoogleFonts.poppins(
                        fontSize: 24, // Prominent size
                        fontWeight: FontWeight.bold, // Bold like logo
                        color: colorScheme.primary, // Accent Blue
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Navigation Controls (Bottom)
          Positioned(
            bottom: 30.0,
            left: 20.0,
            right: 20.0,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  // Dot Indicator
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _onboardingData.length,
                    effect: WormEffect(
                      spacing: 12,
                      dotWidth: 10,
                      dotHeight: 10,
                      dotColor: colorScheme.primary.withOpacity(0.3), // Light blue
                      activeDotColor: colorScheme.primary, // Accent Blue
                    ),
                  ),

                  // Next / Done Button
                  SizedBox(
                    width: 80,
                    child: isLastPage
                        ? TextButton(
                            onPressed: _completeOnboarding,
                            child: Text(
                              'Done',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                        : IconButton(
                            tooltip: 'Next',
                            icon: Icon(
                              Icons.arrow_forward_ios,
                              color: colorScheme.primary,
                            ),
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
            ),
          ),
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
    final colorScheme = theme.colorScheme;

    final titleStyle = GoogleFonts.poppins(
      textStyle: theme.textTheme.headlineSmall,
      fontWeight: FontWeight.bold,
      color: theme.textTheme.titleLarge?.color, // Ensure readable text in dark mode
    );

    final descriptionStyle = GoogleFonts.poppins(
      textStyle: theme.textTheme.bodyMedium,
      color: Colors.grey[600],
      height: 1.5,
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
              // Fallback icon if Lottie fails
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.shopping_bag_outlined, 
                  size: 100, 
                  color: colorScheme.primary.withOpacity(0.3)
                );
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
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