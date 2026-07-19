import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'package:prawn_farm_app/services/fcm_service.dart';
import 'package:prawn_farm_app/services/notification_service.dart';
import '../profile/user_profile.dart';
import '../pond/pond_overview_screen.dart';
import '../water/water_log_screen.dart';
import '../feed/feed_screen.dart';
import '../growth/growth_sampling_screen.dart';
import '../expenses/expense_screen.dart';
import '../reports/reports_screen.dart';
import '../market/market_screen.dart';
import '../settings/language_settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  String? _highlightRequirementId;

  int get _marketTabIndex => widget.profile.showsMarketTab ? 0 : -1;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    FcmService.instance.marketHighlightRequirementId
        .addListener(_onMarketHighlightRequest);
    _loadPendingNotificationRoute();
    // Bind DO/feed/expense local alerts to this account only (or clear for traders).
    NotificationService.instance.syncAlertsForProfile(widget.profile);
  }

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.uid != widget.profile.uid ||
        oldWidget.profile.showsFarmTabs != widget.profile.showsFarmTabs) {
      NotificationService.instance.syncAlertsForProfile(widget.profile);
    }
  }

  Future<void> _loadPendingNotificationRoute() async {
    await FcmService.instance.ensureInitialized();
    if (!mounted) return;

    final pending = FcmService.instance.consumePendingRequirementId();
    if (pending != null && widget.profile.showsMarketTab) {
      setState(() {
        _highlightRequirementId = pending;
        _currentIndex = _marketTabIndex;
      });
    }
  }

  @override
  void dispose() {
    FcmService.instance.marketHighlightRequirementId
        .removeListener(_onMarketHighlightRequest);
    super.dispose();
  }

  void _onMarketHighlightRequest() {
    final id = FcmService.instance.marketHighlightRequirementId.value;
    if (id == null || !widget.profile.showsMarketTab) return;
    setState(() {
      _highlightRequirementId = id;
      _currentIndex = _marketTabIndex;
    });
  }

  void _clearHighlightRequirement() {
    if (_highlightRequirementId == null) return;
    setState(() => _highlightRequirementId = null);
    FcmService.instance.marketHighlightRequirementId.value = null;
  }

  bool get _showFarmSetupBanner =>
      widget.profile.role == UserRole.farmer &&
      widget.profile.farmerIntent == FarmerIntent.both;

  List<Widget> get _pages {
    final pages = <Widget>[];
    if (widget.profile.showsMarketTab) {
      pages.add(
        MarketScreen(
          profile: widget.profile,
          showFarmSetupBanner: _showFarmSetupBanner,
          highlightRequirementId: _highlightRequirementId,
          onHighlightConsumed: _clearHighlightRequirement,
        ),
      );
    }
    if (widget.profile.showsFarmTabs) {
      pages.addAll(const [
        PondOverviewScreen(),
        WaterLogScreen(),
        FeedScreen(),
        GrowthSamplingScreen(),
        ExpenseScreen(),
        ReportsScreen(),
      ]);
    }
    if (pages.isEmpty) {
      pages.add(MarketScreen(profile: widget.profile));
    }
    return pages;
  }

  List<BottomNavigationBarItem> _navItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <BottomNavigationBarItem>[];
    if (widget.profile.showsMarketTab) {
      items.add(
        BottomNavigationBarItem(
          icon: const Icon(Icons.storefront_outlined),
          label: l10n.tabMarket,
        ),
      );
    }
    if (widget.profile.showsFarmTabs) {
      items.addAll([
        BottomNavigationBarItem(
          icon: const Icon(Icons.water),
          label: l10n.tabPonds,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.opacity),
          label: l10n.tabWater,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.set_meal),
          label: l10n.tabFeed,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.show_chart),
          label: l10n.tabGrowth,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.account_balance_wallet),
          label: l10n.tabExpenses,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.bar_chart),
          label: l10n.tabReports,
        ),
      ]);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.toLowerCase() ?? '';
    final pages = _pages;
    final navItems = _navItems(context);
    final index = _currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      body: Column(
        children: [
          if (user != null) _accountBar(context, email),
          Expanded(child: pages[index]),
        ],
      ),
      bottomNavigationBar: navItems.length <= 1
          ? null
          : BottomNavigationBar(
              currentIndex: index,
              type: BottomNavigationBarType.fixed,
              onTap: (i) => setState(() => _currentIndex = i),
              items: navItems,
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
                onPressed: () async {
                  await NotificationService.instance.clearFarmAlerts();
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
