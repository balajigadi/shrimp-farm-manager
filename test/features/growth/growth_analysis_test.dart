import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';
import 'package:prawn_farm_app/services/growth_analysis_service.dart';
import 'package:prawn_farm_app/services/growth_reference.dart';

Pond _pond({
  int stockingCount = 100000,
  double abw = 10,
  double survival = 90,
}) {
  return Pond(
    id: 'p1',
    farmId: 'f1',
    name: 'A1',
    location: 'x',
    areaAcres: 1,
    species: 'L. vannamei',
    stockingDate: DateTime(2026, 1, 1),
    stockingCount: stockingCount,
    initialStockingDensity: 20,
    daysOfCulture: 50,
    avgBodyWeightGrams: abw,
    survivalPercent: survival,
    totalFeedTons: 1,
    fcr: 1.2,
    estimatedHarvestDate: DateTime(2026, 4, 1),
    estimatedBiomassTons: 1,
  );
}

void main() {
  group('GrowthReference', () {
    test('closest DOC snaps to table keys', () {
      expect(GrowthReference.getClosestDoc(48), 50);
      expect(GrowthReference.getClosestDoc(0), 10);
      expect(GrowthReference.getClosestDoc(-5), 10);
    });

    test('DOC 50 expected range is 10–12 g', () {
      final range = GrowthReference.getExpectedRange(50);
      expect(range.expectedMin, 10);
      expect(range.expectedMax, 12);
    });

    test('status bands at DOC 50', () {
      expect(
        GrowthReference.evaluateGrowthStatus(50, 5).status,
        GrowthStatus.slow,
      );
      expect(
        GrowthReference.evaluateGrowthStatus(50, 10).status,
        GrowthStatus.good,
      );
      expect(
        GrowthReference.evaluateGrowthStatus(50, 11).status,
        GrowthStatus.good,
      );
      expect(
        GrowthReference.evaluateGrowthStatus(50, 12).status,
        GrowthStatus.good,
      );
      expect(
        GrowthReference.evaluateGrowthStatus(50, 20).status,
        GrowthStatus.excellent,
      );
    });

    test('parseStatus defaults unknown to good', () {
      expect(GrowthReference.parseStatus('SLOW'), GrowthStatus.slow);
      expect(GrowthReference.parseStatus('excellent'), GrowthStatus.excellent);
      expect(GrowthReference.parseStatus('???'), GrowthStatus.good);
    });
  });

  group('GrowthAnalysisService', () {
    final service = GrowthAnalysisService.instance;

    test('daysOfCulture never negative', () {
      expect(
        service.daysOfCulture(
          stockingDate: DateTime(2026, 7, 10),
          asOf: DateTime(2026, 7, 5),
        ),
        0,
      );
      expect(
        service.daysOfCulture(
          stockingDate: DateTime(2026, 7, 1),
          asOf: DateTime(2026, 7, 11),
        ),
        10,
      );
    });

    test('same calendar day as stocking is DOC 0', () {
      final day = DateTime(2026, 7, 1, 18);
      expect(
        service.daysOfCulture(stockingDate: DateTime(2026, 7, 1, 6), asOf: day),
        0,
      );
    });

    test('pondSummaryUpdate maps analysis fields', () {
      final analysis = service.analyze(
        stockingDate: DateTime(2026, 5, 21),
        actualAbw: 11,
        asOf: DateTime(2026, 7, 10),
      );
      final update = service.pondSummaryUpdate(
        analysis: analysis,
        survivalPercent: 88,
      );
      expect(update['avgBodyWeightGrams'], 11);
      expect(update['survivalPercent'], 88);
      expect(update['growthStatus'], isA<String>());
    });

    test('flags low feed and bad water as slow-growth contributors', () {
      final pond = _pond(abw: 10, survival: 90, stockingCount: 100000);
      final feedLogs = [
        FeedLog(
          id: '1',
          farmId: 'f1',
          pondId: 'p1',
          dateTime: DateTime.now(),
          feedType: 'pellet',
          quantityKg: 0.1,
        ),
      ];
      final waterLogs = [
        PondLog(
          id: 'w1',
          farmId: 'f1',
          pondId: 'p1',
          date: DateTime.now(),
          waterTempC: 30,
          dissolvedOxygen: 3.0,
          ph: 6.5,
          salinityPpt: 15,
          ammoniaPpm: 0.8,
          hardnessMgL: 50,
          feedKg: 0,
          mortalityCount: 0,
        ),
      ];

      final contributors = service.evaluateSlowGrowthContributors(
        pond: pond,
        feedLogs: feedLogs,
        waterLogs: waterLogs,
      );
      expect(contributors.feedLikelyLow, isTrue);
      expect(contributors.waterLikelyIssue, isTrue);
      expect(
        service.combinedSuggestion(
          status: GrowthStatus.slow,
          contributors: contributors,
        ),
        contains('low feeding or water issue'),
      );
    });
  });
}
