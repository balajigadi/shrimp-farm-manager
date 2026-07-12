import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/feed/feed_tray_suggestion.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';

void main() {
  group('suggestedNextFeedKg', () {
    test('empty tray increases ~12%', () {
      expect(suggestedNextFeedKg(100, FeedTrayStatus.empty), closeTo(112, 0.001));
    });

    test('partial tray increases slightly', () {
      expect(suggestedNextFeedKg(100, FeedTrayStatus.partial), closeTo(102, 0.001));
    });

    test('full tray decreases ~12%', () {
      expect(suggestedNextFeedKg(100, FeedTrayStatus.full), closeTo(88, 0.001));
    });
  });

  group('dailyTotalsChronological / trend', () {
    test('aggregates same calendar day', () {
      final totals = dailyTotalsChronological([
        FeedLog(
          id: '1',
          farmId: 'f',
          pondId: 'p',
          dateTime: DateTime(2026, 7, 1, 8),
          feedType: 'pellet',
          quantityKg: 10,
        ),
        FeedLog(
          id: '2',
          farmId: 'f',
          pondId: 'p',
          dateTime: DateTime(2026, 7, 1, 18),
          feedType: 'pellet',
          quantityKg: 5,
        ),
        FeedLog(
          id: '3',
          farmId: 'f',
          pondId: 'p',
          dateTime: DateTime(2026, 7, 2, 8),
          feedType: 'pellet',
          quantityKg: 20,
        ),
      ]);
      expect(totals, [15, 20]);
    });

    test('trend detects increase / decrease / stable', () {
      expect(trendFromDailyTotals([10, 10, 20, 20]), FeedTrendHint.increasing);
      expect(trendFromDailyTotals([20, 20, 10, 10]), FeedTrendHint.decreasing);
      expect(trendFromDailyTotals([10, 10.2]), FeedTrendHint.stable);
      expect(trendFromDailyTotals([10]), FeedTrendHint.stable);
    });
  });

  group('FeedTrayStatus.tryParse', () {
    test('parses known values and rejects unknown', () {
      expect(FeedTrayStatus.tryParse('empty'), FeedTrayStatus.empty);
      expect(FeedTrayStatus.tryParse('partial'), FeedTrayStatus.partial);
      expect(FeedTrayStatus.tryParse('full'), FeedTrayStatus.full);
      expect(FeedTrayStatus.tryParse('nope'), isNull);
      expect(FeedTrayStatus.tryParse(null), isNull);
    });
  });
}
