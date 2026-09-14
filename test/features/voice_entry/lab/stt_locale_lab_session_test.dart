import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/voice_entry/lab/ios_english_stt_corpus.dart';
import 'package:prawn_farm_app/features/voice_entry/lab/stt_locale_lab_session.dart';

void main() {
  test('session store records per locale and builds report', () {
    final store = SttLocaleLabSessionStore();
    final phrase = iosEnglishSttCorpus.first;
    store.record(
      localeId: 'en_IN',
      phrase: phrase,
      heard: phrase.expectedTranscript,
    );
    store.record(
      localeId: 'en_US',
      phrase: phrase,
      heard: 'South Point growth booster feed 20 kg tray full',
    );

    final inSummary = store.summaryFor('en_IN')!;
    final usSummary = store.summaryFor('en_US')!;
    expect(inSummary.exactRate, 1);
    expect(usSummary.exactRate, 0);
    expect(store.allSummaries(), hasLength(2));

    final report = store.buildReport();
    expect(report, contains('en_IN'));
    expect(report, contains('en_US'));
    expect(report, contains(phrase.id));
  });

  test('recording same phrase again replaces prior result', () {
    final store = SttLocaleLabSessionStore();
    final phrase = iosEnglishSttCorpus.first;
    store.record(localeId: 'en_IN', phrase: phrase, heard: 'wrong');
    store.record(
      localeId: 'en_IN',
      phrase: phrase,
      heard: phrase.expectedTranscript,
    );
    expect(store.resultsByLocale['en_IN'], hasLength(1));
    expect(store.summaryFor('en_IN')!.exactRate, 1);
  });
}
