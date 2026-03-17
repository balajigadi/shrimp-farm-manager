import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../pond/pond_model.dart';
import '../../services/firestore_service.dart';

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

  @override
  void dispose() {
    _feedTypeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pond>>(
      stream: FirestoreService.instance.watchPonds(),
      builder: (context, pondSnapshot) {
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
                    const Text(
                      'Log New Feed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Feed Type',
                      hint: 'e.g., Probiotic Feed',
                      controller: _feedTypeController,
                    ),
                    _buildNumberField(
                      label: 'Quantity (kg)',
                      hint: 'e.g., 12.5',
                      controller: _quantityController,
                    ),
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
                        child: const Text(
                          'Add Feed Entry',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Recent Feed Inputs",
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
                    subtitle: Text(dtText),
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
        final sevenDaysAgo = now.subtract(const Duration(days: 7));

        // Logs for the selected pond in the last 7 days.
        final pondLast7Days = pondFeedLogs
            .where((log) => log.dateTime.isAfter(sevenDaysAgo))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        // Logs for all ponds in the farm in the last 7 days.
        final farmLast7Days = farmFeedLogs
            .where((log) => log.dateTime.isAfter(sevenDaysAgo))
            .toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

        final scopedLogs = _reportAllPonds ? farmLast7Days : pondLast7Days;

        final totalThisPeriod = scopedLogs.fold<double>(
          0,
          (sum, l) => sum + l.quantityKg,
        );
        final dailyAverage =
            scopedLogs.isEmpty ? 0 : totalThisPeriod / 7.0;

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
                      title: 'Total This Period',
                      value: '${totalThisPeriod.toStringAsFixed(1)} kg',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      title: 'Daily Average',
                      value: '${dailyAverage.toStringAsFixed(1)} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _feedChart(scopedLogs),
              const SizedBox(height: 24),
              Text(
                'Detailed Log',
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
                        subtitle: Text(timeText),
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

    final log = FeedLog(
      id: '',
      farmId: FirestoreService.defaultFarmId,
      pondId: _selectedPondId!,
      dateTime: _selectedDateTime,
      feedType: _feedTypeController.text.trim(),
      quantityKg: qty,
    );

    FirestoreService.instance.addFeedLog(log);

    setState(() {
      _feedTypeController.clear();
      _quantityController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.feedEntrySaved)),
    );
  }
}

