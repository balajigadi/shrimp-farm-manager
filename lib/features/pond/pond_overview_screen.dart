import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'pond_model.dart';
import 'pond_detail_screen.dart';
import 'pond_form_screen.dart';
import 'pond_list_screen.dart';
import '../alerts/alerts_screen.dart';
import '../mortality/mortality_log_screen.dart';
import '../settings/language_settings_screen.dart';
import '../../services/firestore_service.dart';
import '../../services/growth_analysis_service.dart';
import '../../services/growth_reference.dart';

class PondOverviewScreen extends StatefulWidget {
  const PondOverviewScreen({super.key});

  @override
  State<PondOverviewScreen> createState() => _PondOverviewScreenState();
}

class _PondOverviewScreenState extends State<PondOverviewScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pond>>(
      stream: FirestoreService.instance.watchPonds(),
      builder: (context, snapshot) {
        final ponds = snapshot.data ?? [];

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.titlePondOverview),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => LanguageSettingsScreen.open(context),
                ),
              ],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load ponds.\n${snapshot.error}\n\n'
                  'Check internet on the emulator, Firebase project '
                  '(prawn-farm-app), and deploy Firestore indexes/rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            ponds.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (ponds.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.titlePondOverview),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.list_alt),
                onPressed: () {},
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => LanguageSettingsScreen.open(context),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: const Color(0xFF005F73),
              onPressed: () => _openAddPond(),
              child: const Icon(Icons.add),
            ),
            body: Center(
              child: Text(
                AppLocalizations.of(context)!.noPondsYetAddFirst,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final selectedIndex =
            _selectedIndex.clamp(0, ponds.length - 1);
        final selectedPond = ponds[selectedIndex];

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.titlePondOverview),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.list_alt),
              onPressed: () => _openPondList(ponds, selectedIndex),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AlertsScreen(),
                    ),
                  );
                },
              )
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF005F73),
            onPressed: () => _openAddPond(),
            child: const Icon(Icons.add),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pondSelector(ponds, selectedIndex),
                const SizedBox(height: 12),
                _selectedPondHeader(context, selectedPond),
                const SizedBox(height: 16),
                _heroStats(selectedPond),
                const SizedBox(height: 16),
                _growthCard(selectedPond),
                const SizedBox(height: 16),
                _summaryGrid(selectedPond),
                const SizedBox(height: 12),
                _recommendedFeedCard(selectedPond),
                const SizedBox(height: 12),
                _mortalityActionRow(selectedPond),
                const SizedBox(height: 16),
                _harvestEstimate(selectedPond),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pond selector (segmented control)
  Widget _pondSelector(List<Pond> ponds, int selectedIndex) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < ponds.length; i++)
            _pondTab(
              ponds[i].name,
              selected: i == selectedIndex,
              onTap: () {
                setState(() {
                  _selectedIndex = i;
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _pondTab(
    String label, {
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow:
                selected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? const Color(0xFF005F73) : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  /// Quick header for the selected pond with navigation to detail.
  Widget _selectedPondHeader(BuildContext context, Pond pond) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          pond.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${pond.species} • ${pond.areaAcres.toStringAsFixed(1)} acres',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PondDetailScreen(pond: pond),
            ),
          );
        },
      ),
    );
  }

  /// Days of culture from stocking date (always current).
  int _daysOfCulture(Pond pond) {
    final days = DateTime.now().difference(pond.stockingDate).inDays;
    return days < 0 ? 0 : days;
  }

  /// Hero stats cards
  Widget _heroStats(Pond pond) {
    return Row(
      children: [
        Expanded(
          child: _heroCard(
            title: AppLocalizations.of(context)!.daysOfCulture,
            value: _daysOfCulture(pond).toString(),
            primary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _heroCard(
            title: '${AppLocalizations.of(context)!.avgBodyWeight} (g)',
            value: pond.avgBodyWeightGrams.toStringAsFixed(1),
          ),
        ),
      ],
    );
  }

  Widget _heroCard({
    required String title,
    required String value,
    bool primary = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary ? const Color(0xFF005F73) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: primary ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primary ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Growth trend card with actual growth sample chart.
  Widget _growthCard(Pond pond) {
    final l10n = AppLocalizations.of(context)!;
    final analysis = _growthAnalysisForPond(pond);
    final statusColor = _growthStatusColor(analysis.status);
    final localizedStatus = _localizedGrowthStatus(analysis.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.growthTrend,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${pond.avgBodyWeightGrams.toStringAsFixed(1)}g ($localizedStatus)',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.growthExpectedShort(
              analysis.expectedMin.toStringAsFixed(0),
              analysis.expectedMax.toStringAsFixed(0),
            ),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (analysis.status == GrowthStatus.slow) ...[
            const SizedBox(height: 6),
            StreamBuilder<List<FeedLog>>(
              stream: FirestoreService.instance.watchFeedLogs(pond.id),
              builder: (context, feedSnapshot) {
                final feedLogs = feedSnapshot.data ?? const <FeedLog>[];
                return StreamBuilder<List<PondLog>>(
                  stream: FirestoreService.instance.watchWaterLogs(pond.id),
                  builder: (context, waterSnapshot) {
                    final waterLogs = waterSnapshot.data ?? const <PondLog>[];
                    final contributors =
                        GrowthAnalysisService.instance.evaluateSlowGrowthContributors(
                      pond: pond,
                      feedLogs: feedLogs,
                      waterLogs: waterLogs,
                    );
                    final hasLikelyCause =
                        contributors.feedLikelyLow || contributors.waterLikelyIssue;
                    final message = hasLikelyCause
                        ? l10n.growthCombinedSuggestion
                        : '${l10n.growthSuggestionCheckFeedQty}. ${l10n.growthSuggestionCheckWaterQuality}.';
                    return Text(
                      message,
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: StreamBuilder<List<GrowthSample>>(
              stream: FirestoreService.instance.watchGrowthSamples(pond.id),
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
                return _buildOverviewGrowthChart(samples);
              },
            ),
          ),
        ],
      ),
    );
  }

  GrowthAnalysisResult _growthAnalysisForPond(Pond pond) {
    if (pond.expectedAbwMin > 0 &&
        pond.expectedAbwMax > 0 &&
        pond.growthStatus.isNotEmpty) {
      final status = GrowthReference.parseStatus(pond.growthStatus);
      final doc = GrowthAnalysisService.instance.daysOfCulture(
        stockingDate: pond.stockingDate,
      );
      return GrowthAnalysisResult(
        doc: doc,
        closestDoc: GrowthReference.getClosestDoc(doc),
        expectedMin: pond.expectedAbwMin,
        expectedMax: pond.expectedAbwMax,
        actualAbw: pond.avgBodyWeightGrams,
        status: status,
        growthGap: pond.growthGap,
        quickSuggestions: const [],
      );
    }

    return GrowthAnalysisService.instance.analyze(
      stockingDate: pond.stockingDate,
      actualAbw: pond.avgBodyWeightGrams,
    );
  }

  Color _growthStatusColor(GrowthStatus status) {
    switch (status) {
      case GrowthStatus.good:
        return Colors.green;
      case GrowthStatus.slow:
        return Colors.orange;
      case GrowthStatus.excellent:
        return Colors.blue;
    }
  }

  String _localizedGrowthStatus(GrowthStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case GrowthStatus.good:
        return l10n.growthStatusGood;
      case GrowthStatus.slow:
        return l10n.growthStatusSlow;
      case GrowthStatus.excellent:
        return l10n.growthStatusExcellent;
    }
  }

  Widget _buildOverviewGrowthChart(List<GrowthSample> samples) {
    final sorted = [...samples]..sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];
    final docLabels = <int>[];
    for (var i = 0; i < sorted.length; i++) {
      spots.add(FlSpot(i.toDouble(), sorted[i].avgBodyWeightGrams));
      final doc = DateTime.now().difference(sorted[i].date).inDays;
      docLabels.add(doc < 0 ? 0 : doc);
    }

    if (spots.length == 1) {
      final only = spots.first;
      spots.add(FlSpot(1, only.y));
      docLabels.add(docLabels.first);
    }

    var minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 1;
    var maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1;
    if (minY < 0) minY = 0;
    if (maxY <= minY) maxY = minY + 2;

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
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= docLabels.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  'D${docLabels[index]}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
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
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: spots.last.x,
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
  }

  /// Summary grid
  Widget _summaryGrid(Pond pond) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _SummaryTile(
          icon: Icons.health_and_safety,
          value: '${pond.survivalPercent.toStringAsFixed(0)}%',
          label: AppLocalizations.of(context)!.survival,
        ),
        _SummaryTile(
          icon: Icons.set_meal,
          value: '${pond.totalFeedTons.toStringAsFixed(1)} T',
          label: AppLocalizations.of(context)!.feed,
        ),
        _SummaryTile(
          icon: Icons.sync_alt,
          value: pond.fcr.toStringAsFixed(2),
          label: '${AppLocalizations.of(context)!.fcr} ${_fcrStatusLabel(pond.fcr)}',
        ),
      ],
    );
  }

  /// Harvest estimate card
  Widget _harvestEstimate(Pond pond) {
    final harvestDateStr =
        '${pond.estimatedHarvestDate.day}/${pond.estimatedHarvestDate.month}/${pond.estimatedHarvestDate.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF94D2BD).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.harvestEstimate,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HarvestItem(label: AppLocalizations.of(context)!.date, value: harvestDateStr),
              _HarvestItem(
                label: AppLocalizations.of(context)!.biomass,
                value: '${pond.estimatedBiomassTons.toStringAsFixed(1)} Tons',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Recommended daily feed based on biomass and feeding table.
  Widget _recommendedFeedCard(Pond pond) {
    final biomassKg = _biomassKgForPond(pond);
    final biomassTons = biomassKg / 1000.0;
    final feedRatePercent = _feedRateForWeight(pond.avgBodyWeightGrams);
    final recommendedKg = biomassKg * feedRatePercent / 100.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.recommendedFeedToday,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feedRatePercent > 0
                      ? 'Rate: ${feedRatePercent.toStringAsFixed(1)}% of biomass'
                      : 'Enter weight & survival to see recommendation',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  biomassKg > 0
                      ? 'Biomass: ${biomassTons.toStringAsFixed(2)} T'
                      : 'Biomass not available',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            Text(
              recommendedKg > 0
                  ? '${recommendedKg.toStringAsFixed(1)} kg'
                  : '--',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005F73),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _biomassKgForPond(Pond pond) {
    final seed = pond.stockingCount.toDouble();
    if (seed <= 0) return 0;
    final survival = pond.survivalPercent.clamp(0, 100) / 100.0;
    final w = pond.avgBodyWeightGrams;
    if (w <= 0) return 0;
    return seed * survival * w / 1000.0;
  }

  /// Feeding rate table (vannamei) as % of biomass / day.
  double _feedRateForWeight(double weightGrams) {
    if (weightGrams <= 0) return 0;
    if (weightGrams <= 3) return 13.5; // 12–15%
    if (weightGrams <= 5) return 9.0; // 8–10%
    if (weightGrams <= 10) return 5.5; // 5–6%
    if (weightGrams <= 15) return 4.5; // 4–5%
    if (weightGrams <= 20) return 3.5; // 3–4%
    if (weightGrams <= 25) return 2.75; // 2.5–3%
    if (weightGrams <= 35) return 2.25; // 2–2.5%
    if (weightGrams <= 50) return 1.75; // 1.5–2%
    return 1.5;
  }

  String _fcrStatusLabel(double fcr) {
    if (fcr <= 0) return '';
    if (fcr < 1.4) return '(Excellent)';
    if (fcr < 1.6) return '(Good)';
    if (fcr < 1.8) return '(Average)';
    return '(Poor)';
  }

  /// Quick access to log mortality from overview.
  Widget _mortalityActionRow(Pond pond) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Colors.red.shade700,
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MortalityLogScreen(initialPond: pond),
            ),
          );
        },
        icon: const Icon(Icons.warning_amber_rounded),
        label: Text(AppLocalizations.of(context)!.logMortality),
      ),
    );
  }

  Future<void> _savePond(Pond pond) async {
    try {
      await FirestoreService.instance.upsertPond(pond);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save pond: $e')),
      );
    }
  }

  void _openAddPond() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PondFormScreen(
          mode: PondFormMode.create,
          onSave: _savePond,
        ),
      ),
    );
  }

  void _openPondList(List<Pond> ponds, int selectedIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PondListScreen(
          ponds: ponds,
          onCreate: _savePond,
          onUpdate: _savePond,
          onDelete: (pond) async {
            try {
              await FirestoreService.instance.deletePond(pond.id);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not delete pond: $e')),
              );
            }
          },
        ),
      ),
    );
  }
}

/// Reusable widgets
class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF94D2BD), size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HarvestItem extends StatelessWidget {
  final String label;
  final String value;

  const _HarvestItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
