import 'package:flutter/material.dart';
import 'package:prawn_farm_app/app/app.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'package:prawn_farm_app/services/notification_service.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppLocaleScope.of(context);
    final currentLocale = scope.locale;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Language'),
          ),
          RadioListTile<Locale?>(
            title: const Text('English'),
            value: const Locale('en'),
            groupValue: currentLocale ?? Localizations.localeOf(context),
            onChanged: (value) => scope.setLocale(value),
          ),
          RadioListTile<Locale?>(
            title: const Text('తెలుగు'),
            value: const Locale('te'),
            groupValue: currentLocale ?? Localizations.localeOf(context),
            onChanged: (value) => scope.setLocale(value),
          ),
          const Divider(),
          ListTile(
            title: const Text('Test alerts'),
            subtitle: const Text('Send a test notification now'),
            leading: const Icon(Icons.notifications_active_outlined),
            onTap: () async {
              await NotificationService.instance.showTestNotificationNow();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent. Check the status bar.'),
                  ),
                );
              }
            },
          ),
          ListTile(
            title: const Text('Test alert in 10 sec'),
            subtitle: const Text('Schedule a notification in 10 seconds'),
            leading: const Icon(Icons.schedule),
            onTap: () async {
              await NotificationService.instance.scheduleTestNotification(seconds: 10);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification in 10 seconds. Minimize the app to see it.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

