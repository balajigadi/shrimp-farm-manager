import 'package:flutter/material.dart';
import 'package:prawn_farm_app/services/notification_service.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Operational reminders',
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
            title: 'Feed Reminder',
            subtitle: '6:00, 11:00, 16:00, 21:00',
            body: 'Tap to log feed',
          ),
          _AlertTile(
            icon: Icons.opacity,
            iconColor: const Color(0xFF2196F3),
            title: 'Water Quality Check',
            subtitle: 'Daily 7:00 AM',
            body: 'Test pH, DO, Ammonia, Temperature',
          ),
          _AlertTile(
            icon: Icons.show_chart,
            iconColor: const Color(0xFF9C27B0),
            title: 'Growth Sampling Due',
            subtitle: 'Weekly Monday 9:00 AM',
            body: 'Take shrimp sample and record growth',
          ),
          _AlertTile(
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
            title: 'Mortality Check',
            subtitle: 'Daily 7:30 AM',
            body: 'Check ponds and log mortality',
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Test notification'),
            subtitle: const Text('Send a test alert now'),
            onTap: () async {
              await NotificationService.instance.showTestNotificationNow();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test notification sent. Check status bar.'),
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
              backgroundColor: iconColor.withOpacity(0.15),
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
