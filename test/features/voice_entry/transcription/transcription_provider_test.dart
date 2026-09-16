import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/services/farm_speech_normalizer.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/openai_transcription_provider.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/platform_transcription_provider.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/resolving_transcription_provider.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/transcription_failure.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/transcription_request.dart';
import 'package:prawn_farm_app/features/voice_entry/transcription/voice_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_speech_recognition_service.dart';
import '../helpers/test_ponds.dart';
import 'fake_farm_transcription_client.dart';
import 'fake_voice_audio_recorder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformTranscriptionProvider', () {
    test('returns raw platform transcript', () async {
      final speech = FakeSpeechRecognitionService(
        scriptedResult: 'Feed Pandu 245 kgs Re enti',
      );
      final provider = PlatformTranscriptionProvider(speech: speech);
      await provider.start(request: const TranscriptionRequest());
      final result = await provider.stop();
      expect(result.providerId, 'platform');
      expect(result.transcript, 'Feed Pandu 245 kgs Re enti');
    });
  });

  group('provider → normalizer invariant', () {
    test('raw provider text is passed unchanged into normalizer', () {
      const raw = 'Feed Pandu 245 kgs Re enti';
      const normalizer = FarmSpeechNormalizer();
      final normalized = normalizer.normalize(raw, ponds: demoPonds());
      expect(normalized.rawTranscript, raw);
    });
  });

  group('OpenAiTranscriptionProvider', () {
    test('success deletes temp audio and returns transcript', () async {
      final recorder = FakeVoiceAudioRecorder();
      final client = FakeFarmTranscriptionClient(
        transcript: 'Feed Pond 2 45 kg tray empty',
      );
      final provider = OpenAiTranscriptionProvider(
        recorder: recorder,
        client: client,
        networkAvailable: () async => true,
      );
      await provider.start(
        request: const TranscriptionRequest(pondNames: ['Pond 2']),
      );
      final result = await provider.stop();
      expect(result.transcript, 'Feed Pond 2 45 kg tray empty');
      expect(result.providerId, 'openai_gpt_transcribe');
      expect(recorder.deleteCalls, 1);
      expect(client.calls, 1);
    });

    test('failure still deletes audio', () async {
      final recorder = FakeVoiceAudioRecorder();
      final client = FakeFarmTranscriptionClient(
        failure: TranscriptionException(TranscriptionFailure.timeout),
      );
      final provider = OpenAiTranscriptionProvider(
        recorder: recorder,
        client: client,
        networkAvailable: () async => true,
      );
      await provider.start(request: const TranscriptionRequest());
      await expectLater(
        provider.stop(),
        throwsA(
          isA<TranscriptionException>().having(
            (e) => e.failure,
            'failure',
            TranscriptionFailure.timeout,
          ),
        ),
      );
      expect(recorder.deleteCalls, 1);
    });

    test('empty transcript surfaces empty failure', () async {
      final provider = OpenAiTranscriptionProvider(
        recorder: FakeVoiceAudioRecorder(),
        client: FakeFarmTranscriptionClient(transcript: '  '),
        networkAvailable: () async => true,
      );
      await provider.start(request: const TranscriptionRequest());
      await expectLater(
        provider.stop(),
        throwsA(
          isA<TranscriptionException>().having(
            (e) => e.failure,
            'failure',
            TranscriptionFailure.empty,
          ),
        ),
      );
    });

    test('offline before start fails with networkUnavailable', () async {
      final provider = OpenAiTranscriptionProvider(
        recorder: FakeVoiceAudioRecorder(),
        client: FakeFarmTranscriptionClient(),
        networkAvailable: () async => false,
      );
      await expectLater(
        provider.start(request: const TranscriptionRequest()),
        throwsA(
          isA<TranscriptionException>().having(
            (e) => e.failure,
            'failure',
            TranscriptionFailure.networkUnavailable,
          ),
        ),
      );
    });

    test('double start is rejected', () async {
      final provider = OpenAiTranscriptionProvider(
        recorder: FakeVoiceAudioRecorder(),
        client: FakeFarmTranscriptionClient(),
        networkAvailable: () async => true,
      );
      await provider.start(request: const TranscriptionRequest());
      await expectLater(
        provider.start(request: const TranscriptionRequest()),
        throwsA(
          isA<TranscriptionException>().having(
            (e) => e.failure,
            'failure',
            TranscriptionFailure.busy,
          ),
        ),
      );
      await provider.cancel();
    });

    test('cancel cleans up recording', () async {
      final recorder = FakeVoiceAudioRecorder();
      final provider = OpenAiTranscriptionProvider(
        recorder: recorder,
        client: FakeFarmTranscriptionClient(),
        networkAvailable: () async => true,
      );
      await provider.start(request: const TranscriptionRequest());
      await provider.cancel();
      expect(recorder.stopCalls + recorder.cancelCalls, greaterThan(0));
      expect(recorder.deleteCalls, greaterThan(0));
    });

    test('max duration defaults to 20 seconds', () async {
      final recorder = FakeVoiceAudioRecorder();
      final provider = OpenAiTranscriptionProvider(
        recorder: recorder,
        client: FakeFarmTranscriptionClient(),
        networkAvailable: () async => true,
      );
      await provider.start(request: const TranscriptionRequest());
      expect(recorder.lastMaxDuration, TranscriptionRequest.defaultMaxDuration);
      await provider.cancel();
    });
  });

  group('ResolvingTranscriptionProvider auto', () {
    test('offline auto uses platform', () async {
      final speech = FakeSpeechRecognitionService(
        scriptedResult: 'platform transcript',
      );
      final platform = PlatformTranscriptionProvider(speech: speech);
      final cloud = OpenAiTranscriptionProvider(
        recorder: FakeVoiceAudioRecorder(),
        client: FakeFarmTranscriptionClient(),
        networkAvailable: () async => false,
      );
      final resolver = ResolvingTranscriptionProvider(
        engine: VoiceEngine.auto,
        platform: platform,
        cloud: cloud,
        networkAvailable: () async => false,
      );
      await resolver.start(request: const TranscriptionRequest());
      final result = await resolver.stop();
      expect(result.transcript, 'platform transcript');
      expect(result.usedFallback, isTrue);
      expect(result.providerId, 'platform');
    });
  });

  group('VoiceEngineStore', () {
    test('persists selection', () async {
      SharedPreferences.setMockInitialValues({});
      const store = VoiceEngineStore();
      await store.save(VoiceEngine.cloud);
      expect(await store.load(), VoiceEngine.cloud);
      await store.save(VoiceEngine.auto);
      expect(await store.load(), VoiceEngine.auto);
    });
  });
}
