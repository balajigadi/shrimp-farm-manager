import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DEBUG-only local comparison log. Never stores audio.
class TranscriptionPilotAttempt {
  const TranscriptionPilotAttempt({
    required this.at,
    required this.providerId,
    required this.transcript,
    required this.latencyMs,
    required this.usedFallback,
    this.expectedLabel,
    this.language,
    this.error,
  });

  final DateTime at;
  final String providerId;
  final String transcript;
  final int latencyMs;
  final bool usedFallback;
  final String? expectedLabel;
  final String? language;
  final String? error;

  Map<String, Object?> toJson() => {
    'at': at.toIso8601String(),
    'providerId': providerId,
    'transcript': transcript,
    'latencyMs': latencyMs,
    'usedFallback': usedFallback,
    'expectedLabel': expectedLabel,
    'language': language,
    'error': error,
  };

  static TranscriptionPilotAttempt fromJson(Map<String, dynamic> json) {
    return TranscriptionPilotAttempt(
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      providerId: json['providerId'] as String? ?? 'unknown',
      transcript: json['transcript'] as String? ?? '',
      latencyMs: json['latencyMs'] as int? ?? 0,
      usedFallback: json['usedFallback'] as bool? ?? false,
      expectedLabel: json['expectedLabel'] as String?,
      language: json['language'] as String?,
      error: json['error'] as String?,
    );
  }

  String toClipboardBlock() {
    final buffer = StringBuffer()
      ..writeln('Provider: $providerId')
      ..writeln('Said/expected:')
      ..writeln(expectedLabel ?? '(not supplied)')
      ..writeln()
      ..writeln('Transcript:')
      ..writeln(transcript.isEmpty ? '(empty)' : transcript)
      ..writeln()
      ..writeln('Latency:')
      ..writeln('${latencyMs / 1000.0} sec');
    if (error != null) {
      buffer
        ..writeln()
        ..writeln('Error: $error');
    }
    if (language != null) {
      buffer
        ..writeln()
        ..writeln('Language: $language');
    }
    buffer
      ..writeln()
      ..writeln('---');
    return buffer.toString();
  }
}

class TranscriptionPilotLog {
  TranscriptionPilotLog({this.persistInDebug = true});

  static const prefKey = 'voice_transcription_pilot_attempts';
  static final List<TranscriptionPilotAttempt> _memory = [];

  final bool persistInDebug;

  List<TranscriptionPilotAttempt> get attempts => List.unmodifiable(_memory);

  Future<void> add(TranscriptionPilotAttempt attempt) async {
    assert(() {
      _memory.insert(0, attempt);
      if (_memory.length > 50) {
        _memory.removeRange(50, _memory.length);
      }
      return true;
    }());
    if (!kDebugMode || !persistInDebug) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        prefKey,
        _memory.map((a) => jsonEncode(a.toJson())).toList(),
      );
    } catch (_) {}
  }

  Future<void> load() async {
    if (!kDebugMode || !persistInDebug) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rows = prefs.getStringList(prefKey) ?? const [];
      _memory
        ..clear()
        ..addAll(
          rows.map((row) {
            final decoded = jsonDecode(row) as Map<String, dynamic>;
            return TranscriptionPilotAttempt.fromJson(decoded);
          }),
        );
    } catch (_) {}
  }

  Future<void> clear() async {
    _memory.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKey);
    } catch (_) {}
  }

  String toClipboardText() {
    if (_memory.isEmpty) return '';
    return _memory.map((a) => a.toClipboardBlock()).join('\n');
  }
}
