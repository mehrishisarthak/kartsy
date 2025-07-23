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
  bool _isPasswordVisible = false;
  
  //State to control the visibility of the "Resend Email" button
  bool _showResendButton = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Shows a SnackBar with a given message and color.
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

  /// ⭐️ NEW: Function to resend the verification email.
  Future<void> _resendVerificationEmail() async {
    // Ensure fields are not empty before proceeding
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showSnackBar("Please enter your email and password to resend verification.", isError: true);
      return;
    }

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
      if(mounted) {
        setState(() => _isLoading = false);
      }
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
                    'images/login.json', // Consider a different animation for verification
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    "Verify Your Email",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "A verification link was sent to your email. Please check your inbox and login.",
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
                  const SizedBox(height: 32),

                  _buildLoginButton(),
                  const SizedBox(height: 16),

                  if (_showResendButton) _buildResendButton(),

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
  
  Widget _buildResendButton() {
    return Center(
      child: TextButton(
        onPressed: _isLoading ? null : _resendVerificationEmail,
        child: Text(
          "Didn't get an email? Resend",
          style: GoogleFonts.poppins(
            color: Colors.deepOrange.shade600,
            fontWeight: FontWeight.w600,
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
          "Want to use a different account?",
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
