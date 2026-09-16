enum TranscriptionFailure {
  unavailable,
  permissionDenied,
  networkUnavailable,
  unauthenticated,
  timeout,
  empty,
  cancelled,
  busy,
  unknown,
}

class TranscriptionException implements Exception {
  TranscriptionException(this.failure, [this.message]);

  final TranscriptionFailure failure;
  final String? message;

  @override
  String toString() => message ?? failure.name;
}
