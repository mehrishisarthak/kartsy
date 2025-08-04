import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:ecommerce_shop/theme/theme_data.dart';
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;
  final SharedPreferenceHelper _prefs = SharedPreferenceHelper();

  ThemeData get themeData => _themeData;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    bool isDarkMode = await _prefs.getTheme();
    _themeData = isDarkMode ? darkMode : lightMode;
    notifyListeners();
  }

  void toggleTheme() async {
    bool isDarkMode = _themeData.brightness == Brightness.light;
    _themeData = isDarkMode ? darkMode : lightMode;
    await _prefs.saveTheme(isDarkMode);
    notifyListeners();
  }
}
