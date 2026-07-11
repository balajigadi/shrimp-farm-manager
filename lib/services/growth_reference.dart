enum GrowthStatus { good, slow, excellent }

class GrowthReferenceResult {
  final int closestDoc;
  final double expectedMin;
  final double expectedMax;
  final GrowthStatus status;

  const GrowthReferenceResult({
    required this.closestDoc,
    required this.expectedMin,
    required this.expectedMax,
    required this.status,
  });

  double get expectedMidpoint => (expectedMin + expectedMax) / 2.0;
}

class GrowthReference {
  GrowthReference._();

  static const Map<int, List<double>> growthTable = {
    10: [0.2, 0.5],
    15: [0.5, 1.0],
    20: [1.0, 1.5],
    25: [1.5, 2.5],
    30: [2.5, 4.0],
    35: [4.0, 6.0],
    40: [6.0, 8.0],
    45: [8.0, 10.0],
    50: [10.0, 12.0],
    55: [12.0, 14.0],
    60: [14.0, 16.0],
    65: [16.0, 18.0],
    70: [18.0, 20.0],
    75: [20.0, 22.0],
    80: [22.0, 24.0],
    85: [24.0, 26.0],
    90: [26.0, 30.0],
    100: [30.0, 35.0],
    110: [35.0, 40.0],
    120: [40.0, 45.0],
  };

  static int getClosestDoc(int doc) {
    final safeDoc = doc < 0 ? 0 : doc;
    int closest = growthTable.keys.first;
    var smallestDiff = (safeDoc - closest).abs();
    for (final d in growthTable.keys) {
      final diff = (safeDoc - d).abs();
      if (diff < smallestDiff) {
        closest = d;
        smallestDiff = diff;
      }
    }
    return closest;
  }

  static ({double expectedMin, double expectedMax}) getExpectedRange(int doc) {
    final closest = getClosestDoc(doc);
    final range = growthTable[closest]!;
    return (expectedMin: range[0], expectedMax: range[1]);
  }

  static GrowthReferenceResult evaluateGrowthStatus(int doc, double actualAbw) {
    final closest = getClosestDoc(doc);
    final expected = getExpectedRange(doc);
    final status = actualAbw < expected.expectedMin
        ? GrowthStatus.slow
        : actualAbw > expected.expectedMax
            ? GrowthStatus.excellent
            : GrowthStatus.good;
    return GrowthReferenceResult(
      closestDoc: closest,
      expectedMin: expected.expectedMin,
      expectedMax: expected.expectedMax,
      status: status,
    );
  }

  static String statusLabel(GrowthStatus status) {
    switch (status) {
      case GrowthStatus.good:
        return 'GOOD';
      case GrowthStatus.slow:
        return 'SLOW';
      case GrowthStatus.excellent:
        return 'EXCELLENT';
    }
  }

  static GrowthStatus parseStatus(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'SLOW':
        return GrowthStatus.slow;
      case 'EXCELLENT':
        return GrowthStatus.excellent;
      default:
        return GrowthStatus.good;
    }
  }
}
