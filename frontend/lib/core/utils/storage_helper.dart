import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class StorageHelper {
  StorageHelper._();

  static late SharedPreferences _prefs;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- Secure Storage (Tokens, Credentials) ---

  static Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyAccessToken, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.keyAccessToken);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.keyRefreshToken);
  }

  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: AppConstants.keyAccessToken);
    await _secureStorage.delete(key: AppConstants.keyRefreshToken);
  }

  // --- Shared Preferences (Preferences) ---

  static Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  static Future<bool> clearAll() async {
    await clearTokens();
    return await _prefs.clear();
  }
}
