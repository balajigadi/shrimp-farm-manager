import 'package:flutter/material.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'pond_model.dart';
import '../../services/firestore_service.dart';

enum PondFormMode { create, edit }

class PondFormScreen extends StatefulWidget {
  final PondFormMode mode;
  final Pond? existing;
  final void Function(Pond pond) onSave;
  final void Function(Pond pond)? onDelete;

  const PondFormScreen({
    super.key,
    required this.mode,
    this.existing,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<PondFormScreen> createState() => _PondFormScreenState();
}

class _PondFormScreenState extends State<PondFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _sizeController;
  late TextEditingController _stockingCountController;
  late TextEditingController _densityController;
  late TextEditingController _avgBodyWeightController;
  late TextEditingController _survivalController;
  late TextEditingController _totalFeedController;
  late TextEditingController _fcrController;
  late TextEditingController _estimatedBiomassController;
  late TextEditingController _notesController;
  DateTime? _stockingDate;
  DateTime? _estimatedHarvestDate;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _locationController =
        TextEditingController(text: existing?.location ?? '');
    _sizeController = TextEditingController(
      text: existing != null ? existing.areaAcres.toString() : '',
    );
    _stockingCountController = TextEditingController(
      text: existing != null && existing.stockingCount > 0
          ? existing.stockingCount.toString()
          : '',
    );
    _densityController = TextEditingController(
      text: existing != null ? existing.initialStockingDensity.toString() : '',
    );
    _avgBodyWeightController = TextEditingController(
      text: existing != null && existing.avgBodyWeightGrams > 0
          ? existing.avgBodyWeightGrams.toString()
          : '',
    );
    _survivalController = TextEditingController(
      text: existing != null && existing.survivalPercent > 0
          ? existing.survivalPercent.toString()
          : '',
    );
    _totalFeedController = TextEditingController(
      text: existing != null && existing.totalFeedTons > 0
          ? existing.totalFeedTons.toString()
          : '',
    );
    _fcrController = TextEditingController(
      text: existing != null && existing.fcr > 0
          ? existing.fcr.toString()
          : '',
    );
    _estimatedBiomassController = TextEditingController(
      text: existing != null && existing.estimatedBiomassTons > 0
          ? existing.estimatedBiomassTons.toString()
          : '',
    );
    _notesController = TextEditingController();
    _stockingDate = existing?.stockingDate;
    _estimatedHarvestDate = existing?.estimatedHarvestDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _sizeController.dispose();
    _stockingCountController.dispose();
    _densityController.dispose();
    _avgBodyWeightController.dispose();
    _survivalController.dispose();
    _totalFeedController.dispose();
    _fcrController.dispose();
    _estimatedBiomassController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.mode == PondFormMode.edit;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isEdit
              ? AppLocalizations.of(context)!.editPond
              : AppLocalizations.of(context)!.addPond,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                label: AppLocalizations.of(context)!.pondName,
                hint: 'e.g., Pond A',
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter pond name';
                  }
                  return null;
                },
              ),
              _buildTextField(
                label: AppLocalizations.of(context)!.location,
                hint: 'e.g., North Field, Section 2',
                controller: _locationController,
              ),
              _buildTextField(
                label: AppLocalizations.of(context)!.area,
                hint: 'e.g., 1.5',
                controller: _sizeController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffixText: 'acres',
              ),
              _buildTextField(
                label: AppLocalizations.of(context)!.stockingCount,
                hint: 'e.g., 100000',
                controller: _stockingCountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
              ),
              _buildTextField(
                label: AppLocalizations.of(context)!.initialStockingDensity,
                hint: 'e.g., 20',
                controller: _densityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffixText: 'PLs/m²',
              ),
              _buildDateField(context),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.growthHarvestOptional,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF005F73),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                label: '${AppLocalizations.of(context)!.avgBodyWeight} (g)',
                hint: 'e.g., 12.5',
                controller: _avgBodyWeightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffixText: 'g',
              ),
              _buildTextField(
                label: AppLocalizations.of(context)!.survivalPercent,
                hint: 'e.g., 85',
                controller: _survivalController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffixText: '%',
              ),
              _buildTextField(
                label: '${AppLocalizations.of(context)!.totalFeed} (T)',
                hint: 'e.g., 2.5',
                controller: _totalFeedController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffixText: 'T',
              ),
              _buildTextField(
                label: AppLocalizations.of(context)!.fcr,
                hint: 'e.g., 1.4',
                controller: _fcrController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              _buildHarvestDateField(context),
              _buildTextField(
                label: AppLocalizations.of(context)!.estimatedBiomassTons,
                hint: 'e.g., 5.0',
                controller: _estimatedBiomassController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                suffixText: 'T',
              ),
              _buildNotesField(),
              const SizedBox(height: 24),
              _buildPrimaryButton(
                label: isEdit
                    ? AppLocalizations.of(context)!.saveChanges
                    : AppLocalizations.of(context)!.addPond,
                color: const Color(0xFF00C853),
                onPressed: _handleSave,
              ),
              if (isEdit && widget.onDelete != null) ...[
                const SizedBox(height: 12),
                _buildPrimaryButton(
                  label: AppLocalizations.of(context)!.deletePond,
                  color: Colors.red,
                  onPressed: _handleDelete,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? suffixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              suffixText: suffixText,
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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestDateField(BuildContext context) {
    final text = _estimatedHarvestDate == null
        ? 'mm/dd/yyyy'
        : '${_estimatedHarvestDate!.month.toString().padLeft(2, '0')}/${_estimatedHarvestDate!.day.toString().padLeft(2, '0')}/${_estimatedHarvestDate!.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Harvest Date',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _estimatedHarvestDate ?? now.add(const Duration(days: 90)),
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) {
                setState(() {
                  _estimatedHarvestDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color:
                      _estimatedHarvestDate == null ? Colors.grey : Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    final text = _stockingDate == null
        ? 'mm/dd/yyyy'
        : '${_stockingDate!.month.toString().padLeft(2, '0')}/${_stockingDate!.day.toString().padLeft(2, '0')}/${_stockingDate!.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Stocking Date',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: _stockingDate ?? now,
                firstDate: DateTime(now.year - 5),
                lastDate: DateTime(now.year + 5),
              );
              if (picked != null) {
                setState(() {
                  _stockingDate = picked;
                });
              }
            },
            child: InputDecorator(
              decoration: InputDecoration(
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color:
                      _stockingDate == null ? Colors.grey : Colors.grey.shade800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes / Comments',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'e.g., Soil quality, previous usage, etc.',
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
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final size = double.tryParse(_sizeController.text.trim()) ?? 0;
    final density = double.tryParse(_densityController.text.trim()) ?? 0;
    final stocking = _stockingDate ?? DateTime.now();
    final daysOfCulture = DateTime.now().difference(stocking).inDays.clamp(0, 999999);
    final avgBodyWeight = double.tryParse(_avgBodyWeightController.text.trim()) ?? 0;
    final survival = double.tryParse(_survivalController.text.trim()) ?? 0;
    final totalFeed = double.tryParse(_totalFeedController.text.trim()) ?? 0;
    final fcr = double.tryParse(_fcrController.text.trim()) ?? 0;
    final estimatedBiomass = double.tryParse(_estimatedBiomassController.text.trim()) ?? 0;
    final harvestDate = _estimatedHarvestDate ?? stocking.add(const Duration(days: 90));
    final existing = widget.existing;
    final stockingCount =
        int.tryParse(_stockingCountController.text.trim()) ?? existing?.stockingCount ?? 0;
    final pond = Pond(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      farmId: existing?.farmId ?? FirestoreService.defaultFarmId,
      name: _nameController.text.trim(),
      location: _locationController.text.trim(),
      areaAcres: size,
      species: existing?.species ?? 'L. vannamei',
      stockingDate: stocking,
      stockingCount: stockingCount,
      initialStockingDensity: density,
      daysOfCulture: daysOfCulture,
      avgBodyWeightGrams: avgBodyWeight,
      survivalPercent: survival,
      totalFeedTons: totalFeed,
      fcr: fcr,
      estimatedHarvestDate: harvestDate,
      estimatedBiomassTons: estimatedBiomass,
    );

    widget.onSave(pond);
    Navigator.of(context).pop();
  }

  void _handleDelete() {
    final existing = widget.existing;
    if (existing == null || widget.onDelete == null) return;
    widget.onDelete!(existing);
    Navigator.of(context).pop();
  }
}

