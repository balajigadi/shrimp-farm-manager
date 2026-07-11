import '../features/pond/pond_model.dart';
import 'growth_reference.dart';

class GrowthContributors {
  final bool feedLikelyLow;
  final bool waterLikelyIssue;

  const GrowthContributors({
    required this.feedLikelyLow,
    required this.waterLikelyIssue,
  });
}

class GrowthAnalysisResult {
  final int doc;
  final int closestDoc;
  final double expectedMin;
  final double expectedMax;
  final double actualAbw;
  final GrowthStatus status;
  final double growthGap;
  final List<String> quickSuggestions;

  const GrowthAnalysisResult({
    required this.doc,
    required this.closestDoc,
    required this.expectedMin,
    required this.expectedMax,
    required this.actualAbw,
    required this.status,
    required this.growthGap,
    required this.quickSuggestions,
  });

  String get statusLabel => GrowthReference.statusLabel(status);
}

class GrowthAnalysisService {
  GrowthAnalysisService._();

  static final GrowthAnalysisService instance = GrowthAnalysisService._();

  int daysOfCulture({
    required DateTime stockingDate,
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();
    final doc = now.difference(stockingDate).inDays;
    return doc < 0 ? 0 : doc;
  }

  GrowthAnalysisResult analyze({
    required DateTime stockingDate,
    required double actualAbw,
    DateTime? asOf,
  }) {
    final doc = daysOfCulture(stockingDate: stockingDate, asOf: asOf);
    final ref = GrowthReference.evaluateGrowthStatus(doc, actualAbw);
    final growthGap = actualAbw - ref.expectedMidpoint;
    return GrowthAnalysisResult(
      doc: doc,
      closestDoc: ref.closestDoc,
      expectedMin: ref.expectedMin,
      expectedMax: ref.expectedMax,
      actualAbw: actualAbw,
      status: ref.status,
      growthGap: growthGap,
      quickSuggestions: _quickSuggestions(ref.status),
    );
  }

  Map<String, dynamic> pondSummaryUpdate({
    required GrowthAnalysisResult analysis,
    required double survivalPercent,
  }) {
    return {
      'avgBodyWeightGrams': analysis.actualAbw,
      'survivalPercent': survivalPercent,
      'expectedAbwMin': analysis.expectedMin,
      'expectedAbwMax': analysis.expectedMax,
      'growthStatus': analysis.statusLabel,
      'growthGap': analysis.growthGap,
    };
  }

  GrowthContributors evaluateSlowGrowthContributors({
    required Pond pond,
    required List<FeedLog> feedLogs,
    required List<PondLog> waterLogs,
  }) {
    final recommendedDailyKg = _recommendedFeedKg(pond);
    final avgDailyFeedKg = _averageDailyFeedKgLast3Days(feedLogs);
    final feedLikelyLow = recommendedDailyKg > 0 &&
        avgDailyFeedKg > 0 &&
        avgDailyFeedKg < recommendedDailyKg * 0.8;

    final latestWater = _latestWaterLog(waterLogs);
    final waterLikelyIssue = latestWater != null &&
        (latestWater.dissolvedOxygen < 5.0 ||
            latestWater.ammoniaPpm > 0.5 ||
            latestWater.ph < 7.0 ||
            latestWater.ph > 9.0 ||
            latestWater.hardnessMgL < 90.0 ||
            latestWater.hardnessMgL > 300.0);

    return GrowthContributors(
      feedLikelyLow: feedLikelyLow,
      waterLikelyIssue: waterLikelyIssue,
    );
  }

  String combinedSuggestion({
    required GrowthStatus status,
    required GrowthContributors contributors,
  }) {
    if (status == GrowthStatus.good) {
      return 'Growth on track.';
    }
    if (status == GrowthStatus.excellent) {
      return 'Growth above expected.';
    }
    if (contributors.feedLikelyLow || contributors.waterLikelyIssue) {
      return 'Growth below expected. Likely due to low feeding or water issue.';
    }
    return 'Growth below expected. Check feed quantity and water quality.';
  }

  List<String> _quickSuggestions(GrowthStatus status) {
    switch (status) {
      case GrowthStatus.slow:
        return const ['Check feed quantity', 'Check water quality'];
      case GrowthStatus.excellent:
        return const ['Growth above expected'];
      case GrowthStatus.good:
        return const ['Growth on track'];
    }
  }

  PondLog? _latestWaterLog(List<PondLog> waterLogs) {
    if (waterLogs.isEmpty) return null;
    final sorted = [...waterLogs]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first;
  }

  double _averageDailyFeedKgLast3Days(List<FeedLog> feedLogs) {
    if (feedLogs.isEmpty) return 0;
    final byDay = <String, double>{};
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 2));
    for (final log in feedLogs) {
      if (log.dateTime.isBefore(start)) continue;
      final dayKey =
          '${log.dateTime.year}-${log.dateTime.month}-${log.dateTime.day}';
      byDay.update(dayKey, (v) => v + log.quantityKg,
          ifAbsent: () => log.quantityKg);
    }
    if (byDay.isEmpty) return 0;
    final total = byDay.values.reduce((a, b) => a + b);
    return total / byDay.length;
  }

  double _recommendedFeedKg(Pond pond) {
    final biomassKg = _biomassKg(pond);
    final feedRatePercent = _feedRateForWeight(pond.avgBodyWeightGrams);
    return biomassKg * feedRatePercent / 100.0;
  }

  double _biomassKg(Pond pond) {
    final seed = pond.stockingCount.toDouble();
    if (seed <= 0) return 0;
    final survival = pond.survivalPercent.clamp(0, 100) / 100.0;
    final w = pond.avgBodyWeightGrams;
    if (w <= 0) return 0;
    return seed * survival * w / 1000.0;
  }

  double _feedRateForWeight(double weightGrams) {
    if (weightGrams <= 0) return 0;
    if (weightGrams <= 3) return 13.5;
    if (weightGrams <= 5) return 9.0;
    if (weightGrams <= 10) return 5.5;
    if (weightGrams <= 15) return 4.5;
    if (weightGrams <= 20) return 3.5;
    if (weightGrams <= 25) return 2.75;
    if (weightGrams <= 35) return 2.25;
    if (weightGrams <= 50) return 1.75;
    return 1.5;
  }
}
