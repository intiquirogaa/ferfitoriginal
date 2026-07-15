import 'dart:convert';
import 'package:http/http.dart' as http;
import 'clerk_service.dart';
import 'auth_storage.dart';
import 'package:home_widget/home_widget.dart';

import 'package:flutter/foundation.dart';

class ApiService {
  static String get baseUrl {
    const configured = String.fromEnvironment('FERFIT_API_URL');
    if (configured.isNotEmpty) return configured;
    
    // Si estás corriendo en el celular, localhost no va a encontrar la PC.
    // Usamos la IP de la computadora en la red local.
    return 'http://192.168.0.144:3000/api/mobile';
  }

  static String get baseHost {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  static Future<void> saveToken(String token) async =>
      AuthStorage.saveToken(token);

  static Future<String?> getToken() async => AuthStorage.getToken();

  static Future<void> clearToken() async => AuthStorage.clear();
  static Future<String?> _getAuthToken() async {
    final savedToken = await getToken();
    if (savedToken != null && savedToken.isNotEmpty) {
      return savedToken;
    }

    final sessionToken = await ClerkService.getSessionToken();
    if (sessionToken != null && sessionToken.isNotEmpty) {
      await saveToken(sessionToken);
      return sessionToken;
    }

    return null;
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // 1. Auth / Login verification
  static Future<Map<String, dynamic>?> authenticate(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['success'] == true) {
          await saveToken(token);
        }
        return body is Map<String, dynamic> ? body : null;
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        return {'success': false, '_unauthorized': true};
      }
      return null;
    } catch (e) {
      print('Auth error: $e');
      return null;
    }
  }

  // 2. Fetch Dashboard Data
  static Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/dashboard'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        try {
          if (data['progress'] != null) {
            final p = data['progress'];
            final streak = (p['streak'] is num) ? (p['streak'] as num).toInt() : 0;
            final level = (p['level'] is num) ? (p['level'] as num).toInt() : 1;
            await HomeWidget.saveWidgetData('streak', streak);
            await HomeWidget.saveWidgetData('level', level);
            await HomeWidget.updateWidget(
              name: 'FerFitWidgetProvider',
              androidName: 'FerFitWidgetProvider',
            );
          }
        } catch (e) {
          print('HomeWidget update error: $e');
        }
        return data;
      }
      print('Dashboard failed (${response.statusCode}): ${response.body}');
      return null;
    } catch (e) {
      print('Dashboard fetch error: $e');
      return null;
    }
  }

  // 3. Fetch AI Tips
  static Future<List<dynamic>?> getTips() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/tips'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tips = data['tips'];
        return tips is List ? tips : null;
      }
      return null;
    } catch (e) {
      print('Tips fetch error: $e');
      return null;
    }
  }

  // 4. Fetch Active Plan
  static Future<Map<String, dynamic>?> getActivePlan() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/plan/active'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Active plan error: $e');
      return null;
    }
  }

  // 5. Fetch Today's Checklist
  static Future<Map<String, dynamic>?> getTodayChecklist() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/checklist/today'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Checklist fetch error: $e');
      return null;
    }
  }

  // 6. Mark Series Completed
  static Future<Map<String, dynamic>?> completeSeries({
    required int trainingPlanId,
    required int dayNumber,
    required int exerciseIndex,
    required int seriesIndex,
    required bool completed,
    double? weight,
    int? reps,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/series/complete'),
        headers: await _headers(),
        body: jsonEncode({
          'trainingPlanId': trainingPlanId,
          'dayNumber': dayNumber,
          'exerciseIndex': exerciseIndex,
          'seriesIndex': seriesIndex,
          'completed': completed,
          if (weight != null) 'weight': weight,
          if (reps != null) 'reps': reps,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Complete series error: $e');
      return null;
    }
  }

  // 7. Create custom training plan (LLM puede tardar)
  static Future<Map<String, dynamic>?> createPlan(
      Map<String, dynamic> wizardData) async {
    try {
      final headers = await _headers();
      print('Create plan headers: $headers');
      final response = await http
          .post(
            Uri.parse('$baseUrl/plan/create'),
            headers: headers,
            body: jsonEncode(wizardData),
          )
          .timeout(const Duration(minutes: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      print('Create plan failed (${response.statusCode}): ${response.body}');
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return {'success': false, 'error': body['error'] ?? response.body};
        }
      } catch (_) {}
      return {'success': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('Create plan error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // 7b. Nutrition active plan
  static Future<Map<String, dynamic>?> getActiveNutritionPlan() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/nutrition/active'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Active nutrition plan error: $e');
      return null;
    }
  }

  // --- FASE 3: STORE ---
  static Future<Map<String, dynamic>?> getInventory() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/store/inventory'), headers: await _headers());
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }
  static Future<Map<String, dynamic>?> buyItem(String itemId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/store/buy'), headers: await _headers(), body: jsonEncode({'itemId': itemId}));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }
  static Future<Map<String, dynamic>?> equipItem(String? itemId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/store/equip'), headers: await _headers(), body: jsonEncode({'itemId': itemId}));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }

  static Future<Map<String, dynamic>?> getPersonalities() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/store/personalities'), headers: await _headers());
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }
  
  static Future<Map<String, dynamic>?> buyPersonality(String id, int price) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/store/buy-personality'), headers: await _headers(), body: jsonEncode({'personalityId': id, 'price': price}));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }
  
  static Future<Map<String, dynamic>?> equipPersonality(String id) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/store/equip-personality'), headers: await _headers(), body: jsonEncode({'personalityId': id}));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }

  static Future<Map<String, dynamic>?> getTodayQuests() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/quests/today'), headers: await _headers());
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }

  static Future<Map<String, dynamic>?> autoregulateWorkout(int planId, int dayIndex, String howUserFeels) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/training/autoregulate'),
        headers: await _headers(),
        body: jsonEncode({'planId': planId, 'dayIndex': dayIndex, 'howUserFeels': howUserFeels}),
      ).timeout(const Duration(minutes: 2));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }

  // --- FASE 4 & 5: MISSIONS AND LEAGUES ---
  static Future<List<dynamic>?> getDailyQuests() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/gamification/quests'), headers: await _headers());
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }
  static Future<Map<String, dynamic>?> getLeagueLeaderboard() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/gamification/league'), headers: await _headers());
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }

  // --- FASE 6: SOCIAL ---
  static Future<List<dynamic>?> getFriendsFeed() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/social/feed'), headers: await _headers());
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (e) { return null; }
  }

  // 7c. Create nutrition plan
  static Future<Map<String, dynamic>?> createNutritionPlan(
      Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/nutrition/create'),
            headers: await _headers(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      print(
          'Nutrition create failed (${response.statusCode}): ${response.body}');
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) return body;
      } catch (_) {}
      return {'success': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      print('Nutrition create error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // 8. Fetch Training History
  static Future<Map<String, dynamic>?> getTrainingHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/training-history'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Training history fetch error: $e');
      return null;
    }
  }

  // 9. Fetch Exercise Media
  static Future<Map<String, dynamic>?> getExerciseMedia(String name) async {
    try {
      final uri = Uri.parse('$baseUrl/exercise-media')
          .replace(queryParameters: {'name': name});
      final response = await http.get(
        uri,
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('Exercise media fetch error: $e');
      return null;
    }
  }

  // 10. Engagement alerts (Duolingo-style)
  static Future<Map<String, dynamic>?> getEngagementAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/engagement/alerts'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Engagement alerts error: $e');
      return null;
    }
  }

  // 11. Badges (Logros)
  static Future<List<dynamic>?> getBadges() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/badges'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['badges'] as List<dynamic>?;
      }
      return null;
    } catch (e) {
      print('Badges fetch error: $e');
      return null;
    }
  }

  // --- FUNCIONALIDAD 1: Chat con la mascota Feo ---
  static Future<Map<String, dynamic>?> chatWithFeo(
      String message, List<Map<String, dynamic>> history) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/social/feo-chat'),
        headers: await _headers(),
        body: jsonEncode({'message': message, 'history': history}),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      return null;
    } catch (e) {
      print('chatWithFeo error: $e');
      return null;
    }
  }

  // --- FUNCIONALIDAD 5: Notificación motivacional dinámica ---
  static Future<String?> getMotivationalQuote() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/gamification/quote'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['quote'] as String?;
      }
      return null;
    } catch (e) {
      print('getMotivationalQuote error: $e');
      return null;
    }
  }

  // --- FUNCIONALIDAD 2: Carga inteligente de alimentos ---
  static Future<Map<String, dynamic>?> smartLog(String description) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/nutrition/smart-log'),
        headers: await _headers(),
        body: jsonEncode({'description': description}),
      ).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      print('smartLog failed (${res.statusCode}): ${res.body}');
      return null;
    } catch (e) {
      print('smartLog error: $e');
      return null;
    }
  }

  // --- FUNCIONALIDAD 4: Generador de recetas con ingredientes ---
  static Future<Map<String, dynamic>?> generateFridgeRecipe(
      String ingredients, {Map<String, dynamic>? macrosLeft}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/nutrition/fridge-recipe'),
        headers: await _headers(),
        body: jsonEncode({'ingredients': ingredients, if (macrosLeft != null) 'macrosLeft': macrosLeft}),
      ).timeout(const Duration(seconds: 40));
      if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
      print('generateFridgeRecipe failed (${res.statusCode}): ${res.body}');
      return null;
    } catch (e) {
      print('generateFridgeRecipe error: $e');
      return null;
    }
  }
}

