import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'voice_audio_recorder.dart';

/// Uses the mature `record` package for short m4a/aac clips.
class RecordPackageAudioRecorder implements VoiceAudioRecorder {
  RecordPackageAudioRecorder({AudioRecorder? plugin})
    : _plugin = plugin ?? AudioRecorder();

  final AudioRecorder _plugin;
  String? _path;
  DateTime? _startedAt;
  Timer? _maxTimer;
  var _recording = false;

  @override
  bool get isRecording => _recording;

  @override
  Future<void> start({
    Duration maxDuration = const Duration(seconds: 20),
  }) async {
    if (_recording) {
      throw StateError('already recording');
    }
    final permitted = await _plugin.hasPermission();
    if (!permitted) {
      throw StateError('microphone permission denied');
    }
    final dir = await getTemporaryDirectory();
    _path =
        '${dir.path}${Platform.pathSeparator}farm_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _startedAt = DateTime.now();
    await _plugin.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        numChannels: 1,
        sampleRate: 16000,
      ),
      path: _path!,
    );
    _recording = true;
    _maxTimer?.cancel();
    _maxTimer = Timer(maxDuration, () async {
      if (_recording) {
        try {
          await stop();
        } catch (_) {}
      }
    });
  }

  @override
  Future<RecordedAudio> stop() async {
    _maxTimer?.cancel();
    _maxTimer = null;
    final path = _path;
    final started = _startedAt ?? DateTime.now();
    final stoppedPath = await _plugin.stop();
    _recording = false;
    final finalPath = stoppedPath ?? path;
    if (finalPath == null) {
      throw StateError('no recording path');
    }
    final file = File(finalPath);
    final bytes = await file.readAsBytes();
    final duration = DateTime.now().difference(started);
    _path = null;
    _startedAt = null;
    return RecordedAudio(
      path: finalPath,
      bytes: bytes,
      contentType: 'audio/mp4',
      duration: duration,
    );
  }

  @override
  Future<void> cancel() async {
    _maxTimer?.cancel();
    _maxTimer = null;
    try {
      if (_recording) {
        final path = await _plugin.stop();
        _recording = false;
        if (path != null) {
          await deleteRecording(
            RecordedAudio(
              path: path,
              contentType: 'audio/mp4',
              duration: Duration.zero,
            ),
          );
        }
      }
    } catch (_) {}
    final leftover = _path;
    _path = null;
    _startedAt = null;
    _recording = false;
    if (leftover != null) {
      try {
        final f = File(leftover);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteRecording(RecordedAudio audio) async {
    try {
      final f = File(audio.path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
