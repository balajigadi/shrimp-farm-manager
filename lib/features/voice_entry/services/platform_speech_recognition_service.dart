import 'package:speech_to_text/speech_to_text.dart';
import 'speech_recognition_service.dart';

/// Device speech recognizer via `speech_to_text` (no cloud API keys).
class PlatformSpeechRecognitionService implements SpeechRecognitionService {
  PlatformSpeechRecognitionService({SpeechToText? plugin})
    : _plugin = plugin ?? SpeechToText();

  final SpeechToText _plugin;
  var _listening = false;
  var _available = false;

  @override
  bool get isListening => _listening;

  @override
  bool get isAvailable => _available;

  @override
  Future<void> initialize() async {
    try {
      _available = await _plugin.initialize(
        onError: (_) {},
        onStatus: (status) {
          _listening = status == 'listening';
        },
      );
    } catch (_) {
      _available = false;
    }
    if (!_available) {
      final denied = !(await _plugin.hasPermission);
      throw SpeechRecognitionException(
        denied ? SpeechFailure.permissionDenied : SpeechFailure.unavailable,
      );
    }
  }

  @override
  Future<void> startListening({
    required void Function(String text, {required bool isFinal}) onResult,
    String? localeId,
  }) async {
    if (!_available) {
      await initialize();
    }
    _listening = true;
    await _plugin.listen(
      onResult: (result) {
        final text = result.recognizedWords.trim();
        if (text.isEmpty && !result.finalResult) {
          return;
        }
        onResult(text, isFinal: result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        localeId: localeId,
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    _listening = false;
    await _plugin.stop();
  }

  @override
  Future<List<SpeechLocale>> locales() async {
    try {
      final list = await _plugin.locales();
      return [
        for (final locale in list)
          SpeechLocale(id: locale.localeId, name: locale.name),
      ];
    } catch (_) {
      return const [];
    }
  }
}
