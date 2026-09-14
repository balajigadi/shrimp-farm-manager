/// Fixed English phrases for on-device STT locale comparison.
///
/// Testers speak [speakPrompt]; scoring compares raw STT to [expectedTranscript].
/// Does not run FarmSpeechNormalizer — this measures locale fidelity.
class IosEnglishSttPhrase {
  const IosEnglishSttPhrase({
    required this.id,
    required this.speakPrompt,
    required this.expectedTranscript,
  });

  final String id;

  /// What the tester reads aloud.
  final String speakPrompt;

  /// Ideal STT text for scoring (usually same as [speakPrompt]).
  final String expectedTranscript;
}

/// Short fixed English farming corpus for iOS/Android locale lab runs.
const List<IosEnglishSttPhrase> iosEnglishSttCorpus = [
  IosEnglishSttPhrase(
    id: 'en_feed_south_growth_booster',
    speakPrompt: 'South Pond growth booster feed 20 kg tray full',
    expectedTranscript: 'South Pond growth booster feed 20 kg tray full',
  ),
  IosEnglishSttPhrase(
    id: 'en_feed_south_hard_tray',
    speakPrompt: 'South Pond growth booster 20 kg tray full',
    expectedTranscript: 'South Pond growth booster 20 kg tray full',
  ),
  IosEnglishSttPhrase(
    id: 'en_growth_pond3_abw',
    speakPrompt: 'Pond 3 sample ABW 24 grams survival 85 percent',
    expectedTranscript: 'Pond 3 sample ABW 24 grams survival 85 percent',
  ),
  IosEnglishSttPhrase(
    id: 'en_mortality_pond2',
    speakPrompt: 'Pond 2 mortality 12',
    expectedTranscript: 'Pond 2 mortality 12',
  ),
  IosEnglishSttPhrase(
    id: 'en_water_spoken_decimal',
    speakPrompt: 'South pond salinity 14 ammonia point zero five',
    expectedTranscript: 'South pond salinity 14 ammonia point zero five',
  ),
  IosEnglishSttPhrase(
    id: 'en_water_full_params',
    speakPrompt:
        'Pond 1 pH 8.1 DO 5.2 temperature 29 salinity 14 ammonia 0.05 hardness 120',
    expectedTranscript:
        'Pond 1 pH 8.1 DO 5.2 temperature 29 salinity 14 ammonia 0.05 hardness 120',
  ),
  IosEnglishSttPhrase(
    id: 'en_feed_pond2_empty',
    speakPrompt: 'Pond 2 morning feed 45 kilos tray empty',
    expectedTranscript: 'Pond 2 morning feed 45 kilos tray empty',
  ),
];
