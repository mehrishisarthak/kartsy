import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/bottomnav.dart';
import 'package:ecommerce_shop/pages/login.dart';
import 'package:ecommerce_shop/pages/login_after_signup.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/utils/authmethods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:random_string/random_string.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isLoading = false;
  // State variable to toggle password visibility
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _isPasswordVisible = false; // Initially, password is not visible

    // It's good practice to not clear user info here unless you have a specific reason.
    // Let's assume this is intended for now.
    SharedPreferenceHelper().clearUserInfo();
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ));
  }


  /// Handles the user signup process.
  Future<void> _handleSignup() async {
    // Basic validation on the client side
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showSnackBar("Please fill in all the fields.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    String userId = randomAlphaNumeric(10);
    // This is a placeholder image URL.
    String image =
        "https://firebasestorage.googleapis.com/v0/b/kartsy-3ff24.firebasestorage.app/o/assets%2Fdefault_profile.png?alt=media&token=2038c7c3-dd79-41f1-b5bd-30e39e76af5d";

    String res = await AuthMethods().signUpUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _nameController.text.trim(),
      userId: userId,
      image: image,
    );

    setState(() => _isLoading = false);

    final bool isSuccess = res.startsWith("Account created successfully");
    _showSnackBar(res, isError: !isSuccess);

    if (isSuccess) {
      // Navigate to the verification page after successful email signup
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPageAfterSignup()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  /// Handles the Google signup process.
  Future<void> _handleGoogleSignup() async {
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
      // Use a container with a gradient for a more modern background
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
                  // Lottie animation for visual appeal
                  Lottie.asset(
                    'images/login.json', // Ensure this path is correct in your assets
                    height: 200, // Adjusted height
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),

                  // Header Text
                  Text(
                    "Create Your Account",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D47A1), // A deep blue color
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Let's get started!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name TextField
                  _buildTextField(
                    controller: _nameController,
                    hintText: "Full Name",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  // Email TextField
                  _buildTextField(
                    controller: _emailController,
                    hintText: "Email Address",
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Password TextField
                  _buildPasswordField(),
                  const SizedBox(height: 32),

                  // Signup Button
                  _buildSignupButton(),
                  const SizedBox(height: 20),

                  // OR Divider
                  _buildDivider(),
                  const SizedBox(height: 20),

                  // Google Signup Button
                  _buildGoogleSignupButton(),
                  const SizedBox(height: 24),

                  // Login Link
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A helper widget to build consistently styled text fields.
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // No border for a cleaner look
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

  /// A specific widget for the password field with a visibility toggle.
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
  
  /// A helper widget for the main signup button with gradient and shadow.
  Widget _buildSignupButton() {
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
        onPressed: _isLoading ? null : _handleSignup,
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
                "Sign Up",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  /// A helper widget for the "OR" divider.
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

  /// A helper widget for the Google signup button.
  Widget _buildGoogleSignupButton() {
    return SizedBox(
      height: 55,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignup, // ⭐️ UPDATED
        icon: Image.asset(
          'images/icons/google.png', // Ensure this path is correct
          height: 24.0,
        ),
        label: Text(
          "Sign up with Google",
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

  /// A helper widget for the link to the login page.
  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey[700]),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: Text(
            "Login",
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
