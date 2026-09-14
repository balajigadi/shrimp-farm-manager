import 'package:prawn_farm_app/features/voice_entry/services/voice_entry_analytics.dart';

class RecordingVoiceEntryAnalytics implements VoiceEntryAnalytics {
  final events = <String>[];

  @override
  void track(String event, [Map<String, Object?>? props]) {
    events.add(event);
  }
}
