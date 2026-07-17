import 'package:flutter/material.dart';
import 'coach_tour_keys.dart';

/// Un paso del tour de Feo (textos en español rioplatense, tono coach).
class CoachTourStep {
  final String id;
  final String title;
  final String message;
  /// Tab del bottom nav a mostrar (0–3), o null.
  final int? tabIndex;
  final GlobalKey? targetKey;
  /// Si no hay target medible, centra la burbuja.
  final bool centerFocus;
  final String mascotAsset;
  final String nextLabel;

  const CoachTourStep({
    required this.id,
    required this.title,
    required this.message,
    this.tabIndex,
    this.targetKey,
    this.centerFocus = false,
    this.mascotAsset = 'assets/mascot/mascot_happy.jpg',
    this.nextLabel = 'Siguiente',
  });
}

/// Guion completo de la primera sesión (por dispositivo).
List<CoachTourStep> buildFeoCoachTourSteps() {
  return [
    const CoachTourStep(
      id: 'welcome',
      title: '¡Hola! Soy Feo',
      message:
          'Soy tu entrenador personal en FerFit. En un minuto te muestro cómo funciona la plataforma: rutina, nutrición, dashboard, progreso y misiones.',
      centerFocus: true,
      mascotAsset: 'assets/mascot/mascot_happy.jpg',
      nextLabel: 'Empezar',
    ),
    CoachTourStep(
      id: 'routine',
      title: 'Tu rutina de entrenamiento',
      message:
          'Acá generás tu plan. Me contás objetivo, nivel, días y equipo; la IA arma una rutina personalizada. Después entrenás marcando series con buena técnica.',
      tabIndex: 1,
      targetKey: CoachTourKeys.tabWorkout,
      nextLabel: 'Siguiente',
    ),
    CoachTourStep(
      id: 'create_plan',
      title: 'Crear el plan',
      message:
          'Si todavía no tenés rutina, usá «Crear plan» o el asistente en Entrenamiento. Es el primer paso para que el resto de la app tenga sentido.',
      tabIndex: 0,
      targetKey: CoachTourKeys.createPlan,
      nextLabel: 'Siguiente',
    ),
    CoachTourStep(
      id: 'nutrition',
      title: 'Plan de nutrición',
      message:
          'En Nutrición ves calorías y macros alineados a tu objetivo. No es una dieta genérica: acompaña tu entrenamiento.',
      tabIndex: 2,
      targetKey: CoachTourKeys.tabNutrition,
      nextLabel: 'Siguiente',
    ),
    CoachTourStep(
      id: 'log_food',
      title: 'Cargar lo que comés',
      message:
          'Con «Cargar comida IA» registrás una comida y te ayudo a estimarla. Así llevás un registro real de lo que comés en el día.',
      tabIndex: 2,
      targetKey: CoachTourKeys.logFood,
      nextLabel: 'Siguiente',
    ),
    CoachTourStep(
      id: 'fridge',
      title: 'Receta de la heladera',
      message:
          '¿No sabés qué cocinar? «Receta heladera» arma ideas con lo que tenés en casa. Práctico y sin complicaciones.',
      tabIndex: 2,
      targetKey: CoachTourKeys.fridgeRecipe,
      nextLabel: 'Siguiente',
    ),
    CoachTourStep(
      id: 'dashboard',
      title: 'Tu dashboard',
      message:
          'El inicio es tu tablero: racha, XP, checklist del día y accesos rápidos. Miralo cada vez que abras la app para saber qué toca.',
      tabIndex: 0,
      targetKey: CoachTourKeys.dashboardHeader,
      nextLabel: 'Siguiente',
    ),
    CoachTourStep(
      id: 'progress',
      title: 'Progreso',
      message:
          'En Progreso ves historial, nivel y logros. Ahí se nota la constancia: no solo un día bueno, sino la tendencia.',
      tabIndex: 3,
      targetKey: CoachTourKeys.tabProgress,
      nextLabel: 'Siguiente',
    ),
    CoachTourStep(
      id: 'missions',
      title: 'Misiones y combates',
      message:
          'Las misiones diarias te dan estructura y FerCoins. Algunos desafíos son combates: un villano ataca, yo me defiendo y vos validás con video y técnica.',
      tabIndex: 0,
      targetKey: CoachTourKeys.hubMissions,
      nextLabel: 'Siguiente',
    ),
    CoachTourStep(
      id: 'leagues',
      title: 'Competencias y ligas',
      message:
          'En Ligas te medís con otros por XP semanal. Es un empujón extra de constancia; el centro sigue siendo tu plan y tu técnica.',
      tabIndex: 0,
      targetKey: CoachTourKeys.hubLeagues,
      nextLabel: 'Siguiente',
    ),
    const CoachTourStep(
      id: 'done',
      title: 'Listo para entrenar',
      message:
          'Ya sabés el mapa. Empezá creando tu rutina o explorá el dashboard. Si te trabás, hablame: estoy para ayudarte con forma, carga y recuperación.',
      centerFocus: true,
      mascotAsset: 'assets/mascot/mascot_goal.jpg',
      nextLabel: '¡Vamos!',
    ),
  ];
}
