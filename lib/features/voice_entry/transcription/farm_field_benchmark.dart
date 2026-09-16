import '../models/farm_activity_draft.dart';

/// Pure farm-field accuracy after the existing parser runs.
class FarmFieldBenchmarkScore {
  const FarmFieldBenchmarkScore({
    required this.activityCorrect,
    required this.pondCorrect,
    required this.quantityCorrect,
    required this.trayCorrect,
    required this.feedTypeCorrect,
    required this.waterNumericsCorrect,
    required this.growthCorrect,
    required this.mortalityCorrect,
    required this.criticalNumericMismatch,
    required this.correctionsNeeded,
  });

  final bool activityCorrect;
  final bool pondCorrect;
  final bool quantityCorrect;
  final bool trayCorrect;
  final bool feedTypeCorrect;
  final bool waterNumericsCorrect;
  final bool growthCorrect;
  final bool mortalityCorrect;
  final bool criticalNumericMismatch;
  final int correctionsNeeded;
}

class FarmFieldBenchmark {
  const FarmFieldBenchmark();

  FarmFieldBenchmarkScore score({
    required FarmActivityDraft expected,
    required FarmActivityDraft actual,
  }) {
    final activityOk = expected.runtimeType == actual.runtimeType;
    var pondOk = true;
    var quantityOk = true;
    var trayOk = true;
    var feedOk = true;
    var waterOk = true;
    var growthOk = true;
    var mortalityOk = true;
    var criticalNumeric = false;
    var corrections = 0;

    if (!activityOk) {
      return const FarmFieldBenchmarkScore(
        activityCorrect: false,
        pondCorrect: false,
        quantityCorrect: false,
        trayCorrect: false,
        feedTypeCorrect: false,
        waterNumericsCorrect: false,
        growthCorrect: false,
        mortalityCorrect: false,
        criticalNumericMismatch: true,
        correctionsNeeded: 1,
      );
    }

    pondOk =
        _eqIgnoreCase(expected.pondReference, actual.pondReference) ||
        (expected.pondId != null && expected.pondId == actual.pondId);

    if (expected is FeedActivityDraft && actual is FeedActivityDraft) {
      quantityOk = _numEq(expected.quantityKg, actual.quantityKg);
      trayOk = expected.trayStatus == actual.trayStatus;
      feedOk = _eqIgnoreCase(expected.feedType, actual.feedType);
      if (!quantityOk) criticalNumeric = true;
    } else if (expected is WaterQualityActivityDraft &&
        actual is WaterQualityActivityDraft) {
      waterOk =
          _numEq(expected.ph, actual.ph) &&
          _numEq(expected.dissolvedOxygen, actual.dissolvedOxygen) &&
          _numEq(expected.temperatureC, actual.temperatureC) &&
          _numEq(expected.salinityPpt, actual.salinityPpt) &&
          _numEq(expected.ammoniaPpm, actual.ammoniaPpm) &&
          _numEq(expected.hardnessMgL, actual.hardnessMgL);
      if (!waterOk) criticalNumeric = true;
    } else if (expected is GrowthActivityDraft &&
        actual is GrowthActivityDraft) {
      growthOk =
          _numEq(expected.avgBodyWeightGrams, actual.avgBodyWeightGrams) &&
          _numEq(expected.survivalPercent, actual.survivalPercent);
      if (!growthOk) criticalNumeric = true;
    } else if (expected is MortalityActivityDraft &&
        actual is MortalityActivityDraft) {
      mortalityOk = expected.count == actual.count;
      if (!mortalityOk) criticalNumeric = true;
    }

    void need(bool ok) {
      if (!ok) corrections += 1;
    }

    need(pondOk);
    if (expected is FeedActivityDraft) {
      need(quantityOk);
      need(trayOk);
      need(feedOk);
    } else if (expected is WaterQualityActivityDraft) {
      need(waterOk);
    } else if (expected is GrowthActivityDraft) {
      need(growthOk);
    } else if (expected is MortalityActivityDraft) {
      need(mortalityOk);
    }

    return FarmFieldBenchmarkScore(
      activityCorrect: activityOk,
      pondCorrect: pondOk,
      quantityCorrect: quantityOk,
      trayCorrect: trayOk,
      feedTypeCorrect: feedOk,
      waterNumericsCorrect: waterOk,
      growthCorrect: growthOk,
      mortalityCorrect: mortalityOk,
      criticalNumericMismatch: criticalNumeric,
      correctionsNeeded: corrections,
    );
  }

  static bool _eqIgnoreCase(String? a, String? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  static bool _numEq(num? a, num? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return (a - b).abs() < 0.0001;
  }
}
