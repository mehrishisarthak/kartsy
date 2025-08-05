import 'package:ecommerce_shop/pages/signup.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // This helper function converts the ThemeMode enum to a user-friendly string.
  String _getTextForTheme(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  // This function handles the logout logic (it remains unchanged).
  Future<void> _handleLogout(BuildContext context) async {
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmLogout == true) {
      await SharedPreferenceHelper().clearUserInfo();
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignupPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the provider, but we no longer need to calculate 'isDarkMode'.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- UPDATED THEME SELECTOR ---
            Card(
              child: ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                // Shows the currently selected theme (e.g., "System")
                subtitle: Text(_getTextForTheme(themeProvider.themeMode)),
                trailing: PopupMenuButton<ThemeMode>(
                  onSelected: (mode) {
                    // Call the new method to set the theme
                    themeProvider.setThemeMode(mode);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    const PopupMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    const PopupMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                onPressed: () => _handleLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.withAlpha(25),
                  foregroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}