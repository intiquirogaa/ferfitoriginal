import 'package:shared_preferences/shared_preferences.dart';

/// Primera sesión en este dispositivo (tour de Feo estilo Duolingo).
class OnboardingService {
  OnboardingService._();
  static final OnboardingService instance = OnboardingService._();

  static const _keyDone = 'feo_coach_tour_v1_done';
  static const _keyStep = 'feo_coach_tour_v1_step';

  Future<bool> shouldShowTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDone) != true;
  }

  Future<void> markTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDone, true);
    await prefs.remove(_keyStep);
  }

  Future<void> resetTour() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDone, false);
    await prefs.setInt(_keyStep, 0);
  }

  Future<int> savedStep() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyStep) ?? 0;
  }

  Future<void> saveStep(int step) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStep, step);
  }
}
