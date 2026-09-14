import 'ios_english_stt_corpus.dart';
import 'stt_transcript_scorer.dart';

class SttLocaleLabPhraseResult {
  const SttLocaleLabPhraseResult({
    required this.phraseId,
    required this.expected,
    required this.heard,
    required this.score,
  });

  final String phraseId;
  final String expected;
  final String heard;
  final SttPhraseScore score;
}

/// In-memory locale lab results. Never written to Firestore.
class SttLocaleLabSessionStore {
  SttLocaleLabSessionStore({
    this.corpus = iosEnglishSttCorpus,
    this.scorer = const SttTranscriptScorer(),
  });

  final List<IosEnglishSttPhrase> corpus;
  final SttTranscriptScorer scorer;

  /// localeId → phrase results for the latest completed run of that locale.
  final Map<String, List<SttLocaleLabPhraseResult>> _byLocale = {};

  Map<String, List<SttLocaleLabPhraseResult>> get resultsByLocale =>
      Map.unmodifiable(_byLocale);

  void clearLocale(String localeId) {
    _byLocale.remove(localeId);
  }

  void clearAll() => _byLocale.clear();

  SttLocaleLabPhraseResult record({
    required String localeId,
    required IosEnglishSttPhrase phrase,
    required String heard,
  }) {
    final score = scorer.score(
      expected: phrase.expectedTranscript,
      heard: heard,
    );
    final result = SttLocaleLabPhraseResult(
      phraseId: phrase.id,
      expected: phrase.expectedTranscript,
      heard: heard,
      score: score,
    );
    final list = _byLocale.putIfAbsent(localeId, () => []);
    final index = list.indexWhere((r) => r.phraseId == phrase.id);
    if (index >= 0) {
      list[index] = result;
    } else {
      list.add(result);
    }
    return result;
  }

  SttLocaleSessionSummary? summaryFor(String localeId) {
    final list = _byLocale[localeId];
    if (list == null || list.isEmpty) return null;
    return scorer.summarize(
      localeId: localeId,
      scores: list.map((r) => r.score).toList(),
    );
  }

  List<SttLocaleSessionSummary> allSummaries() {
    return _byLocale.keys
        .map(summaryFor)
        .whereType<SttLocaleSessionSummary>()
        .toList()
      ..sort((a, b) => a.localeId.compareTo(b.localeId));
  }

  String buildReport() {
    final buffer = StringBuffer();
    buffer.writeln('STT Locale Lab report');
    buffer.writeln('corpus=${corpus.length} phrases');
    buffer.writeln('');
    for (final summary in allSummaries()) {
      buffer.writeln(
        '${summary.localeId}: '
        'n=${summary.phraseCount} '
        'exact=${_pct(summary.exactRate)} '
        'tokenRecall=${_pct(summary.meanTokenRecall)} '
        'werProxy=${_pct(summary.meanWerProxy)}',
      );
      final rows = _byLocale[summary.localeId] ?? const [];
      for (final row in rows) {
        buffer.writeln(
          '  [${row.phraseId}] '
          'exact=${row.score.exactMatch} '
          'recall=${_pct(row.score.tokenRecall)} '
          'wer=${_pct(row.score.werProxy)}',
        );
        buffer.writeln('    expected: ${row.expected}');
        buffer.writeln('    heard:    ${row.heard}');
      }
      buffer.writeln('');
    }
    return buffer.toString().trimRight();
  }

  static String _pct(double value) => '${(value * 100).toStringAsFixed(0)}%';
}
