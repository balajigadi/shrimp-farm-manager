import 'transcription_failure.dart';
import 'transcription_provider.dart';
import 'transcription_request.dart';
import 'transcription_result.dart';
import 'voice_engine.dart';

/// Resolves Platform / Cloud / Auto without changing farm persistence.
class ResolvingTranscriptionProvider implements TranscriptionProvider {
  ResolvingTranscriptionProvider({
    required this.engine,
    required this.platform,
    required this.cloud,
    this.networkAvailable,
  });

  final VoiceEngine engine;
  final TranscriptionProvider platform;
  final TranscriptionProvider cloud;
  final Future<bool> Function()? networkAvailable;

  TranscriptionProvider? _active;
  var _usedFallback = false;

  @override
  String get id => switch (engine) {
    VoiceEngine.platform => platform.id,
    VoiceEngine.cloud => cloud.id,
    VoiceEngine.auto => 'auto',
  };

  @override
  String get displayName => engine.debugLabel;

  @override
  Future<bool> isAvailable() async {
    return switch (engine) {
      VoiceEngine.platform => platform.isAvailable(),
      VoiceEngine.cloud => cloud.isAvailable(),
      VoiceEngine.auto => true,
    };
  }

  Future<TranscriptionProvider> _selectForStart() async {
    switch (engine) {
      case VoiceEngine.platform:
        _usedFallback = false;
        return platform;
      case VoiceEngine.cloud:
        _usedFallback = false;
        return cloud;
      case VoiceEngine.auto:
        final online = await (networkAvailable?.call() ?? Future.value(true));
        if (online && await cloud.isAvailable()) {
          _usedFallback = false;
          return cloud;
        }
        _usedFallback = true;
        return platform;
    }
  }

  @override
  Future<void> start({
    required TranscriptionRequest request,
    void Function(String text, {required bool isFinal})? onResult,
  }) async {
    _active = await _selectForStart();
    try {
      await _active!.start(request: request, onResult: onResult);
    } on TranscriptionException catch (e) {
      if (engine == VoiceEngine.auto &&
          e.failure == TranscriptionFailure.networkUnavailable) {
        _usedFallback = true;
        _active = platform;
        await _active!.start(request: request, onResult: onResult);
        return;
      }
      rethrow;
    }
  }

  @override
  Future<TranscriptionResult> stop() async {
    final active = _active;
    if (active == null) {
      throw TranscriptionException(TranscriptionFailure.cancelled);
    }
    final result = await active.stop();
    if (!_usedFallback) return result;
    return TranscriptionResult(
      transcript: result.transcript,
      providerId: result.providerId,
      latency: result.latency,
      language: result.language,
      usedFallback: true,
    );
  }

  @override
  Future<void> cancel() async {
    await _active?.cancel();
    _active = null;
    _usedFallback = false;
  }
}
