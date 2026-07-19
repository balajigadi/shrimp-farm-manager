import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prawn_farm_app/app/app.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'package:prawn_farm_app/services/notification_service.dart';
import 'package:prawn_farm_app/services/user_profile_service.dart';
import '../profile/user_profile.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  static void open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LanguageSettingsScreen(),
      ),
    );
  }

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  bool _dailyRemindersEnabled = true;
  TimeOfDay _waterAlertTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _feedAlertTime1 = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _feedAlertTime2 = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _feedAlertTime3 = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _feedAlertTime4 = const TimeOfDay(hour: 21, minute: 0);
  TimeOfDay _feedAlertTime5 = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay? _expenseAlertTime;
  bool _applyingAlerts = false;
  bool _loadingAlertSettings = true;

  @override
  void initState() {
    super.initState();
    _initForProfile();
  }

  Future<void> _initForProfile() async {
    final profile = await UserProfileService.instance.getProfile();
    if (!mounted) return;
    if (profile?.showsFarmTabs ?? true) {
      await _loadAlertSettings();
    } else {
      setState(() => _loadingAlertSettings = false);
    }
  }

  Future<void> _loadAlertSettings() async {
    final saved = await NotificationService.instance.loadAlertSettings();
    if (!mounted) return;
    if (saved != null) {
      setState(() {
        _dailyRemindersEnabled = saved.enabled;
        _waterAlertTime = saved.waterTime;
        _feedAlertTime1 =
            saved.feedTimes.isNotEmpty ? saved.feedTimes[0] : _feedAlertTime1;
        _feedAlertTime2 =
            saved.feedTimes.length > 1 ? saved.feedTimes[1] : _feedAlertTime2;
        _feedAlertTime3 =
            saved.feedTimes.length > 2 ? saved.feedTimes[2] : _feedAlertTime3;
        _feedAlertTime4 =
            saved.feedTimes.length > 3 ? saved.feedTimes[3] : _feedAlertTime4;
        _feedAlertTime5 =
            saved.feedTimes.length > 4 ? saved.feedTimes[4] : _feedAlertTime5;
        _expenseAlertTime = saved.expenseTime;
      });
    }
    setState(() => _loadingAlertSettings = false);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '${h.toString().padLeft(2, '0')}:$mm $period';
  }

  Future<void> _pickTime({
    required TimeOfDay initial,
    required void Function(TimeOfDay picked) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null) return;
    setState(() => onPicked(picked));
  }

  Future<void> _applyAlertSettings() async {
    setState(() => _applyingAlerts = true);
    try {
      await NotificationService.instance.applyAlertSettings(
        enabled: _dailyRemindersEnabled,
        waterTime: _waterAlertTime,
        feedTimes: [
          _feedAlertTime1,
          _feedAlertTime2,
          _feedAlertTime3,
          _feedAlertTime4,
          _feedAlertTime5,
        ],
        expenseTime: _expenseAlertTime,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.alertSettingsUpdated)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.couldNotUpdateAlerts}: $e')),
      );
    } finally {
      if (mounted) setState(() => _applyingAlerts = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.currentAccountNoEmail)),
      );
      return;
    }
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.passwordResetEmailSent(email))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scope = AppLocaleScope.of(context);
    final currentLocale = scope.locale;
    const sectionTitleStyle = TextStyle(
      color: Colors.grey,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return StreamBuilder<UserProfile?>(
      stream: UserProfileService.instance.watchProfile(),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        final showsFarmAlerts = profile?.showsFarmTabs ?? true;

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.settingsTitle),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(l10n.settingsAccountSection, style: sectionTitleStyle),
              ),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(l10n.settingsLanguage),
                      subtitle: Text(
                        (currentLocale ?? Localizations.localeOf(context)).languageCode == 'te'
                            ? 'తెలుగు'
                            : 'English',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<Locale?>(
                              dense: true,
                              title: Text(l10n.settingsLanguageEnglish),
                              value: const Locale('en'),
                              groupValue:
                                  currentLocale ?? Localizations.localeOf(context),
                              onChanged: (value) => scope.setLocale(value),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<Locale?>(
                              dense: true,
                              title: Text(l10n.settingsLanguageTelugu),
                              value: const Locale('te'),
                              groupValue:
                                  currentLocale ?? Localizations.localeOf(context),
                              onChanged: (value) => scope.setLocale(value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.fingerprint),
                      title: Text(
                        showsFarmAlerts
                            ? 'Farm account ID (UID)'
                            : 'Account ID (UID)',
                      ),
                      subtitle: Text(
                        FirebaseAuth.instance.currentUser?.uid ?? '—',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.copy),
                      onTap: () async {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null) return;
                        await Clipboard.setData(ClipboardData(text: uid));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UID copied to clipboard')),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_reset),
                      title: Text(l10n.settingsResetPassword),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _resetPassword,
                    ),
                  ],
                ),
              ),

              if (showsFarmAlerts) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text(l10n.settingsNotificationsSection, style: sectionTitleStyle),
                ),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_loadingAlertSettings)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(minHeight: 3),
                          ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.settingsDailyReminders),
                          value: _dailyRemindersEnabled,
                          onChanged: (v) => setState(() => _dailyRemindersEnabled = v),
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.settingsCheckWaterQuality),
                        const SizedBox(height: 4),
                        _timeTile(
                          label: l10n.settingsAlertTime,
                          value: _formatTime(_waterAlertTime),
                          onTap: () => _pickTime(
                            initial: _waterAlertTime,
                            onPicked: (t) => _waterAlertTime = t,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.settingsFeedThePond),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: _timeTile(
                                label: l10n.settingsTime1,
                                value: _formatTime(_feedAlertTime1),
                                onTap: () => _pickTime(
                                  initial: _feedAlertTime1,
                                  onPicked: (t) => _feedAlertTime1 = t,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _timeTile(
                                label: l10n.settingsTime2,
                                value: _formatTime(_feedAlertTime2),
                                onTap: () => _pickTime(
                                  initial: _feedAlertTime2,
                                  onPicked: (t) => _feedAlertTime2 = t,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _timeTile(
                                label: l10n.settingsTime3,
                                value: _formatTime(_feedAlertTime3),
                                onTap: () => _pickTime(
                                  initial: _feedAlertTime3,
                                  onPicked: (t) => _feedAlertTime3 = t,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _timeTile(
                                label: l10n.settingsTime4,
                                value: _formatTime(_feedAlertTime4),
                                onTap: () => _pickTime(
                                  initial: _feedAlertTime4,
                                  onPicked: (t) => _feedAlertTime4 = t,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _timeTile(
                          label: l10n.settingsTime5,
                          value: _formatTime(_feedAlertTime5),
                          onTap: () => _pickTime(
                            initial: _feedAlertTime5,
                            onPicked: (t) => _feedAlertTime5 = t,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.settingsLogExpenses),
                        const SizedBox(height: 4),
                        _timeTile(
                          label: l10n.settingsAlertTime,
                          value: _expenseAlertTime == null
                              ? l10n.settingsNotSet
                              : _formatTime(_expenseAlertTime!),
                          onTap: () => _pickTime(
                            initial: _expenseAlertTime ?? const TimeOfDay(hour: 20, minute: 0),
                            onPicked: (t) => _expenseAlertTime = t,
                          ),
                          trailing: _expenseAlertTime == null
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() => _expenseAlertTime = null),
                                ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _applyingAlerts ? null : _applyAlertSettings,
                            icon: const Icon(Icons.notifications_active_outlined),
                            label: Text(
                              _applyingAlerts
                                  ? l10n.settingsApplying
                                  : l10n.settingsApplyAlertSettings,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.notifications_active_outlined),
                          title: Text(l10n.settingsTestAlerts),
                          subtitle: Text(l10n.settingsSendTestNotificationNow),
                          onTap: () async {
                            await NotificationService.instance.showTestNotificationNow();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.settingsTestNotificationSent)),
                            );
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule),
                          title: Text(l10n.settingsTestAlertIn10Sec),
                          subtitle: Text(l10n.settingsScheduleNotificationIn10Seconds),
                          onTap: () async {
                            await NotificationService.instance
                                .scheduleTestNotification(seconds: 10);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.settingsNotificationIn10Seconds)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(l10n.settingsAppSection, style: sectionTitleStyle),
              ),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: Text(l10n.settingsHelpSupport),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text(l10n.settingsAbout),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.mobile_friendly_outlined),
                      title: Text(l10n.settingsAppVersion),
                      trailing: const Text('1.0.2'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red.shade700,
                ),
                onPressed: () async {
                  await NotificationService.instance.clearFarmAlerts();
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true)
                      .popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.logout),
                label: Text(l10n.settingsLogOut),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _timeTile({
    required String label,
    required String value,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            trailing ?? const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }
}

