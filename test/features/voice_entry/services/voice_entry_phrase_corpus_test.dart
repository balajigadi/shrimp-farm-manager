import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/models/farm_activity_draft.dart';
import 'package:prawn_farm_app/features/voice_entry/services/rule_based_farm_activity_parser.dart';
import '../../../fixtures/voice_entry_phrase_corpus.dart';

void main() {
  const parser = RuleBasedFarmActivityParser();
  final now = DateTime(2026, 9, 11, 10, 30);

  for (final phrase in voiceEntryPhraseCorpus) {
    test('${phrase.category.name} ${phrase.id}', () async {
      final draft = await parser.parse(
        phrase.rawSttTranscript,
        ponds: phrase.ponds(),
        now: now,
      );
      expect(
        draft.rawTranscript,
        phrase.rawSttTranscript,
        reason: 'I heard must keep the raw STT transcript',
      );
      expect(draft.type, phrase.expectedActivity);

      if (phrase.expectedPondId != null) {
        expect(draft.pondId, phrase.expectedPondId);
      }

      if (draft is FeedActivityDraft) {
        if (phrase.expectedQuantityKg != null) {
          expect(draft.quantityKg, phrase.expectedQuantityKg);
        }
        if (phrase.expectedFeedType != null) {
          expect(draft.feedType, phrase.expectedFeedType);
        }
        if (phrase.expectedTray != null) {
          expect(draft.trayStatus, phrase.expectedTray);
        }
        if (phrase.expectedSession != null) {
          expect(draft.session, phrase.expectedSession);
        }
        _expectMissingFeed(draft, phrase.mustBeMissing);
      } else if (draft is WaterQualityActivityDraft) {
        if (phrase.expectedPh != null) expect(draft.ph, phrase.expectedPh);
        if (phrase.expectedDissolvedOxygen != null) {
          expect(draft.dissolvedOxygen, phrase.expectedDissolvedOxygen);
        }
        if (phrase.expectedTemperatureC != null) {
          expect(draft.temperatureC, phrase.expectedTemperatureC);
        }
        if (phrase.expectedSalinityPpt != null) {
          expect(draft.salinityPpt, phrase.expectedSalinityPpt);
        }
        if (phrase.expectedAmmoniaPpm != null) {
          expect(draft.ammoniaPpm, phrase.expectedAmmoniaPpm);
        }
        if (phrase.expectedHardnessMgL != null) {
          expect(draft.hardnessMgL, phrase.expectedHardnessMgL);
        }
        _expectMissingWater(draft, phrase.mustBeMissing);
      } else if (draft is GrowthActivityDraft) {
        if (phrase.expectedAvgBodyWeightGrams != null) {
          expect(draft.avgBodyWeightGrams, phrase.expectedAvgBodyWeightGrams);
        }
        if (phrase.expectedSurvivalPercent != null) {
          expect(draft.survivalPercent, phrase.expectedSurvivalPercent);
        }
        if (phrase.expectedSampleSize != null) {
          expect(draft.sampleSize, phrase.expectedSampleSize);
        }
        _expectMissingGrowth(draft, phrase.mustBeMissing);
      } else if (draft is MortalityActivityDraft) {
        if (phrase.expectedMortalityCount != null) {
          expect(draft.count, phrase.expectedMortalityCount);
        }
        _expectMissingMortality(draft, phrase.mustBeMissing);
      }
    });
  }

  test('dakshina pand is not auto-translated to South Pond', () async {
    final draft = await parser.parse(
      'దక్షిణ పాండ్ లో mortality 12',
      ponds: voiceEntryPhraseCorpus.first.ponds(),
      now: now,
    );
    expect(draft.rawTranscript, 'దక్షిణ పాండ్ లో mortality 12');
    expect(draft, isA<MortalityActivityDraft>());
    expect(draft.pondId, isNull);
    expect((draft as MortalityActivityDraft).count, 12);
  });

  test('mortality without a number does not invent a count', () async {
    final draft = await parser.parse(
      'Rendo pond lo prawns chanipoyayi',
      ponds: voiceEntryPhraseCorpus.first.ponds(),
      now: now,
    );
    expect(draft, isA<MortalityActivityDraft>());
    expect(draft.pondId, 'p2');
    expect((draft as MortalityActivityDraft).count, isNull);
  });
}

void _expectMissingFeed(
  FeedActivityDraft draft,
  Set<VoiceMustBeMissing> missing,
) {
  if (missing.contains(VoiceMustBeMissing.quantityKg)) {
    expect(draft.quantityKg, isNull);
  }
  if (missing.contains(VoiceMustBeMissing.feedType)) {
    expect(draft.feedType, isNull);
  }
  if (missing.contains(VoiceMustBeMissing.trayStatus)) {
    expect(draft.trayStatus, isNull);
  }
  if (missing.contains(VoiceMustBeMissing.session)) {
    expect(draft.session, isNull);
  }
}

void _expectMissingWater(
  WaterQualityActivityDraft draft,
  Set<VoiceMustBeMissing> missing,
) {
  if (missing.contains(VoiceMustBeMissing.ph)) expect(draft.ph, isNull);
  if (missing.contains(VoiceMustBeMissing.dissolvedOxygen)) {
    expect(draft.dissolvedOxygen, isNull);
  }
  if (missing.contains(VoiceMustBeMissing.temperatureC)) {
    expect(draft.temperatureC, isNull);
  }
  if (missing.contains(VoiceMustBeMissing.salinityPpt)) {
    expect(draft.salinityPpt, isNull);
  }
  if (missing.contains(VoiceMustBeMissing.ammoniaPpm)) {
    expect(draft.ammoniaPpm, isNull);
  }
  if (missing.contains(VoiceMustBeMissing.hardnessMgL)) {
    expect(draft.hardnessMgL, isNull);
  }
}

void _expectMissingGrowth(
  GrowthActivityDraft draft,
  Set<VoiceMustBeMissing> missing,
) {
  if (missing.contains(VoiceMustBeMissing.avgBodyWeightGrams)) {
    expect(draft.avgBodyWeightGrams, isNull);
  }
  if (missing.contains(VoiceMustBeMissing.survivalPercent)) {
    expect(draft.survivalPercent, isNull);
  }
  if (missing.contains(VoiceMustBeMissing.sampleSize)) {
    expect(draft.sampleSize, isNull);
  }
}

void _expectMissingMortality(
  MortalityActivityDraft draft,
  Set<VoiceMustBeMissing> missing,
) {
  if (missing.contains(VoiceMustBeMissing.mortalityCount)) {
    expect(draft.count, isNull);
  }
  if (missing.contains(VoiceMustBeMissing.pondId)) {
    expect(draft.pondId, isNull);
  }
}
