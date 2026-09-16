import 'dart:typed_data';

import 'package:prawn_farm_app/features/voice_entry/transcription/voice_audio_recorder.dart';

class FakeVoiceAudioRecorder implements VoiceAudioRecorder {
  FakeVoiceAudioRecorder({
    this.bytes = const [1, 2, 3],
    this.contentType = 'audio/mp4',
    this.duration = const Duration(seconds: 2),
    this.path = '/tmp/fake_farm_voice.m4a',
  });

  List<int> bytes;
  String contentType;
  Duration duration;
  String path;

  var startCalls = 0;
  var stopCalls = 0;
  var cancelCalls = 0;
  var deleteCalls = 0;
  final deletedPaths = <String>[];
  var _recording = false;
  Duration? lastMaxDuration;

  @override
  bool get isRecording => _recording;

  @override
  Future<void> start({
    Duration maxDuration = const Duration(seconds: 20),
  }) async {
    startCalls += 1;
    lastMaxDuration = maxDuration;
    _recording = true;
  }

  @override
  Future<RecordedAudio> stop() async {
    stopCalls += 1;
    _recording = false;
    return RecordedAudio(
      path: path,
      bytes: Uint8List.fromList(bytes),
      contentType: contentType,
      duration: duration,
    );
  }

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
    _recording = false;
  }

  @override
  Future<void> deleteRecording(RecordedAudio audio) async {
    deleteCalls += 1;
    deletedPaths.add(audio.path);
  }
}
