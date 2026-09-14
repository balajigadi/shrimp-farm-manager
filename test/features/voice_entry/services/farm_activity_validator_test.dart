import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/features/voice_entry/models/farm_activity_draft.dart';
import 'package:prawn_farm_app/features/voice_entry/services/farm_activity_validator.dart';

void main() {
  const validator = FarmActivityValidator();
  final now = DateTime(2026, 9, 11);

  group('feed', () {
    test('requires pond, quantity, feed type and tray', () {
      final result = validator.validate(
        FeedActivityDraft(rawTranscript: 'x', occurredAt: now),
      );
      expect(result.isValid, isFalse);
      expect(result.has(VoiceField.pond), isTrue);
      expect(result.has(VoiceField.quantityKg), isTrue);
      expect(result.has(VoiceField.feedType), isTrue);
      expect(result.has(VoiceField.trayStatus), isTrue);
    });

    test('zero or negative quantity is invalid', () {
      final zero = validator.validate(
        FeedActivityDraft(
          rawTranscript: 'x',
          occurredAt: now,
          pondId: 'p1',
          quantityKg: 0,
          feedType: 'pellet feed',
          trayStatus: FeedTrayStatus.empty,
        ),
      );
      expect(zero.has(VoiceField.quantityKg), isTrue);
    });

    test('complete feed is valid', () {
      final result = validator.validate(
        FeedActivityDraft(
          rawTranscript: 'x',
          occurredAt: now,
          pondId: 'p1',
          quantityKg: 45,
          feedType: 'pellet feed',
          trayStatus: FeedTrayStatus.empty,
        ),
      );
      expect(result.isValid, isTrue);
    });
  });

  group('water', () {
    test('partial water capture is not valid and does not invent zeros', () {
      final water = WaterQualityActivityDraft(
        rawTranscript: 'DO 5.1 pH 8.2',
        occurredAt: now,
        pondId: 'p1',
        dissolvedOxygen: 5.1,
        ph: 8.2,
      );
      expect(water.ammoniaPpm, isNull);
      final result = validator.validate(water);
      expect(result.isValid, isFalse);
      expect(result.has(VoiceField.temperatureC), isTrue);
      expect(result.has(VoiceField.salinityPpt), isTrue);
      expect(result.has(VoiceField.ammoniaPpm), isTrue);
      expect(result.has(VoiceField.hardnessMgL), isTrue);
    });

    test('all six water parameters are valid', () {
      final result = validator.validate(
        WaterQualityActivityDraft(
          rawTranscript: 'x',
          occurredAt: now,
          pondId: 'p1',
          ph: 8.1,
          dissolvedOxygen: 5.2,
          temperatureC: 29,
          salinityPpt: 14,
          ammoniaPpm: 0.05,
          hardnessMgL: 120,
        ),
      );
      expect(result.isValid, isTrue);
    });
  });

  group('growth', () {
    test('does not invent survival', () {
      final result = validator.validate(
        GrowthActivityDraft(
          rawTranscript: 'x',
          occurredAt: now,
          pondId: 'p1',
          avgBodyWeightGrams: 24,
        ),
      );
      expect(result.has(VoiceField.survivalPercent), isTrue);
    });

    test('sample size is optional', () {
      final result = validator.validate(
        GrowthActivityDraft(
          rawTranscript: 'x',
          occurredAt: now,
          pondId: 'p1',
          avgBodyWeightGrams: 24,
          survivalPercent: 85,
        ),
      );
      expect(result.isValid, isTrue);
    });

    test('survival outside 0-100 is invalid', () {
      final result = validator.validate(
        GrowthActivityDraft(
          rawTranscript: 'x',
          occurredAt: now,
          pondId: 'p1',
          avgBodyWeightGrams: 24,
          survivalPercent: 140,
        ),
      );
      expect(result.has(VoiceField.survivalPercent), isTrue);
    });
  });

  group('mortality', () {
    test('requires pond and non-negative count', () {
      final missing = validator.validate(
        MortalityActivityDraft(rawTranscript: 'x', occurredAt: now),
      );
      expect(missing.has(VoiceField.pond), isTrue);
      expect(missing.has(VoiceField.mortalityCount), isTrue);

      final zero = validator.validate(
        MortalityActivityDraft(
          rawTranscript: 'x',
          occurredAt: now,
          pondId: 'p1',
          count: 0,
        ),
      );
      expect(zero.isValid, isTrue);
    });
  });

  test('unknown activity is invalid', () {
    final result = validator.validate(
      UnknownActivityDraft(rawTranscript: 'hello', occurredAt: now),
    );
    expect(result.has(VoiceField.activity), isTrue);
  });
}
