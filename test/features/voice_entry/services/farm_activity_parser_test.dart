import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/features/voice_entry/models/farm_activity_draft.dart';
import 'package:prawn_farm_app/features/voice_entry/services/rule_based_farm_activity_parser.dart';
import '../helpers/test_ponds.dart';

void main() {
  const parser = RuleBasedFarmActivityParser();
  final ponds = demoPonds();
  final now = DateTime(2026, 9, 11, 10, 30);

  Future<FarmActivityDraft> parse(String text) {
    return parser.parse(text, ponds: ponds, now: now);
  }

  group('English MVP phrases', () {
    test('feed with kilos and empty tray', () async {
      final draft = await parse('Pond 2 morning feed 45 kilos tray empty');
      expect(draft, isA<FeedActivityDraft>());
      final feed = draft as FeedActivityDraft;
      expect(feed.type, FarmActivityType.feed);
      expect(feed.pondReference, 'Pond 2');
      expect(feed.pondId, 'p2');
      expect(feed.quantityKg, 45);
      expect(feed.trayStatus, FeedTrayStatus.empty);
      expect(feed.session, 'morning');
      expect(feed.feedType, isNull);
    });

    test('feed with partial tray and word numbers', () async {
      final draft = await parse('Pond three feed 60 kg tray partial');
      final feed = draft as FeedActivityDraft;
      expect(feed.pondReference, 'Pond three');
      expect(feed.pondId, 'p3');
      expect(feed.quantityKg, 60);
      expect(feed.trayStatus, FeedTrayStatus.partial);
    });

    test('water quality with decimals', () async {
      final draft = await parse(
        'Pond 1 pH 8.1 DO 5.2 temperature 29 salinity 14 ammonia 0.05 hardness 120',
      );
      final water = draft as WaterQualityActivityDraft;
      expect(water.pondId, 'p1');
      expect(water.ph, 8.1);
      expect(water.dissolvedOxygen, 5.2);
      expect(water.temperatureC, 29);
      expect(water.salinityPpt, 14);
      expect(water.ammoniaPpm, 0.05);
      expect(water.hardnessMgL, 120);
    });

    test('growth sample', () async {
      final draft = await parse(
        'Pond 3 sample ABW 24 grams survival 85 percent sample size 100',
      );
      final growth = draft as GrowthActivityDraft;
      expect(growth.pondId, 'p3');
      expect(growth.avgBodyWeightGrams, 24);
      expect(growth.survivalPercent, 85);
      expect(growth.sampleSize, 100);
    });

    test('mortality with reason', () async {
      final draft = await parse('Pond 2 mortality 12 reason low DO');
      final mort = draft as MortalityActivityDraft;
      expect(mort.pondId, 'p2');
      expect(mort.count, 12);
      expect(mort.reason, 'low do');
    });
  });

  group('Telugu-English mixed vocabulary', () {
    test('feed vesamu', () async {
      final draft = await parse('Pond 2 lo 45 kg feed vesamu tray empty');
      final feed = draft as FeedActivityDraft;
      expect(feed.pondId, 'p2');
      expect(feed.quantityKg, 45);
      expect(feed.trayStatus, FeedTrayStatus.empty);
    });

    test('rendo pond water', () async {
      final draft = await parse('Rendo pond DO 5.1 pH 8.2');
      final water = draft as WaterQualityActivityDraft;
      expect(water.pondId, 'p2');
      expect(water.dissolvedOxygen, 5.1);
      expect(water.ph, 8.2);
      expect(water.temperatureC, isNull);
    });

    test('pond three lo mortality', () async {
      final draft = await parse('Pond three lo mortality 10');
      final mort = draft as MortalityActivityDraft;
      expect(mort.pondId, 'p3');
      expect(mort.count, 10);
    });
  });

  group('robustness', () {
    test('uppercase and extra words', () async {
      final draft = await parse(
        'PLEASE log POND 2 Mortality 12 fish reason LOW DO today',
      );
      expect(draft, isA<MortalityActivityDraft>());
      expect((draft as MortalityActivityDraft).count, 12);
    });

    test('different ordering still finds water fields', () async {
      final draft = await parse(
        'hardness 120 Pond 1 ammonia 0.05 salinity 14 temperature 29 DO 5.2 pH 8.1',
      );
      final water = draft as WaterQualityActivityDraft;
      expect(water.ph, 8.1);
      expect(water.hardnessMgL, 120);
    });

    test('unknown activity', () async {
      final draft = await parse('Pond 2 hello there farmer');
      expect(draft, isA<UnknownActivityDraft>());
    });

    test('unknown pond stays unresolved', () async {
      final draft = await parse('Pond 99 mortality 4');
      expect(draft.pondId, isNull);
      expect(draft.pondReference, 'Pond 99');
    });

    test('ambiguous pond does not pick silently', () async {
      final local = [
        testPond(id: 'a', name: 'Pond 2'),
        testPond(id: 'b', name: 'Pond Two'),
      ];
      final draft = await parser.parse(
        'Pond 2 mortality 4',
        ponds: local,
        now: now,
      );
      expect(draft.pondId, isNull);
      expect(draft.pondReference, 'Pond 2');
    });

    test('empty transcript is unknown', () async {
      final draft = await parse('   ');
      expect(draft, isA<UnknownActivityDraft>());
      expect(draft.rawTranscript, isEmpty);
    });

    test('transcript with no numbers', () async {
      final draft = await parse('Pond 2 morning feed tray empty');
      final feed = draft as FeedActivityDraft;
      expect(feed.quantityKg, isNull);
    });

    test('malformed number is not parsed as quantity', () async {
      final draft = await parse('Pond 2 feed abc kg tray empty');
      expect((draft as FeedActivityDraft).quantityKg, isNull);
    });

    test('negative looking mortality is not coerced', () async {
      final draft = await parse('Pond 2 mortality -12');
      expect((draft as MortalityActivityDraft).count, isNull);
    });

    test('yesterday shifts the calendar day', () async {
      final draft = await parse('Pond 2 yesterday mortality 3');
      expect(draft.occurredAt.day, 10);
      expect(draft.occurredAt.month, 9);
    });

    test('named south pond', () async {
      final draft = await parse('south pond mortality 2');
      expect(draft.pondId, 'ps');
    });

    test('ideal South Pond growth booster feed 20 kg tray full', () async {
      const spoken = 'South Pond growth booster feed 20 kg tray full';
      final draft = await parse(spoken);
      expect(draft.rawTranscript, spoken);
      final feed = draft as FeedActivityDraft;
      expect(feed.pondId, 'ps');
      expect(feed.quantityKg, 20);
      expect(feed.feedType, 'growth booster');
      expect(feed.trayStatus, FeedTrayStatus.full);
    });

    test('real-device STT South Point growth booster C20 kg prayful', () async {
      const heard = 'South Point growth booster C20 kg prayful';
      final draft = await parse(heard);
      expect(draft.rawTranscript, heard);
      expect(
        draft.normalizedTranscript.toLowerCase(),
        isNot(contains('prayful')),
      );
      final feed = draft as FeedActivityDraft;
      expect(feed.type, FarmActivityType.feed);
      expect(feed.pondId, 'ps');
      expect(feed.quantityKg, 20);
      expect(feed.feedType, 'growth booster');
      expect(feed.trayStatus, FeedTrayStatus.full);
    });

    test(
      'real-device STT South Point growth booster 20 kg stray full',
      () async {
        const heard = 'South Point growth booster 20 kg stray full';
        final draft = await parse(heard);
        expect(draft.rawTranscript, heard);
        expect(draft.normalizedTranscript.toLowerCase(), contains('tray full'));
        expect(
          draft.normalizedTranscript.toLowerCase(),
          isNot(contains('stray')),
        );
        final feed = draft as FeedActivityDraft;
        expect(feed.type, FarmActivityType.feed);
        expect(feed.pondId, 'ps');
        expect(feed.quantityKg, 20);
        expect(feed.feedType, 'growth booster');
        expect(feed.trayStatus, FeedTrayStatus.full);
      },
    );

    test('nursery by name', () async {
      final draft = await parse('nursery pond feed 10 kg tray full');
      expect(draft.pondId, 'pn');
      expect((draft as FeedActivityDraft).trayStatus, FeedTrayStatus.full);
    });

    test('remote parser placeholder is not used', () {
      expect(
        () => const RemoteFarmActivityParser().parse('x', ponds: ponds),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
