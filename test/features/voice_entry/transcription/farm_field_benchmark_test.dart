import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/features/voice_entry/models/farm_activity_draft.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/farm_field_benchmark.dart';

void main() {
  const bench = FarmFieldBenchmark();
  final now = DateTime.utc(2026, 9, 15);

  test('critical numeric mismatch when 45 becomes 245', () {
    final expected = FeedActivityDraft(
      rawTranscript: 'Feed Pond 2 45 kgs tray empty',
      occurredAt: now,
      pondReference: 'Pond 2',
      quantityKg: 45,
      trayStatus: FeedTrayStatus.empty,
    );
    final actual = FeedActivityDraft(
      rawTranscript: 'Feed Pandu 245 kgs Re enti',
      occurredAt: now,
      pondReference: 'Pond 2',
      quantityKg: 245,
      trayStatus: FeedTrayStatus.empty,
    );
    final score = bench.score(expected: expected, actual: actual);
    expect(score.quantityCorrect, isFalse);
    expect(score.criticalNumericMismatch, isTrue);
    expect(score.correctionsNeeded, greaterThan(0));
  });

  test('pond casing difference is not a numeric failure', () {
    final expected = FeedActivityDraft(
      rawTranscript: 'x',
      occurredAt: now,
      pondReference: 'Pond 2',
      quantityKg: 45,
    );
    final actual = FeedActivityDraft(
      rawTranscript: 'y',
      occurredAt: now,
      pondReference: 'pond 2',
      quantityKg: 45,
    );
    final score = bench.score(expected: expected, actual: actual);
    expect(score.pondCorrect, isTrue);
    expect(score.quantityCorrect, isTrue);
    expect(score.criticalNumericMismatch, isFalse);
  });
}
