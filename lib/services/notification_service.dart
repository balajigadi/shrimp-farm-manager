import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum AlertType { feed, water, growth, mortality, expense }

class AlertSettings {
  final bool enabled;
  final TimeOfDay waterTime;
  final List<TimeOfDay> feedTimes;
  final TimeOfDay? expenseTime;

  const AlertSettings({
    required this.enabled,
    required this.waterTime,
    required this.feedTimes,
    required this.expenseTime,
  });
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  static const _appLocaleKey = 'app_locale_code';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _initialized = false;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;
  String _localSettingsKey(String uid) => 'alert_settings_$uid';

  Map<String, dynamic> _settingsToJson(AlertSettings s) => {
        'enabled': s.enabled,
        'water': {'h': s.waterTime.hour, 'm': s.waterTime.minute},
        'feed': s.feedTimes
            .map((t) => {'h': t.hour, 'm': t.minute})
            .toList(growable: false),
        'expense': s.expenseTime == null
            ? null
            : {'h': s.expenseTime!.hour, 'm': s.expenseTime!.minute},
      };

  AlertSettings? _settingsFromJson(Map<String, dynamic> json) {
    TimeOfDay readTime(dynamic raw) {
      final map = raw as Map<String, dynamic>;
      return TimeOfDay(hour: map['h'] as int, minute: map['m'] as int);
    }

    final feedRaw = (json['feed'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final feedTimes = feedRaw.map(readTime).toList(growable: false);
    if (feedTimes.isEmpty) return null;

    final expenseRaw = json['expense'];
    return AlertSettings(
      enabled: json['enabled'] as bool? ?? true,
      waterTime: readTime(json['water']),
      feedTimes: feedTimes,
      expenseTime:
          expenseRaw == null ? null : readTime(expenseRaw as Map<String, dynamic>),
    );
  }

  Future<void> saveAlertSettings(AlertSettings settings) async {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty) return;

    final json = _settingsToJson(settings);
    try {
      await _db.collection('userSettings').doc(uid).set(
        {
          'uid': uid,
          'alertSettings': json,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      // If Firestore rules block this write, keep alerts usable by storing
      // settings on-device. This prevents "Could not update alerts" failures.
      if (e.code != 'permission-denied') rethrow;
    }
    await _saveAlertSettingsLocal(uid: uid, settingsJson: json);
  }

  Future<AlertSettings?> loadAlertSettings() async {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty) return null;

    try {
      final doc = await _db.collection('userSettings').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      final json = data['alertSettings'] as Map<String, dynamic>?;
      if (json == null) return null;
      // Keep a local cache so settings still load when Firestore is offline
      // or later blocked by rules changes.
      await _saveAlertSettingsLocal(uid: uid, settingsJson: json);
      return _settingsFromJson(json);
    } catch (_) {
      return _loadAlertSettingsLocal(uid);
    }
  }

  Future<void> _saveAlertSettingsLocal({
    required String uid,
    required Map<String, dynamic> settingsJson,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localSettingsKey(uid), jsonEncode(settingsJson));
  }

  Future<AlertSettings?> _loadAlertSettingsLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localSettingsKey(uid));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _settingsFromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz.initializeTimeZones();
    // Use a fixed timezone so notifications schedule correctly without needing
    // platform timezone plugins (important for build compatibility).
    //
    // If you want this to be dynamic later, we can add a better timezone plugin
    // or read timezone from the device.
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

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

    // Request permission on Android 13+ and iOS.
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
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
    final copy = await _copyForLocale();

    final androidDetails = AndroidNotificationDetails(
      'daily_alerts',
      copy.dailyAlertsChannel,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.zonedSchedule(
      999,
      copy.testAlertTitle,
      seconds == 0 ? copy.testTriggeredBody : copy.testScheduledBody,
      scheduled,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode({'type': 'test'}),
    );
  }

  /// Shows a test notification immediately (for quick testing).
  Future<void> showTestNotificationNow() async {
    final copy = await _copyForLocale();
    final androidDetails = AndroidNotificationDetails(
      'daily_alerts',
      copy.dailyAlertsChannel,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      998,
      copy.testAlertTitle,
      copy.testImmediateBody,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
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
    final copy = await _copyForLocale();
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
      copy.dailyAlertsChannel,
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
    final copy = await _copyForLocale();
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
      copy.weeklyAlertsChannel,
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
    final copy = await _copyForLocale();
    // Feed reminders – 5 times per day.
    await scheduleDaily(
      id: 100,
      time: const TimeOfDay(hour: 6, minute: 0),
      title: copy.feedReminderTitle,
      body: copy.feedReminderBody(0),
      type: AlertType.feed,
    );
    await scheduleDaily(
      id: 101,
      time: const TimeOfDay(hour: 11, minute: 0),
      title: copy.feedReminderTitle,
      body: copy.feedReminderBody(1),
      type: AlertType.feed,
    );
    await scheduleDaily(
      id: 102,
      time: const TimeOfDay(hour: 16, minute: 0),
      title: copy.feedReminderTitle,
      body: copy.feedReminderBody(2),
      type: AlertType.feed,
    );
    await scheduleDaily(
      id: 103,
      time: const TimeOfDay(hour: 21, minute: 0),
      title: copy.feedReminderTitle,
      body: copy.feedReminderBody(3),
      type: AlertType.feed,
    );
    await scheduleDaily(
      id: 104,
      time: const TimeOfDay(hour: 23, minute: 0),
      title: copy.feedReminderTitle,
      body: copy.feedReminderBody(4),
      type: AlertType.feed,
    );

    // Water quality – daily.
    await scheduleDaily(
      id: 200,
      time: const TimeOfDay(hour: 7, minute: 0),
      title: copy.waterCheckTitle,
      body: copy.waterCheckBody,
      type: AlertType.water,
    );

    // Growth sampling – weekly (Monday morning).
    await scheduleWeekly(
      id: 300,
      weekday: DateTime.monday,
      time: const TimeOfDay(hour: 9, minute: 0),
      title: copy.growthSamplingTitle,
      body: copy.growthSamplingBody,
      type: AlertType.growth,
    );

    // Mortality check – daily.
    await scheduleDaily(
      id: 400,
      time: const TimeOfDay(hour: 7, minute: 30),
      title: copy.mortalityCheckTitle,
      body: copy.mortalityCheckBody,
      type: AlertType.mortality,
    );
  }

  /// Replaces all configured reminders with user-selected times.
  Future<void> applyAlertSettings({
    required bool enabled,
    required TimeOfDay waterTime,
    required List<TimeOfDay> feedTimes,
    TimeOfDay? expenseTime,
    bool persist = true,
  }) async {
    final copy = await _copyForLocale();
    if (persist) {
      await saveAlertSettings(
        AlertSettings(
          enabled: enabled,
          waterTime: waterTime,
          feedTimes: feedTimes,
          expenseTime: expenseTime,
        ),
      );
    }

    await cancelAll();
    if (!enabled) return;

    // Water quality – daily.
    await scheduleDaily(
      id: 200,
      time: waterTime,
      title: copy.waterCheckTitle,
      body: copy.waterCheckBody,
      type: AlertType.water,
    );

    // Feed reminders (configurable list, up to 5).
    final sortedFeed = [...feedTimes]
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    for (var i = 0; i < sortedFeed.length && i < 5; i++) {
      final t = sortedFeed[i];
      await scheduleDaily(
        id: 100 + i,
        time: t,
        title: copy.feedReminderTitle,
        body: copy.feedReminderBody(i),
        type: AlertType.feed,
      );
    }

    // Optional daily expense log reminder.
    if (expenseTime != null) {
      await scheduleDaily(
        id: 500,
        time: expenseTime,
        title: copy.expenseReminderTitle,
        body: copy.expenseReminderBody,
        type: AlertType.expense,
      );
    }

    // Keep weekly growth + daily mortality as baseline operations.
    await scheduleWeekly(
      id: 300,
      weekday: DateTime.monday,
      time: const TimeOfDay(hour: 9, minute: 0),
      title: copy.growthSamplingTitle,
      body: copy.growthSamplingBody,
      type: AlertType.growth,
    );
    await scheduleDaily(
      id: 400,
      time: const TimeOfDay(hour: 7, minute: 30),
      title: copy.mortalityCheckTitle,
      body: copy.mortalityCheckBody,
      type: AlertType.mortality,
    );
  }

  Future<_NotificationCopy> _copyForLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_appLocaleKey)?.toLowerCase();
    final deviceCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
    final code = (savedCode == 'te' || savedCode == 'en')
        ? savedCode!
        : (deviceCode == 'te' ? 'te' : 'en');
    return _NotificationCopy.forLanguage(code);
  }
}

class _NotificationCopy {
  final bool isTelugu;

  const _NotificationCopy._(this.isTelugu);

  factory _NotificationCopy.forLanguage(String code) =>
      _NotificationCopy._(code == 'te');

  String get dailyAlertsChannel => isTelugu ? 'రోజువారీ అలర్ట్స్' : 'Daily Alerts';
  String get weeklyAlertsChannel => isTelugu ? 'వారపు అలర్ట్స్' : 'Weekly Alerts';
  String get testAlertTitle => isTelugu ? 'టెస్ట్ అలర్ట్' : 'Test Alert';
  String get testTriggeredBody =>
      isTelugu ? 'మీరు ఈ టెస్ట్ నోటిఫికేషన్‌ను ట్రిగర్ చేశారు.' : 'You triggered this test notification.';
  String get testScheduledBody => isTelugu
      ? 'ఇది టెస్ట్ అలర్ట్. నిజమైన అలర్ట్స్ మేత/నీరు/వృద్ధి/మరణాల సమయాలకు వస్తాయి.'
      : 'This is a test. Real alerts fire at feed/water/growth/mortality times.';
  String get testImmediateBody => isTelugu
      ? 'యాప్ తెరవడానికి ట్యాప్ చేయండి. నిజమైన రిమైండర్లు మేత/నీరు/వృద్ధి/మరణాల సమయాల్లో నడుస్తాయి.'
      : 'Tap to open app. Real reminders run at feed/water/growth/mortality times.';

  String get feedReminderTitle => isTelugu ? 'మేత రిమైండర్' : 'Feed Reminder';
  String get waterCheckTitle => isTelugu ? 'నీటి నాణ్యత తనిఖీ' : 'Water Quality Check';
  String get waterCheckBody => isTelugu
      ? 'pH, DO, అమోనియా, ఉష్ణోగ్రత పరీక్షించండి.'
      : 'Test pH, DO, Ammonia, Temperature.';
  String get growthSamplingTitle => isTelugu ? 'వృద్ధి నమూనా సమయం' : 'Growth Sampling Due';
  String get growthSamplingBody => isTelugu
      ? 'రొయ్యల నమూనా తీసి వృద్ధిని నమోదు చేయండి.'
      : 'Take shrimp sample and record growth.';
  String get mortalityCheckTitle => isTelugu ? 'మరణాల తనిఖీ' : 'Mortality Check';
  String get mortalityCheckBody => isTelugu
      ? 'కొలనులు చూసి మరణాలను నమోదు చేయండి.'
      : 'Check ponds for dead shrimp and log mortality.';
  String get expenseReminderTitle => isTelugu ? 'ఖర్చు నమోదు రిమైండర్' : 'Expense Log Reminder';
  String get expenseReminderBody => isTelugu
      ? 'ఈ రోజు ఫార్మ్ ఖర్చులను రసీదు అటాచ్‌మెంట్‌తో నమోదు చేయండి.'
      : 'Log today\'s farm expenses with receipt attachments.';

  String feedReminderBody(int index) {
    final label = switch (index) {
      0 => isTelugu ? 'ఉదయం' : 'morning',
      1 => isTelugu ? 'మధ్యాహ్నం' : 'afternoon',
      2 => isTelugu ? 'సాయంత్రం' : 'evening',
      3 => isTelugu ? 'రాత్రి' : 'night',
      _ => isTelugu ? 'అర్ధరాత్రి' : 'late night',
    };
    return isTelugu
        ? 'రొయ్యలకు మేత ఇవ్వాల్సిన సమయం ($label).'
        : 'Time to feed shrimp ($label).';
  }
}

