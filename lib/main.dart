import 'package:ecommerce_shop/firebase_options.dart';
import 'package:ecommerce_shop/pages/splashscreen.dart';
import 'package:ecommerce_shop/services/cart_provider.dart';
import 'package:ecommerce_shop/services/lead_provider.dart'; // ✅ ADDED: Lead Provider
import 'package:ecommerce_shop/services/root_wrapper.dart'; // Ensure this path is correct based on your folder structure
import 'package:ecommerce_shop/theme/theme_data.dart';
import 'package:ecommerce_shop/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Lock Orientation to Portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 2. UI Polish: Make Status Bar Transparent
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  try {
    // 3. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 4. Security: Activate App Check
    // Note: Ensure you have registered your SHA-256 keys in Firebase Console
    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode
          ? AndroidProvider.playIntegrity
          : AndroidProvider.debug,
      appleProvider: kReleaseMode 
          ? AppleProvider.appAttest 
          : AppleProvider.debug,
    );

    // 5. Performance: Pre-load Onboarding Status
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LeadsProvider()), // ✅ Critical for Furniture Leads
        ],
        child: MyApp(startWithOnboarding: !hasSeenOnboarding),
      ),
    );
  } catch (e) {
    // Fail Gracefully
    runApp(const FirebaseErrorApp());
  }
}

class MyApp extends StatelessWidget {
  final bool startWithOnboarding;

  const MyApp({super.key, required this.startWithOnboarding});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'virTwirl', // ✅ RENAMED: App Title
      
      // 🎨 Theme Configuration
      theme: lightMode,
      darkTheme: darkMode,
      themeMode: themeProvider.themeMode,
      
      // 🚀 Navigation Logic
      // Start with Splash Screen instead of RootWrapper directly
      home: const SplashScreen(), 
      
      // ✅ Named Routes (Critical for Login/Signup navigation)
      routes: {
        '/home': (context) => RootWrapper(showOnboarding: startWithOnboarding),
      },
    );
  }
}

// --- Fallback App if Firebase Fails ---
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
              // Ensure you have error.json in your assets
              Lottie.asset(
                'images/error.json',
                width: 200,
                height: 200,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.error_outline, size: 80, color: Colors.red),
              ),
              const SizedBox(height: 20),
              const Text(
                'Server Initialization Failed',
                style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection\nand restart the app.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}