/// Whether the in-app STT Locale Lab is enabled.
///
/// True in debug builds, or when built with
/// `--dart-define=VOICE_STT_LOCALE_LAB=true` (Codemagic TestFlight).
bool voiceSttLocaleLabEnabled() {
  const fromDefine = bool.fromEnvironment(
    'VOICE_STT_LOCALE_LAB',
    defaultValue: false,
  );
  // kDebugMode is imported by callers that already use foundation;
  // keep this file free of Flutter if possible — use fromEnvironment only
  // plus a separate helper that checks kDebugMode.
  return fromDefine;
}

/// Lab enabled for local debug OR dart-define (TestFlight instrumentation).
bool isVoiceSttLocaleLabVisible({required bool isDebugMode}) {
  return isDebugMode || voiceSttLocaleLabEnabled();
}
