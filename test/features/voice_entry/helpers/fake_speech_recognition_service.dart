import 'package:prawn_farm_app/features/voice_entry/services/speech_recognition_service.dart';

/// Test double. Never uses the microphone.
class FakeSpeechRecognitionService implements SpeechRecognitionService {
  FakeSpeechRecognitionService({
    this.available = true,
    this.permissionDenied = false,
    this.scriptedResult = '',
    this.emitOnStart = true,
    this.finalResult = true,
    this.availableLocales = const [
      SpeechLocale(id: 'en_IN', name: 'English (India)'),
      SpeechLocale(id: 'te_IN', name: 'Telugu (India)'),
    ],
  });

  bool available;
  bool permissionDenied;
  String scriptedResult;
  bool emitOnStart;
  bool finalResult;
  List<SpeechLocale> availableLocales;
  String? lastLocaleId;
  var _listening = false;
  var initializeCalls = 0;
  var startCalls = 0;
  var stopCalls = 0;

  @override
  bool get isAvailable => available;

  @override
  bool get isListening => _listening;

  @override
  Future<void> initialize() async {
    initializeCalls += 1;
    if (permissionDenied) {
      throw SpeechRecognitionException(SpeechFailure.permissionDenied);
    }
    if (!available) {
      throw SpeechRecognitionException(SpeechFailure.unavailable);
    }
  }

  @override
  Future<void> startListening({
    required void Function(String text, {required bool isFinal}) onResult,
    String? localeId,
  }) async {
    startCalls += 1;
    lastLocaleId = localeId;
    if (permissionDenied) {
      throw SpeechRecognitionException(SpeechFailure.permissionDenied);
    }
    if (!available) {
      throw SpeechRecognitionException(SpeechFailure.unavailable);
    }
    _listening = true;
    if (emitOnStart) {
      onResult(scriptedResult, isFinal: finalResult);
    }
  }

  @override
  Future<void> stopListening() async {
    stopCalls += 1;
    _listening = false;
  }

  @override
  Future<List<SpeechLocale>> locales() async => availableLocales;
}
