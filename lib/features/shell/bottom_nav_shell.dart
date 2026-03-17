import 'package:flutter/material.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../pond/pond_overview_screen.dart';
import '../water/water_log_screen.dart';
import '../feed/feed_screen.dart';
import '../growth/growth_sampling_screen.dart';
import '../expenses/expense_screen.dart';
import '../reports/reports_screen.dart';

class BottomNavShell extends StatefulWidget {
  const BottomNavShell({super.key});

  @override
  State<BottomNavShell> createState() => _BottomNavShellState();
}

class _BottomNavShellState extends State<BottomNavShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    PondOverviewScreen(),
    WaterLogScreen(),
    FeedScreen(),
    GrowthSamplingScreen(),
    ExpenseScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
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

