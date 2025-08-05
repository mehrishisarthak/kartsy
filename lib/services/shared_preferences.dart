import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  // User data keys (unchanged)
  static String userIdkey = "USERKEY";
  static String userNamekey = "USERNAMEKEY";
  static String userEmailkey = "USEREMAILKEY";
  static String userImagekey = "USERIMAGEKEY";
  static String userAddressKey = "USERADDRESSKEY";

  // NEW: Updated key for theme preference. Using a new key name is safer
  // to avoid conflicts with old boolean values if users update your app.
  static const String themeModeKey = "THEMEMODEKEY";

  // --- Theme Methods (UPDATED) ---

  /// Saves the theme mode as a String ('system', 'light', or 'dark').
  Future<void> saveThemeMode(String mode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeModeKey, mode);
  }

  /// Retrieves the saved theme mode String.
  /// Returns null if no theme has been saved yet.
  Future<String?> getThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(themeModeKey);
  }


  // --- User Data Methods (Unchanged) ---

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

  /// Clears all saved user data from SharedPreferences.
  Future<void> clearUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(userIdkey);
    await prefs.remove(userNamekey);
    await prefs.remove(userEmailkey);
    await prefs.remove(userImagekey);
    await prefs.remove(userAddressKey);
    // We keep the theme preference intact when clearing user info.
  }

  // NOTE: The old `saveTheme(bool)` and `getTheme()` methods have been removed.
}