import 'package:prawn_farm_app/features/voice_entry/services/speech_recognition_service.dart';

/// Test double. Never uses the microphone.
class FakeSpeechRecognitionService implements SpeechRecognitionService {
  FakeSpeechRecognitionService({
    this.available = true,
    this.permissionDenied = false,
    this.scriptedResult = '',
    this.scriptedResults,
    this.emitOnStart = true,
    this.finalResult = true,
    this.availableLocales = const [
      SpeechLocale(id: 'en_IN', name: 'English (India)'),
      SpeechLocale(id: 'en_US', name: 'English (US)'),
      SpeechLocale(id: 'te_IN', name: 'Telugu (India)'),
    ],
  });

  bool available;
  bool permissionDenied;
  String scriptedResult;

  /// If set, each [startListening] consumes the next entry.
  List<String>? scriptedResults;
  bool emitOnStart;
  bool finalResult;
  List<SpeechLocale> availableLocales;
  String? lastLocaleId;
  final List<String?> localeIdHistory = [];
  var _listening = false;
  var initializeCalls = 0;
  var startCalls = 0;
  var stopCalls = 0;
  var _scriptedIndex = 0;

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
    localeIdHistory.add(localeId);
    if (permissionDenied) {
      throw SpeechRecognitionException(SpeechFailure.permissionDenied);
    }
    if (!available) {
      throw SpeechRecognitionException(SpeechFailure.unavailable);
    }
    _listening = true;
    if (emitOnStart) {
      final text = _nextScriptedResult();
      onResult(text, isFinal: finalResult);
    }
  }

  String _nextScriptedResult() {
    final queue = scriptedResults;
    if (queue != null && queue.isNotEmpty) {
      final index = _scriptedIndex.clamp(0, queue.length - 1);
      _scriptedIndex += 1;
      return queue[index];
    }
    return scriptedResult;
  }

  @override
  Future<void> stopListening() async {
    stopCalls += 1;
    _listening = false;
  }

  @override
  Future<List<SpeechLocale>> locales() async => availableLocales;
}
