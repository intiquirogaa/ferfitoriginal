import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores session credentials outside of the regular preferences database.
class AuthStorage {
  static const _secure = FlutterSecureStorage();
  static const _apiKey = 'auth_token';
  static const _clerkKey = 'clerk_session_token';

  static Future<void> saveToken(String token) async {
    await _secure.write(key: _apiKey, value: token);
    await _secure.write(key: _clerkKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKey);
    await prefs.remove(_clerkKey);
  }

  static Future<String?> getToken() async {
    final token =
        await _secure.read(key: _apiKey) ?? await _secure.read(key: _clerkKey);
    if (token != null && token.isNotEmpty) return token;

    // Migrate tokens written by older app versions.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_apiKey) ?? prefs.getString(_clerkKey);
    if (legacy != null && legacy.isNotEmpty) {
      await saveToken(legacy);
      return legacy;
    }
    return null;
  }

  static Future<void> clear() async {
    await _secure.delete(key: _apiKey);
    await _secure.delete(key: _clerkKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKey);
    await prefs.remove(_clerkKey);
  }
}
