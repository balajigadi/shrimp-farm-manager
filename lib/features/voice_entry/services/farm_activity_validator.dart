import '../models/farm_activity_draft.dart';

enum VoiceField {
  pond,
  activity,
  quantityKg,
  feedType,
  trayStatus,
  ph,
  dissolvedOxygen,
  temperatureC,
  salinityPpt,
  ammoniaPpm,
  hardnessMgL,
  avgBodyWeightGrams,
  survivalPercent,
  mortalityCount,
}

class FieldIssue {
  final VoiceField field;
  final String code;

  const FieldIssue(this.field, this.code);
}

class ValidationResult {
  final List<FieldIssue> issues;

  const ValidationResult(this.issues);

  bool get isValid => issues.isEmpty;

  bool has(VoiceField field) => issues.any((e) => e.field == field);
}

/// Independent of UI. Missing speech values stay missing — never coerced to 0.
class FarmActivityValidator {
  const FarmActivityValidator();

  ValidationResult validate(FarmActivityDraft draft) {
    return switch (draft) {
      FeedActivityDraft d => _feed(d),
      WaterQualityActivityDraft d => _water(d),
      GrowthActivityDraft d => _growth(d),
      MortalityActivityDraft d => _mortality(d),
      UnknownActivityDraft _ => const ValidationResult([
        FieldIssue(VoiceField.activity, 'unknown_activity'),
      ]),
    };
  }

  ValidationResult _feed(FeedActivityDraft d) {
    final issues = <FieldIssue>[];
    if (d.pondId == null || d.pondId!.isEmpty) {
      issues.add(const FieldIssue(VoiceField.pond, 'pond_required'));
    }
    if (d.quantityKg == null || d.quantityKg! <= 0) {
      issues.add(const FieldIssue(VoiceField.quantityKg, 'quantity_required'));
    }
    if (d.feedType == null || d.feedType!.trim().isEmpty) {
      issues.add(const FieldIssue(VoiceField.feedType, 'feed_type_required'));
    }
    if (d.trayStatus == null) {
      issues.add(const FieldIssue(VoiceField.trayStatus, 'tray_required'));
    }
    return ValidationResult(issues);
  }

  ValidationResult _water(WaterQualityActivityDraft d) {
    final issues = <FieldIssue>[];
    if (d.pondId == null || d.pondId!.isEmpty) {
      issues.add(const FieldIssue(VoiceField.pond, 'pond_required'));
    }
    if (d.ph == null) {
      issues.add(const FieldIssue(VoiceField.ph, 'ph_required'));
    }
    if (d.dissolvedOxygen == null) {
      issues.add(const FieldIssue(VoiceField.dissolvedOxygen, 'do_required'));
    }
    if (d.temperatureC == null) {
      issues.add(const FieldIssue(VoiceField.temperatureC, 'temp_required'));
    }
    if (d.salinityPpt == null) {
      issues.add(const FieldIssue(VoiceField.salinityPpt, 'salinity_required'));
    }
    if (d.ammoniaPpm == null) {
      issues.add(const FieldIssue(VoiceField.ammoniaPpm, 'ammonia_required'));
    }
    if (d.hardnessMgL == null) {
      issues.add(const FieldIssue(VoiceField.hardnessMgL, 'hardness_required'));
    }
    return ValidationResult(issues);
  }

  ValidationResult _growth(GrowthActivityDraft d) {
    final issues = <FieldIssue>[];
    if (d.pondId == null || d.pondId!.isEmpty) {
      issues.add(const FieldIssue(VoiceField.pond, 'pond_required'));
    }
    if (d.avgBodyWeightGrams == null || d.avgBodyWeightGrams! <= 0) {
      issues.add(
        const FieldIssue(VoiceField.avgBodyWeightGrams, 'abw_required'),
      );
    }
    if (d.survivalPercent == null) {
      issues.add(
        const FieldIssue(VoiceField.survivalPercent, 'survival_required'),
      );
    } else if (d.survivalPercent! < 0 || d.survivalPercent! > 100) {
      issues.add(
        const FieldIssue(VoiceField.survivalPercent, 'survival_range'),
      );
    }
    return ValidationResult(issues);
  }

  ValidationResult _mortality(MortalityActivityDraft d) {
    final issues = <FieldIssue>[];
    if (d.pondId == null || d.pondId!.isEmpty) {
      issues.add(const FieldIssue(VoiceField.pond, 'pond_required'));
    }
    if (d.count == null || d.count! < 0) {
      issues.add(const FieldIssue(VoiceField.mortalityCount, 'count_required'));
    }
    return ValidationResult(issues);
  }
}
