import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Duration for Entry
    );

    // 2. Define Animations
    // Scale: 0.5 -> 1.0 (Bops in, shrinks out)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    // Opacity: 0.0 -> 1.0 (Fades in, fades out)
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    // Rotation: Slight "Twirl" (-0.1 turns to 0)
    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // 3. Start the Sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // A. Play Entry Animation (Fade In)
    await _controller.forward();

    // B. Hold text on screen for 1 second
    await Future.delayed(const Duration(seconds: 1));

    // C. Check mounted before starting exit
    if (!mounted) return;

    // D. Play Exit Animation (Reverse: Fade Out & Shrink)
    // We reverse slightly faster (from 1.0 to 0) for a snappy exit
    await _controller.reverse().orCancel;

    // E. Navigate
    if (mounted) {
      // ✅ Uses named route to respect your main.dart logic
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Removed Here
                      
                      // Just the Text Logo
                      Text(
                        "virTwirl",
                        style: GoogleFonts.poppins(
                          fontSize: 42,
                          fontWeight: FontWeight.w900, // Extra Bold
                          color: colorScheme.primary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}