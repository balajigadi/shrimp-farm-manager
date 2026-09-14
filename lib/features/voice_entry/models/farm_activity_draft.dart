import 'package:prawn_farm_app/features/pond/pond_model.dart';

enum FarmActivityType { feed, waterQuality, growth, mortality, unknown }

sealed class FarmActivityDraft {
  final String rawTranscript;
  final String normalizedTranscript;
  final String? pondId;
  final String? pondReference;
  final DateTime occurredAt;

  const FarmActivityDraft({
    required this.rawTranscript,
    String? normalizedTranscript,
    this.pondId,
    this.pondReference,
    required this.occurredAt,
  }) : normalizedTranscript = normalizedTranscript ?? rawTranscript;

  FarmActivityType get type;

  FarmActivityDraft copyWithPond({String? pondId, String? pondReference});
}

class FeedActivityDraft extends FarmActivityDraft {
  final double? quantityKg;
  final String? feedType;
  final FeedTrayStatus? trayStatus;

  /// Morning / evening / afternoon when the farmer said it. Not persisted.
  final String? session;

  const FeedActivityDraft({
    required super.rawTranscript,
    super.normalizedTranscript,
    super.pondId,
    super.pondReference,
    required super.occurredAt,
    this.quantityKg,
    this.feedType,
    this.trayStatus,
    this.session,
  });

  @override
  FarmActivityType get type => FarmActivityType.feed;

  @override
  FeedActivityDraft copyWithPond({String? pondId, String? pondReference}) {
    return FeedActivityDraft(
      rawTranscript: rawTranscript,
      normalizedTranscript: normalizedTranscript,
      pondId: pondId ?? this.pondId,
      pondReference: pondReference ?? this.pondReference,
      occurredAt: occurredAt,
      quantityKg: quantityKg,
      feedType: feedType,
      trayStatus: trayStatus,
      session: session,
    );
  }

  FeedActivityDraft copyWith({
    String? pondId,
    String? pondReference,
    DateTime? occurredAt,
    double? quantityKg,
    String? feedType,
    FeedTrayStatus? trayStatus,
    String? session,
    bool clearQuantity = false,
    bool clearFeedType = false,
    bool clearTray = false,
  }) {
    return FeedActivityDraft(
      rawTranscript: rawTranscript,
      normalizedTranscript: normalizedTranscript,
      pondId: pondId ?? this.pondId,
      pondReference: pondReference ?? this.pondReference,
      occurredAt: occurredAt ?? this.occurredAt,
      quantityKg: clearQuantity ? null : (quantityKg ?? this.quantityKg),
      feedType: clearFeedType ? null : (feedType ?? this.feedType),
      trayStatus: clearTray ? null : (trayStatus ?? this.trayStatus),
      session: session ?? this.session,
    );
  }
}

class WaterQualityActivityDraft extends FarmActivityDraft {
  final double? ph;
  final double? dissolvedOxygen;
  final double? temperatureC;
  final double? salinityPpt;
  final double? ammoniaPpm;
  final double? hardnessMgL;

  const WaterQualityActivityDraft({
    required super.rawTranscript,
    super.normalizedTranscript,
    super.pondId,
    super.pondReference,
    required super.occurredAt,
    this.ph,
    this.dissolvedOxygen,
    this.temperatureC,
    this.salinityPpt,
    this.ammoniaPpm,
    this.hardnessMgL,
  });

  @override
  FarmActivityType get type => FarmActivityType.waterQuality;

  @override
  WaterQualityActivityDraft copyWithPond({
    String? pondId,
    String? pondReference,
  }) {
    return copyWith(pondId: pondId, pondReference: pondReference);
  }

  WaterQualityActivityDraft copyWith({
    String? pondId,
    String? pondReference,
    DateTime? occurredAt,
    double? ph,
    double? dissolvedOxygen,
    double? temperatureC,
    double? salinityPpt,
    double? ammoniaPpm,
    double? hardnessMgL,
  }) {
    return WaterQualityActivityDraft(
      rawTranscript: rawTranscript,
      normalizedTranscript: normalizedTranscript,
      pondId: pondId ?? this.pondId,
      pondReference: pondReference ?? this.pondReference,
      occurredAt: occurredAt ?? this.occurredAt,
      ph: ph ?? this.ph,
      dissolvedOxygen: dissolvedOxygen ?? this.dissolvedOxygen,
      temperatureC: temperatureC ?? this.temperatureC,
      salinityPpt: salinityPpt ?? this.salinityPpt,
      ammoniaPpm: ammoniaPpm ?? this.ammoniaPpm,
      hardnessMgL: hardnessMgL ?? this.hardnessMgL,
    );
  }
}

class GrowthActivityDraft extends FarmActivityDraft {
  final double? avgBodyWeightGrams;
  final double? survivalPercent;
  final int? sampleSize;
  final String? notes;

  const GrowthActivityDraft({
    required super.rawTranscript,
    super.normalizedTranscript,
    super.pondId,
    super.pondReference,
    required super.occurredAt,
    this.avgBodyWeightGrams,
    this.survivalPercent,
    this.sampleSize,
    this.notes,
  });

  @override
  FarmActivityType get type => FarmActivityType.growth;

  @override
  GrowthActivityDraft copyWithPond({String? pondId, String? pondReference}) {
    return copyWith(pondId: pondId, pondReference: pondReference);
  }

  GrowthActivityDraft copyWith({
    String? pondId,
    String? pondReference,
    DateTime? occurredAt,
    double? avgBodyWeightGrams,
    double? survivalPercent,
    int? sampleSize,
    String? notes,
  }) {
    return GrowthActivityDraft(
      rawTranscript: rawTranscript,
      normalizedTranscript: normalizedTranscript,
      pondId: pondId ?? this.pondId,
      pondReference: pondReference ?? this.pondReference,
      occurredAt: occurredAt ?? this.occurredAt,
      avgBodyWeightGrams: avgBodyWeightGrams ?? this.avgBodyWeightGrams,
      survivalPercent: survivalPercent ?? this.survivalPercent,
      sampleSize: sampleSize ?? this.sampleSize,
      notes: notes ?? this.notes,
    );
  }
}

class MortalityActivityDraft extends FarmActivityDraft {
  final int? count;
  final String? reason;
  final String? notes;

  const MortalityActivityDraft({
    required super.rawTranscript,
    super.normalizedTranscript,
    super.pondId,
    super.pondReference,
    required super.occurredAt,
    this.count,
    this.reason,
    this.notes,
  });

  @override
  FarmActivityType get type => FarmActivityType.mortality;

  @override
  MortalityActivityDraft copyWithPond({String? pondId, String? pondReference}) {
    return copyWith(pondId: pondId, pondReference: pondReference);
  }

  MortalityActivityDraft copyWith({
    String? pondId,
    String? pondReference,
    DateTime? occurredAt,
    int? count,
    String? reason,
    String? notes,
  }) {
    return MortalityActivityDraft(
      rawTranscript: rawTranscript,
      normalizedTranscript: normalizedTranscript,
      pondId: pondId ?? this.pondId,
      pondReference: pondReference ?? this.pondReference,
      occurredAt: occurredAt ?? this.occurredAt,
      count: count ?? this.count,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
    );
  }
}

class UnknownActivityDraft extends FarmActivityDraft {
  const UnknownActivityDraft({
    required super.rawTranscript,
    super.normalizedTranscript,
    super.pondId,
    super.pondReference,
    required super.occurredAt,
  });

  @override
  FarmActivityType get type => FarmActivityType.unknown;

  @override
  UnknownActivityDraft copyWithPond({String? pondId, String? pondReference}) {
    return UnknownActivityDraft(
      rawTranscript: rawTranscript,
      normalizedTranscript: normalizedTranscript,
      pondId: pondId ?? this.pondId,
      pondReference: pondReference ?? this.pondReference,
      occurredAt: occurredAt,
    );
  }
}
