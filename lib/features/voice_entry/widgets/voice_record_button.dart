import 'package:flutter/material.dart';

class VoiceRecordButton extends StatelessWidget {
  const VoiceRecordButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.listening = false,
  });

  final VoidCallback? onPressed;
  final bool enabled;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: listening ? 'Stop recording' : 'Record farm activity',
      child: InkWell(
        key: const Key('voice_record_button'),
        onTap: enabled ? onPressed : null,
        customBorder: const CircleBorder(),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: listening
              ? const Color(0xFFAE2012)
              : const Color(0xFF005F73),
          child: Icon(
            listening ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 42,
          ),
        ),
      ),
    );
  }
}
