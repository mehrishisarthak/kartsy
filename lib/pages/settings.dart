import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/theme/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // --- LOGOUT LOGIC ---
  Future<void> _handleLogout(BuildContext context) async {
    final confirmLogout = await showDialog<bool>(
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
      // 1. Clear local cache
      await SharedPreferenceHelper().clearUserInfo();

      // 2. Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        // 3. Clear navigation stack and go to auth entry
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Widget _buildThemeSelector(BuildContext context, ThemeProvider themeProvider) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    // REMOVED: Expanded widget
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "App Appearance",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // This LayoutBuilder is what actually prevents the overflow
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate width dynamically based on parent width
              final double buttonWidth = (constraints.maxWidth - 5) / 3;
    
              return ToggleButtons(
                borderRadius: BorderRadius.circular(12.0),
                borderWidth: 1.5,
                borderColor: theme.colorScheme.outline.withOpacity(0.3),
                selectedBorderColor: theme.colorScheme.primary,
                
                fillColor: theme.colorScheme.primary,
                selectedColor: theme.colorScheme.onPrimary,
                
                color: isDark ? Colors.white70 : Colors.black54,
                
                constraints: BoxConstraints(
                  minHeight: 50.0,
                  // This forces the buttons to fit exactly within the card
                  minWidth: buttonWidth, 
                ),
                
                isSelected: [
                  themeProvider.themeMode == ThemeMode.light,
                  themeProvider.themeMode == ThemeMode.dark,
                  themeProvider.themeMode == ThemeMode.system,
                ],
                
                onPressed: (index) {
                  const List<ThemeMode> modes = [
                    ThemeMode.light,
                    ThemeMode.dark,
                    ThemeMode.system
                  ];
                  themeProvider.setThemeMode(modes[index]);
                },
                
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.light_mode_outlined, size: 18),
                      SizedBox(width: 6),
                      Text("Light", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.dark_mode_outlined, size: 18),
                      SizedBox(width: 6),
                      Text("Dark", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.brightness_auto_outlined, size: 18),
                      SizedBox(width: 6),
                      Text("Auto", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Theme Selector
            _buildThemeSelector(context, themeProvider),
            
            const Spacer(),
            
            // 2. Logout Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () => _handleLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.red.shade100),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}