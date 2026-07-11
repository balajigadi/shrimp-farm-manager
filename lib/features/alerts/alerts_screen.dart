import 'package:flutter/material.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'package:prawn_farm_app/services/notification_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alertsTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.alertsOperationalReminders,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _AlertTile(
            icon: Icons.set_meal,
            iconColor: const Color(0xFF00C853),
            title: l10n.alertFeedReminderTitle,
            subtitle: l10n.alertFeedReminderSchedule,
            body: l10n.alertFeedReminderBody,
          ),
          _AlertTile(
            icon: Icons.opacity,
            iconColor: const Color(0xFF2196F3),
            title: l10n.alertWaterCheckTitle,
            subtitle: l10n.alertWaterCheckSchedule,
            body: l10n.alertWaterCheckBody,
          ),
          _AlertTile(
            icon: Icons.show_chart,
            iconColor: const Color(0xFF9C27B0),
            title: l10n.alertGrowthSamplingTitle,
            subtitle: l10n.alertGrowthSamplingSchedule,
            body: l10n.alertGrowthSamplingBody,
          ),
          _AlertTile(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            title: l10n.alertMortalityTitle,
            subtitle: l10n.alertMortalitySchedule,
            body: l10n.alertMortalityBody,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l10n.alertsTestNotificationTitle),
            subtitle: Text(l10n.alertsTestNotificationSubtitle),
            onTap: () async {
              await NotificationService.instance.showTestNotificationNow();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.alertsTestNotificationSent)),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String body;

  const _AlertTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withValues(alpha: 0.15),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
