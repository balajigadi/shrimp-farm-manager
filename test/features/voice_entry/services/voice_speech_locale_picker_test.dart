import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/services/speech_recognition_service.dart';
import 'package:prawn_farm_app/features/voice_entry/services/voice_speech_locale_picker.dart';

void main() {
  const enIn = SpeechLocale(id: 'en_IN', name: 'English (India)');
  const enUs = SpeechLocale(id: 'en_US', name: 'English (US)');
  const teIn = SpeechLocale(id: 'te_IN', name: 'Telugu (India)');
  const teHyphen = SpeechLocale(id: 'te-IN', name: 'Telugu (India)');

  test('english prefers en-IN and does not silently force US English', () {
    final picked = VoiceSpeechLocalePicker.pick(
      preference: VoiceLanguagePreference.english,
      available: const [enUs, enIn, teIn],
    );
    expect(picked.localeId, 'en_IN');
    expect(picked.usedFallback, isFalse);
    expect(picked.teluguUnavailable, isFalse);
  });

  test('english falls back to en-US only when en-IN is missing', () {
    final picked = VoiceSpeechLocalePicker.pick(
      preference: VoiceLanguagePreference.english,
      available: const [enUs, teIn],
    );
    expect(picked.localeId, 'en_US');
    expect(picked.usedFallback, isTrue);
  });

  test('telugu uses te-IN when the device exposes it', () {
    final picked = VoiceSpeechLocalePicker.pick(
      preference: VoiceLanguagePreference.telugu,
      available: const [enIn, teIn],
    );
    expect(picked.localeId, 'te_IN');
    expect(picked.teluguUnavailable, isFalse);
  });

  test('telugu matches hyphenated te-IN ids', () {
    final picked = VoiceSpeechLocalePicker.pick(
      preference: VoiceLanguagePreference.telugu,
      available: const [enIn, teHyphen],
    );
    expect(picked.localeId, 'te-IN');
  });

  test('telugu falls back without crashing when te-IN is missing', () {
    final picked = VoiceSpeechLocalePicker.pick(
      preference: VoiceLanguagePreference.telugu,
      available: const [enUs, enIn],
    );
    expect(picked.localeId, 'en_IN');
    expect(picked.teluguUnavailable, isTrue);
    expect(picked.usedFallback, isTrue);
  });

  test('auto/mixed prefers te-IN when available', () {
    final picked = VoiceSpeechLocalePicker.pick(
      preference: VoiceLanguagePreference.autoMixed,
      available: const [enIn, teIn],
    );
    expect(picked.localeId, 'te_IN');
  });

  test('auto/mixed uses en-IN when Telugu speech is not installed', () {
    final picked = VoiceSpeechLocalePicker.pick(
      preference: VoiceLanguagePreference.autoMixed,
      available: const [enUs, enIn],
    );
    expect(picked.localeId, 'en_IN');
    expect(picked.teluguUnavailable, isTrue);
    expect(picked.usedFallback, isTrue);
  });

  test('empty locale list does not crash and avoids forcing US English', () {
    final picked = VoiceSpeechLocalePicker.pick(
      preference: VoiceLanguagePreference.telugu,
      available: const [],
    );
    expect(picked.localeId, 'en_IN');
    expect(picked.usedFallback, isTrue);
    expect(picked.teluguUnavailable, isTrue);
  });
}
