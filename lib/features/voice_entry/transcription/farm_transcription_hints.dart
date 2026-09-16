import '../services/voice_speech_locale_picker.dart';

/// Domain hints for OpenAI `gpt-transcribe` only — never invent values.
class FarmTranscriptionHints {
  const FarmTranscriptionHints();

  static const vocabulary = <String>[
    'Prawn Farm Manager',
    'pond',
    'tray',
    'feed',
    'ABW',
    'DO',
    'pH',
    'salinity',
    'ammonia',
    'hardness',
    'mortality',
    'survival',
    'growth booster',
    'starter',
    'probiotic',
    'empty',
    'partial',
    'full',
    'kg',
    'kgs',
    'grams',
    'temperature',
    'vesam',
  ];

  String prompt({required List<String> pondNames}) {
    final ponds = pondNames.where((n) => n.trim().isNotEmpty).join(', ');
    final pondClause = ponds.isEmpty
        ? 'Pond names may appear as spoken.'
        : 'Known pond names for this farm: $ponds.';
    return 'Prawn farm activity dictation. '
        'Transcribe the spoken words only. '
        'Do not invent missing numbers, ponds, or tray status. '
        'Do not output JSON or structured farm records. '
        '$pondClause';
  }

  List<String> keywords({required List<String> pondNames}) {
    final out = <String>{...vocabulary};
    for (final name in pondNames) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty) out.add(trimmed);
    }
    return out.toList(growable: false);
  }

  List<String> languagesFor(VoiceLanguagePreference preference) {
    return switch (preference) {
      VoiceLanguagePreference.english => const ['en'],
      VoiceLanguagePreference.telugu => const ['te', 'en'],
      VoiceLanguagePreference.autoMixed => const ['en', 'te'],
    };
  }
}
