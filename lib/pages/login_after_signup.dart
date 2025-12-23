import 'package:ecommerce_shop/pages/signup.dart';
import 'package:ecommerce_shop/services/shimmer/signup_shimmer.dart';
import 'package:ecommerce_shop/utils/authmethods.dart';
import 'package:ecommerce_shop/utils/show_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Added Import

class LoginPageAfterSignup extends StatefulWidget {
  const LoginPageAfterSignup({super.key});

  @override
  State<LoginPageAfterSignup> createState() => _LoginPageAfterSignupState();
}

class _LoginPageAfterSignupState extends State<LoginPageAfterSignup> {
  // 1. Add Form Key
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _showResendButton = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _resendVerificationEmail() async {
    // Validate inputs first
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (cred.user != null && !cred.user!.emailVerified) {
        await cred.user!.sendEmailVerification();
        showCustomSnackBar(
            context, "Verification email sent! Please check your inbox.",
            type: SnackBarType.success);
      } else {
        showCustomSnackBar(context, "This email is already verified.",
            type: SnackBarType.info);
      }

      // ✅ FIX: Removed signOut() here.
      // This keeps the user on the screen so they can see the Snackbar.
      // The RootWrapper will naturally keep them here because emailVerified is still false.

    } on FirebaseAuthException catch (e) {
      showCustomSnackBar(context, "Error: ${e.message}",
          type: SnackBarType.error);
    } catch (e) {
      showCustomSnackBar(context, "An unexpected error occurred.",
          type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    // 1. Validate Form
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _showResendButton = false;
    });

    try {
      final res = await AuthMethods().signInUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (res == "Login successful.") {
        // ✅ FIX: Mark Onboarding as seen
        // This ensures if they restart the app later, they go straight to Home
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('seenOnboarding', true);

        // 2. SUCCESS: Pop to root. RootWrapper takes over from here.
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        showCustomSnackBar(context, res, type: SnackBarType.error);
        if (res.contains("Please verify your email")) {
          setState(() => _showResendButton = true);
        }
      }
    } catch (e) {
      if (mounted)
        showCustomSnackBar(context, "Login failed: ${e.toString()}",
            type: SnackBarType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      // Ensure the Scaffold resizes when keyboard opens to prevent bottom overflow
      resizeToAvoidBottomInset: true,
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withAlpha(25),
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          // 3. Overflow Fix: Use LayoutBuilder to handle scrolling + centering
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      // 4. Wrap in Form
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Lottie.asset(
                              'images/login.json',
                              height: 220,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.mark_email_read, size: 80),
                            ),
                            const SizedBox(height: 24),

                            Text(
                              "Verify Your Email",
                              textAlign: TextAlign.center,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Link sent! Please verify and login.",
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 32),

                            // Inputs
                            _buildTextFormField(
                              controller: _emailController,
                              hintText: "Email Address",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) {
                                if (val == null || val.isEmpty)
                                  return "Enter your email";
                                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val))
                                  return "Invalid email";
                                return null;
                              },
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
            },
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      validator: (val) => val!.isEmpty ? "Enter your password" : null,
      decoration: InputDecoration(
        hintText: "Password",
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        suffixIcon: IconButton(
          tooltip: 'Toggle password visibility',
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[500],
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 55,
      child: _isLoading
          ? const SignupShimmerButton() // reuse same shimmer bar
          : ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Login",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          style: TextStyle(
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
        Text("Wrong email?",
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey[700])),
        TextButton(
          onPressed: () {
            // PushReplacement is fine here to switch back to signup
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const SignupPage()));
          },
          child: Text(
            "Sign Up Again",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        )
      ],
    );
  }
}
