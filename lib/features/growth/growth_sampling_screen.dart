import 'package:flutter/material.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../pond/pond_model.dart';
import '../../services/firestore_service.dart';

class GrowthSamplingScreen extends StatefulWidget {
  const GrowthSamplingScreen({super.key});

  @override
  State<GrowthSamplingScreen> createState() => _GrowthSamplingScreenState();
}

class _GrowthSamplingScreenState extends State<GrowthSamplingScreen> {
  String? _selectedPondId;
  DateTime _sampleDate = DateTime.now();

  final _formKey = GlobalKey<FormState>();
  final _avgBodyWeightController = TextEditingController();
  final _survivalController = TextEditingController();
  final _sampleSizeController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _avgBodyWeightController.dispose();
    _survivalController.dispose();
    _sampleSizeController.dispose();
    _notesController.dispose();
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
            appBar: AppBar(
              title: Text(AppLocalizations.of(context)!.titleGrowthSampling),
              centerTitle: true,
            ),
            body: Center(
              child: Text(
                AppLocalizations.of(context)!.noPondsYetGrowth,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final selectedPond = ponds.firstWhere(
          (p) => p.id == _selectedPondId,
          orElse: () {
            _selectedPondId ??= ponds.first.id;
            return ponds.first;
          },
        );

        return StreamBuilder<List<GrowthSample>>(
          stream: FirestoreService.instance.watchGrowthSamples(selectedPond.id),
          builder: (context, sampleSnapshot) {
            final samples = sampleSnapshot.data ?? [];
            return Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.titleGrowthSampling),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _selectorCard(
                            label: 'Pond',
                            value: selectedPond.name,
                            onTap: () => _selectPond(ponds),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _selectorCard(
                            label: 'Sample date',
                            value: _formatDate(_sampleDate),
                            onTap: _selectDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Recent samples',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildSampleList(samples),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormCard() {
    return Card(
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
                'Record sample',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildNumberField(
                label: 'Avg. body weight (g)',
                hint: 'e.g., 12.5',
                controller: _avgBodyWeightController,
              ),
              _buildNumberField(
                label: 'Survival (%)',
                hint: 'e.g., 85',
                controller: _survivalController,
              ),
              _buildNumberField(
                label: 'Sample size (optional)',
                hint: 'e.g., 50 prawns',
                controller: _sampleSizeController,
                required: false,
              ),
              _buildNotesField(),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005F73),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveSample,
                  child: const Text(
                    'Save sample',
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
    );
  }

  Widget _buildNumberField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool required = true,
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
                borderSide: const BorderSide(color: Color(0xFF005F73)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: required
                ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    if (double.tryParse(value.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Optional',
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
                borderSide: const BorderSide(color: Color(0xFF005F73)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleList(List<GrowthSample> samples) {
    if (samples.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Text(
          'No growth samples for this pond yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: samples.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = samples[index];
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF005F73).withOpacity(0.2),
              child: const Icon(
                Icons.show_chart,
                color: Color(0xFF005F73),
              ),
            ),
            title: Text(
              '${s.avgBodyWeightGrams.toStringAsFixed(1)}g  •  ${s.survivalPercent.toStringAsFixed(0)}% survival',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _formatDate(s.date) +
                  (s.sampleSize > 0 ? '  •  n=${s.sampleSize}' : ''),
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
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

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
      initialDate: _sampleDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _sampleDate = picked;
      });
    }
  }

  void _saveSample() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPondId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectPondFirst)),
      );
      return;
    }

    final avgG = double.parse(_avgBodyWeightController.text.trim());
    final survival = double.parse(_survivalController.text.trim());
    final sampleSize = int.tryParse(_sampleSizeController.text.trim()) ?? 0;

    final sample = GrowthSample(
      id: '',
      farmId: FirestoreService.defaultFarmId,
      pondId: _selectedPondId!,
      date: _sampleDate,
      avgBodyWeightGrams: avgG,
      survivalPercent: survival.clamp(0.0, 100.0),
      sampleSize: sampleSize,
      notes: _notesController.text.trim(),
    );

    FirestoreService.instance.addGrowthSample(sample);

    _avgBodyWeightController.clear();
    _survivalController.clear();
    _sampleSizeController.clear();
    _notesController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.growthSampleSaved)),
    );
  }
}
