import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'normalizer and parser production logic are unchanged vs git HEAD',
    () async {
      final result = await Process.run('git', [
        'diff',
        '--exit-code',
        '--',
        'lib/features/voice_entry/services/farm_speech_normalizer.dart',
        'lib/features/voice_entry/services/rule_based_farm_activity_parser.dart',
      ]);

      expect(
        result.exitCode,
        0,
        reason:
            'FarmSpeechNormalizer and RuleBasedFarmActivityParser must not be edited.',
      );
    },
  );
}
