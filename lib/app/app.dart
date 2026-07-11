import 'package:flutter/material.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation.dart';
import 'routes.dart';
import 'theme.dart';

class PrawnFarmApp extends StatefulWidget {
  const PrawnFarmApp({super.key});

  @override
  State<PrawnFarmApp> createState() => _PrawnFarmAppState();
}

class _PrawnFarmAppState extends State<PrawnFarmApp> {
  static const _localePrefKey = 'app_locale_code';
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localePrefKey);
    if (!mounted) return;
    if (code == 'en' || code == 'te') {
      setState(() {
        _locale = Locale(code!);
      });
    }
  }

  Future<void> _persistLocale(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_localePrefKey);
      return;
    }
    await prefs.setString(_localePrefKey, locale.languageCode);
  }

  void _setLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
    _persistLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      locale: _locale,
      setLocale: _setLocale,
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
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
