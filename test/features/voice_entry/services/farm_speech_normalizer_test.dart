import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/services/farm_speech_normalizer.dart';
import '../helpers/test_ponds.dart';

void main() {
  const normalizer = FarmSpeechNormalizer();

  setUp(FarmSpeechNormalizer.debugCorrections.clear);

  group('confirmed STT: pond fuzzy match', () {
    test('South Point rewrites to unique known South Pond', () {
      final ponds = [
        testPond(id: 'n', name: 'North Pond'),
        testPond(id: 's', name: 'South Pond'),
      ];
      final result = normalizer.normalize(
        'South Point growth booster feed 20 kg tray full',
        ponds: ponds,
      );
      expect(result.rawTranscript, contains('South Point'));
      expect(result.normalizedTranscript, contains('South Pond'));
      expect(
        result.normalizedTranscript.toLowerCase(),
        isNot(contains('south point')),
      );
      expect(
        result.normalizedTranscript,
        'South Pond growth booster feed 20 kg tray full',
      );
      expect(
        FarmSpeechNormalizer.debugCorrections.any(
          (c) =>
              c.kind == 'pond' &&
              c.from == 'South Point' &&
              c.to == 'South Pond',
        ),
        isTrue,
      );
    });

    test('ambiguous South Point is not silently rewritten', () {
      final result = normalizer.normalize(
        'South Point growth booster feed 20 kg tray full',
        ponds: [
          testPond(id: 's', name: 'South Pond'),
          testPond(id: 'f', name: 'South Point Farm'),
        ],
      );
      expect(
        result.normalizedTranscript.toLowerCase(),
        contains('south point'),
      );
      expect(
        result.normalizedTranscript.toLowerCase(),
        isNot(contains('south pond')),
      );
    });

    test('unrelated market point is not rewritten to pond', () {
      final result = normalizer.normalize(
        'market point price 20',
        ponds: [
          testPond(id: 'n', name: 'North Pond'),
          testPond(id: 's', name: 'South Pond'),
        ],
      );
      expect(result.normalizedTranscript, 'market point price 20');
      expect(
        result.normalizedTranscript.toLowerCase(),
        isNot(contains('market pond')),
      );
    });
  });

  group('confirmed STT: tray status variants', () {
    const feedCtx = 'Pond 2 feed 20 kg';

    for (final variant in [
      'stray full',
      'pray full',
      'prayful',
      'strayful',
      'spray full',
      'trade full',
      'straight full',
      'sprayful',
    ]) {
      test('$variant becomes tray full in feed context', () {
        final result = normalizer.normalize(
          '$feedCtx $variant',
          ponds: demoPonds(),
        );
        expect(
          result.normalizedTranscript.toLowerCase(),
          contains('tray full'),
        );
        expect(
          result.normalizedTranscript.toLowerCase(),
          isNot(contains(variant.toLowerCase())),
        );
        expect(
          FarmSpeechNormalizer.debugCorrections.any((c) => c.kind == 'tray'),
          isTrue,
        );
      });
    }

    test('stray remains unchanged outside feed or tray context', () {
      final result = normalizer.normalize('a stray dog near the road');
      expect(result.normalizedTranscript, 'a stray dog near the road');
    });
  });

  group('confirmed STT: quantity letter prefix noise', () {
    test('C20 / B15 / x40 kg lose the glued letter', () {
      expect(
        normalizer
            .normalize('Pond 2 feed C20 kg tray full', ponds: demoPonds())
            .normalizedTranscript
            .toLowerCase(),
        contains('20 kg'),
      );
      expect(
        normalizer
            .normalize('Pond 2 feed B15 kg tray empty', ponds: demoPonds())
            .normalizedTranscript
            .toLowerCase(),
        contains('15 kg'),
      );
      expect(
        normalizer
            .normalize('Pond 2 feed x40 kg tray partial', ponds: demoPonds())
            .normalizedTranscript
            .toLowerCase(),
        contains('40 kg'),
      );
      expect(
        FarmSpeechNormalizer.debugCorrections.any((c) => c.kind == 'quantity'),
        isTrue,
      );
    });

    test('pond ids A1 B2 Pond C3 are not stripped as quantities', () {
      final ponds = [
        testPond(id: 'a1', name: 'A1'),
        testPond(id: 'b2', name: 'B2'),
        testPond(id: 'c3', name: 'Pond C3'),
      ];
      expect(
        normalizer
            .normalize('A1 mortality 12', ponds: ponds)
            .normalizedTranscript,
        contains('A1'),
      );
      expect(
        normalizer
            .normalize('B2 mortality 12', ponds: ponds)
            .normalizedTranscript,
        contains('B2'),
      );
      expect(
        normalizer
            .normalize('Pond C3 mortality 12', ponds: ponds)
            .normalizedTranscript,
        contains('Pond C3'),
      );
      expect(
        normalizer
            .normalize('Pond C3 feed C3 kg tray full', ponds: ponds)
            .normalizedTranscript,
        contains('C3 kg'),
      );
    });

    test('A1 feed C20 kg keeps A1 and strips C20', () {
      final ponds = [
        testPond(id: 'a1', name: 'A1'),
        testPond(id: 'b2', name: 'B2'),
        testPond(id: 'c3', name: 'Pond C3'),
      ];
      final result = normalizer.normalize(
        'A1 feed C20 kg tray full',
        ponds: ponds,
      );
      expect(result.rawTranscript, 'A1 feed C20 kg tray full');
      expect(result.normalizedTranscript, 'A1 feed 20 kg tray full');
    });
  });

  group('confirmed STT: combined end-to-end normalizer', () {
    test('South Point + C20 kg + stray full', () {
      final result = normalizer.normalize(
        'South Point growth booster C20 kg stray full',
        ponds: [
          testPond(id: 'n', name: 'North Pond'),
          testPond(id: 's', name: 'South Pond'),
        ],
      );
      expect(
        result.rawTranscript,
        'South Point growth booster C20 kg stray full',
      );
      expect(
        result.normalizedTranscript,
        'South Pond growth booster 20 kg tray full',
      );
    });
  });

  // --- existing regression coverage below ---

  test('C20 kg becomes 20 kg in normalized text only', () {
    const raw = 'South Point growth booster C20 kg prayful';
    final result = normalizer.normalize(raw, ponds: demoPonds());
    expect(result.rawTranscript, raw);
    expect(result.normalizedTranscript.contains('C20'), isFalse);
    expect(result.normalizedTranscript.toLowerCase(), contains('20 kg'));
  });

  test('prayful / pray full / trayful become tray full in feed context', () {
    expect(
      normalizer
          .normalize('Pond 2 feed 20 kg prayful', ponds: demoPonds())
          .normalizedTranscript
          .toLowerCase(),
      contains('tray full'),
    );
    expect(
      normalizer
          .normalize('Pond 2 feed 20 kg pray full', ponds: demoPonds())
          .normalizedTranscript
          .toLowerCase(),
      contains('tray full'),
    );
    expect(
      normalizer
          .normalize('Pond 2 feed 20 kg trayful', ponds: demoPonds())
          .normalizedTranscript
          .toLowerCase(),
      contains('tray full'),
    );
  });

  test('prayful is not rewritten outside feed or tray context', () {
    final result = normalizer.normalize('a prayful morning');
    expect(result.normalizedTranscript, 'a prayful morning');
  });

  test('stray full / strayful become tray full in feed context', () {
    expect(
      normalizer
          .normalize(
            'South Point growth booster 20 kg stray full',
            ponds: demoPonds(),
          )
          .normalizedTranscript
          .toLowerCase(),
      contains('tray full'),
    );
    expect(
      normalizer
          .normalize('Pond 2 feed 20 kg strayful', ponds: demoPonds())
          .normalizedTranscript
          .toLowerCase(),
      contains('tray full'),
    );
  });

  test('does not globally replace the word stray', () {
    final result = normalizer.normalize(
      'a stray cat near Pond 2 feed 10 kg tray empty',
      ponds: demoPonds(),
    );
    expect(result.normalizedTranscript.toLowerCase(), contains('stray cat'));
    expect(
      result.normalizedTranscript.toLowerCase(),
      isNot(contains(RegExp(r'\btray cat\b'))),
    );
  });

  test('stray full is not rewritten outside feed or tray context', () {
    final result = normalizer.normalize('a stray full moon');
    expect(result.normalizedTranscript, 'a stray full moon');
  });

  test('unique South Point rewrites to South Pond', () {
    final result = normalizer.normalize(
      'South Point growth booster C20 kg prayful',
      ponds: [
        testPond(id: 'n', name: 'North Pond'),
        testPond(id: 's', name: 'South Pond'),
      ],
    );
    expect(result.rawTranscript, contains('South Point'));
    expect(result.normalizedTranscript, contains('South Pond'));
    expect(
      result.normalizedTranscript.toLowerCase(),
      isNot(contains('south point')),
    );
  });

  test('ambiguous named ponds are not rewritten', () {
    final result = normalizer.normalize(
      'South Point growth booster 20 kg tray full',
      ponds: [
        testPond(id: 's', name: 'South Pond'),
        testPond(id: 'f', name: 'South Point Farm'),
      ],
    );
    expect(result.normalizedTranscript.toLowerCase(), contains('south point'));
  });

  test('does not globally replace the word point', () {
    final result = normalizer.normalize(
      'The point of this Pond 2 feed 10 kg tray empty',
      ponds: demoPonds(),
    );
    expect(result.normalizedTranscript.toLowerCase(), contains('the point of'));
    expect(
      result.normalizedTranscript.toLowerCase(),
      isNot(contains('the pond of')),
    );
  });

  test('Telugu script farming phrases map to English farming tokens', () {
    const raw = 'సౌత్ పాండ్ లో గ్రోత్ బూస్టర్ ఫీడ్ 20 కిలోలు వేశాం ట్రే ఫుల్';
    final result = normalizer.normalize(raw, ponds: demoPonds());
    expect(result.rawTranscript, raw);
    final normalized = result.normalizedTranscript.toLowerCase();
    expect(normalized, contains('south pond'));
    expect(normalized, contains('growth booster'));
    expect(normalized, contains('20 kg'));
    expect(normalized, contains('vesam'));
    expect(normalized, contains('tray full'));
  });

  test('point zero five becomes 0.05 without rewriting other points', () {
    final result = normalizer.normalize(
      'South pond salinity 14 ammonia point zero five',
      ponds: demoPonds(),
    );
    expect(result.normalizedTranscript, contains('0.05'));
    expect(result.normalizedTranscript.toLowerCase(), contains('south pond'));
  });

  test('tray clean maps to tray empty only in feed context', () {
    expect(
      normalizer
          .normalize(
            'South pond lo morning 40 kg feed vesam tray clean',
            ponds: demoPonds(),
          )
          .normalizedTranscript
          .toLowerCase(),
      contains('tray empty'),
    );
    final unrelated = normalizer.normalize('please clean the nets');
    expect(unrelated.normalizedTranscript, 'please clean the nets');
  });

  test('vesam stays an action marker, not a feed type phrase', () {
    final result = normalizer.normalize(
      'South pond lo growth booster feed 20 kg vesam tray full',
      ponds: demoPonds(),
    );
    expect(result.normalizedTranscript.toLowerCase(), contains('vesam'));
    expect(
      result.normalizedTranscript.toLowerCase(),
      isNot(contains('vesam feed')),
    );
  });

  test('full and empty are not rewritten outside tray phrases', () {
    final result = normalizer.normalize(
      'the pond is full and the tray is idle',
    );
    expect(
      result.normalizedTranscript,
      'the pond is full and the tray is idle',
    );
  });
}
