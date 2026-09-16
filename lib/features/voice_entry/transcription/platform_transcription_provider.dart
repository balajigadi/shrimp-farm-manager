import '../services/speech_recognition_service.dart';
import 'transcription_failure.dart';
import 'transcription_provider.dart';
import 'transcription_request.dart';
import 'transcription_result.dart';

/// Existing device STT as a [TranscriptionProvider].
class PlatformTranscriptionProvider implements TranscriptionProvider {
  PlatformTranscriptionProvider({required this.speech});

  final SpeechRecognitionService speech;

  String _partial = '';
  DateTime? _startedAt;
  var _active = false;

  @override
  String get id => 'platform';

  @override
  String get displayName => 'Platform STT';

  @override
  Future<bool> isAvailable() async {
    try {
      await speech.initialize();
      return speech.isAvailable;
    } on SpeechRecognitionException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> start({
    required TranscriptionRequest request,
    void Function(String text, {required bool isFinal})? onResult,
  }) async {
    if (_active) {
      throw TranscriptionException(TranscriptionFailure.busy);
    }
    _partial = '';
    _startedAt = DateTime.now();
    _active = true;
    try {
      await speech.initialize();
      await speech.startListening(
        localeId: request.localeId,
        onResult: (text, {required isFinal}) {
          _partial = text;
          onResult?.call(text, isFinal: isFinal);
        },
      );
    } on SpeechRecognitionException catch (e) {
      _active = false;
      throw TranscriptionException(_map(e.failure), e.message);
    } catch (e) {
      _active = false;
      throw TranscriptionException(TranscriptionFailure.unknown, e.toString());
    }
  }

  @override
  Future<TranscriptionResult> stop() async {
    try {
      if (_active) {
        await speech.stopListening();
      }
      final transcript = _partial.trim();
      final latency = DateTime.now().difference(_startedAt ?? DateTime.now());
      if (transcript.isEmpty) {
        throw TranscriptionException(TranscriptionFailure.empty);
      }
      return TranscriptionResult(
        transcript: transcript,
        providerId: id,
        latency: latency,
      );
    } finally {
      _active = false;
    }
  }

  @override
  Future<void> cancel() async {
    _active = false;
    _partial = '';
    try {
      await speech.stopListening();
    } catch (_) {}
  }

  static TranscriptionFailure _map(SpeechFailure failure) {
    return switch (failure) {
      SpeechFailure.permissionDenied => TranscriptionFailure.permissionDenied,
      SpeechFailure.unavailable => TranscriptionFailure.unavailable,
      SpeechFailure.noResult => TranscriptionFailure.empty,
      SpeechFailure.unknown => TranscriptionFailure.unknown,
    };
  }
}
