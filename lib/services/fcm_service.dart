import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:prawn_farm_app/app/navigation.dart';
import 'notification_service.dart';
import 'user_profile_service.dart';

/// FCM push for new market requirements + tap routing to [MarketScreen].
class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool get _isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Notifies [AppShell] to switch to Market and highlight a requirement.
  final ValueNotifier<String?> marketHighlightRequirementId =
      ValueNotifier<String?>(null);

  String? _pendingRequirementId;
  Future<void>? _initFuture;
  bool _listenersRegistered = false;

  /// Ensures token setup and initial-message check have finished.
  Future<void> ensureInitialized() => _initFuture ??= _initInternal();

  Future<void> init() => ensureInitialized();

  Future<void> _initInternal() async {
    if (_listenersRegistered) return;
    _listenersRegistered = true;

    try {
      await _ensureAndroidNotificationChannel();
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // iOS: APNs token must exist before FCM token fetch, otherwise getToken()
      // often returns null / fails on physical devices.
      if (_isIos) {
        var apnsToken = await _messaging.getAPNSToken();
        // APNs registration can lag briefly after registerForRemoteNotifications.
        if (apnsToken == null) {
          await Future<void>.delayed(const Duration(seconds: 2));
          apnsToken = await _messaging.getAPNSToken();
        }
        if (apnsToken == null) {
          debugPrint(
            'FcmService: APNs token is null — skipping FCM token registration',
          );
        } else {
          await _saveFcmToken();
        }
      } else {
        await _saveFcmToken();
      }

      _messaging.onTokenRefresh.listen((newToken) {
        UserProfileService.instance.saveFcmToken(newToken);
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _storePendingRequirement(_extractRequirementId(initial));
      }
    } catch (e) {
      debugPrint('FcmService.init failed: $e');
    }
  }

  Future<void> _saveFcmToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await UserProfileService.instance.saveFcmToken(token);
    }
  }

  /// Call when [AppShell] mounts after auth + onboarding.
  String? consumePendingRequirementId() {
    final id = _pendingRequirementId;
    _pendingRequirementId = null;
    return id;
  }

  /// Shared entry for background tap and in-app routing.
  void navigateToRequirement(String requirementId) {
    if (requirementId.isEmpty) return;

    _pendingRequirementId = requirementId;
    marketHighlightRequirementId.value = requirementId;

    final nav = rootNavigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final id = _extractRequirementId(message);
    if (id == null) return;
    navigateToRequirement(id);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('FCM foreground message: ${message.data}');

    // Android already surfaces notification payloads via the system tray /
    // channel. On iOS, foreground FCM does not show a banner unless we display
    // a local notification.
    if (!_isIos) return;

    final notification = message.notification;
    final title = notification?.title ?? 'New buyer requirement near you';
    final body = notification?.body ?? '';
    if (body.isEmpty && notification == null) return;

    final requirementId = _extractRequirementId(message);
    await NotificationService.instance.showForegroundPushNotification(
      title: title,
      body: body.isEmpty ? title : body,
      payload: requirementId == null
          ? null
          : '{"type":"market_requirement","requirementId":"$requirementId"}',
    );
  }

  void _storePendingRequirement(String? requirementId) {
    if (requirementId == null || requirementId.isEmpty) return;
    _pendingRequirementId = requirementId;
  }

  String? _extractRequirementId(RemoteMessage message) {
    final data = message.data;
    if (data['type'] != 'market_requirement') return null;
    final id = data['requirementId'];
    if (id is String && id.isNotEmpty) return id;
    return null;
  }

  /// Matches [onRequirementCreated] `android.notification.channelId`.
  Future<void> _ensureAndroidNotificationChannel() async {
    if (kIsWeb) return;
    final android = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'market_requirements',
        'Buyer requirements',
        description: 'Alerts when traders post buyer needs in your mandal',
        importance: Importance.high,
      ),
    );
  }
}
