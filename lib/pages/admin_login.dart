import 'package:ecommerce_shop/pages/admin_hompage.dart';
import 'package:ecommerce_shop/utils/authmethods.dart';
import 'package:ecommerce_shop/utils/database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    setState(() => _isLoading = true);

    String res = await AuthMethods().signInAdmin(
      username: _usernameController.text.trim().toLowerCase(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return; // Ensure widget is still in the tree
    if (res == "Login successful.") {

String? adminId = await DatabaseMethods().fetchAdminId(
  _usernameController.text.trim().toLowerCase(),
  _passwordController.text.trim(),
);
if(adminId==''){
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Critical Error : Admin ID not fetched"),
      backgroundColor: Colors.red,
    ),
  );
  return;
}
ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res),
        backgroundColor: res == "Login successful." ? Colors.green : Colors.red,
      ),
    );
Navigator.pushAndRemoveUntil(
  // ignore: use_build_context_synchronously
  context,
  MaterialPageRoute(
    builder: (context) => AdminHomePage(adminId: adminId),
  ),
  (Route<dynamic> route) => false, // This removes all previous routes
);
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
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Image.asset(
                'images/admin.gif',
                height: 280,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              Text(
                "Admin Panel",
                style: GoogleFonts.lato(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter your credentials",
                style: GoogleFonts.lato(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 40),

              /// Username Input
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Admin Username",
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              /// Password Input
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              /// Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAdminLogin,
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
                          "Login as Admin",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
