import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../lab/voice_stt_locale_lab_flags.dart';
import '../models/farm_activity_draft.dart';
import 'pond_resolver.dart';

/// Pilot logging. Compiled out of release via [assert] unless the STT locale
/// lab dart-define is enabled (TestFlight instrumentation). Never stores audio.
abstract final class VoiceEntryDebugLog {
  static bool get _labLoggingEnabled =>
      kDebugMode || voiceSttLocaleLabEnabled();

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

  static void localeLabResult({
    required String localeId,
    required String phraseId,
    required String expected,
    required String heard,
    required bool exactMatch,
    required double tokenRecall,
    required double werProxy,
  }) {
    if (!_labLoggingEnabled) return;
    developer.log(
      '[LocaleLab] phrase locale="$localeId" id=$phraseId '
      'exact=$exactMatch recall=${tokenRecall.toStringAsFixed(2)} '
      'wer=${werProxy.toStringAsFixed(2)} '
      'expected="$expected" heard="$heard"',
      name: 'voice_entry',
    );
  }

  static void localeLabSummary({
    required String localeId,
    required int phraseCount,
    required double exactRate,
    required double meanTokenRecall,
    required double meanWerProxy,
  }) {
    if (!_labLoggingEnabled) return;
    developer.log(
      '[LocaleLab] summary locale="$localeId" n=$phraseCount '
      'exact=${exactRate.toStringAsFixed(2)} '
      'tokenRecall=${meanTokenRecall.toStringAsFixed(2)} '
      'werProxy=${meanWerProxy.toStringAsFixed(2)}',
      name: 'voice_entry',
    );
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
