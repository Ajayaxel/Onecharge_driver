import 'dart:convert';
import 'package:onecharge_d/core/models/driver.dart';
import 'package:onecharge_d/core/storage/token_storage.dart';

class AuthHelper {
  // Get stored token
  static Future<String?> getToken() async {
    return await TokenStorage.getToken();
  }

  // Get stored driver data
  static Future<Driver?> getDriver() async {
    final driverJson = await TokenStorage.getDriverData();
    if (driverJson != null) {
      return Driver.fromJson(jsonDecode(driverJson));
    }
    return null;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    return await TokenStorage.isLoggedIn();
  }

  // Logout - clear all stored data
  static Future<void> logout() async {
    await TokenStorage.clearAll();
  }
}
