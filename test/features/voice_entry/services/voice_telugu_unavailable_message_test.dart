import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/services/voice_telugu_unavailable_message.dart';
import 'package:prawn_farm_app/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('iOS Telugu-unavailable copy does not mention Android', () {
    final message = voiceTeluguSpeechUnavailableMessage(
      l10n,
      platform: TargetPlatform.iOS,
    );
    expect(message.toLowerCase(), isNot(contains('android')));
    expect(message, contains("isn't available"));
    expect(message, contains('English (India)'));
  });

  test('Android Telugu-unavailable copy may mention Android settings', () {
    final message = voiceTeluguSpeechUnavailableMessage(
      l10n,
      platform: TargetPlatform.android,
    );
    expect(message, contains('Android'));
  });
}
