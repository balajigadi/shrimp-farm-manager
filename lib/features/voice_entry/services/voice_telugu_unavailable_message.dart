import 'package:flutter/foundation.dart';
import 'package:prawn_farm_app/l10n/app_localizations.dart';

/// Platform-specific Telugu-unavailable STT banner. iOS must not mention Android.
String voiceTeluguSpeechUnavailableMessage(
  AppLocalizations l10n, {
  TargetPlatform? platform,
}) {
  final target = platform ?? defaultTargetPlatform;
  if (target == TargetPlatform.iOS) {
    return l10n.voiceTeluguSpeechUnavailableIos;
  }
  return l10n.voiceTeluguSpeechUnavailable;
}
