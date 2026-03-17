import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:prawn_farm_app/services/notification_service.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  await NotificationService.instance.scheduleDefaultMvpAlerts();
  runApp(const PrawnFarmApp());
}
