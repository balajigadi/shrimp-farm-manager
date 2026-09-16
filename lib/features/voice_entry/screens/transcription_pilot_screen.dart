import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../transcription/transcription_pilot_log.dart';

class TranscriptionPilotScreen extends StatefulWidget {
  const TranscriptionPilotScreen({super.key, this.log});

  final TranscriptionPilotLog? log;

  @override
  State<TranscriptionPilotScreen> createState() =>
      _TranscriptionPilotScreenState();
}

class _TranscriptionPilotScreenState extends State<TranscriptionPilotScreen> {
  late final TranscriptionPilotLog _log;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _log = widget.log ?? TranscriptionPilotLog();
    _load();
  }

  Future<void> _load() async {
    await _log.load();
    if (!mounted) return;
    setState(() => _loaded = true);
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _log.toClipboardText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transcription pilot log copied')),
    );
  }

  Future<void> _clear() async {
    await _log.clear();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final attempts = _log.attempts;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transcription pilot'),
        actions: [
          IconButton(
            key: const Key('transcription_pilot_copy'),
            tooltip: 'Copy CSV',
            onPressed: attempts.isEmpty ? null : _copy,
            icon: const Icon(Icons.copy),
          ),
          IconButton(
            key: const Key('transcription_pilot_clear'),
            tooltip: 'Clear',
            onPressed: attempts.isEmpty ? null : _clear,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Debug-only comparison log. Audio is never stored.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                if (attempts.isEmpty)
                  const Text('No transcription attempts recorded yet.'),
                for (final attempt in attempts) _attemptCard(attempt),
              ],
            ),
    );
  }

  Widget _attemptCard(TranscriptionPilotAttempt attempt) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${attempt.providerId} · ${attempt.latencyMs} ms',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(attempt.at.toLocal().toString()),
            if (attempt.usedFallback) const Text('Fallback used'),
            if (attempt.error != null)
              Text(
                'Error: ${attempt.error}',
                style: const TextStyle(color: Color(0xFFAE2012)),
              ),
            if (attempt.transcript.isNotEmpty) Text(attempt.transcript),
          ],
        ),
      ),
    );
  }
}
