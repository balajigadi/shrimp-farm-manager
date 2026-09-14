import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/features/voice_entry/models/farm_activity_draft.dart';
import '../features/voice_entry/helpers/test_ponds.dart';

enum VoicePhraseCategory {
  english,
  teluguEnglishMixed,
  teluguScript,
  realDeviceFailures,
}

/// Fields the parser must leave empty — never invent values.
enum VoiceMustBeMissing {
  quantityKg,
  feedType,
  trayStatus,
  session,
  ph,
  dissolvedOxygen,
  temperatureC,
  salinityPpt,
  ammoniaPpm,
  hardnessMgL,
  avgBodyWeightGrams,
  survivalPercent,
  sampleSize,
  mortalityCount,
  pondId,
}

class VoicePhraseCase {
  const VoicePhraseCase({
    required this.id,
    required this.category,
    required this.spokenIntentDescription,
    required this.rawSttTranscript,
    required this.expectedActivity,
    this.knownPonds,
    this.expectedPondId,
    this.expectedQuantityKg,
    this.expectedFeedType,
    this.expectedTray,
    this.expectedSession,
    this.expectedPh,
    this.expectedDissolvedOxygen,
    this.expectedTemperatureC,
    this.expectedSalinityPpt,
    this.expectedAmmoniaPpm,
    this.expectedHardnessMgL,
    this.expectedAvgBodyWeightGrams,
    this.expectedSurvivalPercent,
    this.expectedSampleSize,
    this.expectedMortalityCount,
    this.mustBeMissing = const {},
  });

  final String id;
  final VoicePhraseCategory category;
  final String spokenIntentDescription;
  final String rawSttTranscript;
  final FarmActivityType expectedActivity;
  final List<Pond>? knownPonds;
  final String? expectedPondId;
  final double? expectedQuantityKg;
  final String? expectedFeedType;
  final FeedTrayStatus? expectedTray;
  final String? expectedSession;
  final double? expectedPh;
  final double? expectedDissolvedOxygen;
  final double? expectedTemperatureC;
  final double? expectedSalinityPpt;
  final double? expectedAmmoniaPpm;
  final double? expectedHardnessMgL;
  final double? expectedAvgBodyWeightGrams;
  final double? expectedSurvivalPercent;
  final int? expectedSampleSize;
  final int? expectedMortalityCount;
  final Set<VoiceMustBeMissing> mustBeMissing;

  List<Pond> ponds() => knownPonds ?? demoPonds();
}

/// Regression corpus for English, Telugu-English mixed, Telugu script, and
/// real-device STT failures. This is initial farming-vocabulary coverage,
/// not a claim of general Telugu NLP.
final List<VoicePhraseCase> voiceEntryPhraseCorpus = [
  ..._english,
  ..._teluguEnglishMixed,
  ..._teluguScript,
  ..._realDeviceFailures,
];

const _incompleteFeed = {
  VoiceMustBeMissing.quantityKg,
  VoiceMustBeMissing.feedType,
  VoiceMustBeMissing.trayStatus,
};

const _waterPartialMissing = {
  VoiceMustBeMissing.temperatureC,
  VoiceMustBeMissing.salinityPpt,
  VoiceMustBeMissing.ammoniaPpm,
  VoiceMustBeMissing.hardnessMgL,
};

final _english = <VoicePhraseCase>[
  VoicePhraseCase(
    id: 'en_feed_south_growth_booster',
    category: VoicePhraseCategory.english,
    spokenIntentDescription:
        'South Pond growth booster feed 20 kg with tray full',
    rawSttTranscript: 'South Pond growth booster feed 20 kg tray full',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'ps',
    expectedQuantityKg: 20,
    expectedFeedType: 'growth booster',
    expectedTray: FeedTrayStatus.full,
  ),
  VoicePhraseCase(
    id: 'en_growth_pond3_sample_abw',
    category: VoicePhraseCategory.english,
    spokenIntentDescription: 'Pond 3 growth sample ABW 24 g survival 85%',
    rawSttTranscript: 'Pond 3 sample lo ABW 24 grams survival 85 percent',
    expectedActivity: FarmActivityType.growth,
    expectedPondId: 'p3',
    expectedAvgBodyWeightGrams: 24,
    expectedSurvivalPercent: 85,
    mustBeMissing: {VoiceMustBeMissing.sampleSize},
  ),
  VoicePhraseCase(
    id: 'en_mortality_pond2',
    category: VoicePhraseCategory.english,
    spokenIntentDescription: 'Pond 2 mortality count 12',
    rawSttTranscript: 'Pond 2 lo mortality 12',
    expectedActivity: FarmActivityType.mortality,
    expectedPondId: 'p2',
    expectedMortalityCount: 12,
  ),
  VoicePhraseCase(
    id: 'en_water_salinity_ammonia_spoken_decimal',
    category: VoicePhraseCategory.english,
    spokenIntentDescription:
        'South Pond salinity 14 ammonia 0.05 spoken as point zero five',
    rawSttTranscript: 'South pond salinity 14 ammonia point zero five',
    expectedActivity: FarmActivityType.waterQuality,
    expectedPondId: 'ps',
    expectedSalinityPpt: 14,
    expectedAmmoniaPpm: 0.05,
    mustBeMissing: {
      VoiceMustBeMissing.ph,
      VoiceMustBeMissing.dissolvedOxygen,
      VoiceMustBeMissing.temperatureC,
      VoiceMustBeMissing.hardnessMgL,
    },
  ),
];

final _teluguEnglishMixed = <VoicePhraseCase>[
  VoicePhraseCase(
    id: 'mix_feed_south_vesam_tray_full',
    category: VoicePhraseCategory.teluguEnglishMixed,
    spokenIntentDescription:
        'South pond growth booster 20 kg feed given, tray full',
    rawSttTranscript: 'South pond lo growth booster 20 kg feed vesam tray full',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'ps',
    expectedQuantityKg: 20,
    expectedFeedType: 'growth booster',
    expectedTray: FeedTrayStatus.full,
  ),
  VoicePhraseCase(
    id: 'mix_feed_pond2_vesamu_tray_empty',
    category: VoicePhraseCategory.teluguEnglishMixed,
    spokenIntentDescription: 'Pond 2 45 kg feed given, tray empty',
    rawSttTranscript: 'Pond 2 lo 45 kg feed vesamu tray empty',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'p2',
    expectedQuantityKg: 45,
    expectedTray: FeedTrayStatus.empty,
    mustBeMissing: {VoiceMustBeMissing.feedType},
  ),
  VoicePhraseCase(
    id: 'mix_feed_rendo_konchem_migilindi',
    category: VoicePhraseCategory.teluguEnglishMixed,
    spokenIntentDescription: 'Pond 2 45 kg feed, tray partial leftover',
    rawSttTranscript:
        'Rendo pond lo 45 kilos feed vesam tray konchem migilindi',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'p2',
    expectedQuantityKg: 45,
    expectedTray: FeedTrayStatus.partial,
    mustBeMissing: {VoiceMustBeMissing.feedType},
  ),
  VoicePhraseCase(
    id: 'mix_feed_south_morning_tray_clean',
    category: VoicePhraseCategory.teluguEnglishMixed,
    spokenIntentDescription:
        'South pond morning 40 kg feed, tray clean meaning empty',
    rawSttTranscript: 'South pond lo morning 40 kg feed vesam tray clean',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'ps',
    expectedQuantityKg: 40,
    expectedTray: FeedTrayStatus.empty,
    expectedSession: 'morning',
    mustBeMissing: {VoiceMustBeMissing.feedType},
  ),
  VoicePhraseCase(
    id: 'mix_feed_rendo_growth_booster_full_sentence',
    category: VoicePhraseCategory.teluguEnglishMixed,
    spokenIntentDescription:
        'Pond 2 growth booster 20 kg feed given, tray full',
    rawSttTranscript: 'Rendo pond lo growth booster feed 20 kg vesam tray full',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'p2',
    expectedQuantityKg: 20,
    expectedFeedType: 'growth booster',
    expectedTray: FeedTrayStatus.full,
  ),
  VoicePhraseCase(
    id: 'mix_water_rendo_ph_do_temp',
    category: VoicePhraseCategory.teluguEnglishMixed,
    spokenIntentDescription: 'Pond 2 pH, DO, and temperature only',
    rawSttTranscript: 'Rendo pond lo pH 8.1 DO 5.2 temperature 29',
    expectedActivity: FarmActivityType.waterQuality,
    expectedPondId: 'p2',
    expectedPh: 8.1,
    expectedDissolvedOxygen: 5.2,
    expectedTemperatureC: 29,
    mustBeMissing: {
      VoiceMustBeMissing.salinityPpt,
      VoiceMustBeMissing.ammoniaPpm,
      VoiceMustBeMissing.hardnessMgL,
    },
  ),
  VoicePhraseCase(
    id: 'mix_water_south_partial_undi',
    category: VoicePhraseCategory.teluguEnglishMixed,
    spokenIntentDescription:
        'South pond pH and DO only; other water fields stay missing',
    rawSttTranscript: 'South pond lo pH 8.1 DO 5.2 undi',
    expectedActivity: FarmActivityType.waterQuality,
    expectedPondId: 'ps',
    expectedPh: 8.1,
    expectedDissolvedOxygen: 5.2,
    mustBeMissing: _waterPartialMissing,
  ),
  VoicePhraseCase(
    id: 'mix_mortality_rendo_chanipoyayi',
    category: VoicePhraseCategory.teluguEnglishMixed,
    spokenIntentDescription: 'Pond 2 twelve prawns died',
    rawSttTranscript: 'Rendo pond lo 12 prawns chanipoyayi',
    expectedActivity: FarmActivityType.mortality,
    expectedPondId: 'p2',
    expectedMortalityCount: 12,
  ),
  VoicePhraseCase(
    id: 'mix_feed_incomplete_no_invented_values',
    category: VoicePhraseCategory.teluguEnglishMixed,
    spokenIntentDescription:
        'Pond 2 feed given with no quantity, type, or tray — leave missing',
    rawSttTranscript: 'Rendo pond lo feed vesam',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'p2',
    mustBeMissing: _incompleteFeed,
  ),
  VoicePhraseCase(
    id: 'mix_feed_iravai_number_word',
    category: VoicePhraseCategory.teluguEnglishMixed,
    spokenIntentDescription: 'Pond 2 twenty kg via iravai number word',
    rawSttTranscript: 'Rendo pond lo iravai kg feed vesam tray full',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'p2',
    expectedQuantityKg: 20,
    expectedTray: FeedTrayStatus.full,
    mustBeMissing: {VoiceMustBeMissing.feedType},
  ),
];

final _teluguScript = <VoicePhraseCase>[
  VoicePhraseCase(
    id: 'te_feed_south_growth_booster',
    category: VoicePhraseCategory.teluguScript,
    spokenIntentDescription:
        'South Pond growth booster 20 kg feed given, tray full',
    rawSttTranscript:
        'సౌత్ పాండ్ లో గ్రోత్ బూస్టర్ ఫీడ్ 20 కిలోలు వేశాం ట్రే ఫుల్',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'ps',
    expectedQuantityKg: 20,
    expectedFeedType: 'growth booster',
    expectedTray: FeedTrayStatus.full,
  ),
  VoicePhraseCase(
    id: 'te_feed_rendo_tray_khali',
    category: VoicePhraseCategory.teluguScript,
    spokenIntentDescription: 'Pond 2 45 kg feed given, tray empty',
    rawSttTranscript: 'రెండో పాండ్ లో 45 కిలోల ఫీడ్ వేశాం ట్రే ఖాళీ',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'p2',
    expectedQuantityKg: 45,
    expectedTray: FeedTrayStatus.empty,
    mustBeMissing: {VoiceMustBeMissing.feedType},
  ),
  VoicePhraseCase(
    id: 'te_water_rendo_ph_do_temp',
    category: VoicePhraseCategory.teluguScript,
    spokenIntentDescription: 'Pond 2 pH, DO, temperature in Telugu script',
    rawSttTranscript: 'రెండో పాండ్ లో పీహెచ్ 8.1 డీఓ 5.2 టెంపరేచర్ 29',
    expectedActivity: FarmActivityType.waterQuality,
    expectedPondId: 'p2',
    expectedPh: 8.1,
    expectedDissolvedOxygen: 5.2,
    expectedTemperatureC: 29,
    mustBeMissing: {
      VoiceMustBeMissing.salinityPpt,
      VoiceMustBeMissing.ammoniaPpm,
      VoiceMustBeMissing.hardnessMgL,
    },
  ),
  VoicePhraseCase(
    id: 'te_growth_mudo_abw_survival',
    category: VoicePhraseCategory.teluguScript,
    spokenIntentDescription: 'Pond 3 sample ABW 24 g survival 85%',
    rawSttTranscript:
        'మూడో పాండ్ శాంపిల్ ఏబీడబ్ల్యూ 24 గ్రాములు సర్వైవల్ 85 పర్సెంట్',
    expectedActivity: FarmActivityType.growth,
    expectedPondId: 'p3',
    expectedAvgBodyWeightGrams: 24,
    expectedSurvivalPercent: 85,
    mustBeMissing: {VoiceMustBeMissing.sampleSize},
  ),
  VoicePhraseCase(
    id: 'te_mortality_rendo_chanipoyayi',
    category: VoicePhraseCategory.teluguScript,
    spokenIntentDescription: 'Pond 2 twelve prawns died',
    rawSttTranscript: 'రెండో పాండ్ లో 12 రొయ్యలు చనిపోయాయి',
    expectedActivity: FarmActivityType.mortality,
    expectedPondId: 'p2',
    expectedMortalityCount: 12,
  ),
];

final _realDeviceFailures = <VoicePhraseCase>[
  VoicePhraseCase(
    id: 'stt_south_point_c20_prayful',
    category: VoicePhraseCategory.realDeviceFailures,
    spokenIntentDescription:
        'South Pond growth booster 20 kg tray full (C20 kg / prayful STT)',
    rawSttTranscript: 'South Point growth booster C20 kg prayful',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'ps',
    expectedQuantityKg: 20,
    expectedFeedType: 'growth booster',
    expectedTray: FeedTrayStatus.full,
  ),
  VoicePhraseCase(
    id: 'stt_south_point_stray_full',
    category: VoicePhraseCategory.realDeviceFailures,
    spokenIntentDescription:
        'South Pond growth booster 20 kg tray full (stray full STT)',
    rawSttTranscript: 'South Point growth booster 20 kg stray full',
    expectedActivity: FarmActivityType.feed,
    expectedPondId: 'ps',
    expectedQuantityKg: 20,
    expectedFeedType: 'growth booster',
    expectedTray: FeedTrayStatus.full,
  ),
];
