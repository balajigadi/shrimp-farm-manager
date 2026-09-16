import 'dart:typed_data';

class RecordedAudio {
  const RecordedAudio({
    required this.path,
    required this.contentType,
    required this.duration,
    this.bytes,
  });

  final String path;
  final Uint8List? bytes;
  final String contentType;
  final Duration duration;
}

/// Short farm utterance capture. No Firestore / Storage upload here.
abstract interface class VoiceAudioRecorder {
  Future<void> start({Duration maxDuration = const Duration(seconds: 20)});
  Future<RecordedAudio> stop();
  Future<void> cancel();
  Future<void> deleteRecording(RecordedAudio audio);
  bool get isRecording;
}
