import 'package:flutter/material.dart';

/// GlobalKeys para que Feo apunte a componentes reales (estilo Duolingo).
class CoachTourKeys {
  CoachTourKeys._();

  // Tabs de la barra inferior
  static final tabDashboard = GlobalKey(debugLabel: 'tour_tab_dashboard');
  static final tabWorkout = GlobalKey(debugLabel: 'tour_tab_workout');
  static final tabNutrition = GlobalKey(debugLabel: 'tour_tab_nutrition');
  static final tabProgress = GlobalKey(debugLabel: 'tour_tab_progress');

  // Dashboard
  static final dashboardHeader = GlobalKey(debugLabel: 'tour_dashboard_header');
  static final createPlan = GlobalKey(debugLabel: 'tour_create_plan');
  static final hubMissions = GlobalKey(debugLabel: 'tour_hub_missions');
  static final hubLeagues = GlobalKey(debugLabel: 'tour_hub_leagues');

  // Entrenamiento
  static final workoutHeader = GlobalKey(debugLabel: 'tour_workout_header');

  // Nutrición
  static final nutritionHeader = GlobalKey(debugLabel: 'tour_nutrition_header');
  static final logFood = GlobalKey(debugLabel: 'tour_log_food');
  static final fridgeRecipe = GlobalKey(debugLabel: 'tour_fridge_recipe');

  // Progreso
  static final progressHeader = GlobalKey(debugLabel: 'tour_progress_header');
}
