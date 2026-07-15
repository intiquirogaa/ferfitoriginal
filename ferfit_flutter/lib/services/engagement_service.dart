import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';

/// Motor de avisos automáticos estilo Duolingo.
///
/// El usuario NO elige horarios. Nosotros decidimos cuándo avisar según:
/// - cuánto hace que no abre la app
/// - racha / XP / plan (vía backend)
class EngagementService {
  EngagementService._();
  static final EngagementService instance = EngagementService._();

  static const _dismissPrefix = 'engagement_dismissed_';
  static const _lastOpenKey = 'ferfit_last_open_ms';
  static const _userNameKey = 'user_name';

  /// Horas fijas del sistema (no configurables por el usuario).
  static const _systemAfternoonHour = 18;
  static const _systemEveningHour = 20;
  static const _systemEveningMinute = 30;
  static const _systemMorningHour = 10;
  static const _systemMorningMinute = 30;

  Map<String, dynamic>? _lastResult;
  Map<String, dynamic>? _welcomeBackAlert;
  Map<String, dynamic>? get lastResult => _lastResult;

  /// Llamar al abrir la app / entrar al dashboard / volver del background.
  Future<Map<String, dynamic>?> onAppOpened({String? userName}) async {
    final prefs = await SharedPreferences.getInstance();

    // Detectar “volvió después de X días” ANTES de actualizar last_open
    final prevMs = prefs.getInt(_lastOpenKey);
    _welcomeBackAlert = null;
    if (prevMs != null) {
      final daysAway = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(prevMs)).inDays;
      if (daysAway >= 1) {
        final n = (userName ?? prefs.getString(_userNameKey) ?? 'campeón').trim().split(' ').first;
        _welcomeBackAlert = {
          'id': 'welcome_back_$daysAway',
          'type': 'missed_you',
          'priority': 110,
          'emoji': daysAway >= 3 ? '💔' : '😢',
          'title': daysAway == 1
              ? '¡Feo se alegra de verte, $n!'
              : '¡Feo te extrañaba, $n!',
          'body': daysAway == 1
              ? 'Hace un día que no pasabas. Retomemos el ritmo hoy con Feo.'
              : 'Hace $daysAway días que no abrías FerFit. Feo y tu plan siguen listos.',
          'cta': 'Entrenar ahora',
          'action': 'open_workout',
          'dismissible': true,
        };
      }
    }

    await prefs.setInt(_lastOpenKey, DateTime.now().millisecondsSinceEpoch);
    if (userName != null && userName.trim().isNotEmpty) {
      await prefs.setString(_userNameKey, userName.trim());
    }

    final name = userName?.trim().isNotEmpty == true
        ? userName!.trim().split(' ').first
        : (prefs.getString(_userNameKey) ?? 'campeón').split(' ').first;

    // Al abrir: cancelar avisos viejos y reprogramar la cadena de inactividad
    await NotificationService.instance.cancelAll();
    await _scheduleInactivityChain(name);

    final data = await ApiService.getEngagementAlerts();
    if (data != null) {
      _lastResult = data;
      await _scheduleTrainingNudges(data, name);
    }
    return data;
  }

  /// Llamar cuando la app se minimiza para asegurar que las notificaciones locales 
  /// están al día con lo último que hizo el usuario en la sesión.
  Future<void> onAppPaused() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_userNameKey) ?? 'campeón';
    
    // Al minimizar, limpiamos y resincronizamos con el estado actual
    await NotificationService.instance.cancelAll();
    await _scheduleInactivityChain(name.split(' ').first);
    
    final data = await ApiService.getEngagementAlerts();
    if (data != null) {
      _lastResult = data;
      await _scheduleTrainingNudges(data, name.split(' ').first);
    }
  }

  Future<Map<String, dynamic>?> sync({bool rescheduleNotifications = true}) async {
    if (!rescheduleNotifications) {
      final data = await ApiService.getEngagementAlerts();
      if (data != null) _lastResult = data;
      return data;
    }
    return onAppOpened();
  }

  /// Si no abre la app, avisamos a las 24h / 48h / 72h / 7 días (habla Feo).
  Future<void> _scheduleInactivityChain(String name) async {
    await NotificationService.instance.scheduleAfter(
      id: 2001,
      delay: const Duration(hours: 24),
      title: '😢 Feo te extraña',
      body: '$name, hace un día que no abrís la app. Feo y tu plan te esperan.',
    );
    await NotificationService.instance.scheduleAfter(
      id: 2002,
      delay: const Duration(hours: 48),
      title: '👀 Feo pregunta: ¿todo bien, $name?',
      body: 'Llevás 2 días sin pasar. Un rato alcanza — Feo no se rinde.',
    );
    await NotificationService.instance.scheduleAfter(
      id: 2003,
      delay: const Duration(hours: 72),
      title: '💔 Feo te extraña mucho',
      body: 'Hace 3 días que no venís. Volvé hoy y retomamos juntos con Feo.',
    );
    await NotificationService.instance.scheduleAfter(
      id: 2004,
      delay: const Duration(days: 7),
      title: '⚡ Feo sigue acá, $name',
      body: 'Pasó una semana. Tu rutina sigue lista cuando quieras volver.',
    );
  }

  /// Nudges de entrenamiento con horas fijas del sistema.
  Future<void> _scheduleTrainingNudges(Map<String, dynamic> data, String name) async {
    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    final trainedToday = meta['trainedToday'] == true;
    if (trainedToday) return;

    final alerts = data['alerts'] as List<dynamic>? ?? [];
    final hasMissed = alerts.any((a) => a is Map && a['type'] == 'missed_you');
    final hasStreakRisk = alerts.any((a) => a is Map && a['type'] == 'streak_at_risk');
    final hasCloseLevel = alerts.any((a) => a is Map && a['type'] == 'close_to_level');
    final hasNoPlan = alerts.any((a) => a is Map && a['type'] == 'no_plan');
    final daysSince = meta['daysSinceLastWorkout'];
    final hasPlan = !hasNoPlan;

    if (hasPlan) {
      await NotificationService.instance.scheduleNextAtHour(
        id: 1001,
        hour: _systemAfternoonHour,
        minute: 0,
        title: '⏰ Feo: hora de moverte',
        body: '$name, ¿entrenamos hoy? Feo te acompaña.',
      );
    }

    if (hasStreakRisk) {
      await NotificationService.instance.scheduleNextAtHour(
        id: 1002,
        hour: _systemEveningHour,
        minute: _systemEveningMinute,
        title: '🔥 Feo: tu racha te necesita',
        body: 'Si no entrenás, podés perder la racha. Un rato corto alcanza.',
      );
    }

    if (hasMissed || (daysSince is num && daysSince >= 2)) {
      await NotificationService.instance.scheduleNextAtHour(
        id: 1003,
        hour: _systemMorningHour,
        minute: _systemMorningMinute,
        title: '😢 Feo te extraña',
        body: '$name, hace rato que no entrenás. Volvé un rato con Feo.',
      );
    }

    if (hasCloseLevel) {
      await NotificationService.instance.scheduleNextAtHour(
        id: 1005,
        hour: 17,
        minute: 0,
        title: '⭐ Feo: casi subís de nivel',
        body: 'Un entrenamiento más y subís. ¡Dale!',
      );
    }

    if (hasNoPlan) {
      await NotificationService.instance.scheduleAfter(
        id: 1006,
        delay: const Duration(hours: 20),
        title: '🎯 Feo quiere tu plan',
        body: 'En 2 minutos generamos tu rutina con IA.',
      );
    }
  }

  Future<bool> isDismissed(String alertId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_dismissPrefix$alertId';
    final day = prefs.getString(key);
    if (day == null) return false;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return day == today;
  }

  Future<void> dismiss(String alertId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('$_dismissPrefix$alertId', today);
    if (_welcomeBackAlert?['id'] == alertId) {
      _welcomeBackAlert = null;
    }
  }

  Future<void> clearOnLogout() async {
    _lastResult = null;
    _welcomeBackAlert = null;
    await NotificationService.instance.cancelAll();
  }

  Future<Map<String, dynamic>?> primaryAlert() async {
    // Prioridad: “te extrañamos / bienvenida de vuelta” local
    if (_welcomeBackAlert != null) {
      final id = _welcomeBackAlert!['id']?.toString() ?? '';
      if (id.isNotEmpty && !(await isDismissed(id))) {
        return _welcomeBackAlert;
      }
    }

    final data = _lastResult ?? await sync(rescheduleNotifications: false);
    if (data == null) return null;

    final primary = data['primary'];
    if (primary is Map) {
      final id = primary['id']?.toString() ?? '';
      if (id.isNotEmpty && !(await isDismissed(id))) {
        return Map<String, dynamic>.from(primary);
      }
    }

    final alerts = data['alerts'] as List<dynamic>? ?? [];
    for (final a in alerts) {
      if (a is! Map) continue;
      final map = Map<String, dynamic>.from(a);
      final id = map['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      if (!(await isDismissed(id))) return map;
    }
    return null;
  }
}
