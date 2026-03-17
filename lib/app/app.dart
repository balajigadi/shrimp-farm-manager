import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'routes.dart';
import 'theme.dart';

class PrawnFarmApp extends StatefulWidget {
  const PrawnFarmApp({super.key});

  @override
  State<PrawnFarmApp> createState() => _PrawnFarmAppState();
}

class _PrawnFarmAppState extends State<PrawnFarmApp> {
  Locale? _locale;

  void _setLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      locale: _locale,
      setLocale: _setLocale,
      child: MaterialApp(
        title: 'Prawn Farm Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _locale,
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.home,
      ),
    );
  }
}

class AppLocaleScope extends InheritedWidget {
  final Locale? locale;
  final void Function(Locale? locale) setLocale;

  const AppLocaleScope({
    required this.locale,
    required this.setLocale,
    required Widget child,
  }) : super(key: null, child: child);

  static AppLocaleScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'No AppLocaleScope found in context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppLocaleScope oldWidget) {
    return oldWidget.locale != locale;
  }
}
