import 'package:flutter/material.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../models/farm_activity_draft.dart';
import '../services/farm_activity_validator.dart';
import '../widgets/parsed_activity_card.dart';
import '../widgets/voice_transcript_card.dart';

class VoiceConfirmationScreen extends StatefulWidget {
  const VoiceConfirmationScreen({
    super.key,
    required this.draft,
    required this.ponds,
    required this.onDraftChanged,
    required this.onConfirm,
    required this.onTryAgain,
    required this.onCancel,
    this.saving = false,
    this.saveFailed = false,
  });

  final FarmActivityDraft draft;
  final List<Pond> ponds;
  final ValueChanged<FarmActivityDraft> onDraftChanged;
  final VoidCallback onConfirm;
  final VoidCallback onTryAgain;
  final VoidCallback onCancel;
  final bool saving;
  final bool saveFailed;

  @override
  State<VoiceConfirmationScreen> createState() =>
      _VoiceConfirmationScreenState();
}

class _VoiceConfirmationScreenState extends State<VoiceConfirmationScreen> {
  final _validator = const FarmActivityValidator();
  late final TextEditingController _feedType;
  late final TextEditingController _quantity;
  late final TextEditingController _ph;
  late final TextEditingController _do;
  late final TextEditingController _temp;
  late final TextEditingController _salinity;
  late final TextEditingController _ammonia;
  late final TextEditingController _hardness;
  late final TextEditingController _abw;
  late final TextEditingController _survival;
  late final TextEditingController _sampleSize;
  late final TextEditingController _count;
  late final TextEditingController _reason;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _feedType = TextEditingController(
      text: d is FeedActivityDraft ? (d.feedType ?? '') : '',
    );
    _quantity = TextEditingController(
      text: d is FeedActivityDraft ? _fmt(d.quantityKg) : '',
    );
    _ph = TextEditingController(
      text: d is WaterQualityActivityDraft ? _fmt(d.ph) : '',
    );
    _do = TextEditingController(
      text: d is WaterQualityActivityDraft ? _fmt(d.dissolvedOxygen) : '',
    );
    _temp = TextEditingController(
      text: d is WaterQualityActivityDraft ? _fmt(d.temperatureC) : '',
    );
    _salinity = TextEditingController(
      text: d is WaterQualityActivityDraft ? _fmt(d.salinityPpt) : '',
    );
    _ammonia = TextEditingController(
      text: d is WaterQualityActivityDraft ? _fmt(d.ammoniaPpm) : '',
    );
    _hardness = TextEditingController(
      text: d is WaterQualityActivityDraft ? _fmt(d.hardnessMgL) : '',
    );
    _abw = TextEditingController(
      text: d is GrowthActivityDraft ? _fmt(d.avgBodyWeightGrams) : '',
    );
    _survival = TextEditingController(
      text: d is GrowthActivityDraft ? _fmt(d.survivalPercent) : '',
    );
    _sampleSize = TextEditingController(
      text: d is GrowthActivityDraft && d.sampleSize != null
          ? '${d.sampleSize}'
          : '',
    );
    _count = TextEditingController(
      text: d is MortalityActivityDraft && d.count != null ? '${d.count}' : '',
    );
    _reason = TextEditingController(
      text: d is MortalityActivityDraft ? (d.reason ?? '') : '',
    );
    _notes = TextEditingController(
      text: switch (d) {
        GrowthActivityDraft g => g.notes ?? '',
        MortalityActivityDraft m => m.notes ?? '',
        _ => '',
      },
    );
  }

  @override
  void dispose() {
    _feedType.dispose();
    _quantity.dispose();
    _ph.dispose();
    _do.dispose();
    _temp.dispose();
    _salinity.dispose();
    _ammonia.dispose();
    _hardness.dispose();
    _abw.dispose();
    _survival.dispose();
    _sampleSize.dispose();
    _count.dispose();
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _fmt(double? value) => value == null ? '' : '$value';

  ValidationResult get _validation => _validator.validate(widget.draft);

  void _emit(FarmActivityDraft next) {
    widget.onDraftChanged(next);
  }

  void _selectPond(String? pondId) {
    if (pondId == null) return;
    Pond? pond;
    for (final p in widget.ponds) {
      if (p.id == pondId) {
        pond = p;
        break;
      }
    }
    if (pond == null) return;
    _emit(widget.draft.copyWithPond(pondId: pond.id, pondReference: pond.name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final valid = _validation.isValid;
    final pondMissing = _validation.has(VoiceField.pond);
    return Column(
      key: const Key('voice_review'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              VoiceTranscriptCard(
                title: l10n.voiceIHeard,
                transcript: widget.draft.rawTranscript,
              ),
              const SizedBox(height: 12),
              if (pondMissing && (widget.draft.pondReference ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l10n.voicePleaseConfirmPond(widget.draft.pondReference!),
                    style: const TextStyle(
                      color: Color(0xFFAE2012),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.pond,
                  errorText: pondMissing ? l10n.voiceMissingField : null,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('voice_pond_dropdown'),
                    isExpanded: true,
                    hint: Text(l10n.voiceSelectPond),
                    value: _dropdownValue(),
                    items: [
                      for (final pond in widget.ponds)
                        DropdownMenuItem(
                          value: pond.id,
                          child: Text(pond.name),
                        ),
                    ],
                    onChanged: widget.saving ? null : _selectPond,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._fields(l10n),
              const SizedBox(height: 12),
              ParsedActivityCard(
                draft: widget.draft,
                ponds: widget.ponds,
                validation: _validation,
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.saveFailed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.voiceSaveFailed,
                      key: const Key('voice_save_failed'),
                      style: const TextStyle(color: Color(0xFFAE2012)),
                    ),
                  ),
                FilledButton(
                  key: const Key('voice_confirm_button'),
                  onPressed: valid && !widget.saving ? widget.onConfirm : null,
                  child: widget.saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.voiceConfirmAndSave),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('voice_try_again_button'),
                  onPressed: widget.saving ? null : widget.onTryAgain,
                  child: Text(l10n.voiceTryAgain),
                ),
                TextButton(
                  key: const Key('voice_cancel_button'),
                  onPressed: widget.saving ? null : widget.onCancel,
                  child: Text(l10n.voiceCancel),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _dropdownValue() {
    final id = widget.draft.pondId;
    if (id == null) return null;
    for (final pond in widget.ponds) {
      if (pond.id == id) return id;
    }
    return null;
  }

  List<Widget> _fields(AppLocalizations l10n) {
    return switch (widget.draft) {
      FeedActivityDraft d => _feedFields(l10n, d),
      WaterQualityActivityDraft d => _waterFields(l10n, d),
      GrowthActivityDraft d => _growthFields(l10n, d),
      MortalityActivityDraft d => _mortalityFields(l10n, d),
      UnknownActivityDraft _ => [
        Text(
          l10n.voiceUnknownActivity,
          key: const Key('voice_unknown_activity'),
        ),
      ],
    };
  }

  List<Widget> _feedFields(AppLocalizations l10n, FeedActivityDraft d) {
    return [
      _traySelector(l10n, d),
      TextField(
        key: const Key('voice_field_quantity'),
        controller: _quantity,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.quantityKg,
          errorText: _validation.has(VoiceField.quantityKg)
              ? l10n.voiceMissingField
              : null,
        ),
        onChanged: (value) {
          final current = widget.draft;
          if (current is! FeedActivityDraft) return;
          final parsed = double.tryParse(value.trim());
          _emit(
            current.copyWith(quantityKg: parsed, clearQuantity: parsed == null),
          );
        },
      ),
      TextField(
        key: const Key('voice_field_feed_type'),
        controller: _feedType,
        decoration: InputDecoration(
          labelText: l10n.feedType,
          errorText: _validation.has(VoiceField.feedType)
              ? l10n.voiceMissingField
              : null,
        ),
        onChanged: (value) {
          final current = widget.draft;
          if (current is! FeedActivityDraft) return;
          final trimmed = value.trim();
          _emit(
            current.copyWith(feedType: trimmed, clearFeedType: trimmed.isEmpty),
          );
        },
      ),
    ];
  }

  Widget _traySelector(AppLocalizations l10n, FeedActivityDraft d) {
    final missing = _validation.has(VoiceField.trayStatus);
    Widget tile({
      required FeedTrayStatus status,
      required Key key,
      required String label,
      required Color color,
      required IconData icon,
    }) {
      final selected = d.trayStatus == status;
      return Expanded(
        child: Material(
          color: selected
              ? color.withValues(alpha: 0.15)
              : missing
              ? const Color(0xFFFFEBEE)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            key: key,
            borderRadius: BorderRadius.circular(12),
            onTap: widget.saving
                ? null
                : () {
                    final current = widget.draft;
                    if (current is! FeedActivityDraft) return;
                    _emit(current.copyWith(trayStatus: status));
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
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

    return InputDecorator(
      key: const Key('voice_field_tray'),
      decoration: InputDecoration(
        labelText: l10n.checkTrayStatus,
        errorText: missing ? l10n.voiceMissingField : null,
        border: InputBorder.none,
      ),
      child: Row(
        children: [
          tile(
            status: FeedTrayStatus.empty,
            key: const Key('voice_tray_empty'),
            label: l10n.trayEmpty,
            color: const Color(0xFF00C853),
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(width: 8),
          tile(
            status: FeedTrayStatus.partial,
            key: const Key('voice_tray_partial'),
            label: l10n.trayPartial,
            color: const Color(0xFFFF9800),
            icon: Icons.remove_circle_outline,
          ),
          const SizedBox(width: 8),
          tile(
            status: FeedTrayStatus.full,
            key: const Key('voice_tray_full'),
            label: l10n.trayFull,
            color: const Color(0xFFE53935),
            icon: Icons.cancel_outlined,
          ),
        ],
      ),
    );
  }

  List<Widget> _waterFields(
    AppLocalizations l10n,
    WaterQualityActivityDraft _,
  ) {
    Widget field({
      required Key key,
      required TextEditingController controller,
      required String label,
      required VoiceField field,
      required WaterQualityActivityDraft Function(
        WaterQualityActivityDraft current,
        double? value,
      )
      applyOn,
    }) {
      return TextField(
        key: key,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          errorText: _validation.has(field) ? l10n.voiceMissingField : null,
        ),
        onChanged: (value) {
          final current = widget.draft;
          if (current is! WaterQualityActivityDraft) return;
          _emit(applyOn(current, double.tryParse(value.trim())));
        },
      );
    }

    return [
      field(
        key: const Key('voice_field_ph'),
        controller: _ph,
        label: l10n.ph,
        field: VoiceField.ph,
        applyOn: (current, v) => current.copyWith(ph: v),
      ),
      field(
        key: const Key('voice_field_do'),
        controller: _do,
        label: l10n.dissolvedOxygen,
        field: VoiceField.dissolvedOxygen,
        applyOn: (current, v) => current.copyWith(dissolvedOxygen: v),
      ),
      field(
        key: const Key('voice_field_temp'),
        controller: _temp,
        label: l10n.temperature,
        field: VoiceField.temperatureC,
        applyOn: (current, v) => current.copyWith(temperatureC: v),
      ),
      field(
        key: const Key('voice_field_salinity'),
        controller: _salinity,
        label: l10n.salinity,
        field: VoiceField.salinityPpt,
        applyOn: (current, v) => current.copyWith(salinityPpt: v),
      ),
      field(
        key: const Key('voice_field_ammonia'),
        controller: _ammonia,
        label: l10n.ammonia,
        field: VoiceField.ammoniaPpm,
        applyOn: (current, v) => current.copyWith(ammoniaPpm: v),
      ),
      field(
        key: const Key('voice_field_hardness'),
        controller: _hardness,
        label: l10n.hardness,
        field: VoiceField.hardnessMgL,
        applyOn: (current, v) => current.copyWith(hardnessMgL: v),
      ),
    ];
  }

  List<Widget> _growthFields(AppLocalizations l10n, GrowthActivityDraft _) {
    return [
      TextField(
        key: const Key('voice_field_abw'),
        controller: _abw,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.avgBodyWeight,
          errorText: _validation.has(VoiceField.avgBodyWeightGrams)
              ? l10n.voiceMissingField
              : null,
        ),
        onChanged: (value) {
          final current = widget.draft;
          if (current is! GrowthActivityDraft) return;
          _emit(
            current.copyWith(avgBodyWeightGrams: double.tryParse(value.trim())),
          );
        },
      ),
      TextField(
        key: const Key('voice_field_survival'),
        controller: _survival,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.survivalPercent,
          errorText: _validation.has(VoiceField.survivalPercent)
              ? l10n.voiceMissingField
              : null,
        ),
        onChanged: (value) {
          final current = widget.draft;
          if (current is! GrowthActivityDraft) return;
          _emit(
            current.copyWith(survivalPercent: double.tryParse(value.trim())),
          );
        },
      ),
      TextField(
        key: const Key('voice_field_sample_size'),
        controller: _sampleSize,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: l10n.sampleSize),
        onChanged: (value) {
          final current = widget.draft;
          if (current is! GrowthActivityDraft) return;
          _emit(current.copyWith(sampleSize: int.tryParse(value.trim())));
        },
      ),
      TextField(
        controller: _notes,
        decoration: InputDecoration(labelText: l10n.notes),
        onChanged: (value) {
          final current = widget.draft;
          if (current is! GrowthActivityDraft) return;
          _emit(current.copyWith(notes: value));
        },
      ),
    ];
  }

  List<Widget> _mortalityFields(
    AppLocalizations l10n,
    MortalityActivityDraft _,
  ) {
    return [
      TextField(
        key: const Key('voice_field_count'),
        controller: _count,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: l10n.deadCount,
          errorText: _validation.has(VoiceField.mortalityCount)
              ? l10n.voiceMissingField
              : null,
        ),
        onChanged: (value) {
          final current = widget.draft;
          if (current is! MortalityActivityDraft) return;
          _emit(current.copyWith(count: int.tryParse(value.trim())));
        },
      ),
      TextField(
        controller: _reason,
        decoration: InputDecoration(labelText: l10n.reason),
        onChanged: (value) {
          final current = widget.draft;
          if (current is! MortalityActivityDraft) return;
          _emit(current.copyWith(reason: value));
        },
      ),
      TextField(
        controller: _notes,
        decoration: InputDecoration(labelText: l10n.notes),
        onChanged: (value) {
          final current = widget.draft;
          if (current is! MortalityActivityDraft) return;
          _emit(current.copyWith(notes: value));
        },
      ),
    ];
  }
}
