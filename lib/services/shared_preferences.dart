import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static String userIdkey = "USERKEY";
  static String userNamekey = "USERNAMEKEY";
  static String userEmailkey = "USEREMAILKEY";
  static String userImagekey = "USERIMAGEKEY";
  static String userAddressKey = "USERADDRESSKEY";
  static String themeKey = "THEMEKEY"; // Key for theme preference

  Future<bool> saveUserId(String getUserID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(userIdkey, getUserID);
  }

  Future<bool> saveUserName(String getUserName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(userNamekey, getUserName);
  }

  Future<bool> saveUserEmail(String getUserEmail) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(userEmailkey, getUserEmail);
  }

  Future<bool> saveUserImage(String getUserImage) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setString(userImagekey, getUserImage);
  }

  Future<bool> saveUserAddress(Map<String, dynamic> address) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String addressJson = json.encode(address);
    return await prefs.setString(userAddressKey, addressJson);
  }

  /// Saves the theme preference (true for dark, false for light).
  Future<bool> saveTheme(bool isDarkMode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(themeKey, isDarkMode);
  }

  Future<String?> getUserID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userIdkey);
  }

  Future<String?> getUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userNamekey);
  }

  Future<String?> getUserEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userEmailkey);
  }

  Future<String?> getUserImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(userImagekey);
  }

  Future<Map<String, dynamic>?> getUserAddress() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? addressJson = prefs.getString(userAddressKey);
    if (addressJson != null) {
      return json.decode(addressJson) as Map<String, dynamic>;
    }
    return null;
  }

  /// Retrieves the theme preference. Defaults to false (light mode).
  Future<bool> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(themeKey) ?? false;
  }

  /// Clears all saved user data from SharedPreferences.
  Future<void> clearUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdkey);
    await prefs.remove(userNamekey);
    await prefs.remove(userEmailkey);
    await prefs.remove(userImagekey);
    await prefs.remove(userAddressKey);
    // we keep theme preference intact
  }
}
