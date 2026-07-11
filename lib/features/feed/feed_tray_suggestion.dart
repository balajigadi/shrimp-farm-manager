import 'package:prawn_farm_app/features/pond/pond_model.dart';

/// Simple next-feed hint from this amount + tray check (~±10–12%).
double suggestedNextFeedKg(double currentQtyKg, FeedTrayStatus tray) {
  final factor = switch (tray) {
    FeedTrayStatus.empty => 1.12,
    FeedTrayStatus.partial => 1.02,
    FeedTrayStatus.full => 0.88,
  };
  return (currentQtyKg * factor).clamp(0.1, 1e9);
}

/// Daily kg totals, oldest → newest (for trend).
List<double> dailyTotalsChronological(List<FeedLog> logs) {
  final byDate = <DateTime, double>{};
  for (final log in logs) {
    final d = DateTime(log.dateTime.year, log.dateTime.month, log.dateTime.day);
    byDate[d] = (byDate[d] ?? 0) + log.quantityKg;
  }
  final dates = byDate.keys.toList()..sort();
  return dates.map((d) => byDate[d]!).toList();
}

enum FeedTrendHint { increasing, decreasing, stable }

FeedTrendHint trendFromDailyTotals(List<double> dailyTotals) {
  if (dailyTotals.length < 2) return FeedTrendHint.stable;
  final mid = dailyTotals.length ~/ 2;
  final first = dailyTotals.sublist(0, mid);
  final second = dailyTotals.sublist(mid);
  double avg(List<double> xs) =>
      xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;
  final a1 = avg(first);
  final a2 = avg(second);
  if (a1 <= 0) return FeedTrendHint.stable;
  if (a2 > a1 * 1.05) return FeedTrendHint.increasing;
  if (a2 < a1 * 0.95) return FeedTrendHint.decreasing;
  return FeedTrendHint.stable;
}
