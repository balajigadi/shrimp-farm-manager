import 'transcription_request.dart';
import 'transcription_result.dart';

/// AUDIO → raw transcript. Does not parse farm activity or touch Firestore.
abstract interface class TranscriptionProvider {
  String get id;
  String get displayName;

  Future<bool> isAvailable();

  Future<void> start({
    required TranscriptionRequest request,
    void Function(String text, {required bool isFinal})? onResult,
  });

  Future<TranscriptionResult> stop();

  Future<void> cancel();
}
