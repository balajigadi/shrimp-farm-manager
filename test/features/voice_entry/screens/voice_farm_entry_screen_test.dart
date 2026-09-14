import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/features/profile/user_profile.dart';
import 'package:prawn_farm_app/features/voice_entry/models/farm_activity_draft.dart';
import 'package:prawn_farm_app/features/voice_entry/screens/voice_farm_entry_screen.dart';
import 'package:prawn_farm_app/features/voice_entry/services/farm_activity_writer.dart';
import 'package:prawn_farm_app/features/voice_entry/services/speech_recognition_service.dart';
import 'package:prawn_farm_app/features/voice_entry/services/voice_speech_locale_picker.dart';
import 'package:prawn_farm_app/features/voice_entry/voice_entry_access.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../helpers/fake_speech_recognition_service.dart';
import '../helpers/recording_farm_activity_repository.dart';
import '../helpers/test_ponds.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 11, 10);

  MortalityActivityDraft validMortality({String? pondId = 'p2'}) {
    return MortalityActivityDraft(
      rawTranscript: 'Pond 2 mortality 12 reason low DO',
      occurredAt: now,
      pondId: pondId,
      pondReference: 'Pond 2',
      count: 12,
      reason: 'low DO',
    );
  }

  FeedActivityDraft incompleteFeed() {
    return FeedActivityDraft(
      rawTranscript: 'Pond 2 morning feed 45 kilos tray empty',
      occurredAt: now,
      pondId: 'p2',
      pondReference: 'Pond 2',
      quantityKg: 45,
      trayStatus: FeedTrayStatus.empty,
    );
  }

  FeedActivityDraft feedMissingTray() {
    return FeedActivityDraft(
      rawTranscript: 'South Point growth booster 20 kg stray full',
      occurredAt: now,
      pondId: 'ps',
      pondReference: 'South Pond',
      quantityKg: 20,
      feedType: 'growth booster',
    );
  }

  FeedActivityDraft feedWithTray(FeedTrayStatus tray) {
    return FeedActivityDraft(
      rawTranscript: 'South Pond growth booster feed 20 kg tray full',
      occurredAt: now,
      pondId: 'ps',
      pondReference: 'South Pond',
      quantityKg: 20,
      feedType: 'growth booster',
      trayStatus: tray,
    );
  }

  Widget harness({
    required RecordingFarmActivityRepository repo,
    FakeSpeechRecognitionService? speech,
    List<Pond>? ponds,
    FarmActivityDraft? initialDraft,
    VoiceLanguagePreference? voiceLanguagePreference =
        VoiceLanguagePreference.autoMixed,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: VoiceFarmEntryScreen(
        ponds: ponds ?? demoPonds(),
        speech: speech ?? FakeSpeechRecognitionService(),
        writer: FarmActivityWriter(repository: repo, farmId: () => 'farm-1'),
        now: now,
        initialDraft: initialDraft,
        voiceLanguagePreference: voiceLanguagePreference,
      ),
    );
  }

  Future<void> speak(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('voice_record_button')));
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.byKey(const Key('voice_review')).evaluate().isNotEmpty ||
          find.byKey(const Key('voice_error_message')).evaluate().isNotEmpty) {
        return;
      }
    }
  }

  Future<void> tapConfirm(WidgetTester tester) async {
    final confirm = find.byKey(const Key('voice_confirm_button'));
    await tester.ensureVisible(confirm);
    await tester.pump();
    await tester.tap(confirm);
    await tester.pump();
    await tester.pump();
  }

  Future<void> useTallSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder trayKey(String name) => find.byKey(Key(name), skipOffstage: false);

  testWidgets('speech result shows review and does not write', (tester) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(
        speech: FakeSpeechRecognitionService(
          scriptedResult: 'Pond 2 mortality 12 reason low DO',
        ),
        repo: repo,
      ),
    );
    await speak(tester);

    expect(find.byKey(const Key('voice_review')), findsOneWidget);
    expect(find.textContaining('Pond 2 mortality 12'), findsWidgets);
    expect(find.byKey(const Key('voice_confirm_button')), findsOneWidget);
    expect(repo.writeCount, 0);
  });

  testWidgets('I heard keeps raw STT text for noisy South Point transcript', (
    tester,
  ) async {
    const heard = 'South Point growth booster C20 kg prayful';
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(
        speech: FakeSpeechRecognitionService(scriptedResult: heard),
        repo: repo,
      ),
    );
    await speak(tester);

    expect(find.byKey(const Key('voice_review')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('voice_transcript_card')),
        matching: find.textContaining(heard),
      ),
      findsOneWidget,
    );
    expect(repo.writeCount, 0);
  });

  testWidgets('cancel does not write', (tester) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: validMortality()),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('voice_cancel_button')));
    await tester.tap(find.byKey(const Key('voice_cancel_button')));
    await tester.pump();
    expect(repo.writeCount, 0);
  });

  testWidgets('confirm stays disabled when validation fails', (tester) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: incompleteFeed()),
    );
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('voice_confirm_button')),
    );
    expect(button.onPressed, isNull);
    await tester.tap(find.byKey(const Key('voice_confirm_button')));
    await tester.pump();
    expect(repo.writeCount, 0);
  });

  testWidgets('confirm writes exactly one record', (tester) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: validMortality()),
    );
    await tester.pump();
    await tapConfirm(tester);
    expect(repo.mortalityLogs, hasLength(1));
    expect(repo.writeCount, 1);
    expect(find.byKey(const Key('voice_saved_success')), findsOneWidget);
  });

  testWidgets('double tap confirm cannot duplicate', (tester) async {
    final repo = RecordingFarmActivityRepository();
    final gate = Completer<void>();
    repo.beforeComplete = () => gate.future;
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: validMortality()),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('voice_confirm_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('voice_confirm_button')));
    await tester.tap(find.byKey(const Key('voice_confirm_button')));
    await tester.pump();
    gate.complete();
    await tester.pump();
    await tester.pump();
    expect(repo.writeCount, 1);
  });

  testWidgets('save failure keeps draft and does not show success', (
    tester,
  ) async {
    final repo = RecordingFarmActivityRepository()
      ..failWith = Exception('network');
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: validMortality()),
    );
    await tester.pump();
    await tapConfirm(tester);
    expect(find.byKey(const Key('voice_saved_success')), findsNothing);
    expect(find.byKey(const Key('voice_save_failed')), findsOneWidget);
    expect(find.byKey(const Key('voice_confirm_button')), findsOneWidget);
  });

  testWidgets('user can edit a parsed field before saving', (tester) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: incompleteFeed()),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('voice_field_feed_type'), skipOffstage: false),
      'pellet feed',
    );
    await tester.pump();
    await tapConfirm(tester);
    expect(repo.feedLogs, hasLength(1));
    expect(repo.feedLogs.single.feedType, 'pellet feed');
    expect(repo.feedLogs.single.quantityKg, 45);
  });

  testWidgets('missing tray status renders an editable tray control', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: feedMissingTray()),
    );
    await tester.pump();
    expect(trayKey('voice_field_tray'), findsOneWidget);
    expect(trayKey('voice_tray_empty'), findsOneWidget);
    expect(trayKey('voice_tray_partial'), findsOneWidget);
    expect(trayKey('voice_tray_full'), findsOneWidget);
    expect(repo.writeCount, 0);
  });

  testWidgets('Confirm is disabled while tray is missing', (tester) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: feedMissingTray()),
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('voice_confirm_button')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('voice_confirm_button')));
    await tester.pump();
    expect(repo.writeCount, 0);
  });

  testWidgets('selecting Full enables Confirm without Try Again', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: feedMissingTray()),
    );
    await tester.pump();
    await tester.ensureVisible(trayKey('voice_tray_full'));
    await tester.pumpAndSettle();
    await tester.tap(trayKey('voice_tray_full'));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('voice_confirm_button')))
          .onPressed,
      isNotNull,
    );
    expect(repo.writeCount, 0);
    await tapConfirm(tester);
    expect(repo.feedLogs, hasLength(1));
    expect(repo.feedLogs.single.trayStatus, FeedTrayStatus.full);
    expect(repo.writeCount, 1);
  });

  testWidgets('parsed tray full is preselected and Confirm is enabled', (
    tester,
  ) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: feedWithTray(FeedTrayStatus.full)),
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('voice_confirm_button')))
          .onPressed,
      isNotNull,
    );
    expect(repo.writeCount, 0);
  });

  testWidgets('changing parsed Full to Partial persists Partial', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: feedWithTray(FeedTrayStatus.full)),
    );
    await tester.pump();
    await tester.ensureVisible(trayKey('voice_tray_partial'));
    await tester.pumpAndSettle();
    await tester.tap(trayKey('voice_tray_partial'));
    await tester.pump();
    await tapConfirm(tester);
    expect(repo.feedLogs.single.trayStatus, FeedTrayStatus.partial);
  });

  testWidgets('Cancel on missing-tray feed still performs no write', (
    tester,
  ) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(repo: repo, initialDraft: feedMissingTray()),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('voice_cancel_button')));
    await tester.tap(find.byKey(const Key('voice_cancel_button')));
    await tester.pump();
    expect(repo.writeCount, 0);
  });

  testWidgets('ambiguous pond requires an explicit choice', (tester) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(
        repo: repo,
        ponds: [
          testPond(id: 'a', name: 'Pond 2'),
          testPond(id: 'b', name: 'Pond Two'),
        ],
        initialDraft: validMortality(pondId: null),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('voice_confirm_button')))
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byKey(const Key('voice_pond_dropdown')));
    await tester.tap(find.byKey(const Key('voice_pond_dropdown')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Pond Two').last);
    await tester.pump();
    await tapConfirm(tester);
    expect(repo.mortalityLogs.single.pondId, 'b');
  });

  testWidgets('microphone permission denial shows useful UI', (tester) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(
        speech: FakeSpeechRecognitionService(permissionDenied: true),
        repo: repo,
      ),
    );
    await speak(tester);
    expect(find.byKey(const Key('voice_error_message')), findsOneWidget);
    expect(find.byKey(const Key('voice_retry_button')), findsOneWidget);
    expect(repo.writeCount, 0);
  });

  testWidgets('speech unavailable shows useful UI', (tester) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(
        speech: FakeSpeechRecognitionService(available: false),
        repo: repo,
      ),
    );
    await speak(tester);
    expect(find.byKey(const Key('voice_error_message')), findsOneWidget);
    expect(repo.writeCount, 0);
  });

  testWidgets('empty transcript can retry', (tester) async {
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(
        speech: FakeSpeechRecognitionService(scriptedResult: ''),
        repo: repo,
      ),
    );
    await speak(tester);
    expect(find.byKey(const Key('voice_error_message')), findsOneWidget);
    expect(find.byKey(const Key('voice_retry_button')), findsOneWidget);
    expect(repo.writeCount, 0);
  });

  testWidgets('Telugu preference falls back when te-IN is missing', (
    tester,
  ) async {
    final repo = RecordingFarmActivityRepository();
    final speech = FakeSpeechRecognitionService(
      scriptedResult: 'Pond 2 mortality 12',
      availableLocales: const [
        SpeechLocale(id: 'en_IN', name: 'English (India)'),
      ],
    );
    await tester.pumpWidget(
      harness(
        speech: speech,
        repo: repo,
        voiceLanguagePreference: VoiceLanguagePreference.telugu,
      ),
    );
    await speak(tester);
    expect(speech.lastLocaleId, 'en_IN');
    expect(find.byKey(const Key('voice_locale_fallback')), findsOneWidget);
    expect(find.byKey(const Key('voice_review')), findsOneWidget);
    expect(repo.writeCount, 0);
  });

  testWidgets('English preference uses en-IN not en-US', (tester) async {
    final repo = RecordingFarmActivityRepository();
    final speech = FakeSpeechRecognitionService(
      scriptedResult: 'Pond 2 mortality 12',
      availableLocales: const [
        SpeechLocale(id: 'en_US', name: 'English (US)'),
        SpeechLocale(id: 'en_IN', name: 'English (India)'),
      ],
    );
    await tester.pumpWidget(
      harness(
        speech: speech,
        repo: repo,
        voiceLanguagePreference: VoiceLanguagePreference.english,
      ),
    );
    await speak(tester);
    expect(speech.lastLocaleId, 'en_IN');
    expect(find.byKey(const Key('voice_locale_fallback')), findsNothing);
  });

  testWidgets('incomplete mixed feed stays editable and unsaved', (
    tester,
  ) async {
    await useTallSurface(tester);
    final repo = RecordingFarmActivityRepository();
    await tester.pumpWidget(
      harness(
        speech: FakeSpeechRecognitionService(
          scriptedResult: 'Rendo pond lo feed vesam',
        ),
        repo: repo,
      ),
    );
    await speak(tester);
    expect(find.byKey(const Key('voice_review')), findsOneWidget);
    expect(find.textContaining('Rendo pond lo feed vesam'), findsWidgets);
    expect(
      find.byKey(const Key('voice_field_quantity'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('voice_field_feed_type'), skipOffstage: false),
      findsOneWidget,
    );
    expect(trayKey('voice_field_tray'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('voice_confirm_button')))
          .onPressed,
      isNull,
    );
    expect(repo.writeCount, 0);
  });

  test('trader-only users cannot access farm voice entry', () {
    expect(
      canAccessVoiceFarmEntry(
        const UserProfile(uid: 't', role: UserRole.trader),
      ),
      isFalse,
    );
    expect(
      canAccessVoiceFarmEntry(
        const UserProfile(uid: 'f', role: UserRole.farmer),
      ),
      isTrue,
    );
    expect(
      canAccessVoiceFarmEntry(
        const UserProfile(
          uid: 'f',
          role: UserRole.farmer,
          farmerIntent: FarmerIntent.buyerNotifications,
        ),
      ),
      isFalse,
    );
  });
}
