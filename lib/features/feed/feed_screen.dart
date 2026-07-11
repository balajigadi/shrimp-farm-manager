import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'package:prawn_farm_app/utils/calendar_ranges.dart';
import '../pond/pond_model.dart';
import '../../services/firestore_service.dart';
import 'feed_tray_suggestion.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  String? _selectedPondId;
  DateTime _selectedDateTime = DateTime.now();

  /// Scope for the feed report tab: selected pond or all ponds in the farm.
  bool _reportAllPonds = false;

  final _formKey = GlobalKey<FormState>();
  final _feedTypeController = TextEditingController();
  final _quantityController = TextEditingController();

  FeedTrayStatus? _selectedTrayStatus;

  void _onQuantityChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_onQuantityChanged);
    _feedTypeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pond>>(
      stream: FirestoreService.instance.watchPonds(),
      builder: (context, pondSnapshot) {
        if (pondSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.titleFeedManagement),
              centerTitle: true,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load ponds.\n${pondSnapshot.error}\n\n'
                  'Sign in as demo1@ or demo2@ for seeded data. '
                  'Check emulator internet if Firestore is UNAVAILABLE.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final ponds = pondSnapshot.data ?? [];
        if (ponds.isEmpty) {
          return Scaffold(
            body: Center(
              child: Text(
                AppLocalizations.of(context)!.noPondsYetFeed,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final selectedPond =
            ponds.firstWhere((p) => p.id == _selectedPondId, orElse: () {
          _selectedPondId ??= ponds.first.id;
          return ponds.first;
        });

        return StreamBuilder<List<FeedLog>>(
          stream: FirestoreService.instance.watchFeedLogs(selectedPond.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.titleFeedManagement),
                  centerTitle: true,
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load feed logs.\n${snapshot.error}\n\n'
                      'Deploy Firestore indexes if the error mentions an index. '
                      'Otherwise check network on the emulator.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final pondFeedLogs = snapshot.data ?? [];
            return DefaultTabController(
              length: 2,
              child: Scaffold(
                backgroundColor: const Color(0xFFF8F9FA),
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.titleFeedManagement),
                  centerTitle: true,
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Daily Entry'),
                      Tab(text: 'Feed Report'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    _buildEntryTab(ponds, selectedPond, pondFeedLogs),
                    _buildReportTab(ponds, selectedPond, pondFeedLogs),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEntryTab(
    List<Pond> ponds,
    Pond pond,
    List<FeedLog> pondFeedLogs,
  ) {
    final dateText =
        '${_selectedDateTime.year}-${_selectedDateTime.month.toString().padLeft(2, '0')}-${_selectedDateTime.day.toString().padLeft(2, '0')}';
    final timeText =
        '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _selectorCard(
                  label: 'Pond',
                  value: pond.name,
                  onTap: () => _selectPond(ponds),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _selectorCard(
                  label: 'Date',
                  value: dateText,
                  onTap: _selectDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _selectorCard(
            label: 'Time',
            value: timeText,
            onTap: _selectTime,
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.logNewFeed,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: AppLocalizations.of(context)!.feedType,
                      hint: 'e.g., Probiotic Feed',
                      controller: _feedTypeController,
                    ),
                    _buildNumberField(
                      label: AppLocalizations.of(context)!.quantityKg,
                      hint: 'e.g., 12.5',
                      controller: _quantityController,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.checkTrayStatus,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildTraySelector(context),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveFeedLog,
                        child: Text(
                          AppLocalizations.of(context)!.addFeedEntry,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    _buildNextFeedSuggestionCard(context),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.recentFeedInputs,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (pondFeedLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Text(
                'No feed entries for this pond yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pondFeedLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = pondFeedLogs[index];
                final dt = log.dateTime;
                final dtText =
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.set_meal),
                    title: Text(log.feedType),
                    subtitle: Text(
                      log.trayStatus == null
                          ? dtText
                          : '$dtText · ${_trayLabel(log.trayStatus!, context)}',
                    ),
                    trailing: Text(
                      '${log.quantityKg.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildReportTab(
    List<Pond> ponds,
    Pond pond,
    List<FeedLog> pondFeedLogs,
  ) {
    return StreamBuilder<List<FeedLog>>(
      stream: FirestoreService.instance.watchFeedLogsForFarm(),
      builder: (context, farmSnapshot) {
        final farmFeedLogs = farmSnapshot.data ?? [];

        final now = DateTime.now();
        final endDay = CalendarRanges.startOfDay(now);
        final startDay =
            CalendarRanges.windowStartInclusive(end: now, dayCount: 7);

        // Logs for the selected pond in the last 7 days.
        final pondLast7Days = pondFeedLogs
            .where(
              (log) => CalendarRanges.isDateInInclusiveRange(
                log.dateTime,
                startDay,
                endDay,
              ),
            )
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        // Logs for all ponds in the farm in the last 7 days.
        final farmLast7Days = farmFeedLogs
            .where(
              (log) => CalendarRanges.isDateInInclusiveRange(
                log.dateTime,
                startDay,
                endDay,
              ),
            )
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        final scopedLogs = _reportAllPonds ? farmLast7Days : pondLast7Days;

        final totalThisPeriod = scopedLogs.fold<double>(
          0,
          (sum, l) => sum + l.quantityKg,
        );
        // Match the chart: bars are cumulative kg per calendar day; average
        // should be mean of those daily totals (not total ÷ 7).
        final daysWithFeed =
            CalendarRanges.distinctLocalDayCount(
          scopedLogs.map((l) => l.dateTime),
        );
        final dailyAverage = daysWithFeed == 0
            ? 0.0
            : totalThisPeriod / daysWithFeed;

        // Label for current scope in dropdown.
        String pondLabel;
        if (_reportAllPonds) {
          pondLabel = AppLocalizations.of(context)!.allPonds;
        } else {
          pondLabel = pond.name;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pond / scope selector dropdown.
              GestureDetector(
                onTap: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (_) {
                      return ListView(
                        children: [
                          ListTile(
                            title: Text(AppLocalizations.of(context)!.allPonds),
                            onTap: () {
                              setState(() {
                                _reportAllPonds = true;
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                          ...ponds.map((p) {
                            return ListTile(
                              title: Text(p.name),
                              onTap: () {
                                setState(() {
                                  _reportAllPonds = false;
                                  _selectedPondId = p.id;
                                });
                                Navigator.of(context).pop();
                              },
                            );
                          }),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scope',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pondLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _reportAllPonds
                    ? 'Feed Report (last 7 days – all ponds)'
                    : 'Feed Report (last 7 days – this pond)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      title: AppLocalizations.of(context)!.totalThisPeriod,
                      value: '${totalThisPeriod.toStringAsFixed(1)} kg',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      title: AppLocalizations.of(context)!.dailyAverage,
                      value: '${dailyAverage.toStringAsFixed(1)} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _feedChart(scopedLogs),
              const SizedBox(height: 16),
              _buildSevenDayInsightCard(context, scopedLogs),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.detailedLog,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (scopedLogs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Text(
                    'No feed data in the last 7 days.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: scopedLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final log = scopedLogs[index];
                    final dt = log.dateTime;
                    final dateText =
                        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                    final timeText =
                        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: Text('$dateText  •  ${log.feedType}'),
                        subtitle: Text(
                          log.trayStatus == null
                              ? timeText
                              : '$timeText · ${_trayLabel(log.trayStatus!, context)}',
                        ),
                        trailing: Text(
                          '${log.quantityKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard({required String title, required String value}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feedChart(List<FeedLog> logs) {
    if (logs.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        child: Container(
          height: 180,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: const Text(
            'No feed data for this pond in the last 7 days.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Aggregate per day.
    final byDate = <DateTime, double>{};
    for (final log in logs) {
      final d = DateTime(log.dateTime.year, log.dateTime.month, log.dateTime.day);
      byDate[d] = (byDate[d] ?? 0) + log.quantityKg;
    }

    final dates = byDate.keys.toList()..sort();
    final bars = <BarChartGroupData>[];
    for (var i = 0; i < dates.length; i++) {
      final date = dates[i];
      final qty = byDate[date] ?? 0;
      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: qty,
              color: const Color(0xFF00C853),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade300),
              ),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= dates.length) {
                        return const SizedBox.shrink();
                      }
                      final d = dates[index];
                      return Text(
                        '${d.day}/${d.month}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              barGroups: bars,
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectorCard({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00C853)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00C853)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              if (double.tryParse(value.trim()) == null) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectPond(List<Pond> ponds) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView(
          children: ponds.map((pond) {
            return ListTile(
              title: Text(pond.name),
              subtitle: Text(
                '${pond.species} • ${pond.areaAcres.toStringAsFixed(1)} acres',
              ),
              onTap: () {
                setState(() {
                  _selectedPondId = pond.id;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  String _trayLabel(FeedTrayStatus status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      FeedTrayStatus.empty => l10n.trayEmpty,
      FeedTrayStatus.partial => l10n.trayPartial,
      FeedTrayStatus.full => l10n.trayFull,
    };
  }

  String _nextFeedReasonText(FeedTrayStatus status, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      FeedTrayStatus.empty => l10n.nextFeedReasonEmpty,
      FeedTrayStatus.partial => l10n.nextFeedReasonPartial,
      FeedTrayStatus.full => l10n.nextFeedReasonFull,
    };
  }

  Widget _buildTraySelector(BuildContext context) {
    Widget tile(FeedTrayStatus status, Color color, IconData icon) {
      final selected = _selectedTrayStatus == status;
      return Expanded(
        child: Material(
          color: selected ? color.withValues(alpha: 0.15) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _selectedTrayStatus = status),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    _trayLabel(status, context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? color : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(FeedTrayStatus.empty, const Color(0xFF00C853), Icons.check_circle_outline),
        const SizedBox(width: 8),
        tile(FeedTrayStatus.partial, const Color(0xFFFF9800), Icons.remove_circle_outline),
        const SizedBox(width: 8),
        tile(FeedTrayStatus.full, const Color(0xFFE53935), Icons.cancel_outlined),
      ],
    );
  }

  Widget _buildNextFeedSuggestionCard(BuildContext context) {
    final qty = double.tryParse(_quantityController.text.trim());
    final tray = _selectedTrayStatus;
    if (tray == null || qty == null || qty <= 0) {
      return const SizedBox.shrink();
    }
    final suggested = suggestedNextFeedKg(qty, tray);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.blue.shade100, width: 1),
        ),
        elevation: 2,
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.suggestedNextFeed,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${suggested.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.nextFeedReason,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _nextFeedReasonText(tray, context),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSevenDayInsightCard(BuildContext context, List<FeedLog> logs) {
    final l10n = AppLocalizations.of(context)!;
    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }

    final daily = dailyTotalsChronological(logs);
    final avgFeed = daily.isEmpty
        ? 0.0
        : daily.reduce((a, b) => a + b) / daily.length;

    final trend = trendFromDailyTotals(daily);
    var trendLabel = l10n.trendStable;
    var trendEmoji = '➡️';
    if (trend == FeedTrendHint.increasing) {
      trendLabel = l10n.trendIncreasing;
      trendEmoji = '📈';
    } else if (trend == FeedTrendHint.decreasing) {
      trendLabel = l10n.trendDecreasing;
      trendEmoji = '📉';
    }

    var emptyC = 0;
    var partialC = 0;
    var fullC = 0;
    for (final log in logs) {
      switch (log.trayStatus) {
        case FeedTrayStatus.empty:
          emptyC++;
        case FeedTrayStatus.partial:
          partialC++;
        case FeedTrayStatus.full:
          fullC++;
        case null:
          break;
      }
    }
    final trayLogged = emptyC + partialC + fullC;

    final String insightBody;
    if (trayLogged == 0) {
      insightBody = l10n.feedInsightSuggestOk;
    } else if (fullC >= emptyC && fullC >= partialC && fullC >= 2) {
      insightBody = l10n.feedInsightSuggestDecrease;
    } else if (emptyC > fullC && emptyC >= 2) {
      insightBody = l10n.feedInsightSuggestIncrease;
    } else {
      insightBody = l10n.feedInsightSuggestOk;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📊 ', style: TextStyle(fontSize: 18)),
                Text(
                  l10n.feedInsightTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${l10n.feedInsightAvg}: ${avgFeed.toStringAsFixed(1)} kg',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              '${l10n.feedInsightTrend}: $trendLabel $trendEmoji',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.feedInsightTrayPattern,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            if (trayLogged == 0)
              Text(
                l10n.feedInsightNoTrayData,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              )
            else
              Text(
                l10n.feedInsightTrayLine(emptyC, partialC, fullC),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
            const SizedBox(height: 12),
            Text(
              l10n.feedInsightSuggestion,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              insightBody,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  void _saveFeedLog() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final qty = double.parse(_quantityController.text.trim());
    if (_selectedPondId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectPondFirst)),
      );
      return;
    }
    if (_selectedTrayStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectTrayBeforeSave),
        ),
      );
      return;
    }

    final log = FeedLog(
      id: '',
      farmId: FirestoreService.instance.currentFarmId,
      pondId: _selectedPondId!,
      dateTime: _selectedDateTime,
      feedType: _feedTypeController.text.trim(),
      quantityKg: qty,
      trayStatus: _selectedTrayStatus,
    );

    FirestoreService.instance.addFeedLog(log);

    setState(() {
      _feedTypeController.clear();
      _quantityController.clear();
      _selectedTrayStatus = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.feedEntrySaved)),
    );
  }
}

