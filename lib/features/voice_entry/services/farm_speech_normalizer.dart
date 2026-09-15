import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'pond_resolver.dart';

/// One debug-only STT correction recorded by [FarmSpeechNormalizer].
class VoiceNormalizerCorrection {
  const VoiceNormalizerCorrection({
    required this.kind,
    required this.from,
    required this.to,
  });

  final String kind;
  final String from;
  final String to;
}

/// Result of conservative STT preprocessing. Does not replace [rawTranscript].
class FarmSpeechNormalization {
  final String rawTranscript;
  final String normalizedTranscript;

  const FarmSpeechNormalization({
    required this.rawTranscript,
    required this.normalizedTranscript,
  });
}

/// Farming-domain STT corrections only. No unrestricted translation.
class FarmSpeechNormalizer {
  const FarmSpeechNormalizer();

  /// Debug-only correction log. Cleared by tests; never written to Firestore.
  @visibleForTesting
  static final List<VoiceNormalizerCorrection> debugCorrections = [];

  static const maxPondEditDistance = 3;

  static final _quantityPrefix = RegExp(
    r'\b([A-Za-z])(\d+(?:\.\d+)?)\s*(kgs?|kilos?|kilograms?|kg)\b',
    caseSensitive: false,
  );

  static final _pondIdToken = RegExp(r'^[A-Za-z]\d+$');

  /// Plausible directional pond spans only — never every "point" in a sentence.
  static final _namedPondSpan = RegExp(
    r'\b((?:south|north|east|west|nursery)\s+(?:pond|point))\b',
    caseSensitive: false,
  );

  /// Telugu script farming phrases, longest first. Not a general translator.
  static const _teluguPhrases = <List<String>>[
    ['ట్రే లో కొంచెం ఉంది', 'tray partial'],
    ['కొంచెం మిగిలింది', 'tray partial'],
    ['ట్రే నిండింది', 'tray full'],
    ['ట్రే ఖాళీ', 'tray empty'],
    ['ట్రే ఎంప్టీ', 'tray empty'],
    ['ట్రే ఫుల్', 'tray full'],
    ['రెండో పాండ్', 'pond 2'],
    ['రెండవ పాండ్', 'pond 2'],
    ['మూడో పాండ్', 'pond 3'],
    ['మూడవ పాండ్', 'pond 3'],
    ['సౌత్ పాండ్', 'south pond'],
    ['గ్రోత్ బూస్టర్', 'growth booster'],
    ['ఏబీడబ్ల్యూ', 'abw'],
    ['సర్వైవల్', 'survival'],
    ['శాంప్లింగ్', 'sample'],
    ['శాంపిల్', 'sample'],
    ['గ్రాములు', 'grams'],
    ['పర్సెంట్', 'percent'],
    ['చనిపోయినవి', 'mortality'],
    ['చనిపోయాయి', 'mortality'],
    ['పీహెచ్', 'ph'],
    ['డీఓ', 'do'],
    ['టెంపరేచర్', 'temperature'],
    ['సాలినిటీ', 'salinity'],
    ['అమోనియా', 'ammonia'],
    ['హార్డ్నెస్', 'hardness'],
    ['మధ్యాహ్నం', 'afternoon'],
    ['సాయంత్రం', 'evening'],
    ['ఉదయం', 'morning'],
    ['రాత్రి', 'night'],
    ['వేశాము', 'vesam'],
    ['వేశాం', 'vesam'],
    ['వేసాం', 'vesam'],
    ['కిలోలు', 'kg'],
    ['కిలోల', 'kg'],
    ['కిలో', 'kg'],
    ['ఫీడ్', 'feed'],
    ['పాండ్', 'pond'],
    ['చెరువు', 'pond'],
    ['రొయ్యలు', 'prawns'],
    ['ఒకటి', '1'],
    ['రెండు', '2'],
    ['మూడు', '3'],
    ['పది', '10'],
    ['ఇరవై', '20'],
    ['ముప్పై', '30'],
    ['నలభై', '40'],
    ['యాభై', '50'],
  ];

  static const _trayFullVariants = <List<String>>[
    [r'\bstraight\s+full\b', 'straight full'],
    [r'\bspray\s+full\b', 'spray full'],
    [r'\btrade\s+full\b', 'trade full'],
    [r'\bstray\s+full\b', 'stray full'],
    [r'\bpray\s+full\b', 'pray full'],
    [r'\bprayful\b', 'prayful'],
    [r'\btrayful\b', 'trayful'],
    [r'\bstrayful\b', 'strayful'],
    [r'\bsprayful\b', 'sprayful'],
  ];

  FarmSpeechNormalization normalize(String raw, {List<Pond> ponds = const []}) {
    final original = raw.trim();
    var text = original;
    if (text.isEmpty) {
      return FarmSpeechNormalization(
        rawTranscript: original,
        normalizedTranscript: original,
      );
    }

    text = _applyTeluguPhrases(text);
    text = _applyLatinFarmingPhrases(text);
    text = _normalizeNumberWords(text);
    text = _normalizeSpokenDecimals(text);
    text = _normalizeQuantityPrefix(text, ponds);
    text = _normalizeConcatenatedPondQuantity(text, ponds);
    text = _normalizeTrayPhrases(text);
    text = _rewriteUniqueNamedPonds(text, ponds);

    return FarmSpeechNormalization(
      rawTranscript: original,
      normalizedTranscript: text,
    );
  }

  static String _applyTeluguPhrases(String text) {
    var out = text;
    for (final pair in _teluguPhrases) {
      out = out.replaceAll(pair[0], pair[1]);
    }
    return out;
  }

  /// Specific Latin / romanized farming tokens. No global word swaps.
  static String _applyLatinFarmingPhrases(String text) {
    var out = text;
    out = out.replaceAll(
      RegExp(r'\bthird\s+pond\b', caseSensitive: false),
      'pond 3',
    );
    out = out.replaceAll(
      RegExp(r'\bsecond\s+pond\b', caseSensitive: false),
      'pond 2',
    );
    out = out.replaceAll(
      RegExp(r'\bfirst\s+pond\b', caseSensitive: false),
      'pond 1',
    );
    out = out.replaceAll(
      RegExp(r'\bchanipoyina\b', caseSensitive: false),
      'mortality',
    );
    out = out.replaceAll(
      RegExp(r'\bchanipoyayi\b', caseSensitive: false),
      'mortality',
    );
    out = out.replaceAll(
      RegExp(r'\budayam\b', caseSensitive: false),
      'morning',
    );
    out = out.replaceAll(
      RegExp(r'\bmadhyanam\b', caseSensitive: false),
      'afternoon',
    );
    out = out.replaceAll(
      RegExp(r'\bsayamtram\b', caseSensitive: false),
      'evening',
    );
    out = out.replaceAll(RegExp(r'\bratri\b', caseSensitive: false), 'night');
    out = out.replaceAll(
      RegExp(r'\bvesamandi\b', caseSensitive: false),
      'vesam',
    );
    out = out.replaceAll(RegExp(r'\bvesamu\b', caseSensitive: false), 'vesam');
    out = out.replaceAll(RegExp(r'\bvesina\b', caseSensitive: false), 'vesam');
    out = out.replaceAll(RegExp(r'\bdee\s+oh\b', caseSensitive: false), 'do');
    out = out.replaceAll(RegExp(r'\ba\s+b\s+w\b', caseSensitive: false), 'abw');
    out = out.replaceAll(
      RegExp(r'\baverage\s+body\s+weight\b', caseSensitive: false),
      'abw',
    );
    out = out.replaceAll(
      RegExp(r'\baverage\s+weight\b', caseSensitive: false),
      'abw',
    );
    out = out.replaceAll(
      RegExp(r'\btray\s+lo\s+konchem\s+undi\b', caseSensitive: false),
      'tray partial',
    );
    out = out.replaceAll(
      RegExp(r'\bkonchem\s+migilindi\b', caseSensitive: false),
      'tray partial',
    );
    out = out.replaceAll(
      RegExp(r'\btray\s+nindindi\b', caseSensitive: false),
      'tray full',
    );
    out = out.replaceAll(
      RegExp(r'\bkhali\s+tray\b', caseSensitive: false),
      'tray empty',
    );
    out = out.replaceAll(
      RegExp(r'\btray\s+khali\b', caseSensitive: false),
      'tray empty',
    );
    return out;
  }

  /// Small spoken counts only. Skip when the word is a pond ordinal.
  static String _normalizeNumberWords(String text) {
    const words = <String, String>{
      'okati': '1',
      'rendu': '2',
      'moodu': '3',
      'padi': '10',
      'iravai': '20',
      'muppai': '30',
      'nalabai': '40',
      'yabhai': '50',
    };
    return text.replaceAllMapped(
      RegExp(
        r'\b(okati|rendu|moodu|padi|iravai|muppai|nalabai|yabhai)\b(?!\s+pond\b)',
        caseSensitive: false,
      ),
      (match) => words[match.group(1)!.toLowerCase()] ?? match.group(1)!,
    );
  }

  /// Conservative spoken decimals only. Does not rewrite every "point".
  static String _normalizeSpokenDecimals(String text) {
    return text.replaceAll(
      RegExp(r'\b(?:zero\s+)?point\s+zero\s+five\b', caseSensitive: false),
      '0.05',
    );
  }

  /// "C20 kg" → "20 kg". Letter prefixes only before a kg quantity.
  /// Known pond ids such as A1 / B2 / C3 are left untouched.
  static String _normalizeQuantityPrefix(String text, List<Pond> ponds) {
    final protected = _protectedPondIdTokens(ponds);
    return text.replaceAllMapped(_quantityPrefix, (match) {
      final letter = match.group(1)!;
      final number = match.group(2)!;
      final unit = match.group(3)!;
      final glued = '$letter$number';
      if (protected.contains(glued.toLowerCase())) {
        return match.group(0)!;
      }
      final corrected = '$number $unit';
      _logCorrection('quantity', match.group(0)!, corrected);
      return corrected;
    });
  }

  static Set<String> _protectedPondIdTokens(List<Pond> ponds) {
    final out = <String>{};
    for (final pond in ponds) {
      final name = pond.name.trim();
      if (name.isEmpty) continue;
      if (_pondIdToken.hasMatch(name)) {
        out.add(name.toLowerCase());
      }
      for (final token in name.split(RegExp(r'\s+'))) {
        if (_pondIdToken.hasMatch(token)) {
          out.add(token.toLowerCase());
        }
      }
    }
    return out;
  }

  /// Tray STT variants, only when the utterance already looks like feed/tray.
  static String _normalizeTrayPhrases(String text) {
    if (!_isFeedOrTrayContext(text)) return text;
    var out = text;
    for (final variant in _trayFullVariants) {
      final pattern = RegExp(variant[0], caseSensitive: false);
      out = out.replaceAllMapped(pattern, (match) {
        _logCorrection('tray', match.group(0)!, 'tray full');
        return 'tray full';
      });
    }
    out = out.replaceAllMapped(
      RegExp(r'\btray\s+clean\b', caseSensitive: false),
      (match) {
        _logCorrection('tray', match.group(0)!, 'tray empty');
        return 'tray empty';
      },
    );
    out = out.replaceAllMapped(RegExp(r'\bre\s+enti\b', caseSensitive: false), (
      match,
    ) {
      _logCorrection('tray', match.group(0)!, 'tray empty');
      return 'tray empty';
    });
    out = out.replaceAllMapped(
      RegExp(r'\bre\s+empty\b', caseSensitive: false),
      (match) {
        _logCorrection('tray', match.group(0)!, 'tray empty');
        return 'tray empty';
      },
    );
    return out;
  }

  static bool _isFeedOrTrayContext(String text) {
    final lower = text.toLowerCase();
    return RegExp(
          r'\b(kg|kgs|kilos?|kilograms?|feed|vesam|vesamu|vesina|vesamandi|tray)\b',
        ).hasMatch(lower) ||
        _quantityPrefix.hasMatch(text);
  }

  /// "pond 245 kgs" → "pond 2 45 kgs" when exactly one known pond-number prefix
  /// yields a positive quantity suffix. Never splits bare quantities.
  static String _normalizeConcatenatedPondQuantity(
    String text,
    List<Pond> ponds,
  ) {
    final pondIds = _numericPondIds(ponds);
    if (pondIds.isEmpty) return text;
    return text.replaceAllMapped(
      RegExp(
        r'\bpond\s+(\d+)\s*(kgs?|kilos?|kilograms?|kg)\b',
        caseSensitive: false,
      ),
      (match) {
        final digits = match.group(1)!;
        final unit = match.group(2)!;
        final splits = <({String pondId, String qty})>[];
        for (final id in pondIds) {
          if (!digits.startsWith(id) || digits.length <= id.length) continue;
          final qty = digits.substring(id.length);
          final value = double.tryParse(qty);
          if (value == null || value <= 0) continue;
          // Reject leading-zero quirks like pond 20 + "05" from "2005" — allow
          // only when qty has no pointless leading zero unless decimal.
          if (qty.length > 1 && qty.startsWith('0') && !qty.startsWith('0.')) {
            continue;
          }
          splits.add((pondId: id, qty: qty));
        }
        if (splits.length != 1) return match.group(0)!;
        final split = splits.single;
        final corrected = 'pond ${split.pondId} ${split.qty} $unit';
        _logCorrection('pond_qty', match.group(0)!, corrected);
        return corrected;
      },
    );
  }

  /// Numeric ids from names like "Pond 2" / "pond 24" only.
  static List<String> _numericPondIds(List<Pond> ponds) {
    final ids = <String>[];
    final pattern = RegExp(r'^pond\s+(\d+)$', caseSensitive: false);
    for (final pond in ponds) {
      final match = pattern.firstMatch(pond.name.trim());
      if (match != null) {
        ids.add(match.group(1)!);
      }
    }
    return ids;
  }

  /// Rewrites a directional "… pond/point" span only when one known pond is a
  /// clear Levenshtein match (distance <= 3). Never rewrites every "point".
  String _rewriteUniqueNamedPonds(String text, List<Pond> ponds) {
    if (ponds.isEmpty) return text;
    return text.replaceAllMapped(_namedPondSpan, (match) {
      final span = match.group(0)!;
      final corrected = _bestPondNameCorrection(span, ponds);
      if (corrected != null && corrected.toLowerCase() != span.toLowerCase()) {
        _logCorrection('pond', span, corrected);
        return corrected;
      }
      return span;
    });
  }

  /// Exact match wins. Otherwise require Levenshtein <= 3 against an actual
  /// pond name, with exactly one clear acceptable candidate.
  String? _bestPondNameCorrection(String span, List<Pond> ponds) {
    final spanLower = span.toLowerCase();

    final exact = ponds
        .where((p) => p.name.trim().toLowerCase() == spanLower)
        .toList();
    if (exact.length == 1) return exact.first.name;
    if (exact.length > 1) return null;

    final candidates = <Pond>[];
    for (final pond in ponds) {
      final name = pond.name.trim();
      if (name.isEmpty) continue;
      final nameLower = name.toLowerCase();
      final distance = PondResolver.levenshtein(spanLower, nameLower);
      final prefixRelated =
          nameLower.startsWith(spanLower) || spanLower.startsWith(nameLower);
      if (distance <= maxPondEditDistance ||
          (prefixRelated && spanLower.length >= 4)) {
        candidates.add(pond);
      }
    }

    if (candidates.length == 1) return candidates.first.name;
    return null;
  }

  static void _logCorrection(String kind, String from, String to) {
    assert(() {
      debugCorrections.add(
        VoiceNormalizerCorrection(kind: kind, from: from, to: to),
      );
      developer.log(
        '[VoiceNormalizer] $kind:\n  "$from" -> "$to"',
        name: 'voice_entry',
      );
      return true;
    }());
  }
}
