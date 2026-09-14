import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/features/feed/feed_tray_suggestion.dart';
import 'package:prawn_farm_app/features/pond/pond_model.dart';

FeedLog _log(DateTime at, double kg) {
  return FeedLog(
    id: '$at-$kg',
    farmId: 'f',
    pondId: 'p',
    dateTime: at,
    feedType: 'pellet',
    quantityKg: kg,
  );
}

void main() {
  group('suggestedNextFeedKg', () {
    test('empty tray increases ~12%', () {
      expect(
        suggestedNextFeedKg(100, FeedTrayStatus.empty),
        closeTo(112, 0.001),
      );
    });

    test('partial tray increases slightly', () {
      expect(
        suggestedNextFeedKg(100, FeedTrayStatus.partial),
        closeTo(102, 0.001),
      );
    });

    test('full tray decreases ~12%', () {
      expect(suggestedNextFeedKg(100, FeedTrayStatus.full), closeTo(88, 0.001));
    });
  });

  group('dailyTotalsChronological', () {
    test('one entry', () {
      expect(dailyTotalsChronological([_log(DateTime(2026, 7, 1, 8), 10)]), [
        10,
      ]);
    });

    test('several entries same day are summed', () {
      final totals = dailyTotalsChronological([
        _log(DateTime(2026, 7, 1, 8), 10),
        _log(DateTime(2026, 7, 1, 18), 5),
      ]);
      expect(totals, [15]);
    });

    test('multiple days stay chronological', () {
      final totals = dailyTotalsChronological([
        _log(DateTime(2026, 7, 1, 8), 10),
        _log(DateTime(2026, 7, 1, 18), 5),
        _log(DateTime(2026, 7, 2, 8), 20),
      ]);
      expect(totals, [15, 20]);
    });

    test('unsorted logs are ordered by calendar day', () {
      final totals = dailyTotalsChronological([
        _log(DateTime(2026, 7, 3, 8), 3),
        _log(DateTime(2026, 7, 1, 8), 1),
        _log(DateTime(2026, 7, 2, 8), 2),
      ]);
      expect(totals, [1, 2, 3]);
    });
  });

  group('trendFromDailyTotals', () {
    test('one entry is stable', () {
      expect(trendFromDailyTotals([10]), FeedTrendHint.stable);
    });

    test('increasing', () {
      expect(trendFromDailyTotals([10, 10, 20, 20]), FeedTrendHint.increasing);
    });

    test('decreasing', () {
      expect(trendFromDailyTotals([20, 20, 10, 10]), FeedTrendHint.decreasing);
    });

    test('stable within 5%', () {
      expect(trendFromDailyTotals([10, 10.2]), FeedTrendHint.stable);
    });
  });

  group('FeedTrayStatus.tryParse', () {
    test('parses known values', () {
      expect(FeedTrayStatus.tryParse('empty'), FeedTrayStatus.empty);
      expect(FeedTrayStatus.tryParse('partial'), FeedTrayStatus.partial);
      expect(FeedTrayStatus.tryParse('full'), FeedTrayStatus.full);
    });

    test('null and empty string are unknown', () {
      expect(FeedTrayStatus.tryParse(null), isNull);
      expect(FeedTrayStatus.tryParse(''), isNull);
    });

    test('unknown string is null', () {
      expect(FeedTrayStatus.tryParse('nope'), isNull);
      expect(FeedTrayStatus.tryParse('EMPTY'), isNull);
    });
  });
}
