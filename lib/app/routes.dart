import 'package:flutter/material.dart';
import '../features/auth/auth_gate.dart';

class AppRoutes {
  static const home = '/';

  static Map<String, WidgetBuilder> routes = {
    home: (_) => const AuthGate(),
  };
}
