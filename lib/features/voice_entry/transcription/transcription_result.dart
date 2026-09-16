class TranscriptionResult {
  const TranscriptionResult({
    required this.transcript,
    required this.providerId,
    required this.latency,
    this.language,
    this.usedFallback = false,
  });

  final String transcript;
  final String providerId;
  final Duration latency;
  final String? language;
  final bool usedFallback;

  TranscriptionResult copyWith({
    String? transcript,
    String? providerId,
    Duration? latency,
    String? language,
    bool? usedFallback,
  }) {
    return TranscriptionResult(
      transcript: transcript ?? this.transcript,
      providerId: providerId ?? this.providerId,
      latency: latency ?? this.latency,
      language: language ?? this.language,
      usedFallback: usedFallback ?? this.usedFallback,
    );
  }
}
