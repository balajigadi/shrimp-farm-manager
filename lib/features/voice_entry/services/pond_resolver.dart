import 'dart:math';

import 'package:prawn_farm_app/features/pond/pond_model.dart';

enum PondResolveStatus { resolved, unknown, ambiguous }

enum PondMatchKind { exact, partial, fuzzy }

class PondResolveResult {
  final PondResolveStatus status;
  final Pond? pond;
  final List<Pond> candidates;
  final String heardReference;
  final PondMatchKind? matchKind;

  const PondResolveResult({
    required this.status,
    this.pond,
    this.candidates = const [],
    this.heardReference = '',
    this.matchKind,
  });
}

/// Maps spoken pond references onto the farmer's existing ponds.
class PondResolver {
  const PondResolver();

  /// Similarity floor for non-exact matches. Point/pond on "South Point" vs
  /// "South Pond" scores ~0.82; a different compass pond stays ~0.64.
  static const double minAcceptableScore = 0.75;

  PondResolveResult resolve(String? reference, List<Pond> ponds) {
    final heard = (reference ?? '').trim();
    if (heard.isEmpty || ponds.isEmpty) {
      return PondResolveResult(
        status: PondResolveStatus.unknown,
        heardReference: heard,
        candidates: ponds,
      );
    }

    final scored = [
      for (final pond in ponds)
        (pond: pond, score: scoreAgainst(heard, pond.name)),
    ];

    final exact = scored
        .where((s) => s.score.kind == PondMatchKind.exact)
        .toList();
    if (exact.length == 1) {
      return PondResolveResult(
        status: PondResolveStatus.resolved,
        pond: exact.first.pond,
        candidates: [exact.first.pond],
        heardReference: heard,
        matchKind: PondMatchKind.exact,
      );
    }
    if (exact.length > 1) {
      return PondResolveResult(
        status: PondResolveStatus.ambiguous,
        candidates: exact.map((e) => e.pond).toList(),
        heardReference: heard,
      );
    }

    final good =
        scored.where((s) => s.score.value >= minAcceptableScore).toList()
          ..sort((a, b) => b.score.value.compareTo(a.score.value));

    if (good.isEmpty) {
      return PondResolveResult(
        status: PondResolveStatus.unknown,
        heardReference: heard,
        candidates: ponds,
      );
    }
    if (good.length == 1) {
      return PondResolveResult(
        status: PondResolveStatus.resolved,
        pond: good.first.pond,
        candidates: [good.first.pond],
        heardReference: heard,
        matchKind: good.first.score.kind,
      );
    }
    return PondResolveResult(
      status: PondResolveStatus.ambiguous,
      candidates: good.map((e) => e.pond).toList(),
      heardReference: heard,
    );
  }

  /// Score [heard] against one pond name. Public for tests.
  ///
  /// Generic tokens `pond` / `point` are ignored for edit distance so that
  /// "nursery pond" does not look similar to "south pond". They are still
  /// treated as synonyms when the remaining distinctive tokens match
  /// ("South Point" vs "South Pond").
  static PondNameScore scoreAgainst(String heard, String pondName) {
    final a = normalize(heard);
    final b = normalize(pondName);
    if (a.isEmpty || b.isEmpty) {
      return const PondNameScore(0, PondMatchKind.fuzzy);
    }
    if (a == b) {
      return const PondNameScore(1, PondMatchKind.exact);
    }

    var best = 0.0;
    var kind = PondMatchKind.fuzzy;

    final heardNumber = extractNumber(a);
    final nameNumber = extractNumber(b);
    if (heardNumber != null && heardNumber == nameNumber) {
      best = 0.9;
      kind = PondMatchKind.partial;
    }

    if (a.length >= 4 && (b.contains(a) || a.contains(b))) {
      if (0.92 > best) {
        best = 0.92;
        kind = PondMatchKind.partial;
      }
    }

    final da = _distinctive(a);
    final db = _distinctive(b);
    if (da.isNotEmpty && db.isNotEmpty) {
      if (da == db && 0.88 > best) {
        best = 0.88;
        kind = PondMatchKind.fuzzy;
      }
      final maxLen = max(da.length, db.length);
      final levSim = 1.0 - (levenshtein(da, db) / maxLen);
      if (levSim > best) {
        best = levSim;
        kind = PondMatchKind.fuzzy;
      }
      final tokenSim = _tokenSimilarity(da, db);
      if (tokenSim > best) {
        best = tokenSim;
        kind = PondMatchKind.fuzzy;
      }
    }

    return PondNameScore(best, kind);
  }

  static String _distinctive(String normalized) {
    return normalized
        .split(' ')
        .where((t) => t.isNotEmpty && t != 'pond' && t != 'point')
        .join(' ');
  }

  static String normalize(String raw) {
    var text = raw.toLowerCase().trim();
    const teluguTokens = {
      'పాండ్': 'pond',
      'చెరువు': 'pond',
      'సౌత్': 'south',
      'రెండో': '2',
      'రెండవ': '2',
      'మూడో': '3',
      'మూడవ': '3',
    };
    for (final entry in teluguTokens.entries) {
      text = text.replaceAll(entry.key, ' ${entry.value} ');
    }
    text = text.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    const words = {
      'one': '1',
      'two': '2',
      'three': '3',
      'four': '4',
      'five': '5',
      'six': '6',
      'seven': '7',
      'eight': '8',
      'nine': '9',
      'ten': '10',
      'first': '1',
      'second': '2',
      'third': '3',
      'okati': '1',
      'oka': '1',
      'rendu': '2',
      'rendo': '2',
      'moodu': '3',
      'mudu': '3',
      'mudo': '3',
    };
    final parts = text.split(' ').map((w) => words[w] ?? w).toList();
    return parts.join(' ');
  }

  static int? extractNumber(String normalized) {
    final match = RegExp(r'\b(\d+)\b').firstMatch(normalized);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final prev = List<int>.generate(b.length + 1, (j) => j);
    for (var i = 1; i <= a.length; i++) {
      var diagonal = prev[0];
      prev[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final temp = prev[j];
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        prev[j] = min(prev[j] + 1, min(prev[j - 1] + 1, diagonal + cost));
        diagonal = temp;
      }
    }
    return prev[b.length];
  }

  static double _tokenSimilarity(String a, String b) {
    final aTokens = a.split(' ').where((t) => t.isNotEmpty).toList();
    final bTokens = b.split(' ').where((t) => t.isNotEmpty).toList();
    if (aTokens.isEmpty || bTokens.isEmpty) return 0;
    var sum = 0.0;
    for (final token in aTokens) {
      var best = 0.0;
      for (final other in bTokens) {
        final maxLen = max(token.length, other.length);
        if (maxLen == 0) continue;
        final sim = 1.0 - (levenshtein(token, other) / maxLen);
        if (sim > best) best = sim;
      }
      sum += best;
    }
    return sum / aTokens.length;
  }
}

class PondNameScore {
  final double value;
  final PondMatchKind kind;

  const PondNameScore(this.value, this.kind);
}
