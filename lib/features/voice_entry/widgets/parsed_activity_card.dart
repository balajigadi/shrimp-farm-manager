import 'package:flutter/material.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../models/farm_activity_draft.dart';
import '../services/farm_activity_validator.dart';

class ParsedActivityCard extends StatelessWidget {
  const ParsedActivityCard({
    super.key,
    required this.draft,
    required this.ponds,
    required this.validation,
  });

  final FarmActivityDraft draft;
  final List<Pond> ponds;
  final ValidationResult validation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pondName = _pondName();
    return Card(
      key: const Key('voice_parsed_activity_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row(l10n.pond, pondName, missing: validation.has(VoiceField.pond)),
            _row(
              l10n.voiceActivityLabel,
              _activityLabel(l10n),
              missing: validation.has(VoiceField.activity),
            ),
            ..._typeRows(l10n),
          ],
        ),
      ),
    );
  }

  String _pondName() {
    for (final pond in ponds) {
      if (pond.id == draft.pondId) return pond.name;
    }
    return draft.pondReference ?? '';
  }

  String _activityLabel(AppLocalizations l10n) {
    return switch (draft.type) {
      FarmActivityType.feed => l10n.voiceActivityFeed,
      FarmActivityType.waterQuality => l10n.voiceActivityWater,
      FarmActivityType.growth => l10n.voiceActivityGrowth,
      FarmActivityType.mortality => l10n.voiceActivityMortality,
      FarmActivityType.unknown => l10n.voiceActivityUnknown,
    };
  }

  List<Widget> _typeRows(AppLocalizations l10n) {
    return switch (draft) {
      FeedActivityDraft d => [
        _row(
          l10n.quantityKg,
          d.quantityKg == null ? '' : '${d.quantityKg}',
          missing: validation.has(VoiceField.quantityKg),
        ),
        _row(
          l10n.feedType,
          d.feedType ?? '',
          missing: validation.has(VoiceField.feedType),
        ),
        _row(
          l10n.checkTrayStatus,
          d.trayStatus?.name ?? '',
          missing: validation.has(VoiceField.trayStatus),
        ),
      ],
      WaterQualityActivityDraft d => [
        _row(l10n.ph, _n(d.ph), missing: validation.has(VoiceField.ph)),
        _row(
          l10n.dissolvedOxygen,
          _n(d.dissolvedOxygen),
          missing: validation.has(VoiceField.dissolvedOxygen),
        ),
        _row(
          l10n.temperature,
          _n(d.temperatureC),
          missing: validation.has(VoiceField.temperatureC),
        ),
        _row(
          l10n.salinity,
          _n(d.salinityPpt),
          missing: validation.has(VoiceField.salinityPpt),
        ),
        _row(
          l10n.ammonia,
          _n(d.ammoniaPpm),
          missing: validation.has(VoiceField.ammoniaPpm),
        ),
        _row(
          l10n.hardness,
          _n(d.hardnessMgL),
          missing: validation.has(VoiceField.hardnessMgL),
        ),
      ],
      GrowthActivityDraft d => [
        _row(
          l10n.avgBodyWeight,
          _n(d.avgBodyWeightGrams),
          missing: validation.has(VoiceField.avgBodyWeightGrams),
        ),
        _row(
          l10n.survivalPercent,
          _n(d.survivalPercent),
          missing: validation.has(VoiceField.survivalPercent),
        ),
      ],
      MortalityActivityDraft d => [
        _row(
          l10n.deadCount,
          d.count?.toString() ?? '',
          missing: validation.has(VoiceField.mortalityCount),
        ),
        _row(l10n.reason, d.reason ?? ''),
      ],
      UnknownActivityDraft _ => const [],
    };
  }

  String _n(double? value) => value == null ? '' : value.toString();

  Widget _row(String label, String value, {bool missing = false}) {
    final shown = value.trim().isEmpty ? (missing ? '—' : '') : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: missing ? const Color(0xFFAE2012) : Colors.grey.shade700,
                fontWeight: missing ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              shown,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: missing ? const Color(0xFFAE2012) : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
