/// Helpers for inclusive calendar-day ranges (avoids "last 7 days" bugs when
/// comparing [DateTime] values that include time-of-day).
class CalendarRanges {
  CalendarRanges._();

  static DateTime startOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// Last [dayCount] calendar days ending on [end] (inclusive), in local time.
  /// Example: dayCount=7, end=Mar 9 → includes Mar 3 … Mar 9 (7 days).
  static DateTime windowStartInclusive({
    required DateTime end,
    int dayCount = 7,
  }) {
    final endDay = startOfDay(end);
    return endDay.subtract(Duration(days: dayCount - 1));
  }

  /// True if [t] falls on a calendar day in \[ [startDay], [endDay] \]
  /// where [startDay]/[endDay] are typically from [startOfDay].
  static bool isDateInInclusiveRange(
    DateTime t,
    DateTime startDay,
    DateTime endDay,
  ) {
    final day = startOfDay(t);
    return !day.isBefore(startDay) && !day.isAfter(endDay);
  }

  /// For "last N days ending on [selected]" UIs: never use a future calendar
  /// day as the range end (there are no logs dated in the future).
  static DateTime clampEndOfRangeToToday(DateTime selected) {
    final today = startOfDay(DateTime.now());
    final sel = startOfDay(selected);
    return sel.isAfter(today) ? today : sel;
  }

  /// Distinct local calendar days in [dates] (e.g. for “daily average” when
  /// multiple log rows fall on the same day).
  static int distinctLocalDayCount(Iterable<DateTime> dates) {
    final seen = <int>{};
    for (final d in dates) {
      seen.add(DateTime(d.year, d.month, d.day).millisecondsSinceEpoch);
    }
    return seen.length;
  }
}
