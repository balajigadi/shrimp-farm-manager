import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import 'transcription_failure.dart';

/// Client → authenticated Firebase backend only (never OpenAI directly).
abstract interface class FarmTranscriptionClient {
  Future<String> transcribe({
    required Uint8List bytes,
    required String mimeType,
    required int durationMs,
    required List<String> pondNames,
    required List<String> languages,
    required String prompt,
    required List<String> keywords,
  });
}

class CallableFarmTranscriptionClient implements FarmTranscriptionClient {
  CallableFarmTranscriptionClient({
    FirebaseFunctions? functions,
    this.timeout = const Duration(seconds: 45),
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;
  final Duration timeout;

  @override
  Future<String> transcribe({
    required Uint8List bytes,
    required String mimeType,
    required int durationMs,
    required List<String> pondNames,
    required List<String> languages,
    required String prompt,
    required List<String> keywords,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'transcribeFarmAudio',
        options: HttpsCallableOptions(timeout: timeout),
      );
      final result = await callable.call(<String, dynamic>{
        'audioBase64': base64Encode(bytes),
        'mimeType': mimeType,
        'durationMs': durationMs,
        'pondNames': pondNames,
        'languages': languages,
        'prompt': prompt,
        'keywords': keywords,
      });
      final data = result.data;
      if (data is! Map) {
        throw TranscriptionException(TranscriptionFailure.unknown);
      }
      final transcript = data['transcript']?.toString().trim() ?? '';
      if (transcript.isEmpty) {
        throw TranscriptionException(TranscriptionFailure.empty);
      }
      return transcript;
    } on FirebaseFunctionsException catch (e) {
      throw TranscriptionException(_mapCode(e.code), e.message);
    } on TranscriptionException {
      rethrow;
    } catch (_) {
      throw TranscriptionException(TranscriptionFailure.unknown);
    }
  }

  static TranscriptionFailure _mapCode(String code) {
    return switch (code) {
      'unauthenticated' => TranscriptionFailure.unauthenticated,
      'deadline-exceeded' => TranscriptionFailure.timeout,
      'unavailable' => TranscriptionFailure.networkUnavailable,
      'resource-exhausted' => TranscriptionFailure.busy,
      _ => TranscriptionFailure.unknown,
    };
  }
}
