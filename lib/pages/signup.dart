import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/bottomnav.dart';
import 'package:ecommerce_shop/pages/login.dart';
import 'package:ecommerce_shop/pages/login_after_signup.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/utils/authmethods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    // Clear any previous user info from shared preferences
    // This is important to ensure a fresh start for the signup process.
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
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
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
    // This is a placeholder image URL.
    String image =
        "https://firebasestorage.googleapis.com/v0/b/kartsyapp-87532.firebasestorage.app/o/default_profile.png?alt=media&token=d328f93c-400f-4deb-a0e8-014eb2e2b795";

    String res = await AuthMethods().signUpUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _nameController.text.trim(),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // Use a container with a gradient for a more modern background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withAlpha(26), // 0.1 opacity
              colorScheme.surface,
              colorScheme.surface,
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
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Let's get started!",
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
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
        prefixIcon: Icon(icon, color: Colors.grey[500]),
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
      ),
    );
  }
  
  /// A helper widget for the main signup button.
  Widget _buildSignupButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignup,
        child: _isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
              )
            : const Text("Sign Up"),
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
            style: TextStyle(
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
    final theme = Theme.of(context);
    return SizedBox(
      height: 55,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignup,
        icon: Image.asset(
          'images/icons/google.png', // Ensure this path is correct
          height: 24.0,
        ),
        label: Text(
          "Sign up with Google",
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(((0.8) * 255).toInt()), // Adjusted for better visibility
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: theme.colorScheme.surface,
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account?",
          style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
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
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}
