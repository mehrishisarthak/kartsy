import 'package:ecommerce_shop/firebase_options.dart';
import 'package:ecommerce_shop/pages/onboarding.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/theme/theme_data.dart'; // 1. ADD THIS IMPORT for your custom themes
import 'package:ecommerce_shop/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase first
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Activate App Check
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(const FirebaseErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the ThemeProvider instance
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kartsy',
      // 2. DEFINE your light theme
      theme: lightMode,
      // 3. DEFINE your dark theme
      darkTheme: darkMode,
      // 4. LET THE PROVIDER control which theme is active
      themeMode: themeProvider.themeMode,
      home: const OnboardingScreen(),
    );
  }
}

// No changes needed in FirebaseErrorApp
class FirebaseErrorApp extends StatelessWidget {
  const FirebaseErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('images/error.json', width: 200, height: 200),
              const SizedBox(height: 20),
              const Text(
                'Server Initialization Failed',
                style: TextStyle(fontSize: 24, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}