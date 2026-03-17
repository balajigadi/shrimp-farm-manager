import 'package:flutter/material.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../pond/pond_model.dart';
import '../../services/firestore_service.dart';

class WaterLogScreen extends StatefulWidget {
  const WaterLogScreen({super.key});

  @override
  State<WaterLogScreen> createState() => _WaterLogScreenState();
}

class _WaterLogScreenState extends State<WaterLogScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPondId;
  DateTime _selectedDate = DateTime.now();

  final _phController = TextEditingController();
  final _salinityController = TextEditingController();
  final _ammoniaController = TextEditingController();
  final _doController = TextEditingController();
  final _tempController = TextEditingController();

  @override
  void dispose() {
    _phController.dispose();
    _salinityController.dispose();
    _ammoniaController.dispose();
    _doController.dispose();
    _tempController.dispose();
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
                AppLocalizations.of(context)!.noPondsYetWater,
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

        return StreamBuilder<List<PondLog>>(
          stream: FirestoreService.instance.watchWaterLogs(selectedPond.id),
          builder: (context, snapshot) {
            final pondLogs = snapshot.data ?? [];
            return DefaultTabController(
              length: 2,
              child: Scaffold(
                backgroundColor: const Color(0xFFF8F9FA),
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.titleWaterQuality),
                  centerTitle: true,
                  bottom: const TabBar(
                    tabs: [
                      Tab(text: 'Daily Entry'),
                      Tab(text: 'Historical Trends'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    _buildDailyEntryTab(ponds, selectedPond, pondLogs),
                    _buildReportTab(ponds, selectedPond, pondLogs),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDailyEntryTab(
    List<Pond> ponds,
    Pond selectedPond,
    List<PondLog> pondLogs,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopSelectors(ponds, selectedPond),
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
                      'Daily Water Quality Log',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildNumberField(
                      label: 'pH',
                      controller: _phController,
                      hint: 'e.g., 7.8',
                    ),
                    _buildNumberField(
                      label: 'Salinity (ppt)',
                      controller: _salinityController,
                      hint: 'e.g., 16.5',
                    ),
                    _buildNumberField(
                      label: 'Ammonia (ppm)',
                      controller: _ammoniaController,
                      hint: 'e.g., 0.4',
                    ),
                    _buildNumberField(
                      label: 'Dissolved Oxygen (mg/L)',
                      controller: _doController,
                      hint: 'e.g., 6.5',
                    ),
                    _buildNumberField(
                      label: 'Temperature (°C)',
                      controller: _tempController,
                      hint: 'e.g., 29',
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
                        onPressed: _saveLog,
                        child: const Text(
                          'Save Log',
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
            'Recent Logs',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (pondLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Text(
                'No water quality data for this pond yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pondLogs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = pondLogs[index];
                final dateText =
                    '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')} '
                    '${log.date.hour.toString().padLeft(2, '0')}:${log.date.minute.toString().padLeft(2, '0')}';
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    title: Text(dateText),
                    subtitle: Text(
                      'pH ${log.ph.toStringAsFixed(1)}, '
                      'Sal ${log.salinityPpt.toStringAsFixed(1)} ppt, '
                      'DO ${log.dissolvedOxygen.toStringAsFixed(1)} mg/L, '
                      'Temp ${log.waterTempC.toStringAsFixed(1)} °C',
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
    Pond selectedPond,
    List<PondLog> pondLogs,
  ) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recent = pondLogs
        .where((log) => log.date.isAfter(sevenDaysAgo))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final latest = recent.isNotEmpty ? recent.first : null;

    String _statusForPh(double ph) {
      if (ph >= 7.5 && ph <= 8.5) return 'Good';
      if (ph >= 7.0 && ph <= 9.0) return 'Warning';
      return 'Danger';
    }

    String _statusForAmmonia(double amm) {
      if (amm < 0.1) return 'Good';
      if (amm < 0.5) return 'Warning';
      return 'Danger';
    }

    Color _statusColor(String status) {
      switch (status) {
        case 'Good':
          return Colors.green;
        case 'Warning':
          return Colors.orange;
        default:
          return Colors.red;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopSelectors(ponds, selectedPond),
          const SizedBox(height: 16),
          if (latest == null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Text(
                AppLocalizations.of(context)!.noDataLast7Days,
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    title: 'pH Level',
                    value: latest.ph.toStringAsFixed(1),
                    status: _statusForPh(latest.ph),
                    unit: '',
                    color: _statusColor(_statusForPh(latest.ph)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    title: 'Ammonia',
                    value: latest.ammoniaPpm.toStringAsFixed(2),
                    status: _statusForAmmonia(latest.ammoniaPpm),
                    unit: 'ppm',
                    color: _statusColor(_statusForAmmonia(latest.ammoniaPpm)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _chartPlaceholder(),
          ],
          const SizedBox(height: 24),
          Text(
            'Historical Data (last 7 days)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const Text(
                'There is no water quality data for the selected pond and date range.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = recent[index];
                final dateText =
                    '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')} '
                    '${log.date.hour.toString().padLeft(2, '0')}:${log.date.minute.toString().padLeft(2, '0')}';
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(dateText),
                    subtitle: Text(
                      'pH ${log.ph.toStringAsFixed(1)}, '
                      'Sal ${log.salinityPpt.toStringAsFixed(1)} ppt, '
                      'NH₃ ${log.ammoniaPpm.toStringAsFixed(2)} ppm, '
                      'DO ${log.dissolvedOxygen.toStringAsFixed(1)} mg/L, '
                      'Temp ${log.waterTempC.toStringAsFixed(1)} °C',
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String status,
    required String unit,
    required Color color,
  }) {
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
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: color),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartPlaceholder() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const Text(
          '7‑day chart will be added here later',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildTopSelectors(List<Pond> ponds, Pond selectedPond) {
    final dateText =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(
          child: _selectorCard(
            label: 'Pond',
            value: selectedPond.name,
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
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _selectorCard(
            label: 'Date',
            value: dateText,
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 2),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = DateTime(
                    picked.year,
                    picked.month,
                    picked.day,
                    _selectedDate.hour,
                    _selectedDate.minute,
                  );
                });
              }
            },
          ),
        ),
      ],
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

  Widget _buildNumberField({
    required String label,
    required TextEditingController controller,
    required String hint,
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
          ),
        ],
      ),
    );
  }

  void _saveLog() {
    if (!_formKey.currentState!.validate()) {
      // currently no validators, but left here for future rules.
    }

    final ph = double.tryParse(_phController.text.trim());
    final salinity = double.tryParse(_salinityController.text.trim());
    final ammonia = double.tryParse(_ammoniaController.text.trim());
    final doVal = double.tryParse(_doController.text.trim());
    final temp = double.tryParse(_tempController.text.trim());

    if (ph == null ||
        salinity == null ||
        ammonia == null ||
        doVal == null ||
        temp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterAllValues)),
      );
      return;
    }

    final now = DateTime.now();
    final logDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
    );

    if (_selectedPondId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectPondFirst)),
      );
      return;
    }

    final log = PondLog(
      id: '',
      farmId: FirestoreService.defaultFarmId,
      pondId: _selectedPondId!,
      date: logDate,
      waterTempC: temp,
      dissolvedOxygen: doVal,
      ph: ph,
      salinityPpt: salinity,
      ammoniaPpm: ammonia,
      feedKg: 0,
      mortalityCount: 0,
    );

    FirestoreService.instance.addWaterLog(log);

    setState(() {
      _phController.clear();
      _salinityController.clear();
      _ammoniaController.clear();
      _doController.clear();
      _tempController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.waterQualityLogSaved)),
    );
  }
}

