import 'package:shared_preferences/shared_preferences.dart';
import 'voice_speech_locale_picker.dart';

/// Persists the voice STT language the same way app UI locale is stored.
class VoiceLanguageStore {
  const VoiceLanguageStore();

  static const prefKey = 'voice_language_preference';

  Future<VoiceLanguagePreference> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return VoiceSpeechLocalePicker.parseStored(prefs.getString(prefKey));
    } catch (_) {
      return VoiceLanguagePreference.autoMixed;
    }
  }

  Future<void> save(VoiceLanguagePreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      prefKey,
      VoiceSpeechLocalePicker.storeValue(preference)!,
    );
  }
}
