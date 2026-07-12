import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/utils/farm_metrics.dart';

void main() {
  group('FarmMetrics', () {
    test('totalFeedTonsFromKg converts kg sum to tons', () {
      expect(FarmMetrics.totalFeedTonsFromKg([500, 500]), 1.0);
      expect(FarmMetrics.totalFeedTonsFromKg(const []), 0);
    });

    test('survivalPercent clamps mortality', () {
      expect(
        FarmMetrics.survivalPercent(stockingCount: 1000, totalMortality: 100),
        closeTo(90, 0.001),
      );
      expect(
        FarmMetrics.survivalPercent(stockingCount: 1000, totalMortality: 5000),
        0,
      );
      expect(
        FarmMetrics.survivalPercent(stockingCount: 0, totalMortality: 10),
        0,
      );
    });

    test('estimatedBiomassTons uses survivors and ABW', () {
      // 900 survivors * 20g / 1e6 = 0.018 tons
      expect(
        FarmMetrics.estimatedBiomassTons(
          stockingCount: 1000,
          totalMortality: 100,
          avgBodyWeightGrams: 20,
        ),
        closeTo(0.018, 1e-9),
      );
      expect(
        FarmMetrics.estimatedBiomassTons(
          stockingCount: 1000,
          totalMortality: 0,
          avgBodyWeightGrams: 0,
        ),
        isNull,
      );
    });

    test('fcr requires positive feed and biomass', () {
      expect(
        FarmMetrics.fcr(totalFeedTons: 1.2, biomassTons: 0.8),
        closeTo(1.5, 1e-9),
      );
      expect(
        FarmMetrics.fcr(totalFeedTons: 0, biomassTons: 1),
        isNull,
      );
      expect(
        FarmMetrics.fcr(totalFeedTons: 1, biomassTons: 0),
        isNull,
      );
    });
  });
}
