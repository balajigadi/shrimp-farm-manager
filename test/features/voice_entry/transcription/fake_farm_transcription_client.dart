import 'dart:typed_data';

import 'package:prawn_farm_app/features/voice_entry/transcription/farm_transcription_client.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/transcription_failure.dart';

class FakeFarmTranscriptionClient implements FarmTranscriptionClient {
  FakeFarmTranscriptionClient({
    this.transcript = 'Feed Pond 2 45 kg tray empty',
    this.failure,
    this.delay = Duration.zero,
  });

  String transcript;
  TranscriptionException? failure;
  Duration delay;
  var calls = 0;
  Uint8List? lastBytes;

  @override
  Future<String> transcribe({
    required Uint8List bytes,
    required String mimeType,
    required int durationMs,
    required List<String> pondNames,
    required List<String> languages,
    required String prompt,
    required List<String> keywords,
  }) async {
    calls += 1;
    lastBytes = bytes;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (failure != null) throw failure!;
    return transcript;
  }
}
