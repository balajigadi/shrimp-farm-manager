import 'package:flutter/material.dart';

class VoiceTranscriptCard extends StatelessWidget {
  const VoiceTranscriptCard({
    super.key,
    required this.title,
    required this.transcript,
  });

  final String title;
  final String transcript;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('voice_transcript_card'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              transcript.isEmpty ? '—' : '"$transcript"',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
