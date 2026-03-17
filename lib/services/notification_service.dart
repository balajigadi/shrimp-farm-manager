import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum AlertType { feed, water, growth, mortality }

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );
  }

  static void _onTap(NotificationResponse response) {
    // For MVP we only ensure the app opens.
    // Navigation to a specific tab can be wired later using a global navigator key.
    final payload = response.payload;
    if (payload == null) return;
    // ignore: unused_local_variable
    final data = jsonDecode(payload) as Map<String, dynamic>;
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Schedules a test notification in [seconds] from now. Use for testing.
  Future<void> scheduleTestNotification({int seconds = 10}) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = now.add(Duration(seconds: seconds));

    const androidDetails = AndroidNotificationDetails(
      'daily_alerts',
      'Daily Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      999,
      'Test Alert',
      seconds == 0
          ? 'You triggered this test notification.'
          : 'This is a test. Real alerts fire at 6:00, 11:00, 16:00, 21:00 (feed); 7:00 (water); 7:30 (mortality); Mon 9:00 (growth).',
      scheduled,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'test'}),
    );
  }

  /// Shows a test notification immediately (for quick testing).
  Future<void> showTestNotificationNow() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_alerts',
      'Daily Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      998,
      'Test Alert',
      'Tap to open app. Real reminders run at feed/water/growth/mortality times.',
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: jsonEncode({'type': 'test'}),
    );
  }

  Future<void> scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
    required AlertType type,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'daily_alerts',
      'Daily Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: jsonEncode({'type': type.name}),
    );
  }

  Future<void> scheduleWeekly({
    required int id,
    required int weekday,
    required TimeOfDay time,
    required String title,
    required String body,
    required AlertType type,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'weekly_alerts',
      'Weekly Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: jsonEncode({'type': type.name}),
    );
  }

  Future<void> scheduleDefaultMvpAlerts() async {
    // Feed reminders – 4 times per day.
    await scheduleDaily(
      id: 100,
      time: const TimeOfDay(hour: 6, minute: 0),
      title: 'Feed Reminder',
      body: 'Time to feed shrimp (morning).',
      type: AlertType.feed,
    );
    await scheduleDaily(
      id: 101,
      time: const TimeOfDay(hour: 11, minute: 0),
      title: 'Feed Reminder',
      body: 'Time to feed shrimp (noon).',
      type: AlertType.feed,
    );
    await scheduleDaily(
      id: 102,
      time: const TimeOfDay(hour: 16, minute: 0),
      title: 'Feed Reminder',
      body: 'Time to feed shrimp (evening).',
      type: AlertType.feed,
    );
    await scheduleDaily(
      id: 103,
      time: const TimeOfDay(hour: 21, minute: 0),
      title: 'Feed Reminder',
      body: 'Time to feed shrimp (night).',
      type: AlertType.feed,
    );

    // Water quality – daily.
    await scheduleDaily(
      id: 200,
      time: const TimeOfDay(hour: 7, minute: 0),
      title: 'Water Quality Check',
      body: 'Test pH, DO, Ammonia, Temperature.',
      type: AlertType.water,
    );

    // Growth sampling – weekly (Monday morning).
    await scheduleWeekly(
      id: 300,
      weekday: DateTime.monday,
      time: const TimeOfDay(hour: 9, minute: 0),
      title: 'Growth Sampling Due',
      body: 'Take shrimp sample and record growth.',
      type: AlertType.growth,
    );

    // Mortality check – daily.
    await scheduleDaily(
      id: 400,
      time: const TimeOfDay(hour: 7, minute: 30),
      title: 'Mortality Check',
      body: 'Check ponds for dead shrimp and log mortality.',
      type: AlertType.mortality,
    );
  }
}

