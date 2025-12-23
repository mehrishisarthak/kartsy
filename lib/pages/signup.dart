import 'package:ecommerce_shop/pages/login.dart';
import 'package:ecommerce_shop/services/shimmer/signup_shimmer.dart';
import 'package:ecommerce_shop/utils/authmethods.dart';
import 'package:ecommerce_shop/utils/show_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  // Focus Nodes for form navigation
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  // --- ROBUST SIGNUP LOGIC ---
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    String res = await AuthMethods().signUpUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _nameController.text.trim(),
      image: "",
    );

    if (!mounted) return;

    if (res.startsWith("Account created successfully")) {
      showCustomSnackBar(
          context, "Account created! Please check your email to verify.",
          type: SnackBarType.success);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenOnboarding', true);

      // Short delay to let user see the message
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context)
          .pushNamedAndRemoveUntil('/login_after_signup', (route) => false);
    } else {
      setState(() => _isLoading = false);
      showCustomSnackBar(context, res, type: SnackBarType.error);
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => _isLoading = true);
    try {
      String res = await AuthMethods().signInWithGoogle();
      if (!mounted) return;

      if (res == "Login successful.") {
        showCustomSnackBar(context, "Google sign-in successful!",
            type: SnackBarType.success);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('seenOnboarding', true);

        // Short delay to let user see the message
        await Future.delayed(const Duration(seconds: 2));

        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        setState(() => _isLoading = false);
        showCustomSnackBar(context, res, type: SnackBarType.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showCustomSnackBar(
            context, "Google Sign-In failed. Please try again.",
            type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withAlpha(26),
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Lottie.asset(
                      'images/login.json',
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.person_add, size: 80),
                    ),
                    const SizedBox(height: 24),

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
                      style: textTheme.titleMedium
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Inputs using TextFormField
                    _buildTextFormField(
                      controller: _nameController,
                      hintText: "Full Name",
                      icon: Icons.person_outline,
                      validator: (val) =>
                          val!.isEmpty ? "Enter your name" : null,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          _emailFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 20),

                    _buildTextFormField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      hintText: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.isEmpty)
                          return "Enter your email";
                        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val))
                          return "Invalid email address";
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          _passwordFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 20),

                    _buildPasswordField(),
                    const SizedBox(height: 32),

                    _buildSignupButton(),
                    const SizedBox(height: 20),

                    _buildDivider(),
                    const SizedBox(height: 20),

                    _buildGoogleSignupButton(),
                    const SizedBox(height: 24),

                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    VoidCallback? onEditingComplete,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      onEditingComplete: onEditingComplete,
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
      focusNode: _passwordFocusNode,
      obscureText: !_isPasswordVisible,
      validator: (val) {
        if (val == null || val.isEmpty) return "Enter a password";
        if (val.length < 6) return "Password must be at least 6 chars";
        return null;
      },
      textInputAction: TextInputAction.done,
      onEditingComplete: _handleSignup,
      decoration: InputDecoration(
        hintText: "Password",
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        suffixIcon: IconButton(
          tooltip: "Toggle password visibility",
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

  Widget _buildSignupButton() {
    return SizedBox(
      height: 55,
      child: _isLoading
          ? const SignupShimmerButton()
          : ElevatedButton(
              onPressed: _handleSignup,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Sign Up",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          child: Text("OR",
              style: TextStyle(
                  color: Colors.grey[600], fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Divider(color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildGoogleSignupButton() {
    final theme = Theme.of(context);
    return SizedBox(
      height: 55,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignup,
        icon: Image.asset('images/icons/google.png',
            height: 24.0,
            errorBuilder: (c, e, s) => const Icon(Icons.login)),
        label: Text("Sign up with Google", style: theme.textTheme.labelLarge),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Already have an account?",
            style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const LoginPage()));
          },
          child: Text("Login",
              style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}
