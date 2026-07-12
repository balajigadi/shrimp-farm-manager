import 'package:flutter_test/flutter_test.dart';
import 'package:prawn_farm_app/utils/calendar_ranges.dart';
import 'package:prawn_farm_app/utils/relative_expiry.dart';
import 'package:prawn_farm_app/features/market/requirement_model.dart';
import 'package:prawn_farm_app/l10n/app_localizations_en.dart';

void main() {
  group('CalendarRanges', () {
    test('startOfDay strips time', () {
      final d = DateTime(2026, 7, 10, 15, 30);
      expect(CalendarRanges.startOfDay(d), DateTime(2026, 7, 10));
    });

    test('windowStartInclusive covers last N calendar days', () {
      final end = DateTime(2026, 3, 9, 18);
      expect(
        CalendarRanges.windowStartInclusive(end: end, dayCount: 7),
        DateTime(2026, 3, 3),
      );
    });

    test('isDateInInclusiveRange uses calendar days', () {
      final start = DateTime(2026, 3, 3);
      final end = DateTime(2026, 3, 9);
      expect(
        CalendarRanges.isDateInInclusiveRange(
          DateTime(2026, 3, 3, 23, 59),
          start,
          end,
        ),
        isTrue,
      );
      expect(
        CalendarRanges.isDateInInclusiveRange(
          DateTime(2026, 3, 2, 23, 59),
          start,
          end,
        ),
        isFalse,
      );
    });

    test('distinctLocalDayCount collapses same-day timestamps', () {
      expect(
        CalendarRanges.distinctLocalDayCount([
          DateTime(2026, 7, 1, 8),
          DateTime(2026, 7, 1, 20),
          DateTime(2026, 7, 2, 9),
        ]),
        2,
      );
    });
  });

  group('relative_expiry', () {
    final l10n = AppLocalizationsEn();
    final now = DateTime(2026, 7, 10, 12);

    test('labels expired / today / one day / many days', () {
      expect(
        formatRequirementExpiry(now.subtract(const Duration(hours: 1)), now, l10n),
        l10n.requirementExpired,
      );
      expect(
        formatRequirementExpiry(now.add(const Duration(hours: 5)), now, l10n),
        l10n.requirementExpiresToday,
      );
      expect(
        formatRequirementExpiry(now.add(const Duration(days: 1, hours: 1)), now, l10n),
        l10n.requirementExpiresInOneDay,
      );
      expect(
        formatRequirementExpiry(now.add(const Duration(days: 3)), now, l10n),
        l10n.requirementExpiresInDays(3),
      );
    });

    test('expired badge only for open + past expiry', () {
      expect(
        requirementShowsExpiredBadge(
          status: RequirementStatus.open,
          expiresAt: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        isTrue,
      );
      expect(
        requirementShowsExpiredBadge(
          status: RequirementStatus.fulfilled,
          expiresAt: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        isFalse,
      );
    });
  });
}
