import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/bottomnav.dart';
import 'package:ecommerce_shop/pages/login_after_signup.dart';
import 'package:ecommerce_shop/pages/signup.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/utils/authmethods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false, Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? (isError ? Colors.redAccent : Colors.green),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final res = await AuthMethods().signInUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      /// Check for the verification error specifically
      if (res.contains("Please verify your email")) {
        if (mounted) {
          // Show a helpful message and then navigate
          _showSnackBar(res, backgroundColor: Colors.orange.shade700);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPageAfterSignup()),
          );
        }
        return; // Stop further execution
      }

      // Handle other responses
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
        // Handle all other errors
        _showSnackBar(res, isError: true);
      }
    } catch (e) {
      _showSnackBar("Login failed: ${e.toString()}", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handles the Google login process.
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      String res = await AuthMethods().signInWithGoogle();
      
      final bool isSuccess = res == "Login successful.";

      _showSnackBar(res, isError: !isSuccess);

      if (isSuccess) {
        // If Google sign-in is successful, fetch user data and navigate to home
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final userSnap = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (!userSnap.exists) {
          throw Exception("User profile not found in the database after Google Sign-In.");
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
      }
    } catch (e) {
      _showSnackBar("An unexpected error occurred during Google Sign-In.", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lightBlue.shade50,
              Colors.white,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Lottie.asset(
                    'images/login.json',
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Welcome Back!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Login to continue",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildTextField(
                    controller: _emailController,
                    hintText: "Email Address",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  _buildPasswordField(),
                  const SizedBox(height: 10),
                  
                  _buildForgotPasswordButton(),
                  const SizedBox(height: 20),

                  _buildLoginButton(),
                  const SizedBox(height: 20),

                  _buildDivider(),
                  const SizedBox(height: 20),

                  _buildGoogleLoginButton(),
                  const SizedBox(height: 24),

                  _buildSignupLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        hintText: "Password",
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[500],
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            // TODO: Implement forgot password logic
          },
          child: Text(
            "Forgot Password?",
            style: GoogleFonts.poppins(
              color: const Color(0xFF1976D2),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(
                "Login",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[400])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Text(
            "OR",
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildGoogleLoginButton() {
    return SizedBox(
      height: 55,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleLogin,
        icon: Image.asset(
          'images/icons/google.png',
          height: 24.0,
        ),
        label: Text(
          "Sign in with Google",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSignupLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700]),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignupPage()),
            );
          },
          child: Text(
            "Sign Up",
            style: GoogleFonts.poppins(
              color: const Color(0xFF1976D2),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        )
      ],
    );
  }
}
