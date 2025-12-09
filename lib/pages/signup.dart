import 'package:ecommerce_shop/pages/login.dart';
import 'package:ecommerce_shop/services/shimmer/signup_shimmer.dart';
import 'package:ecommerce_shop/utils/authmethods.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // 1. Add Form Key for validation
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

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
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
  }

  // --- ROBUST SIGNUP LOGIC ---
  Future<void> _handleSignup() async {
    // 1. Validate inputs BEFORE hitting the server
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Note: We use an empty string or null for image. 
    // The UI should handle displaying a default asset if this is empty.
    String res = await AuthMethods().signUpUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      username: _nameController.text.trim(),
      image: "", // Don't rely on hardcoded URLs
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 2. Check for the specific success message from your AuthMethods
    if (res.startsWith("Account created successfully")) {
      // SUCCESS: Clear the stack so RootWrapper can show the Home Screen
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);

    } else {
      _showSnackBar(res, isError: true);
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => _isLoading = true);

    try {
      String res = await AuthMethods().signInWithGoogle();
      
      if (!mounted) return;

      if (res == "Login successful.") {
         // SUCCESS: Clear stack -> RootWrapper detects user -> Shows Home
         Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        _showSnackBar(res, isError: true);
      }
    } catch (e) {
      _showSnackBar("Google Sign-In failed", isError: true);
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              // 3. Wrap everything in a Form
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Lottie.asset(
                      'images/login.json', 
                      height: 200,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(Icons.person_add, size: 80),
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
                      style: textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Inputs using TextFormField
                    _buildTextFormField(
                      controller: _nameController,
                      hintText: "Full Name",
                      icon: Icons.person_outline,
                      validator: (val) => val!.isEmpty ? "Enter your name" : null,
                    ),
                    const SizedBox(height: 20),

                    _buildTextFormField(
                      controller: _emailController,
                      hintText: "Email Address",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                         if (val == null || val.isEmpty) return "Enter your email";
                         // Basic Email Regex
                         if (!RegExp(r'\S+@\S+\.\S+').hasMatch(val)) return "Invalid email address";
                         return null;
                      },
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

  // --- UPDATED WIDGETS ---

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
      validator: validator, // Connects to the Form Key
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        // Remove standard borders if you use a theme, but this is safe default
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
      validator: (val) {
        if (val == null || val.isEmpty) return "Enter a password";
        if (val.length < 6) return "Password must be at least 6 chars";
        return null;
      },
      decoration: InputDecoration(
        hintText: "Password",
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[500],
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
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
          child: Text("OR", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
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
        // Make sure to add error builder here too just in case asset is missing
        icon: Image.asset('images/icons/google.png', height: 24.0, errorBuilder: (c,e,s) => const Icon(Icons.login)),
        label: Text("Sign up with Google", style: theme.textTheme.labelLarge),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        Text("Already have an account?", style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
        TextButton(
          onPressed: () {
            // Use PushReplacement so they can't "Back" into signup
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
          },
          child: Text("Login", style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}