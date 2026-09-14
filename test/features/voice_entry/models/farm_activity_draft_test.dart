import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/features/voice_entry/models/farm_activity_draft.dart';

void main() {
  final now = DateTime(2026, 9, 11, 10);

  test('sealed drafts expose activity types', () {
    expect(
      FeedActivityDraft(rawTranscript: 'x', occurredAt: now).type,
      FarmActivityType.feed,
    );
    expect(
      WaterQualityActivityDraft(rawTranscript: 'x', occurredAt: now).type,
      FarmActivityType.waterQuality,
    );
    expect(
      GrowthActivityDraft(rawTranscript: 'x', occurredAt: now).type,
      FarmActivityType.growth,
    );
    expect(
      MortalityActivityDraft(rawTranscript: 'x', occurredAt: now).type,
      FarmActivityType.mortality,
    );
    expect(
      UnknownActivityDraft(rawTranscript: 'x', occurredAt: now).type,
      FarmActivityType.unknown,
    );
  });

  test('missing numbers stay null rather than zero', () {
    final water = WaterQualityActivityDraft(
      rawTranscript: 'DO 5.1',
      occurredAt: now,
      dissolvedOxygen: 5.1,
    );
    expect(water.ph, isNull);
    expect(water.dissolvedOxygen, 5.1);
    expect(water.ammoniaPpm, isNull);
    expect(water.temperatureC, isNull);
    expect(water.salinityPpt, isNull);
    expect(water.hardnessMgL, isNull);
  });

  test('copyWithPond keeps feed fields', () {
    final draft = FeedActivityDraft(
      rawTranscript: 'feed',
      occurredAt: now,
      quantityKg: 45,
      trayStatus: FeedTrayStatus.empty,
    );
    final next = draft.copyWithPond(pondId: 'p2', pondReference: 'Pond 2');
    expect(next.pondId, 'p2');
    expect(next.quantityKg, 45);
    expect(next.trayStatus, FeedTrayStatus.empty);
  });

  test('normalizedTranscript defaults to rawTranscript', () {
    final draft = FeedActivityDraft(
      rawTranscript: 'heard this',
      occurredAt: now,
    );
    expect(draft.normalizedTranscript, 'heard this');
  });
}
