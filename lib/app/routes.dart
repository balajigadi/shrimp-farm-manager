import 'package:flutter/material.dart';
import '../features/shell/bottom_nav_shell.dart';

class AppRoutes {
  static const home = '/';

  static Map<String, WidgetBuilder> routes = {
    home: (_) => const BottomNavShell(),
  };
}
