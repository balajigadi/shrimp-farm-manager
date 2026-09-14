import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/lab/ios_english_stt_corpus.dart';
import 'package:prawn_farm_app/features/voice_entry/lab/stt_locale_lab_session.dart';
import 'package:prawn_farm_app/features/voice_entry/lab/voice_stt_locale_lab_flags.dart';
import 'package:prawn_farm_app/features/voice_entry/screens/stt_locale_lab_screen.dart';
import 'package:prawn_farm_app/features/voice_entry/services/speech_recognition_service.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../helpers/fake_speech_recognition_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lab visibility respects debug mode and dart-define helper', () {
    expect(isVoiceSttLocaleLabVisible(isDebugMode: true), isTrue);
    // Without dart-define in test process, define is false:
    expect(voiceSttLocaleLabEnabled(), isFalse);
    expect(isVoiceSttLocaleLabVisible(isDebugMode: false), isFalse);
  });

  testWidgets('locale lab records with selected English locale id', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final phrase = iosEnglishSttCorpus.first;
    final speech = FakeSpeechRecognitionService(
      scriptedResult: phrase.expectedTranscript,
      finalResult: false,
      availableLocales: const [
        SpeechLocale(id: 'en_US', name: 'English (US)'),
        SpeechLocale(id: 'en_IN', name: 'English (India)'),
      ],
    );
    final store = SttLocaleLabSessionStore();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SttLocaleLabScreen(speech: speech, sessionStore: store),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('stt_lab_phrase_card')), findsOneWidget);
    expect(find.byKey(const Key('stt_lab_speak_prompt')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stt_lab_record')));
    await tester.pump();
    expect(speech.lastLocaleId, 'en_US');
    expect(find.textContaining(phrase.expectedTranscript), findsWidgets);

    await tester.tap(find.byKey(const Key('stt_lab_record')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('stt_lab_result_card')), findsOneWidget);
    expect(find.textContaining('Exact match'), findsOneWidget);
    expect(store.resultsByLocale['en_US'], hasLength(1));
    expect(store.resultsByLocale['en_US']!.first.score.exactMatch, isTrue);
    expect(find.byKey(const Key('stt_lab_next')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stt_lab_next')));
    await tester.pump();
    expect(find.textContaining('Phrase 2 /'), findsOneWidget);
  });

  testWidgets('locale lab filters to English locales only', (tester) async {
    final speech = FakeSpeechRecognitionService(
      scriptedResult: 'x',
      availableLocales: const [
        SpeechLocale(id: 'te_IN', name: 'Telugu'),
        SpeechLocale(id: 'en_IN', name: 'English (India)'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(home: SttLocaleLabScreen(speech: speech)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const Key('stt_lab_locale_dropdown')));
    await tester.pumpAndSettle();
    expect(find.textContaining('en_IN'), findsWidgets);
    expect(find.textContaining('te_IN'), findsNothing);
  });
}
