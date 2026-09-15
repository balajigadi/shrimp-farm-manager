import 'package:prawn_farm_app/features/pond/pond_model.dart';
import '../models/farm_activity_draft.dart';
import 'farm_activity_parser.dart';
import 'farm_activity_validator.dart';
import 'farm_speech_normalizer.dart';
import 'pond_resolver.dart';
import 'voice_entry_debug_log.dart';

/// Deterministic V1 parser for a small English / mixed Telugu-English vocabulary.
class RuleBasedFarmActivityParser implements FarmActivityParser {
  const RuleBasedFarmActivityParser({
    this.pondResolver = const PondResolver(),
    this.normalizer = const FarmSpeechNormalizer(),
  });

  final PondResolver pondResolver;
  final FarmSpeechNormalizer normalizer;

  /// Known feed-type phrases that map to the existing free-text [FeedLog.feedType].
  static const knownFeedTypes = [
    'probiotic starter',
    'growth booster',
    'regular pellet',
    'starter feed',
    'pellet feed',
    'booster feed',
  ];

  static const _sessionWords = {'morning', 'evening', 'afternoon', 'night'};

  static const _feedTypeNoise = {
    'lo',
    'vesam',
    'vesamu',
    'vesina',
    'vesamandi',
    'kg',
    'kilo',
    'kilos',
    'kilogram',
    'kilograms',
    'tray',
    'full',
    'empty',
    'partial',
    'clean',
    'pond',
    'point',
    'undi',
  };

  @override
  Future<FarmActivityDraft> parse(
    String transcript, {
    required List<Pond> ponds,
    DateTime? now,
  }) async {
    final occurredAt = now ?? DateTime.now();
    final raw = transcript.trim();
    if (raw.isEmpty) {
      return UnknownActivityDraft(rawTranscript: raw, occurredAt: occurredAt);
    }

    final normalization = normalizer.normalize(raw, ponds: ponds);
    final lower = normalization.normalizedTranscript.toLowerCase();
    final pondReference = _extractPondReference(lower, ponds);
    final resolved = pondResolver.resolve(pondReference, ponds);
    final pondId = resolved.status == PondResolveStatus.resolved
        ? resolved.pond!.id
        : null;
    final occurred = _applyRelativeDay(lower, occurredAt);

    final type = _detectType(lower);
    final draft = switch (type) {
      FarmActivityType.feed => FeedActivityDraft(
        rawTranscript: raw,
        normalizedTranscript: normalization.normalizedTranscript,
        pondId: pondId,
        pondReference: pondReference,
        occurredAt: occurred,
        quantityKg: _extractQuantityKg(lower),
        feedType: _extractFeedType(lower, pondReference),
        trayStatus: _extractTray(lower),
        session: _extractSession(lower),
      ),
      FarmActivityType.waterQuality => WaterQualityActivityDraft(
        rawTranscript: raw,
        normalizedTranscript: normalization.normalizedTranscript,
        pondId: pondId,
        pondReference: pondReference,
        occurredAt: occurred,
        ph: _labeledNumber(lower, [r'\bph\b', r'\bp\.?\s*h\.?\b']),
        dissolvedOxygen: _labeledNumber(lower, [
          r'\bdissolved oxygen\b',
          r'\bdo\b',
          r'\bd\s+o\b',
        ]),
        temperatureC: _labeledNumber(lower, [r'\btemperature\b', r'\btemp\b']),
        salinityPpt: _labeledNumber(lower, [r'\bsalinity\b']),
        ammoniaPpm: _labeledNumber(lower, [r'\bammonia\b']),
        hardnessMgL: _labeledNumber(lower, [r'\bhardness\b']),
      ),
      FarmActivityType.growth => GrowthActivityDraft(
        rawTranscript: raw,
        normalizedTranscript: normalization.normalizedTranscript,
        pondId: pondId,
        pondReference: pondReference,
        occurredAt: occurred,
        avgBodyWeightGrams: _labeledNumber(lower, [
          r'\babw\b',
          r'\baverage body weight\b',
          r'\bavg body weight\b',
          r'\baverage weight\b',
        ]),
        survivalPercent: _labeledNumber(lower, [r'\bsurvival\b']),
        sampleSize: _labeledNumber(lower, [r'\bsample size\b'])?.round(),
      ),
      FarmActivityType.mortality => MortalityActivityDraft(
        rawTranscript: raw,
        normalizedTranscript: normalization.normalizedTranscript,
        pondId: pondId,
        pondReference: pondReference,
        occurredAt: occurred,
        count: _extractMortalityCount(lower),
        reason: _extractReason(lower),
      ),
      FarmActivityType.unknown => UnknownActivityDraft(
        rawTranscript: raw,
        normalizedTranscript: normalization.normalizedTranscript,
        pondId: pondId,
        pondReference: pondReference,
        occurredAt: occurred,
      ),
    };

    final missing = const FarmActivityValidator()
        .validate(draft)
        .issues
        .map((issue) => issue.field.name)
        .toList();
    VoiceEntryDebugLog.parse(
      rawTranscript: raw,
      normalizedTranscript: normalization.normalizedTranscript,
      draft: draft,
      pond: resolved,
      missingFields: missing,
    );
    return draft;
  }

  FarmActivityType _detectType(String lower) {
    if (RegExp(
      r'\bmortality\b|\bdeaths?\b|\bdead\b|\bdead count\b',
    ).hasMatch(lower)) {
      return FarmActivityType.mortality;
    }
    if (RegExp(
      r'\babw\b|\bsurvival\b|\bsample size\b|\bgrowth sample\b',
    ).hasMatch(lower)) {
      return FarmActivityType.growth;
    }
    if (RegExp(
      r'\bph\b|\bdissolved oxygen\b|\bdo\b|\bd\s+o\b|\bsalinity\b|\bammonia\b|\bhardness\b',
    ).hasMatch(lower)) {
      return FarmActivityType.waterQuality;
    }
    if (RegExp(
      r'\bfeed\b|\bvesam\b|\bvesamu\b|\btray\b|\bkilos?\b|\bkgs?\b|\bkg\b',
    ).hasMatch(lower)) {
      return FarmActivityType.feed;
    }
    return FarmActivityType.unknown;
  }

  String? _extractPondReference(String lower, List<Pond> ponds) {
    final numbered = RegExp(
      r'\bpond\s+(one|two|three|four|five|six|seven|eight|nine|ten|\d+)\b',
    ).firstMatch(lower);
    if (numbered != null) {
      return 'Pond ${numbered.group(1)}';
    }
    final teluguFirst = RegExp(
      r'\b(rendo|rendu|okati|oka|moodu|mudu|mudo)\s+pond\b',
    ).firstMatch(lower);
    if (teluguFirst != null) {
      return '${teluguFirst.group(1)} pond';
    }
    final known = _extractKnownPondName(lower, ponds);
    if (known != null) return known;
    final named = RegExp(
      r'\b((?:south|north|east|west|nursery)\s+(?:pond|point))\b',
    ).firstMatch(lower);
    if (named != null) {
      return named.group(1);
    }
    return null;
  }

  /// After normalization a pond may appear as its real name ("Nursery")
  /// rather than "nursery pond".
  static String? _extractKnownPondName(String lower, List<Pond> ponds) {
    final names =
        ponds.map((p) => p.name.trim()).where((n) => n.isNotEmpty).toList()
          ..sort((a, b) => b.length.compareTo(a.length));
    final hits = <String>[];
    for (final name in names) {
      final pattern = RegExp('\\b${RegExp.escape(name.toLowerCase())}\\b');
      if (pattern.hasMatch(lower)) {
        hits.add(name);
      }
    }
    if (hits.length == 1) return hits.first;
    return null;
  }

  DateTime _applyRelativeDay(String lower, DateTime now) {
    if (RegExp(r'\byesterday\b').hasMatch(lower)) {
      return DateTime(now.year, now.month, now.day - 1, now.hour, now.minute);
    }
    return now;
  }

  double? _extractQuantityKg(String lower) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*(kgs?|kilos?|kilograms?|kg)\b',
    ).firstMatch(lower);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  String? _extractFeedType(String lower, String? pondReference) {
    // Longer known phrases first. Do not invent a type from "morning" or vesam.
    for (final type in knownFeedTypes) {
      if (lower.contains(type)) return type;
    }

    final feedMatch = RegExp(r'\bfeed\b').firstMatch(lower);
    if (feedMatch == null) return null;
    var between = lower.substring(0, feedMatch.start).trim();
    if (pondReference != null &&
        between.contains(pondReference.toLowerCase())) {
      final ref = pondReference.toLowerCase();
      between = between.substring(between.indexOf(ref) + ref.length).trim();
    }
    final tokens = between
        .split(RegExp(r'\s+'))
        .where(
          (t) =>
              t.isNotEmpty &&
              !_sessionWords.contains(t) &&
              !_feedTypeNoise.contains(t) &&
              double.tryParse(t) == null,
        )
        .toList();
    if (tokens.isEmpty) return null;
    final candidate = tokens.join(' ');
    for (final type in knownFeedTypes) {
      if (candidate == type ||
          (type.startsWith(candidate) && candidate.length >= 8)) {
        return type;
      }
    }
    return null;
  }

  String? _extractSession(String lower) {
    if (RegExp(r'\bmorning\b').hasMatch(lower)) return 'morning';
    if (RegExp(r'\bevening\b').hasMatch(lower)) return 'evening';
    if (RegExp(r'\bafternoon\b').hasMatch(lower)) return 'afternoon';
    if (RegExp(r'\bnight\b').hasMatch(lower)) return 'night';
    return null;
  }

  FeedTrayStatus? _extractTray(String lower) {
    if (RegExp(
      r'\btray\s+empty\b|\bempty\s+tray\b|\btray empty\b',
    ).hasMatch(lower)) {
      return FeedTrayStatus.empty;
    }
    if (lower.contains('empty') && lower.contains('tray')) {
      return FeedTrayStatus.empty;
    }
    if (RegExp(r'\bpartial\b').hasMatch(lower)) {
      return FeedTrayStatus.partial;
    }
    if (RegExp(r'\btray\s+full\b|\bfull\s+tray\b').hasMatch(lower)) {
      return FeedTrayStatus.full;
    }
    return null;
  }

  double? _labeledNumber(String lower, List<String> labels) {
    for (final label in labels) {
      final after = RegExp(
        '$label\\s*(?:is|=|:)?\\s*(-?\\d+(?:\\.\\d+)?)',
      ).firstMatch(lower);
      if (after != null) {
        return double.tryParse(after.group(1)!);
      }
      final before = RegExp('(-?\\d+(?:\\.\\d+)?)\\s*$label').firstMatch(lower);
      if (before != null) {
        return double.tryParse(before.group(1)!);
      }
    }
    return null;
  }

  int? _extractMortalityCount(String lower) {
    final afterLabel = RegExp(r'\bmortality\s+(\d+)\b').firstMatch(lower);
    if (afterLabel != null) {
      return int.tryParse(afterLabel.group(1)!);
    }
    final dead = RegExp(r'\b(\d+)\s+(?:dead|deaths)\b').firstMatch(lower);
    if (dead != null) {
      return int.tryParse(dead.group(1)!);
    }
    final prawns = RegExp(
      r'\b(\d+)\s+prawns?(?:\s+mortality)?\b',
    ).firstMatch(lower);
    if (prawns == null) return null;
    return int.tryParse(prawns.group(1)!);
  }

  String? _extractReason(String lower) {
    final match = RegExp(r'\breason\s+(.+)$').firstMatch(lower);
    if (match == null) return null;
    return match.group(1)!.trim();
  }
}

/// Placeholder only. Must never hold credentials; not used by default.
class RemoteFarmActivityParser implements FarmActivityParser {
  const RemoteFarmActivityParser();

  @override
  Future<FarmActivityDraft> parse(
    String transcript, {
    required List<Pond> ponds,
    DateTime? now,
  }) {
    throw UnsupportedError(
      'Remote LLM parsing is not enabled. Use RuleBasedFarmActivityParser.',
    );
  }
}
