import 'speech_recognition_service.dart';

/// Minimal voice-language setting, separate from app UI language.
enum VoiceLanguagePreference { autoMixed, telugu, english }

class VoiceSpeechLocaleSelection {
  const VoiceSpeechLocaleSelection({
    required this.localeId,
    required this.usedFallback,
    required this.teluguUnavailable,
  });

  /// Id to pass to the speech plugin. Never null — empty device lists
  /// still request `en_IN` rather than silently forcing `en_US`.
  final String localeId;
  final bool usedFallback;
  final bool teluguUnavailable;
}

/// Picks an on-device STT locale from the runtime list. Does not assume
/// every Android device exposes the same ids (`te_IN` vs `te-IN`).
class VoiceSpeechLocalePicker {
  const VoiceSpeechLocalePicker();

  static const preferredEnglishId = 'en_IN';
  static const preferredTeluguId = 'te_IN';

  static VoiceSpeechLocaleSelection pick({
    required VoiceLanguagePreference preference,
    required List<SpeechLocale> available,
  }) {
    final telugu =
        _findLanguage(available, 'te', country: 'in') ??
        _findLanguage(available, 'te');
    final englishIn = _findLanguage(available, 'en', country: 'in');
    final anyEnglish = _findLanguage(available, 'en');
    final teluguUnavailable = telugu == null;

    switch (preference) {
      case VoiceLanguagePreference.telugu:
        if (telugu != null) {
          return VoiceSpeechLocaleSelection(
            localeId: telugu.id,
            usedFallback: false,
            teluguUnavailable: false,
          );
        }
        return VoiceSpeechLocaleSelection(
          localeId: englishIn?.id ?? anyEnglish?.id ?? preferredEnglishId,
          usedFallback: true,
          teluguUnavailable: true,
        );
      case VoiceLanguagePreference.english:
        if (englishIn != null) {
          return VoiceSpeechLocaleSelection(
            localeId: englishIn.id,
            usedFallback: false,
            teluguUnavailable: teluguUnavailable,
          );
        }
        return VoiceSpeechLocaleSelection(
          localeId: anyEnglish?.id ?? preferredEnglishId,
          usedFallback: true,
          teluguUnavailable: teluguUnavailable,
        );
      case VoiceLanguagePreference.autoMixed:
        if (telugu != null) {
          return VoiceSpeechLocaleSelection(
            localeId: telugu.id,
            usedFallback: false,
            teluguUnavailable: false,
          );
        }
        return VoiceSpeechLocaleSelection(
          localeId: englishIn?.id ?? anyEnglish?.id ?? preferredEnglishId,
          usedFallback: true,
          teluguUnavailable: true,
        );
    }
  }

  static String? storeValue(VoiceLanguagePreference preference) {
    return preference.name;
  }

  static VoiceLanguagePreference parseStored(String? raw) {
    return switch (raw) {
      'telugu' => VoiceLanguagePreference.telugu,
      'english' => VoiceLanguagePreference.english,
      _ => VoiceLanguagePreference.autoMixed,
    };
  }

  static String canonicalize(String localeId) {
    return localeId.toLowerCase().replaceAll('-', '_');
  }

  static SpeechLocale? _findLanguage(
    List<SpeechLocale> available,
    String language, {
    String? country,
  }) {
    final lang = language.toLowerCase();
    final matches = available.where((locale) {
      final id = canonicalize(locale.id);
      return id == lang || id.startsWith('${lang}_');
    }).toList();
    if (matches.isEmpty) return null;
    if (country != null) {
      final wanted = country.toLowerCase();
      for (final locale in matches) {
        final id = canonicalize(locale.id);
        if (id == '${lang}_$wanted' || id.startsWith('${lang}_${wanted}_')) {
          return locale;
        }
      }
      return null;
    }
    return matches.first;
  }
}
