import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/utils/farm_metrics.dart';

void main() {
  group('FarmMetrics.totalFeedTonsFromKg', () {
    test('converts kg sum to tons', () {
      expect(FarmMetrics.totalFeedTonsFromKg([500, 500]), 1.0);
      expect(FarmMetrics.totalFeedTonsFromKg([250]), 0.25);
    });

    test('empty iterable is zero tons', () {
      expect(FarmMetrics.totalFeedTonsFromKg(const []), 0);
    });

    test('zero feed stays zero', () {
      expect(FarmMetrics.totalFeedTonsFromKg([0, 0]), 0);
    });
  });

  group('FarmMetrics.survivalPercent', () {
    test('zero mortality is 100% when stocked', () {
      expect(
        FarmMetrics.survivalPercent(stockingCount: 1000, totalMortality: 0),
        100,
      );
    });

    test('typical mortality', () {
      expect(
        FarmMetrics.survivalPercent(stockingCount: 1000, totalMortality: 100),
        closeTo(90, 0.001),
      );
    });

    test('mortality greater than stocking clamps to 0%', () {
      expect(
        FarmMetrics.survivalPercent(stockingCount: 1000, totalMortality: 5000),
        0,
      );
    });

    test('negative mortality is treated as zero deaths', () {
      expect(
        FarmMetrics.survivalPercent(stockingCount: 1000, totalMortality: -5),
        100,
      );
    });

    test('zero stocking returns 0', () {
      expect(
        FarmMetrics.survivalPercent(stockingCount: 0, totalMortality: 10),
        0,
      );
    });
  });

  group('FarmMetrics.estimatedBiomassTons', () {
    test('uses survivors times ABW', () {
      // 900 survivors * 20g / 1e6 = 0.018 tons
      expect(
        FarmMetrics.estimatedBiomassTons(
          stockingCount: 1000,
          totalMortality: 100,
          avgBodyWeightGrams: 20,
        ),
        closeTo(0.018, 1e-9),
      );
    });

    test('zero ABW is invalid (null)', () {
      expect(
        FarmMetrics.estimatedBiomassTons(
          stockingCount: 1000,
          totalMortality: 0,
          avgBodyWeightGrams: 0,
        ),
        isNull,
      );
    });

    test('negative ABW is invalid (null)', () {
      expect(
        FarmMetrics.estimatedBiomassTons(
          stockingCount: 1000,
          totalMortality: 0,
          avgBodyWeightGrams: -1,
        ),
        isNull,
      );
    });

    test('zero stocking is invalid (null)', () {
      expect(
        FarmMetrics.estimatedBiomassTons(
          stockingCount: 0,
          totalMortality: 0,
          avgBodyWeightGrams: 20,
        ),
        isNull,
      );
    });
  });

  group('FarmMetrics.fcr', () {
    test('feed over biomass', () {
      expect(
        FarmMetrics.fcr(totalFeedTons: 1.2, biomassTons: 0.8),
        closeTo(1.5, 1e-9),
      );
    });

    test('zero feed is unusable', () {
      expect(FarmMetrics.fcr(totalFeedTons: 0, biomassTons: 1), isNull);
    });

    test('zero biomass is unusable', () {
      expect(FarmMetrics.fcr(totalFeedTons: 1, biomassTons: 0), isNull);
    });

    test('negative sides are unusable', () {
      expect(FarmMetrics.fcr(totalFeedTons: -1, biomassTons: 1), isNull);
      expect(FarmMetrics.fcr(totalFeedTons: 1, biomassTons: -1), isNull);
    });
  });
}
