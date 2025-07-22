import 'package:ecommerce_shop/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.blue;
    final Color backgroundColor = const Color(0xFFFFFFFF);
    final Color textColor = const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Image (top right aligned)
              Align(
              alignment: Alignment.topRight,
              child: Image.asset(
                'lib/assets/images/3.jpg',
                width: 180,
              ),
              ),

              const Spacer(flex: 1),

              /// Title text
              Text(
              'Best products',
              style: GoogleFonts.lato(
                textStyle: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: textColor,
                ),
              ),
              ),
              Text(
              'for you',
              style: GoogleFonts.lato(
                textStyle: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                ),
              ),
              ),

              const Spacer(flex: 2),

              /// Navigation button
              Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => SignupPage()),
  (Route<dynamic> route) => false, // removes all previous routes
);
                },
                style: ElevatedButton.styleFrom(
                  iconSize: 40,
                shape: const CircleBorder(),
                padding: const EdgeInsets.fromLTRB(40, 20, 40, 20),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 6.0,
                ),
                child: const Icon(Icons.arrow_forward_ios),
              ),
              ),

              const Spacer(flex: 2),
            ],
            ),
          ),
        ),
      );
  }
}
