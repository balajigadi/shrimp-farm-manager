import 'package:shared_preferences/shared_preferences.dart';

/// Pilot voice engine selection.
enum VoiceEngine {
  platform,
  cloud,
  auto;

  static VoiceEngine parse(String? raw) {
    return switch (raw) {
      'cloud' => VoiceEngine.cloud,
      'auto' => VoiceEngine.auto,
      _ => VoiceEngine.platform,
    };
  }

  String get storageValue => name;

  String get debugLabel => switch (this) {
    VoiceEngine.platform => 'Platform STT',
    VoiceEngine.cloud => 'OpenAI GPT Transcribe',
    VoiceEngine.auto => 'Auto',
  };
}

class VoiceEngineStore {
  const VoiceEngineStore();

  static const prefKey = 'voice_transcription_engine';

  Future<VoiceEngine> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return VoiceEngine.parse(prefs.getString(prefKey));
    } catch (_) {
      return VoiceEngine.platform;
    }
  }

  Future<void> save(VoiceEngine engine) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, engine.storageValue);
  }

  static String storeValue(VoiceEngine engine) => engine.storageValue;

  static VoiceEngine parseStored(String? raw) => VoiceEngine.parse(raw);
}
