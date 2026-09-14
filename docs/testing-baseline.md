# Testing baseline — Prawn Farm Manager

This document captures the quality baseline used before and after adding **Voice Farm Entry**. Existing farm formulas, market rules, and Firestore collections were not changed to make tests pass.

## Toolchain

Captured from `flutter --version` in this workspace:

* Flutter 3.38.5
* Dart 3.10.4

## Commands executed

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

After Voice Farm Entry:

```bash
dart format .
flutter analyze
flutter test
flutter build apk --debug
```

There is no `integration_test/` Firebase Emulator suite in this repository.

## Characterization / regression tests added (before voice UI)

These lock **current** business behavior (no formula redesign):

| File | What it characterizes |
| --- | --- |
| `test/utils/farm_metrics_test.dart` | Feed kg→tons, survival, biomass, FCR, zero/invalid cases |
| `test/features/feed/feed_tray_suggestion_test.dart` | Tray empty/partial/full adjustments, daily totals, trends, `FeedTrayStatus.tryParse` |
| `test/features/growth/growth_analysis_test.dart` | DOC, expected ranges, SLOW/GOOD/EXCELLENT, boundaries |
| `test/market_feed_builder_test.dart` | Existing market feed + `MarketRules` boundaries |
| `test/calendar_and_expiry_test.dart` | Calendar windows and relative expiry labels |

## Voice Farm Entry tests (after baseline)

| File | Purpose |
| --- | --- |
| `test/features/voice_entry/models/farm_activity_draft_test.dart` | Typed drafts; missing numbers stay null |
| `test/features/voice_entry/services/farm_activity_parser_test.dart` | Rule-based English + mixed Telugu-English phrases |
| `test/features/voice_entry/services/farm_activity_validator_test.dart` | Required fields; no zero-filling |
| `test/features/voice_entry/services/pond_resolver_test.dart` | Pond matching, unknown, ambiguous |
| `test/features/voice_entry/services/farm_activity_writer_test.dart` | Confirmed drafts → existing domain models via fake repository |
| `test/features/voice_entry/screens/voice_farm_entry_screen_test.dart` | Fake speech; no write until Confirm; double-submit; errors |

## Analyzer

`flutter analyze` reports **no errors**. Remaining infos/warnings are pre-existing (deprecated `Radio`/`DropdownButton` `value`, unused `_PlaceholderPage`, etc.) and were not mass-fixed. Analyzer exit code is non-zero because of that unused-element warning.

## Tests

`flutter test`: **122 passed**.

## Android debug build

`flutter build apk --debug` is required to pass on a machine with working Gradle/SSL access. Output APK path:

`build/app/outputs/flutter-apk/app-debug.apk`

This workspace hit a **PKIX SSL error** downloading `flutter_embedding_debug` from `storage.googleapis.com` (Java trust store / proxy). That is an environment issue, not an application compile error. Re-run the same command locally if Gradle can reach Flutter's Maven mirror.

## Known limitations of this baseline

* Widget tests do not initialize Firebase; AuthGate/`PrawnFarmApp` smoke remains a unit stub.
* No device microphone is used in tests; speech is injected.
* Platform speech quality (especially Telugu / mixed speech) can only be judged on a real phone.
* Debug APK size/time depends on Gradle cache on the machine.
