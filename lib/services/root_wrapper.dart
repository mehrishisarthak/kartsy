import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/bottomnav.dart';
import 'package:ecommerce_shop/pages/login.dart';
import 'package:ecommerce_shop/pages/maintenance_screen.dart';
import 'package:ecommerce_shop/pages/onboarding.dart';
import 'package:ecommerce_shop/services/shimmer/root_wrapper_shimemr.dart';
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
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }

    // Check maintenance mode first
    return FutureBuilder<bool>(
      future: _isMaintenanceMode(),
      builder: (context, maintenanceSnapshot) {
        if (maintenanceSnapshot.connectionState == ConnectionState.waiting) {
          return const RootWrapperLoading(); // full-screen shimmer
        }

        if (maintenanceSnapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error checking app status')),
          );
        }

        if (maintenanceSnapshot.data == true) {
          return const MaintenanceScreen();
        }

        // Otherwise, proceed with auth check
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const RootWrapperLoading(); // same shimmer while auth resolves
            }

            final user = snapshot.data;

            if (user != null) {
              if (!user.emailVerified) {
                return const LoginPage();
              }
              return BottomBar(userId: user.uid);
            } else {
              return const LoginPage();
            }
          },
        );
      },
    );
  }

  Future<bool> _isMaintenanceMode() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('controls')
          .doc('KiZGQexgPCX2mWgplm15')
          .get();

      print('controls doc exists: ${doc.exists}');
      print('controls data: ${doc.data()}');

      final flag = doc.data()?['maintenance'] as bool? ?? false;
      print('maintenance flag: $flag');

      return flag;
    } catch (e) {
      print("Error checking maintenance mode: $e");
      return false;
    }
  }
}
