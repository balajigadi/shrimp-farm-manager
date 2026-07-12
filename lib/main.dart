import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:prawn_farm_app/services/notification_service.dart';
import 'package:prawn_farm_app/services/fcm_service.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is required for auth/Firestore, but notification scheduling should
  // never block the first UI render (Android would otherwise show a blank
  // screen / launcher icon while awaiting initialization).
  Object? firebaseError;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    firebaseError = e;
  }

  if (firebaseError != null) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Firebase failed to start.\n\n$firebaseError',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
    return;
  }

  // iOS: finish FCM/APNs permission + token registration before first frame so
  // getAPNSToken() is not racing the UI. Android keeps post-runApp init to
  // avoid the blank-screen startup delay.
  final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  if (isIos) {
    await FcmService.instance.init();
  }

  runApp(const PrawnFarmApp());

  if (!isIos) {
    FcmService.instance.init().catchError((_) {});
  }

  // Run notification setup after the UI is already on screen.
  NotificationService.instance.init().then((_) async {
    try {
      final saved = await NotificationService.instance.loadAlertSettings();
      if (saved != null) {
        await NotificationService.instance.applyAlertSettings(
          enabled: saved.enabled,
          waterTime: saved.waterTime,
          feedTimes: saved.feedTimes,
          expenseTime: saved.expenseTime,
          // Already persisted; just re-apply on startup.
          persist: false,
        );
      } else {
        await NotificationService.instance.scheduleDefaultMvpAlerts();
      }
    } catch (_) {
      // Notification failures shouldn't prevent the app from opening.
    }
  }).catchError((_) {
    // If notification initialization fails, don't crash at startup.
  });
}
