import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:prawn_farm_app/data/regions.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../profile/user_profile.dart';
import '../../services/market_service.dart';
import 'requirement_model.dart';

class PostRequirementScreen extends StatefulWidget {
  const PostRequirementScreen({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<PostRequirementScreen> createState() => _PostRequirementScreenState();
}

class _PostRequirementScreenState extends State<PostRequirementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _countMinController = TextEditingController();
  final _countMaxController = TextEditingController();
  final _priceController = TextEditingController();
  String _unit = 'kg';
  String? _region;
  DateTime? _expiresAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _region = widget.profile.region;
    final now = DateTime.now();
    _expiresAt = DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _countMinController.dispose();
    _countMaxController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final l10n = AppLocalizations.of(context)!;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final initial = _expiresAt ?? tomorrow;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(tomorrow) ? initial : tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      helpText: l10n.selectExpiryDate,
    );
    if (picked == null) return;
    setState(() => _expiresAt = DateTime(picked.year, picked.month, picked.day, 23, 59));
  }

  String? _validateCountRange() {
    final l10n = AppLocalizations.of(context)!;
    final min = int.tryParse(_countMinController.text.trim());
    final max = int.tryParse(_countMaxController.text.trim());
    if (min == null || max == null) return null;
    if (min >= max) return l10n.countMinLessThanMax;
    return null;
  }

  String? _validateExpiry() {
    final l10n = AppLocalizations.of(context)!;
    if (_expiresAt == null) return l10n.selectExpiryDate;
    if (!_expiresAt!.isAfter(DateTime.now())) return l10n.expiryMustBeFuture;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!widget.profile.phoneVerified) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.postRequirement)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.traderPhoneRequired, textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final expiryLabel = _expiresAt == null
        ? l10n.selectExpiryDate
        : DateFormat.yMMMd().format(_expiresAt!);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.postRequirement),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.quantityNeeded,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  (double.tryParse(v ?? '') ?? 0) > 0 ? null : l10n.invalidValue,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countMinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.countMin,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (int.tryParse(v ?? '') == null) return l10n.invalidValue;
                      return _validateCountRange();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _countMaxController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.countMax,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (int.tryParse(v ?? '') == null) return l10n.invalidValue;
                      return _validateCountRange();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _unit,
              decoration: InputDecoration(
                labelText: l10n.unit,
                border: const OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'kg', child: Text('kg')),
                DropdownMenuItem(value: 'tons', child: Text('tons')),
              ],
              onChanged: (v) => setState(() => _unit = v ?? 'kg'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.pricePerKgOptional,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _region,
              decoration: InputDecoration(
                labelText: l10n.onboardingRegionLabel,
                border: const OutlineInputBorder(),
              ),
              items: FarmRegions.mandals
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _region = v),
              validator: (v) => v == null ? l10n.selectRegion : null,
            ),
            const SizedBox(height: 12),
            FormField<DateTime>(
              validator: (_) => _validateExpiry(),
              builder: (field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.expiryDateLabel),
                      subtitle: Text(expiryLabel),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: () async {
                        await _pickExpiryDate();
                        field.didChange(_expiresAt);
                      },
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.postRequirement),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_region == null || _expiresAt == null) return;

    setState(() => _saving = true);
    try {
      final price = double.tryParse(_priceController.text.trim());
      await MarketService.instance.createRequirement(
        traderName: widget.profile.displayName ?? 'Trader',
        traderPhone: widget.profile.phoneNumber ?? '',
        countRange: CountRange(
          min: int.parse(_countMinController.text.trim()),
          max: int.parse(_countMaxController.text.trim()),
        ),
        quantityNeeded: double.parse(_quantityController.text.trim()),
        unit: _unit,
        pricePerKg: price,
        region: [_region!],
        expiresAt: _expiresAt!,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.requirementPosted),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
