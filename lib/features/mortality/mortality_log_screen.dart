import 'package:flutter/material.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../pond/pond_model.dart';
import '../../services/firestore_service.dart';

class MortalityLogScreen extends StatefulWidget {
  final Pond initialPond;

  const MortalityLogScreen({super.key, required this.initialPond});

  @override
  State<MortalityLogScreen> createState() => _MortalityLogScreenState();
}

class _MortalityLogScreenState extends State<MortalityLogScreen> {
  String? _selectedPondId;
  DateTime _selectedDateTime = DateTime.now();

  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedPondId = widget.initialPond.id;
  }

  @override
  void dispose() {
    _countController.dispose();
    _reasonController.dispose();
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
              title: Text(AppLocalizations.of(context)!.titleMortalityLog),
              centerTitle: true,
            ),
            body: Center(
              child: Text(
                AppLocalizations.of(context)!.noPondsYetMortality,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final selectedPond = ponds.firstWhere(
          (p) => p.id == _selectedPondId,
          orElse: () {
            _selectedPondId ??= widget.initialPond.id;
            return ponds.firstWhere(
              (p) => p.id == _selectedPondId,
              orElse: () => ponds.first,
            );
          },
        );

        return StreamBuilder<List<MortalityLog>>(
          stream:
              FirestoreService.instance.watchMortalityLogs(selectedPond.id),
          builder: (context, snapshot) {
            final logs = snapshot.data ?? [];
            return Scaffold(
              backgroundColor: const Color(0xFFF8F9FA),
              appBar: AppBar(
                title: Text(AppLocalizations.of(context)!.titleMortalityLog),
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
                            label: 'Date',
                            value: _formatDate(_selectedDateTime),
                            onTap: _selectDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormCard(),
                    const SizedBox(height: 24),
                    Text(
                      'Recent mortality',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildRecentList(logs),
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
                'Record mortality',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildCountField(),
              const SizedBox(height: 8),
              _buildQuickButtonsRow(),
              const SizedBox(height: 16),
              _buildReasonChips(),
              const SizedBox(height: 12),
              _buildNotesField(),
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
                  onPressed: _saveMortality,
                  child: const Text(
                    'Save mortality',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saveNoMortalityToday,
                child: const Text('No mortality today'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dead count',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _countController,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(
            hintText: 'e.g., 0, 5, 12',
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
            final parsed = int.tryParse(value.trim());
            if (parsed == null || parsed < 0) {
              return 'Enter a non-negative number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildQuickButtonsRow() {
    final increments = [1, 5, 10, 50];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: increments.map((inc) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                final current = int.tryParse(_countController.text.trim()) ?? 0;
                final next = current + inc;
                _countController.text = next.toString();
              },
              child: Text('+$inc'),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReasonChips() {
    const reasons = [
      'Bird attack',
      'Disease',
      'Water quality',
      'Molting',
      'Other',
    ];

    final current = _reasonController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reason (optional)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: reasons.map((label) {
            final selected = current == label;
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _reasonController.text = selected ? '' : label;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (optional)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'e.g., found near inlet',
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
    );
  }

  Widget _buildRecentList(List<MortalityLog> logs) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: const Text(
          'No mortality logs for this pond yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final log = logs[index];
        final dt = log.dateTime;
        final dateText =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
        final countText = '${log.count} dead';

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.1),
              child: Icon(
                log.count == 0 ? Icons.check_circle_outline : Icons.warning,
                color: log.count == 0 ? Colors.green : Colors.red,
              ),
            ),
            title: Text(
              countText,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              log.reason.isNotEmpty ? '$dateText • ${log.reason}' : dateText,
            ),
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

  void _saveMortality() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPondId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectPondFirst)),
      );
      return;
    }

    final count = int.parse(_countController.text.trim());
    final log = MortalityLog(
      id: '',
      farmId: FirestoreService.defaultFarmId,
      pondId: _selectedPondId!,
      dateTime: _selectedDateTime,
      count: count,
      reason: _reasonController.text.trim(),
      notes: _notesController.text.trim(),
    );

    FirestoreService.instance.addMortalityLog(log);

    _countController.clear();
    _notesController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.mortalityLogSaved)),
    );
  }

  void _saveNoMortalityToday() {
    _countController.text = '0';
    _reasonController.clear();
    _notesController.text = 'No mortality reported';
    _saveMortality();
  }
}

