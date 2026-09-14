class SpeechLocale {
  const SpeechLocale({required this.id, required this.name});

  /// Plugin locale id, e.g. `en_IN`, `te_IN`, or `te-IN`.
  final String id;
  final String name;
}

abstract interface class SpeechRecognitionService {
  Future<void> initialize();
  Future<void> startListening({
    required void Function(String text, {required bool isFinal}) onResult,
    String? localeId,
  });
  Future<void> stopListening();

  /// Locales the current device actually exposes. May be empty.
  Future<List<SpeechLocale>> locales();

  bool get isListening;
  bool get isAvailable;
}

enum SpeechFailure { unavailable, permissionDenied, noResult, unknown }

class SpeechRecognitionException implements Exception {
  SpeechRecognitionException(this.failure, [this.message]);

  final SpeechFailure failure;
  final String? message;

  @override
  String toString() => message ?? failure.name;
}
