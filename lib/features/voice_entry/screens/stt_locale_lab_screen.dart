import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../lab/ios_english_stt_corpus.dart';
import '../lab/stt_locale_lab_session.dart';
import '../lab/voice_stt_locale_lab_flags.dart';
import '../services/platform_speech_recognition_service.dart';
import '../services/speech_recognition_service.dart';
import '../services/voice_entry_debug_log.dart';
import '../services/voice_speech_locale_picker.dart';

/// Debug / dart-define gated lab for comparing English STT locales.
///
/// Does not save farm activities. Speaks the fixed English corpus under one
/// locale at a time; switch locale and re-run to compare.
class SttLocaleLabScreen extends StatefulWidget {
  const SttLocaleLabScreen({super.key, this.speech, this.sessionStore});

  final SpeechRecognitionService? speech;
  final SttLocaleLabSessionStore? sessionStore;

  static bool get isVisible =>
      isVoiceSttLocaleLabVisible(isDebugMode: kDebugMode);

  @override
  State<SttLocaleLabScreen> createState() => _SttLocaleLabScreenState();
}

class _SttLocaleLabScreenState extends State<SttLocaleLabScreen> {
  late final SpeechRecognitionService _speech;
  late final SttLocaleLabSessionStore _store;

  var _ready = false;
  var _listening = false;
  String? _error;
  List<SpeechLocale> _englishLocales = const [];
  String? _activeLocaleId;
  var _phraseIndex = 0;
  String _liveTranscript = '';
  var _showSummary = false;

  List<IosEnglishSttPhrase> get _corpus => _store.corpus;

  IosEnglishSttPhrase get _currentPhrase => _corpus[_phraseIndex];

  @override
  void initState() {
    super.initState();
    _speech = widget.speech ?? PlatformSpeechRecognitionService();
    _store = widget.sessionStore ?? SttLocaleLabSessionStore();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _speech.initialize();
      final locales = await _speech.locales();
      final english = locales.where((l) {
        final id = VoiceSpeechLocalePicker.canonicalize(l.id);
        return id == 'en' || id.startsWith('en_');
      }).toList();
      if (!mounted) return;
      setState(() {
        _englishLocales = english;
        _activeLocaleId = english.isNotEmpty
            ? english.first.id
            : VoiceSpeechLocalePicker.preferredEnglishId;
        _ready = true;
        _error = english.isEmpty
            ? 'No English speech locales available on this device.'
            : null;
      });
    } on SpeechRecognitionException catch (e) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _error = e.message ?? e.failure.name;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _error = 'Speech recognition failed to initialize.';
      });
    }
  }

  Future<void> _toggleListen() async {
    if (_listening) {
      await _finishListen();
      return;
    }
    final localeId = _activeLocaleId;
    if (localeId == null) return;
    setState(() {
      _error = null;
      _liveTranscript = '';
      _listening = true;
      _showSummary = false;
    });
    try {
      await _speech.startListening(
        localeId: localeId,
        onResult: (text, {required isFinal}) {
          if (!mounted) return;
          setState(() => _liveTranscript = text);
          if (isFinal) {
            _finishListen();
          }
        },
      );
    } on SpeechRecognitionException catch (e) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _error = e.message ?? e.failure.name;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _error = 'Could not start listening.';
      });
    }
  }

  Future<void>? _finishInFlight;

  Future<void> _finishListen() {
    return _finishInFlight ??= _finishListenBody();
  }

  Future<void> _finishListenBody() async {
    try {
      await _speech.stopListening();
      final localeId = _activeLocaleId;
      if (localeId == null || !mounted) return;
      final heard = _liveTranscript.trim();
      if (heard.isEmpty) {
        setState(() {
          _listening = false;
          _error = 'No speech captured. Try again.';
        });
        return;
      }
      final result = _store.record(
        localeId: localeId,
        phrase: _currentPhrase,
        heard: heard,
      );
      VoiceEntryDebugLog.localeLabResult(
        localeId: localeId,
        phraseId: result.phraseId,
        expected: result.expected,
        heard: result.heard,
        exactMatch: result.score.exactMatch,
        tokenRecall: result.score.tokenRecall,
        werProxy: result.score.werProxy,
      );
      setState(() => _listening = false);
    } finally {
      _finishInFlight = null;
    }
  }

  void _nextPhrase() {
    if (_phraseIndex >= _corpus.length - 1) {
      _completeLocaleRun();
      return;
    }
    setState(() {
      _phraseIndex += 1;
      _liveTranscript = '';
      _error = null;
    });
  }

  void _retryPhrase() {
    setState(() {
      _liveTranscript = '';
      _error = null;
    });
  }

  void _completeLocaleRun() {
    final localeId = _activeLocaleId;
    if (localeId != null) {
      final summary = _store.summaryFor(localeId);
      if (summary != null) {
        VoiceEntryDebugLog.localeLabSummary(
          localeId: summary.localeId,
          phraseCount: summary.phraseCount,
          exactRate: summary.exactRate,
          meanTokenRecall: summary.meanTokenRecall,
          meanWerProxy: summary.meanWerProxy,
        );
      }
    }
    setState(() {
      _showSummary = true;
      _liveTranscript = '';
    });
  }

  void _startLocaleRun() {
    final localeId = _activeLocaleId;
    if (localeId != null) {
      _store.clearLocale(localeId);
    }
    setState(() {
      _phraseIndex = 0;
      _liveTranscript = '';
      _showSummary = false;
      _error = null;
    });
  }

  Future<void> _copyReport() async {
    final report = _store.buildReport();
    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Locale lab report copied')));
  }

  SttLocaleLabPhraseResult? get _currentResult {
    final localeId = _activeLocaleId;
    if (localeId == null) return null;
    final list = _store.resultsByLocale[localeId];
    if (list == null) return null;
    for (final row in list) {
      if (row.phraseId == _currentPhrase.id) return row;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STT locale lab'),
        actions: [
          IconButton(
            key: const Key('stt_lab_copy_report'),
            tooltip: 'Copy report',
            onPressed: _store.resultsByLocale.isEmpty ? null : _copyReport,
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Speak each English farming phrase under one locale, '
                  'then switch locale and re-run. Compares raw STT only.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      key: const Key('stt_lab_error'),
                      style: const TextStyle(color: Color(0xFFAE2012)),
                    ),
                  ),
                _localePicker(),
                const SizedBox(height: 12),
                if (_showSummary) ...[
                  _summarySection(),
                ] else ...[
                  _phraseCard(),
                  const SizedBox(height: 12),
                  _listenControls(),
                  if (_currentResult != null) ...[
                    const SizedBox(height: 12),
                    _resultCard(_currentResult!),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const Key('stt_lab_retry'),
                            onPressed: _listening ? null : _retryPhrase,
                            child: const Text('Retry phrase'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            key: const Key('stt_lab_next'),
                            onPressed: _listening ? null : _nextPhrase,
                            child: Text(
                              _phraseIndex >= _corpus.length - 1
                                  ? 'Finish locale'
                                  : 'Next phrase',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
                if (_store.allSummaries().isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _comparisonTable(),
                ],
              ],
            ),
    );
  }

  Widget _localePicker() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Active English locale',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const Key('stt_lab_locale_dropdown'),
          isExpanded: true,
          value: _englishLocales.any((l) => l.id == _activeLocaleId)
              ? _activeLocaleId
              : null,
          hint: const Text('Select locale'),
          items: [
            for (final locale in _englishLocales)
              DropdownMenuItem(
                value: locale.id,
                child: Text('${locale.id} — ${locale.name}'),
              ),
          ],
          onChanged: _listening
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() {
                    _activeLocaleId = value;
                    _showSummary = false;
                    _phraseIndex = 0;
                    _liveTranscript = '';
                  });
                },
        ),
      ),
    );
  }

  Widget _phraseCard() {
    final phrase = _currentPhrase;
    return Card(
      key: const Key('stt_lab_phrase_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Phrase ${_phraseIndex + 1} / ${_corpus.length}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(phrase.id, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            const Text('Speak:'),
            Text(
              phrase.speakPrompt,
              key: const Key('stt_lab_speak_prompt'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_liveTranscript.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Heard:'),
              Text(_liveTranscript, key: const Key('stt_lab_heard')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _listenControls() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            key: const Key('stt_lab_record'),
            onPressed: _activeLocaleId == null ? null : _toggleListen,
            icon: Icon(_listening ? Icons.stop : Icons.mic),
            label: Text(_listening ? 'Stop' : 'Record'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            key: const Key('stt_lab_restart_run'),
            onPressed: _listening ? null : _startLocaleRun,
            child: const Text('Restart locale run'),
          ),
        ),
      ],
    );
  }

  Widget _resultCard(SttLocaleLabPhraseResult result) {
    final s = result.score;
    return Card(
      key: const Key('stt_lab_result_card'),
      color: s.exactMatch ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.exactMatch ? 'Exact match' : 'Mismatch',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              'token recall ${(s.tokenRecall * 100).toStringAsFixed(0)}%  ·  '
              'WER proxy ${(s.werProxy * 100).toStringAsFixed(0)}%',
            ),
            const SizedBox(height: 8),
            Text('Expected: ${result.expected}'),
            Text('Heard: ${result.heard}'),
          ],
        ),
      ),
    );
  }

  Widget _summarySection() {
    final localeId = _activeLocaleId ?? '';
    final summary = _store.summaryFor(localeId);
    return Card(
      key: const Key('stt_lab_summary_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finished $localeId',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (summary != null) ...[
              Text('Phrases: ${summary.phraseCount}'),
              Text(
                'Exact ${(summary.exactRate * 100).toStringAsFixed(0)}%  ·  '
                'Token recall ${(summary.meanTokenRecall * 100).toStringAsFixed(0)}%  ·  '
                'WER proxy ${(summary.meanWerProxy * 100).toStringAsFixed(0)}%',
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('stt_lab_run_again'),
              onPressed: _startLocaleRun,
              child: const Text('Run this locale again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comparisonTable() {
    final summaries = _store.allSummaries();
    return Card(
      key: const Key('stt_lab_comparison'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Locale comparison',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            for (final s in summaries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${s.localeId}: exact ${(s.exactRate * 100).toStringAsFixed(0)}%  '
                  'recall ${(s.meanTokenRecall * 100).toStringAsFixed(0)}%  '
                  'wer ${(s.meanWerProxy * 100).toStringAsFixed(0)}%  '
                  '(n=${s.phraseCount})',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
