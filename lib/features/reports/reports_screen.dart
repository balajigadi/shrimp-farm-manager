import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'package:prawn_farm_app/utils/calendar_ranges.dart';
import '../pond/pond_model.dart';
import '../../services/firestore_service.dart';
import '../settings/language_settings_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String? _selectedPondId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pond>>(
      stream: FirestoreService.instance.watchPonds(),
      builder: (context, snapshot) {
        final ponds = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting &&
            ponds.isEmpty) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (ponds.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.titleReports),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => LanguageSettingsScreen.open(context),
                ),
              ],
            ),
            body: Center(
              child: Text(
                AppLocalizations.of(context)!.noPondsYetReports,
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

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.titleReports),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  LanguageSettingsScreen.open(context);
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pondSelector(ponds, selectedPond),
                const SizedBox(height: 16),
                _cycleSummaryCard(selectedPond),
                const SizedBox(height: 16),
                _growthChartSection(selectedPond),
                const SizedBox(height: 16),
                _feedSummarySection(selectedPond),
                const SizedBox(height: 16),
                _waterSummarySection(selectedPond),
                const SizedBox(height: 16),
                _expenseSummarySection(selectedPond),
                const SizedBox(height: 16),
                _profitEstimateSection(selectedPond),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pondSelector(List<Pond> ponds, Pond selected) {
    return GestureDetector(
      onTap: () async {
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
      },
      child: Container(
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
                  const Text(
                    'Pond',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected.name,
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

  // Section 1 – Cycle Summary
  Widget _cycleSummaryCard(Pond pond) {
    final biomassTons = pond.estimatedBiomassTons > 0
        ? pond.estimatedBiomassTons
        : _biomassKg(pond) / 1000.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.cycleSummary,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem(AppLocalizations.of(context)!.doc, _docForPond(pond).toString()),
                _summaryItem(
                    AppLocalizations.of(context)!.avgWeight, '${pond.avgBodyWeightGrams.toStringAsFixed(1)} g'),
                _summaryItem(
                    AppLocalizations.of(context)!.survival, '${pond.survivalPercent.toStringAsFixed(0)} %'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem(
                  AppLocalizations.of(context)!.biomass,
                  biomassTons > 0 ? '${biomassTons.toStringAsFixed(2)} T' : '--',
                ),
                _summaryItem(
                  AppLocalizations.of(context)!.totalFeed,
                  '${pond.totalFeedTons.toStringAsFixed(2)} T',
                ),
                _summaryItem(
                  AppLocalizations.of(context)!.fcr,
                  pond.fcr > 0 ? pond.fcr.toStringAsFixed(2) : '--',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  int _docForPond(Pond pond) {
    final days = DateTime.now().difference(pond.stockingDate).inDays;
    return days < 0 ? 0 : days;
  }

  double _biomassKg(Pond pond) {
    final seed = pond.stockingCount.toDouble();
    if (seed <= 0) return 0;
    final survival = pond.survivalPercent.clamp(0, 100) / 100.0;
    final w = pond.avgBodyWeightGrams;
    if (w <= 0) return 0;
    return seed * survival * w / 1000.0;
  }

  // Section 2 – Growth Chart
  Widget _growthChartSection(Pond pond) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.growthTrend,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: StreamBuilder<List<GrowthSample>>(
                stream:
                    FirestoreService.instance.watchGrowthSamples(pond.id),
                builder: (context, snapshot) {
                  final samples = snapshot.data ?? [];
                  if (samples.isEmpty) {
                    return Center(
                      child: Text(
                        AppLocalizations.of(context)!.noGrowthSamplesYet,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final sorted = [...samples]
                    ..sort((a, b) => a.date.compareTo(b.date));

                  final spots = <FlSpot>[];
                  final docLabels = <int>[];
                  for (var i = 0; i < sorted.length; i++) {
                    final s = sorted[i];
                    final doc =
                        s.date.difference(pond.stockingDate).inDays;
                    spots.add(FlSpot(i.toDouble(), s.avgBodyWeightGrams));
                    docLabels.add(doc);
                  }

                  double minY = spots
                      .map((e) => e.y)
                      .reduce((a, b) => a < b ? a : b);
                  double maxY = spots
                      .map((e) => e.y)
                      .reduce((a, b) => a > b ? a : b);
                  if (minY == maxY) {
                    minY = (minY - 1).clamp(0, double.infinity);
                    maxY += 1;
                  }

                  final maxX = spots.last.x;

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true, drawVerticalLine: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= docLabels.length) {
                                return const SizedBox.shrink();
                              }
                              final doc = docLabels[index];
                              return Text(
                                'D$doc',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) => Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      minX: 0,
                      maxX: maxX,
                      minY: minY,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: const Color(0xFF005F73),
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section 3 – Feed Summary (last 7 days)
  Widget _feedSummarySection(Pond pond) {
    final now = DateTime.now();
    final endDay = CalendarRanges.startOfDay(now);
    final startDay =
        CalendarRanges.windowStartInclusive(end: now, dayCount: 7);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<FeedLog>>(
          stream: FirestoreService.instance.watchFeedLogs(pond.id),
          builder: (context, snapshot) {
            final logs = (snapshot.data ?? [])
                .where(
                  (l) => CalendarRanges.isDateInInclusiveRange(
                    l.dateTime,
                    startDay,
                    endDay,
                  ),
                )
                .toList()
              ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

            final total = logs.fold<double>(
                0, (sum, l) => sum + l.quantityKg);
            final daysWithFeed = CalendarRanges.distinctLocalDayCount(
              logs.map((l) => l.dateTime),
            );
            final dailyAverage = daysWithFeed == 0
                ? 0.0
                : total / daysWithFeed;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.feedLast7Days,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _summaryItem(
                        AppLocalizations.of(context)!.total,
                        '${total.toStringAsFixed(1)} kg',
                      ),
                    ),
                    Expanded(
                      child: _summaryItem(
                        AppLocalizations.of(context)!.dailyAvg,
                        '${dailyAverage.toStringAsFixed(1)} kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: _feedBarChart(context, logs),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _feedBarChart(BuildContext context, List<FeedLog> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.noFeedData,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

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

    return BarChart(
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
    );
  }

  // Section 4 – Water Quality Summary (last 7 days averages)
  Widget _waterSummarySection(Pond pond) {
    final now = DateTime.now();
    final endDay = CalendarRanges.startOfDay(now);
    final startDay =
        CalendarRanges.windowStartInclusive(end: now, dayCount: 7);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<PondLog>>(
          stream: FirestoreService.instance.watchWaterLogs(pond.id),
          builder: (context, snapshot) {
            final logs = (snapshot.data ?? [])
                .where(
                  (l) => CalendarRanges.isDateInInclusiveRange(
                    l.date,
                    startDay,
                    endDay,
                  ),
                )
                .toList();

            if (logs.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.waterQualityLast7Days,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.noWaterData,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              );
            }

            double avg(List<double> vals) =>
                vals.isEmpty ? 0 : vals.reduce((a, b) => a + b) / vals.length;

            final phAvg =
                avg(logs.map((e) => e.ph).toList());
            final doAvg =
                avg(logs.map((e) => e.dissolvedOxygen).toList());
            final ammAvg =
                avg(logs.map((e) => e.ammoniaPpm).toList());
            final tempAvg =
                avg(logs.map((e) => e.waterTempC).toList());
            final hardAvg =
                avg(logs.map((e) => e.hardnessMgL).toList());

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.waterQualityLast7Days,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem(AppLocalizations.of(context)!.phAvg, phAvg.toStringAsFixed(1)),
                    _summaryItem(AppLocalizations.of(context)!.doAvg, '${doAvg.toStringAsFixed(1)} mg/L'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem(
                      AppLocalizations.of(context)!.ammoniaAvg,
                      '${ammAvg.toStringAsFixed(2)} ppm',
                    ),
                    _summaryItem(
                      AppLocalizations.of(context)!.tempAvg,
                      '${tempAvg.toStringAsFixed(1)} °C',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem(
                      AppLocalizations.of(context)!.hardnessAvg,
                      '${hardAvg.toStringAsFixed(0)} mg/L',
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Section 5 – Expense Summary (per pond)
  Widget _expenseSummarySection(Pond pond) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Expense>>(
          stream: FirestoreService.instance.watchExpenses(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final expenses =
                all.where((e) => e.pondIds.contains(pond.id)).toList();

            final total = expenses.fold<double>(
              0,
              (sum, e) => sum + e.amount,
            );

            final byCategory = <String, double>{};
            for (final e in expenses) {
              byCategory[e.category] =
                  (byCategory[e.category] ?? 0) + e.amount;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.expenseSummary,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _summaryItem(AppLocalizations.of(context)!.total, '₹${total.toStringAsFixed(0)}'),
                const SizedBox(height: 12),
                if (expenses.isEmpty)
                  Text(
                    AppLocalizations.of(context)!.noExpenses,
                    style: const TextStyle(color: Colors.grey),
                  )
                else
                  Column(
                    children: byCategory.entries.map((entry) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key),
                        trailing: Text(
                          '₹${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Section 6 – Profit Estimate
  Widget _profitEstimateSection(Pond pond) {
    const double pricePerKg = 380; // INR/kg, simple constant for MVP

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<Expense>>(
          stream: FirestoreService.instance.watchExpenses(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final expenses =
                all.where((e) => e.pondIds.contains(pond.id)).toList();

            final totalExpenses = expenses.fold<double>(
              0,
              (sum, e) => sum + e.amount,
            );

            final biomassTons = pond.estimatedBiomassTons > 0
                ? pond.estimatedBiomassTons
                : _biomassKg(pond) / 1000.0;
            final harvestKg = biomassTons * 1000.0;
            final revenue = harvestKg * pricePerKg;
            final profit = revenue - totalExpenses;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.profitEstimate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem(
                      AppLocalizations.of(context)!.harvestBiomass,
                      biomassTons > 0
                          ? '${biomassTons.toStringAsFixed(2)} T'
                          : '--',
                    ),
                    _summaryItem(
                      AppLocalizations.of(context)!.price,
                      '₹${pricePerKg.toStringAsFixed(0)}/kg',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryItem(
                      AppLocalizations.of(context)!.revenue,
                      biomassTons > 0
                          ? '₹${revenue.toStringAsFixed(0)}'
                          : '--',
                    ),
                    _summaryItem(
                      AppLocalizations.of(context)!.titleExpenses,
                      '₹${totalExpenses.toStringAsFixed(0)}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _summaryItem(
                  AppLocalizations.of(context)!.estimatedProfit,
                  profit.isNaN ? '--' : '₹${profit.toStringAsFixed(0)}',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

