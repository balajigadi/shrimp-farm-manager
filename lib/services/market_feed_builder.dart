import '../features/market/requirement_model.dart';

/// Pure builder: filters and sorts requirements for the Market UI.
///
/// Mirrors the fleet app's [AlertFeedBuilder] pattern — Firestore-agnostic,
/// used by [MarketService] for client-side filtering when needed.
abstract final class MarketFeedBuilder {
  static List<MarketFeedItem> build({
    required List<BuyerRequirement> requirements,
    required String? farmerRegion,
    required DateTime now,
    bool traderView = false,
    String? traderId,
  }) {
    final out = <MarketFeedItem>[];

    for (final req in requirements) {
      if (traderView) {
        if (traderId != null && req.traderId != traderId) continue;
      } else {
        final region = farmerRegion?.trim();
        if (region == null || region.isEmpty) continue;
        if (!req.region.contains(region)) continue;
      }

      final isExpired = req.status != RequirementStatus.open ||
          !req.expiresAt.isAfter(now);

      if (!traderView && isExpired) continue;

      out.add(
        MarketFeedItem(
          requirement: req,
          matchesRegion: true,
          isExpired: isExpired,
        ),
      );
    }

    out.sort(
      (a, b) =>
          b.requirement.createdAt.compareTo(a.requirement.createdAt),
    );
    return out;
  }
}
