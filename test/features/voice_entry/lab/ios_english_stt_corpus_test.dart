import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/lab/ios_english_stt_corpus.dart';

void main() {
  test('English STT corpus is non-empty and fixed', () {
    expect(iosEnglishSttCorpus, isNotEmpty);
    expect(iosEnglishSttCorpus.length, greaterThanOrEqualTo(6));
    expect(iosEnglishSttCorpus.length, lessThanOrEqualTo(8));
  });

  test('every phrase has id, speak prompt, and expected transcript', () {
    final ids = <String>{};
    for (final phrase in iosEnglishSttCorpus) {
      expect(phrase.id, isNotEmpty);
      expect(phrase.speakPrompt, isNotEmpty);
      expect(phrase.expectedTranscript, isNotEmpty);
      expect(ids.add(phrase.id), isTrue, reason: 'duplicate id ${phrase.id}');
    }
  });

  test('corpus includes South Pond feed and hard tray phrases', () {
    final prompts = iosEnglishSttCorpus.map((p) => p.speakPrompt).toList();
    expect(prompts, contains('South Pond growth booster feed 20 kg tray full'));
    expect(prompts, contains('South Pond growth booster 20 kg tray full'));
  });
}
