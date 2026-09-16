/// Hints for recognition only — never instruct structured farm JSON.
class TranscriptionRequest {
  const TranscriptionRequest({
    this.pondNames = const [],
    this.languageHints = const ['en'],
    this.localeId,
    this.maxDuration = const Duration(seconds: 20),
  });

  final List<String> pondNames;
  final List<String> languageHints;
  final String? localeId;
  final Duration maxDuration;

  static const defaultMaxDuration = Duration(seconds: 20);
}
