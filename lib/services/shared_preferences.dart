import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  static String userIdkey = "USERKEY";
  static String userNamekey = "USERNAMEKEY";
  static String userEmailkey = "USEREMAILKEY";
  static String userImagekey = "USERIMAGEKEY";
  static String userAddressKey = "USERADDRESSKEY"; // New key for the address

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

  /// Encodes a Map to a JSON string and saves it.
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

  /// Retrieves the JSON string and decodes it back to a Map.
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
    await prefs.remove(userAddressKey); // Also clear the address
  }
}
