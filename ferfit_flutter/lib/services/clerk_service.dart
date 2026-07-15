import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'auth_storage.dart';

class ClerkService {
  static String get _baseUrl => '${ApiService.baseUrl}/auth';

  static Future<void> saveSessionToken(String token) async {
    await AuthStorage.saveToken(token);
  }

  static Future<String?> getSessionToken() async {
    return AuthStorage.getToken();
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await AuthStorage.clear();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getSessionToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sign-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String?;
        final userName = data['user']?['name'] as String?;

        if (token != null) {
          await saveSessionToken(token);
          if (userName != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_name', userName);
          }
          return {
            'success': true,
            'token': token,
            'user': {'name': userName ?? 'Atleta'},
          };
        }
      }
      
      final errorBody = _decodeMap(response.body);
      final message = errorBody?['error'] ?? 'Error al iniciar sesión';
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión. Intenta de nuevo.'};
    }
  }

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    String? firstName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sign-up'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          if (firstName != null) 'firstName': firstName,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String?;
        final userName = data['user']?['name'] as String?;

        if (token != null) {
          await saveSessionToken(token);
          if (userName != null || firstName != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_name', userName ?? firstName ?? 'Atleta');
          }
          return {
            'success': true,
            'token': token,
            'user': {'name': userName ?? firstName ?? 'Atleta'},
          };
        }
      }

      final errorBody = _decodeMap(response.body);
      final message = errorBody?['error'] ?? 'Error al crear cuenta';
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión. Intenta de nuevo.'};
    }
  }

  static Map<String, dynamic>? _decodeMap(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
