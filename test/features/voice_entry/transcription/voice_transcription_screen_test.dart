import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/screens/voice_farm_entry_screen.dart';
import 'package:prawn_farm_app/features/voice_entry/services/farm_activity_writer.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/transcription_provider.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/transcription_request.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/transcription_result.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_speech_recognition_service.dart';
import '../helpers/recording_farm_activity_repository.dart';
import '../helpers/test_ponds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'provider transcript reaches review and does not save before confirm',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final repo = RecordingFarmActivityRepository();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: VoiceFarmEntryScreen(
            ponds: demoPonds(),
            speech: FakeSpeechRecognitionService(emitOnStart: false),
            transcriptionProvider: FakeTranscriptProvider(
              transcript: 'Pond 2 mortality 12 reason low DO',
            ),
            writer: FarmActivityWriter(
              repository: repo,
              farmId: () => 'farm-1',
            ),
            now: DateTime(2026, 9, 11, 10),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('voice_record_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('voice_stop_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('voice_stop_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.byKey(const Key('voice_review')), findsOneWidget);
      expect(find.textContaining('Pond 2 mortality 12'), findsWidgets);
      expect(repo.writeCount, 0);
    },
  );
}

class FakeTranscriptProvider implements TranscriptionProvider {
  FakeTranscriptProvider({required this.transcript});

  final String transcript;

  @override
  String get id => 'fake';

  @override
  String get displayName => 'Fake';

  @override
  Future<void> cancel() async {}

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> start({
    required TranscriptionRequest request,
    void Function(String text, {required bool isFinal})? onResult,
  }) async {
    onResult?.call(transcript, isFinal: false);
  }

  @override
  Future<TranscriptionResult> stop() async {
    return TranscriptionResult(
      transcript: transcript,
      providerId: id,
      latency: Duration.zero,
    );
  }
}
