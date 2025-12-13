import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/bottomnav.dart';
import 'package:ecommerce_shop/pages/login.dart';
import 'package:ecommerce_shop/pages/maintenance_screen.dart';
import 'package:ecommerce_shop/pages/onboarding.dart';
import 'package:ecommerce_shop/services/shimmer/root_wrapper_shimemr.dart'; // Ensure filename matches
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RootWrapper extends StatefulWidget {
  final bool showOnboarding;

  const RootWrapper({
    super.key,
    required this.showOnboarding,
  });

  @override
  State<RootWrapper> createState() => _RootWrapperState();
}

class _RootWrapperState extends State<RootWrapper> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    if (mounted) {
      setState(() => _showOnboarding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    // 1. Check Maintenance Mode First
    return FutureBuilder<bool>(
      future: _isMaintenanceMode(),
      builder: (context, maintenanceSnapshot) {
        // Show shimmer while checking maintenance status
        if (maintenanceSnapshot.connectionState == ConnectionState.waiting) {
          return const RootWrapperLoading();
        }

        // If explicitly in maintenance mode, block access
        if (maintenanceSnapshot.data == true) {
          return const MaintenanceScreen();
        }

        // 2. If not maintenance, proceed with Auth Check
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const RootWrapperLoading();
            }

            final user = snapshot.data;

            if (user != null) {
              // 3. Optional: Enforce Email Verification
              if (!user.emailVerified) {
                return const LoginPage();
              }
              // User valid -> Go to Home
              return BottomBar(userId: user.uid);
            } else {
              // No user -> Go to Login
              return const LoginPage();
            }
          },
        );
      },
    );
  }

  /// Checks Firestore for a global 'maintenance' flag.
  /// Returns false if offline or error (Fail-Open strategy).
  Future<bool> _isMaintenanceMode() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('controls')
          .doc('maintenance') // ✅ Standardized ID (create this in Firestore)
          .get()
          .timeout(const Duration(seconds: 3)); // ✅ 3s Timeout prevents hanging

      if (!doc.exists) return false;

      return doc.data()?['maintenance'] as bool? ?? false;
    } catch (e) {
      debugPrint("Maintenance check warning (likely offline): $e");
      return false; // Allow access if check fails
    }
  }
}