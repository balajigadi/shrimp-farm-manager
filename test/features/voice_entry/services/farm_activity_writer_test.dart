import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/features/voice_entry/models/farm_activity_draft.dart';
import 'package:prawn_farm_app/features/voice_entry/services/farm_activity_writer.dart';
import '../helpers/recording_farm_activity_repository.dart';
import '../helpers/test_ponds.dart';

void main() {
  final now = DateTime(2026, 9, 11, 10);
  final ponds = demoPonds();

  FarmActivityWriter writer(RecordingFarmActivityRepository repo) {
    return FarmActivityWriter(repository: repo, farmId: () => 'farm-1');
  }

  test('refuses invalid drafts', () async {
    final repo = RecordingFarmActivityRepository();
    await expectLater(
      writer(repo).save(
        FeedActivityDraft(rawTranscript: 'x', occurredAt: now),
        ponds: ponds,
      ),
      throwsA(isA<StateError>()),
    );
    expect(repo.writeCount, 0);
  });

  test('writes a confirmed feed log', () async {
    final repo = RecordingFarmActivityRepository();
    await writer(repo).save(
      FeedActivityDraft(
        rawTranscript: 'ignored',
        occurredAt: now,
        pondId: 'p2',
        quantityKg: 45,
        feedType: 'pellet feed',
        trayStatus: FeedTrayStatus.empty,
      ),
      ponds: ponds,
    );
    expect(repo.feedLogs, hasLength(1));
    expect(repo.feedLogs.single.pondId, 'p2');
    expect(repo.feedLogs.single.quantityKg, 45);
    expect(repo.feedLogs.single.feedType, 'pellet feed');
    expect(repo.feedLogs.single.trayStatus, FeedTrayStatus.empty);
    expect(repo.feedLogs.single.farmId, 'farm-1');
    expect(repo.waterLogs, isEmpty);
  });

  test('writes a confirmed water log without zero-filling extras', () async {
    final repo = RecordingFarmActivityRepository();
    await writer(repo).save(
      WaterQualityActivityDraft(
        rawTranscript: 'ignored',
        occurredAt: now,
        pondId: 'p1',
        ph: 8.1,
        dissolvedOxygen: 5.2,
        temperatureC: 29,
        salinityPpt: 14,
        ammoniaPpm: 0.05,
        hardnessMgL: 120,
      ),
      ponds: ponds,
    );
    expect(repo.waterLogs, hasLength(1));
    final log = repo.waterLogs.single;
    expect(log.ph, 8.1);
    expect(log.ammoniaPpm, 0.05);
    expect(log.feedKg, 0);
    expect(log.mortalityCount, 0);
  });

  test('writes growth sample and pond summary via existing analysis', () async {
    final repo = RecordingFarmActivityRepository();
    await writer(repo).save(
      GrowthActivityDraft(
        rawTranscript: 'ignored',
        occurredAt: now,
        pondId: 'p3',
        avgBodyWeightGrams: 24,
        survivalPercent: 85,
        sampleSize: 100,
      ),
      ponds: ponds,
    );
    expect(repo.growthSamples, hasLength(1));
    expect(repo.growthSamples.single.avgBodyWeightGrams, 24);
    expect(repo.growthSamples.single.sampleSize, 100);
    expect(repo.pondSummaries.single, isNotNull);
    expect(repo.pondSummaries.single!['survivalPercent'], 85);
  });

  test('writes mortality log', () async {
    final repo = RecordingFarmActivityRepository();
    await writer(repo).save(
      MortalityActivityDraft(
        rawTranscript: 'ignored',
        occurredAt: now,
        pondId: 'p2',
        count: 12,
        reason: 'low DO',
      ),
      ponds: ponds,
    );
    expect(repo.mortalityLogs.single.count, 12);
    expect(repo.mortalityLogs.single.reason, 'low DO');
  });

  test('unknown activity cannot be saved', () async {
    final repo = RecordingFarmActivityRepository();
    await expectLater(
      writer(repo).save(
        UnknownActivityDraft(rawTranscript: 'hello', occurredAt: now),
        ponds: ponds,
      ),
      throwsA(isA<StateError>()),
    );
    expect(repo.writeCount, 0);
  });
}
