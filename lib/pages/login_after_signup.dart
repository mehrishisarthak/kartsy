import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/bottomnav.dart';
import 'package:ecommerce_shop/pages/signup.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/utils/authmethods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class LoginPageAfterSignup extends StatefulWidget {
  const LoginPageAfterSignup({super.key});

  @override
  State<LoginPageAfterSignup> createState() => _LoginPageAfterSignupState();
}

class _LoginPageAfterSignupState extends State<LoginPageAfterSignup> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  
  //State to control the visibility of the "Resend Email" button
  bool _showResendButton = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Shows a SnackBar with a given message and color.
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ));
  }

  /// ⭐️ NEW: Function to resend the verification email.
  Future<void> _resendVerificationEmail() async {
    setState(() => _isLoading = true);
    try {
      // Temporarily sign in the user to get a user object
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (cred.user != null && !cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
        _showSnackBar("A new verification email has been sent. Please check your inbox.");
      }
      // Sign out immediately after sending the email
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      _showSnackBar("Error: ${e.message}", isError: true);
    } catch (e) {
      _showSnackBar("An unexpected error occurred.", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _showResendButton = false; // Reset on each login attempt
    });

    try {
      final res = await AuthMethods().signInUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Handle different responses from AuthMethods
      if (res == "Login successful.") {
        _showSnackBar(res);

        final uid = FirebaseAuth.instance.currentUser!.uid;
        final userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (!userSnap.exists) {
          throw Exception("User profile not found in the database.");
        }

        final userData = userSnap.data()!;
        final prefs = SharedPreferenceHelper();
        await prefs.saveUserEmail(userData['Email']);
        await prefs.saveUserName(userData['Name']);
        await prefs.saveUserId(uid);
        await prefs.saveUserImage(userData['Image']);

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const BottomBar()),
            (route) => false,
          );
        }
      } else {
        _showSnackBar(res, isError: true);
        // ⭐️ NEW: If the error is about verification, show the resend button
        if (res.contains("Please verify your email")) {
          setState(() {
            _showResendButton = true;
          });
        }
      }
    } catch (e) {
      _showSnackBar("Login failed: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset('images/login.json', height: 250),
              const SizedBox(height: 20),
              Text("Verify & Login",
                  style: GoogleFonts.lato(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  )),
              const SizedBox(height: 10),
              Text("Check your email and login to continue",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(fontSize: 16, color: Colors.grey[700])),
              const SizedBox(height: 30),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration("Email", Icons.email),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration("Password", Icons.lock),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Login",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),

              // ⭐️ NEW: Conditionally show the "Resend Email" button
              if (_showResendButton)
                TextButton(
                  onPressed: _isLoading ? null : _resendVerificationEmail,
                  child: const Text(
                    "Didn't get an email? Resend verification link",
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Want to use a different account?", style: GoogleFonts.lato(fontSize: 15)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage()),
                      );
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }
}