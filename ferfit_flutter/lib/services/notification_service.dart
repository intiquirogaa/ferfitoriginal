import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Notificaciones locales automáticas (el usuario no elige horarios).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  ByteArrayAndroidBitmap? _mascotBitmap;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ferfit_engagement',
    'FerFit Motivación',
    description: 'Avisos automáticos de rutina, racha y constancia',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (kIsWeb || _ready) return;

    tz.initializeTimeZones();
    // Usar offset del dispositivo (sin plugin nativo flutter_timezone)
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    final locationName = hours == -3
        ? 'America/Argentina/Buenos_Aires'
        : hours == -5
            ? 'America/Bogota'
            : hours == -6
                ? 'America/Mexico_City'
                : hours == 1
                    ? 'Europe/Madrid'
                    : 'UTC';
    try {
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);
    await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    try {
      final data = await rootBundle.load('assets/mascot/mascot_happy.jpg');
      _mascotBitmap = ByteArrayAndroidBitmap(data.buffer.asUint8List());
    } catch (_) {
      try {
        final data = await rootBundle.load('assets/mascot/ferfit_mascot.jpg');
        _mascotBitmap = ByteArrayAndroidBitmap(data.buffer.asUint8List());
      } catch (_) {
        _mascotBitmap = null;
      }
    }

    _ready = true;
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id);
  }

  Future<void> scheduleAfter({
    required int id,
    required Duration delay,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    if (delay.inSeconds < 30) return;
    final when = tz.TZDateTime.now(tz.local).add(delay);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'engagement',
    );
  }

  Future<void> scheduleAt({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'engagement',
    );
  }

  Future<void> scheduleNextAtHour({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    final when = _nextInstanceOfTime(hour, minute);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'engagement',
    );
  }

  NotificationDetails _details() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/launcher_icon',
        largeIcon: _mascotBitmap,
        styleInformation: _mascotBitmap != null
            ? BigPictureStyleInformation(
                _mascotBitmap!,
                largeIcon: _mascotBitmap,
                contentTitle: null,
                summaryText: 'Feo · FerFit',
              )
            : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
