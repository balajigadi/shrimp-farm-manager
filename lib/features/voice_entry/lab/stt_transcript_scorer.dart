import 'package:prawn_farm_app/features/voice_entry/services/pond_resolver.dart';

/// Light scoring normalize only — not FarmSpeechNormalizer.
String scoreNormalize(String raw) {
  return raw.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

class SttPhraseScore {
  const SttPhraseScore({
    required this.exactMatch,
    required this.tokenRecall,
    required this.werProxy,
  });

  final bool exactMatch;

  /// Fraction of expected tokens found in heard (order-insensitive bag).
  final double tokenRecall;

  /// Token-sequence Levenshtein / max(len), 0 = identical, 1 = totally different.
  final double werProxy;
}

class SttLocaleSessionSummary {
  const SttLocaleSessionSummary({
    required this.localeId,
    required this.phraseCount,
    required this.exactRate,
    required this.meanTokenRecall,
    required this.meanWerProxy,
  });

  final String localeId;
  final int phraseCount;
  final double exactRate;
  final double meanTokenRecall;
  final double meanWerProxy;
}

/// Deterministic STT transcript comparison for locale lab runs.
class SttTranscriptScorer {
  const SttTranscriptScorer();

  SttPhraseScore score({required String expected, required String heard}) {
    final e = scoreNormalize(expected);
    final h = scoreNormalize(heard);
    if (e.isEmpty && h.isEmpty) {
      return const SttPhraseScore(
        exactMatch: true,
        tokenRecall: 1,
        werProxy: 0,
      );
    }
    final exact = e == h;
    final expectedTokens = e.isEmpty ? <String>[] : e.split(' ');
    final heardTokens = h.isEmpty ? <String>[] : h.split(' ');
    final heardBag = heardTokens.toSet();
    final recall = expectedTokens.isEmpty
        ? 1.0
        : expectedTokens.where(heardBag.contains).length /
              expectedTokens.length;
    final maxLen = expectedTokens.length > heardTokens.length
        ? expectedTokens.length
        : heardTokens.length;
    final distance = _tokenLevenshtein(expectedTokens, heardTokens);
    final wer = maxLen == 0 ? 0.0 : distance / maxLen;
    return SttPhraseScore(
      exactMatch: exact,
      tokenRecall: recall,
      werProxy: wer.clamp(0.0, 1.0),
    );
  }

  SttLocaleSessionSummary summarize({
    required String localeId,
    required List<SttPhraseScore> scores,
  }) {
    if (scores.isEmpty) {
      return SttLocaleSessionSummary(
        localeId: localeId,
        phraseCount: 0,
        exactRate: 0,
        meanTokenRecall: 0,
        meanWerProxy: 0,
      );
    }
    final exacts = scores.where((s) => s.exactMatch).length;
    final recallSum = scores.fold<double>(0, (a, s) => a + s.tokenRecall);
    final werSum = scores.fold<double>(0, (a, s) => a + s.werProxy);
    return SttLocaleSessionSummary(
      localeId: localeId,
      phraseCount: scores.length,
      exactRate: exacts / scores.length,
      meanTokenRecall: recallSum / scores.length,
      meanWerProxy: werSum / scores.length,
    );
  }

  static int _tokenLevenshtein(List<String> a, List<String> b) {
    if (a.length == 1 && b.length == 1) {
      return PondResolver.levenshtein(a.first, b.first) == 0 ? 0 : 1;
    }
    // Sequence edit distance treating each token as a symbol.
    final prev = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      var diagonal = prev[0];
      prev[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final temp = prev[j];
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final del = prev[j] + 1;
        final ins = prev[j - 1] + 1;
        final sub = diagonal + cost;
        prev[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
        diagonal = temp;
      }
    }
    return prev[b.length];
  }
}
