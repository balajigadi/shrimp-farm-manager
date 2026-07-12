/// Pure pond metric formulas used by [FirestoreService] recalculation.
abstract final class FarmMetrics {
  /// Sum of feed log quantities (kg) → total feed in metric tons.
  static double totalFeedTonsFromKg(Iterable<double> quantityKg) {
    var totalKg = 0.0;
    for (final kg in quantityKg) {
      totalKg += kg;
    }
    return totalKg / 1000.0;
  }

  /// Survival % after clamping total mortality to [0, stockingCount].
  static double survivalPercent({
    required int stockingCount,
    required int totalMortality,
  }) {
    if (stockingCount <= 0) return 0;
    var dead = totalMortality;
    if (dead < 0) dead = 0;
    if (dead > stockingCount) dead = stockingCount;
    final survivors = stockingCount - dead;
    return (survivors / stockingCount) * 100.0;
  }

  /// Estimated biomass in tons from survivors × ABW (g).
  /// Returns null when ABW is not available (matches FirestoreService).
  static double? estimatedBiomassTons({
    required int stockingCount,
    required int totalMortality,
    required double avgBodyWeightGrams,
  }) {
    if (avgBodyWeightGrams <= 0) return null;
    if (stockingCount <= 0) return null;
    var dead = totalMortality;
    if (dead < 0) dead = 0;
    if (dead > stockingCount) dead = stockingCount;
    final survivors = stockingCount - dead;
    return survivors * avgBodyWeightGrams / 1e6;
  }

  /// FCR = total feed tons / biomass tons. Null when either side is unusable.
  static double? fcr({
    required double totalFeedTons,
    required double biomassTons,
  }) {
    if (totalFeedTons <= 0 || biomassTons <= 0) return null;
    return totalFeedTons / biomassTons;
  }
}
