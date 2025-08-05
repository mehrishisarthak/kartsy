// lib/providers/theme_provider.dart

import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // The state is now a ThemeMode, defaulting to system
  ThemeMode _themeMode = ThemeMode.system;
  final SharedPreferenceHelper _prefs = SharedPreferenceHelper();

  // Getter for the current theme mode
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    // Get the saved theme string ('system', 'light', 'dark')
    final String? savedTheme = await _prefs.getThemeMode();

    if (savedTheme == null) {
      _themeMode = ThemeMode.system; // Default if nothing is saved
    } else if (savedTheme == 'light') {
      _themeMode = ThemeMode.light;
    } else if (savedTheme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  // A new method to explicitly set the theme
  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    // Save the theme mode using its string name (e.g., 'system')
    await _prefs.saveThemeMode(mode.name);
    notifyListeners();
  }
}