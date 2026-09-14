import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/lab/stt_transcript_scorer.dart';

void main() {
  const scorer = SttTranscriptScorer();

  test('exact match scores perfectly', () {
    final score = scorer.score(
      expected: 'South Pond growth booster feed 20 kg tray full',
      heard: 'south pond growth booster feed 20 kg tray full',
    );
    expect(score.exactMatch, isTrue);
    expect(score.tokenRecall, 1);
    expect(score.werProxy, 0);
  });

  test('South Point vs South Pond is not exact and has high recall', () {
    final score = scorer.score(
      expected: 'South Pond growth booster 20 kg tray full',
      heard: 'South Point growth booster 20 kg tray full',
    );
    expect(score.exactMatch, isFalse);
    expect(score.tokenRecall, greaterThan(0.8));
    expect(score.werProxy, greaterThan(0));
    expect(score.werProxy, lessThan(0.3));
  });

  test('empty heard has zero recall', () {
    final score = scorer.score(expected: 'Pond 2 mortality 12', heard: '');
    expect(score.exactMatch, isFalse);
    expect(score.tokenRecall, 0);
    expect(score.werProxy, 1);
  });

  test('session summary aggregates rates', () {
    final scores = [
      scorer.score(expected: 'a b c', heard: 'a b c'),
      scorer.score(expected: 'a b c', heard: 'a b x'),
    ];
    final summary = scorer.summarize(localeId: 'en_IN', scores: scores);
    expect(summary.localeId, 'en_IN');
    expect(summary.phraseCount, 2);
    expect(summary.exactRate, 0.5);
    expect(summary.meanTokenRecall, greaterThan(0.5));
  });
}
