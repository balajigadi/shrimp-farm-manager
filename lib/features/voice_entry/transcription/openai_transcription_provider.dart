import 'dart:io';

import 'farm_transcription_client.dart';
import 'farm_transcription_hints.dart';
import 'transcription_failure.dart';
import 'transcription_provider.dart';
import 'transcription_request.dart';
import 'transcription_result.dart';
import 'voice_audio_recorder.dart';

/// Cloud STT via Firebase → OpenAI `gpt-transcribe`.
class OpenAiTranscriptionProvider implements TranscriptionProvider {
  OpenAiTranscriptionProvider({
    required this.recorder,
    required this.client,
    this.hints = const FarmTranscriptionHints(),
    this.networkAvailable,
  });

  final VoiceAudioRecorder recorder;
  final FarmTranscriptionClient client;
  final FarmTranscriptionHints hints;
  final Future<bool> Function()? networkAvailable;

  DateTime? _startedAt;
  TranscriptionRequest? _request;
  var _active = false;
  var _submitInFlight = false;
  RecordedAudio? _pending;

  @override
  String get id => 'openai_gpt_transcribe';

  @override
  String get displayName => 'OpenAI GPT Transcribe';

  @override
  Future<bool> isAvailable() async {
    final online = await (networkAvailable?.call() ?? Future.value(true));
    return online;
  }

  @override
  Future<void> start({
    required TranscriptionRequest request,
    void Function(String text, {required bool isFinal})? onResult,
  }) async {
    if (_active || _submitInFlight) {
      throw TranscriptionException(TranscriptionFailure.busy);
    }
    final online = await (networkAvailable?.call() ?? Future.value(true));
    if (!online) {
      throw TranscriptionException(TranscriptionFailure.networkUnavailable);
    }
    _request = request;
    _startedAt = DateTime.now();
    _active = true;
    _pending = null;
    onResult?.call('', isFinal: false);
    try {
      await recorder.start(maxDuration: request.maxDuration);
    } catch (e) {
      _active = false;
      throw TranscriptionException(
        TranscriptionFailure.permissionDenied,
        e.toString(),
      );
    }
  }

  @override
  Future<TranscriptionResult> stop() async {
    if (!_active) {
      throw TranscriptionException(TranscriptionFailure.cancelled);
    }
    if (_submitInFlight) {
      throw TranscriptionException(TranscriptionFailure.busy);
    }
    _submitInFlight = true;
    _active = false;
    RecordedAudio? audio;
    try {
      audio = await recorder.stop();
      _pending = audio;
      final bytes = audio.bytes ?? await File(audio.path).readAsBytes();
      final req = _request ?? const TranscriptionRequest();
      final prompt = hints.prompt(pondNames: req.pondNames);
      final keywords = hints.keywords(pondNames: req.pondNames);
      final transcript = await client.transcribe(
        bytes: bytes,
        mimeType: audio.contentType,
        durationMs: audio.duration.inMilliseconds,
        pondNames: req.pondNames,
        languages: req.languageHints,
        prompt: prompt,
        keywords: keywords,
      );
      final trimmed = transcript.trim();
      if (trimmed.isEmpty) {
        throw TranscriptionException(TranscriptionFailure.empty);
      }
      return TranscriptionResult(
        transcript: trimmed,
        providerId: id,
        latency: DateTime.now().difference(_startedAt ?? DateTime.now()),
      );
    } on TranscriptionException {
      rethrow;
    } catch (e) {
      throw TranscriptionException(TranscriptionFailure.unknown, e.toString());
    } finally {
      if (audio != null) {
        await recorder.deleteRecording(audio);
      }
      _pending = null;
      _submitInFlight = false;
      _request = null;
    }
  }

  @override
  Future<void> cancel() async {
    _active = false;
    _submitInFlight = false;
    _request = null;
    try {
      if (recorder.isRecording) {
        final audio = await recorder.stop();
        await recorder.deleteRecording(audio);
      } else if (_pending != null) {
        await recorder.deleteRecording(_pending!);
      } else {
        await recorder.cancel();
      }
    } catch (_) {
      try {
        await recorder.cancel();
      } catch (_) {}
    }
    _pending = null;
  }
}
