import 'dart:developer' as developer;

import '../models/farm_activity_draft.dart';
import 'pond_resolver.dart';

/// Pilot logging. Compiled out of release via [assert]. Never stores audio.
abstract final class VoiceEntryDebugLog {
  static void speechLocale({
    required String selectedLocaleId,
    required bool usedFallback,
    required bool teluguUnavailable,
  }) {
    assert(() {
      developer.log(
        'selectedLocale="$selectedLocaleId" '
        'usedFallback=$usedFallback '
        'teluguUnavailable=$teluguUnavailable',
        name: 'voice_entry',
      );
      return true;
    }());
  }

  static void parse({
    required String rawTranscript,
    required String normalizedTranscript,
    required FarmActivityDraft draft,
    required PondResolveResult pond,
    List<String> missingFields = const [],
  }) {
    assert(() {
      developer.log(
        'raw="$rawTranscript" '
        'normalized="$normalizedTranscript" '
        'type=${draft.type.name} '
        'pondId=${draft.pondId} '
        'pondRef=${draft.pondReference} '
        'pondStatus=${pond.status.name} '
        'pondKind=${pond.matchKind?.name} '
        'fields=${_fields(draft)} '
        'missing=$missingFields',
        name: 'voice_entry',
      );
      return true;
    }());
  }

  static Map<String, Object?> _fields(FarmActivityDraft draft) {
    return switch (draft) {
      FeedActivityDraft d => {
        'pondId': d.pondId,
        'quantityKg': d.quantityKg,
        'feedType': d.feedType,
        'trayStatus': d.trayStatus?.name,
        'session': d.session,
      },
      WaterQualityActivityDraft d => {
        'pondId': d.pondId,
        'ph': d.ph,
        'do': d.dissolvedOxygen,
        'temp': d.temperatureC,
        'salinity': d.salinityPpt,
        'ammonia': d.ammoniaPpm,
        'hardness': d.hardnessMgL,
      },
      GrowthActivityDraft d => {
        'pondId': d.pondId,
        'abw': d.avgBodyWeightGrams,
        'survival': d.survivalPercent,
        'sampleSize': d.sampleSize,
      },
      MortalityActivityDraft d => {
        'pondId': d.pondId,
        'count': d.count,
        'reason': d.reason,
      },
      UnknownActivityDraft d => {'pondId': d.pondId},
    };
  }
}
