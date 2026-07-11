import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../pond/pond_overview_screen.dart';
import '../water/water_log_screen.dart';
import '../feed/feed_screen.dart';
import '../growth/growth_sampling_screen.dart';
import '../expenses/expense_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/language_settings_screen.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _currentIndex = 0;
  bool _demoHintDismissed = false;

  final List<Widget> _pages = const [
    PondOverviewScreen(),
    WaterLogScreen(),
    FeedScreen(),
    GrowthSamplingScreen(),
    ExpenseScreen(),
    ReportsScreen(),
  ];

  static const _demoEmails = {
    'demo1@prawnfarm.com',
    'demo2@prawnfarm.com',
  };

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.toLowerCase() ?? '';
    final showDemoHint =
        user != null && !_demoEmails.contains(email) && !_demoHintDismissed;

    return Scaffold(
      body: Column(
        children: [
          if (user != null) _accountBar(context, email),
          if (showDemoHint)
            MaterialBanner(
              content: Text(
                'Demo ponds and feed are on demo1@ or demo2@. '
                'Tap Log out above, then use Demo Farm buttons on sign-in.',
              ),
              leading: const Icon(Icons.info_outline),
              actions: [
                TextButton(
                  onPressed: () => setState(() => _demoHintDismissed = true),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.water),
            label: AppLocalizations.of(context)!.tabPonds,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.opacity),
            label: AppLocalizations.of(context)!.tabWater,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.set_meal),
            label: AppLocalizations.of(context)!.tabFeed,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.show_chart),
            label: AppLocalizations.of(context)!.tabGrowth,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: AppLocalizations.of(context)!.tabExpenses,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: AppLocalizations.of(context)!.tabReports,
          ),
        ],
      ),
    );
  }

  Widget _accountBar(BuildContext context, String email) {
    return Material(
      color: Colors.white,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  email.isEmpty ? 'Signed in' : email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined, size: 22),
                onPressed: () => LanguageSettingsScreen.open(context),
              ),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          '$title screen coming soon',
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

