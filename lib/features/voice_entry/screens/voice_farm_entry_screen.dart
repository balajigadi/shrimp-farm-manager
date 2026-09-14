import 'package:flutter/material.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';
import '../models/farm_activity_draft.dart';
import '../services/farm_activity_parser.dart';
import '../services/farm_activity_validator.dart';
import '../services/farm_activity_writer.dart';
import '../services/platform_speech_recognition_service.dart';
import '../services/rule_based_farm_activity_parser.dart';
import '../services/speech_recognition_service.dart';
import '../services/voice_entry_analytics.dart';
import '../services/voice_entry_debug_log.dart';
import '../services/voice_language_store.dart';
import '../services/voice_speech_locale_picker.dart';
import '../widgets/voice_record_button.dart';
import '../widgets/voice_transcript_card.dart';
import 'voice_confirmation_screen.dart';

enum VoiceEntryPhase {
  idle,
  initializing,
  listening,
  processing,
  review,
  saving,
  success,
  error,
}

class VoiceFarmEntryScreen extends StatefulWidget {
  const VoiceFarmEntryScreen({
    super.key,
    required this.ponds,
    this.speech,
    this.parser,
    this.writer,
    this.analytics = const NoOpVoiceEntryAnalytics(),
    this.now,
    this.initialDraft,
    this.voiceLanguagePreference,
    this.voiceLanguageStore = const VoiceLanguageStore(),
  });

  final List<Pond> ponds;
  final SpeechRecognitionService? speech;
  final FarmActivityParser? parser;
  final FarmActivityWriter? writer;
  final VoiceEntryAnalytics analytics;
  final DateTime? now;
  final FarmActivityDraft? initialDraft;
  final VoiceLanguagePreference? voiceLanguagePreference;
  final VoiceLanguageStore voiceLanguageStore;

  @override
  State<VoiceFarmEntryScreen> createState() => _VoiceFarmEntryScreenState();
}

class _VoiceFarmEntryScreenState extends State<VoiceFarmEntryScreen> {
  late final SpeechRecognitionService _speech;
  late final FarmActivityParser _parser;
  late final FarmActivityWriter _writer;
  final _validator = const FarmActivityValidator();

  VoiceEntryPhase _phase = VoiceEntryPhase.idle;
  String _liveTranscript = '';
  FarmActivityDraft? _draft;
  SpeechFailure? _speechFailure;
  var _saveFailed = false;
  var _saveInFlight = false;
  String? _localeNotice;

  @override
  void initState() {
    super.initState();
    _speech = widget.speech ?? PlatformSpeechRecognitionService();
    _parser = widget.parser ?? const RuleBasedFarmActivityParser();
    _writer = widget.writer ?? FarmActivityWriter();
    widget.analytics.track(VoiceEvents.opened);
    final seed = widget.initialDraft;
    if (seed != null) {
      _draft = seed;
      _liveTranscript = seed.rawTranscript;
      _phase = VoiceEntryPhase.review;
    }
  }

  Future<VoiceSpeechLocaleSelection> _selectSpeechLocale() async {
    final preference =
        widget.voiceLanguagePreference ??
        await widget.voiceLanguageStore.load();
    List<SpeechLocale> available = const [];
    try {
      available = await _speech.locales();
    } catch (_) {
      available = const [];
    }
    final selection = VoiceSpeechLocalePicker.pick(
      preference: preference,
      available: available,
    );
    VoiceEntryDebugLog.speechLocale(
      selectedLocaleId: selection.localeId,
      usedFallback: selection.usedFallback,
      teluguUnavailable: selection.teluguUnavailable,
    );
    return selection;
  }

  String? _fallbackNotice(
    AppLocalizations l10n,
    VoiceSpeechLocaleSelection selection,
  ) {
    if (!selection.teluguUnavailable) return null;
    if (widget.voiceLanguagePreference == VoiceLanguagePreference.english) {
      return null;
    }
    return l10n.voiceTeluguSpeechUnavailable;
  }

  Future<void> _toggleListening() async {
    if (_phase == VoiceEntryPhase.listening) {
      await _completeRecognition();
      return;
    }
    if (_phase == VoiceEntryPhase.initializing ||
        _phase == VoiceEntryPhase.processing ||
        _phase == VoiceEntryPhase.saving) {
      return;
    }
    await _startListening();
  }

  Future<void> _startListening() async {
    setState(() {
      _phase = VoiceEntryPhase.initializing;
      _liveTranscript = '';
      _draft = null;
      _speechFailure = null;
      _saveFailed = false;
      _localeNotice = null;
    });
    try {
      await _speech.initialize();
      if (!mounted) return;
      final selection = await _selectSpeechLocale();
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _phase = VoiceEntryPhase.listening;
        _localeNotice = _fallbackNotice(l10n, selection);
      });
      widget.analytics.track(VoiceEvents.listeningStarted);
      await _speech.startListening(
        localeId: selection.localeId,
        onResult: (text, {required isFinal}) {
          if (!mounted) return;
          setState(() => _liveTranscript = text);
          if (isFinal) {
            _completeRecognition();
          }
        },
      );
    } on SpeechRecognitionException catch (e) {
      widget.analytics.track(VoiceEvents.recognitionFailed);
      if (!mounted) return;
      setState(() {
        _phase = VoiceEntryPhase.error;
        _speechFailure = e.failure;
      });
    } catch (_) {
      widget.analytics.track(VoiceEvents.recognitionFailed);
      if (!mounted) return;
      setState(() {
        _phase = VoiceEntryPhase.error;
        _speechFailure = SpeechFailure.unknown;
      });
    }
  }

  Future<void>? _completeInFlight;

  Future<void> _completeRecognition() {
    if (_phase == VoiceEntryPhase.review ||
        _phase == VoiceEntryPhase.saving ||
        _phase == VoiceEntryPhase.success) {
      return Future.value();
    }
    return _completeInFlight ??= _completeRecognitionBody();
  }

  Future<void> _completeRecognitionBody() async {
    setState(() => _phase = VoiceEntryPhase.processing);
    try {
      await _speech.stopListening();
      final transcript = _liveTranscript.trim();
      if (transcript.isEmpty) {
        widget.analytics.track(VoiceEvents.recognitionFailed);
        if (!mounted) return;
        setState(() {
          _phase = VoiceEntryPhase.error;
          _speechFailure = SpeechFailure.noResult;
        });
        return;
      }
      widget.analytics.track(VoiceEvents.recognitionSucceeded);
      final draft = await _parser.parse(
        transcript,
        ponds: widget.ponds,
        now: widget.now,
      );
      final validation = _validator.validate(draft);
      widget.analytics.track(VoiceEvents.draftParsed);
      if (!validation.isValid) {
        widget.analytics.track(VoiceEvents.validationFailed);
      }
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _phase = VoiceEntryPhase.review;
      });
    } finally {
      _completeInFlight = null;
    }
  }

  void _onDraftChanged(FarmActivityDraft draft) {
    widget.analytics.track(VoiceEvents.draftEdited);
    setState(() {
      _draft = draft;
      _saveFailed = false;
    });
  }

  Future<void> _confirm() async {
    final draft = _draft;
    if (draft == null) return;
    if (_saveInFlight ||
        _phase == VoiceEntryPhase.saving ||
        _phase == VoiceEntryPhase.success) {
      return;
    }
    if (!_validator.validate(draft).isValid) return;

    _saveInFlight = true;
    widget.analytics.track(VoiceEvents.confirmed);
    setState(() {
      _phase = VoiceEntryPhase.saving;
      _saveFailed = false;
    });
    try {
      await _writer.save(draft, ponds: widget.ponds);
      if (!mounted) return;
      widget.analytics.track(VoiceEvents.saved);
      setState(() => _phase = VoiceEntryPhase.success);
    } catch (_) {
      _saveInFlight = false;
      widget.analytics.track(VoiceEvents.saveFailed);
      if (!mounted) return;
      setState(() {
        _phase = VoiceEntryPhase.review;
        _saveFailed = true;
      });
    }
  }

  void _tryAgain() {
    setState(() {
      _phase = VoiceEntryPhase.idle;
      _liveTranscript = '';
      _draft = null;
      _speechFailure = null;
      _saveFailed = false;
      _saveInFlight = false;
      _localeNotice = null;
      _completeInFlight = null;
    });
  }

  void _cancel() {
    widget.analytics.track(VoiceEvents.cancelled);
    Navigator.of(context).maybePop();
  }

  String _errorMessage(AppLocalizations l10n) {
    return switch (_speechFailure) {
      SpeechFailure.permissionDenied => l10n.voiceMicDenied,
      SpeechFailure.unavailable => l10n.voiceSpeechUnavailable,
      SpeechFailure.noResult => l10n.voiceEmptyTranscript,
      _ => l10n.voiceSpeechUnavailable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.voiceRecordFarmActivity),
        leading: IconButton(
          onPressed: _phase == VoiceEntryPhase.saving ? null : _cancel,
          icon: const Icon(Icons.close),
        ),
      ),
      body: switch (_phase) {
        VoiceEntryPhase.review || VoiceEntryPhase.saving => _review(l10n),
        VoiceEntryPhase.success => _success(l10n),
        _ => _capture(l10n),
      },
    );
  }

  Widget _review(AppLocalizations l10n) {
    final confirmation = VoiceConfirmationScreen(
      key: ValueKey(_draft?.rawTranscript),
      draft: _draft!,
      ponds: widget.ponds,
      onDraftChanged: _onDraftChanged,
      onConfirm: _confirm,
      onTryAgain: _tryAgain,
      onCancel: _cancel,
      saving: _phase == VoiceEntryPhase.saving,
      saveFailed: _saveFailed,
    );
    final notice = _localeNotice;
    if (notice == null) return confirmation;
    return Column(
      children: [
        _localeBanner(notice),
        Expanded(child: confirmation),
      ],
    );
  }

  Widget _localeBanner(String notice) {
    return Material(
      color: const Color(0xFFFFF3CD),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Text(
          notice,
          key: const Key('voice_locale_fallback'),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _success(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF0A9396), size: 72),
            const SizedBox(height: 16),
            Text(
              l10n.voiceSaved,
              key: const Key('voice_saved_success'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: Text(l10n.voiceDone),
            ),
          ],
        ),
      ),
    );
  }

  Widget _capture(AppLocalizations l10n) {
    final listening = _phase == VoiceEntryPhase.listening;
    final busy =
        _phase == VoiceEntryPhase.initializing ||
        _phase == VoiceEntryPhase.processing;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.voiceRecordFarmActivity,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        Center(
          child: busy
              ? const CircularProgressIndicator()
              : VoiceRecordButton(
                  listening: listening,
                  onPressed: _toggleListening,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          listening ? l10n.voiceListening : l10n.voiceTapToSpeak,
          key: Key(listening ? 'voice_listening_label' : 'voice_idle_label'),
          textAlign: TextAlign.center,
        ),
        if (_localeNotice != null) ...[
          const SizedBox(height: 12),
          _localeBanner(_localeNotice!),
        ],
        if (listening) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('voice_stop_button'),
            onPressed: _completeRecognition,
            child: Text(l10n.voiceStop),
          ),
        ],
        if (_liveTranscript.isNotEmpty) ...[
          const SizedBox(height: 16),
          VoiceTranscriptCard(
            title: l10n.voiceIHeard,
            transcript: _liveTranscript,
          ),
        ],
        if (_phase == VoiceEntryPhase.error) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage(l10n),
            key: const Key('voice_error_message'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFAE2012)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('voice_retry_button'),
            onPressed: _tryAgain,
            child: Text(l10n.voiceTryAgain),
          ),
        ],
        const SizedBox(height: 32),
        Text(l10n.voiceExamplesTitle, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(l10n.voiceExampleFeed, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(l10n.voiceExampleWater, textAlign: TextAlign.center),
      ],
    );
  }
}
