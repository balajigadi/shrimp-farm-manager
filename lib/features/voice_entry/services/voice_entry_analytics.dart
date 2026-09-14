/// Lightweight hook for future analytics. No-op in V1.
abstract interface class VoiceEntryAnalytics {
  void track(String event, [Map<String, Object?>? props]);
}

class NoOpVoiceEntryAnalytics implements VoiceEntryAnalytics {
  const NoOpVoiceEntryAnalytics();

  @override
  void track(String event, [Map<String, Object?>? props]) {}
}

abstract final class VoiceEvents {
  static const opened = 'voice_entry_opened';
  static const listeningStarted = 'voice_listening_started';
  static const recognitionSucceeded = 'voice_recognition_succeeded';
  static const recognitionFailed = 'voice_recognition_failed';
  static const draftParsed = 'voice_draft_parsed';
  static const validationFailed = 'voice_draft_validation_failed';
  static const draftEdited = 'voice_draft_edited';
  static const confirmed = 'voice_entry_confirmed';
  static const saved = 'voice_entry_saved';
  static const saveFailed = 'voice_entry_save_failed';
  static const cancelled = 'voice_entry_cancelled';
}
