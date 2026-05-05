import 'package:flutter_test/flutter_test.dart';
import 'package:spendsnap/core/utils/date_utils.dart';

void main() {
  // Fixed reference dates — never call DateTime.now() in tests.
  final _referenceDate = DateTime(2024, 1, 15, 14, 30); // Jan 15 2024, 2:30 PM

  group('AppDateUtils.formatDay', () {
    test('formats a date as "d MMM yyyy"', () {
      expect(AppDateUtils.formatDay(_referenceDate), '15 Jan 2024');
    });

    test('formats the first day of a month correctly', () {
      expect(AppDateUtils.formatDay(DateTime(2024, 3, 1)), '1 Mar 2024');
    });

    test('formats the last day of a year correctly', () {
      expect(AppDateUtils.formatDay(DateTime(2023, 12, 31)), '31 Dec 2023');
    });
  });

  group('AppDateUtils.formatShortDay', () {
    test('formats a date as "d MMM" without the year', () {
      expect(AppDateUtils.formatShortDay(_referenceDate), '15 Jan');
    });
  });

  group('AppDateUtils.formatMonth', () {
    test('formats a date as "MMMM yyyy"', () {
      expect(AppDateUtils.formatMonth(_referenceDate), 'January 2024');
    });

    test('formats December correctly', () {
      expect(AppDateUtils.formatMonth(DateTime(2023, 12, 1)), 'December 2023');
    });
  });

  group('AppDateUtils.formatShortMonth', () {
    test('formats a date as "MMM yyyy"', () {
      expect(AppDateUtils.formatShortMonth(_referenceDate), 'Jan 2024');
    });
  });

  group('AppDateUtils.formatTime', () {
    test('formats time in 12-hour h:mm a format', () {
      final noon = DateTime(2024, 1, 15, 14, 30);
      final result = AppDateUtils.formatTime(noon);
      // 14:30 → "2:30 PM"
      expect(result, '2:30 PM');
    });

    test('formats midnight correctly', () {
      final midnight = DateTime(2024, 1, 15, 0, 0);
      final result = AppDateUtils.formatTime(midnight);
      expect(result, '12:00 AM');
    });
  });

  group('AppDateUtils.startOfMonth', () {
    test('returns the first day of the month at midnight', () {
      final start = AppDateUtils.startOfMonth(_referenceDate);
      expect(start, DateTime(2024, 1, 1));
    });

    test('works correctly for the start of a year', () {
      final start = AppDateUtils.startOfMonth(DateTime(2024, 1, 31));
      expect(start, DateTime(2024, 1, 1));
    });
  });

  group('AppDateUtils.endOfMonth', () {
    test('returns the last day of the month at 23:59:59', () {
      final end = AppDateUtils.endOfMonth(DateTime(2024, 1, 1));
      expect(end, DateTime(2024, 1, 31, 23, 59, 59));
    });

    test('handles February in a leap year', () {
      final end = AppDateUtils.endOfMonth(DateTime(2024, 2, 1));
      expect(end.day, 29, reason: '2024 is a leap year');
    });

    test('handles February in a non-leap year', () {
      final end = AppDateUtils.endOfMonth(DateTime(2023, 2, 1));
      expect(end.day, 28, reason: '2023 is not a leap year');
    });
  });

  group('AppDateUtils.daysInMonth', () {
    test('returns 31 for January', () {
      expect(AppDateUtils.daysInMonth(DateTime(2024, 1, 1)), 31);
    });

    test('returns 28 for February in a non-leap year', () {
      expect(AppDateUtils.daysInMonth(DateTime(2023, 2, 1)), 28);
    });

    test('returns 29 for February in a leap year', () {
      expect(AppDateUtils.daysInMonth(DateTime(2024, 2, 1)), 29);
    });

    test('returns 30 for April', () {
      expect(AppDateUtils.daysInMonth(DateTime(2024, 4, 1)), 30);
    });
  });

  group('AppDateUtils.startOfDay', () {
    test('strips time component from a datetime', () {
      final result = AppDateUtils.startOfDay(_referenceDate);
      expect(result, DateTime(2024, 1, 15));
      expect(result.hour, 0);
      expect(result.minute, 0);
      expect(result.second, 0);
    });
  });

  group('AppDateUtils.isSameMonth', () {
    test('returns true for two dates in the same month', () {
      final a = DateTime(2024, 1, 5);
      final b = DateTime(2024, 1, 25);
      expect(AppDateUtils.isSameMonth(a, b), isTrue);
    });

    test('returns false for dates in different months of the same year', () {
      final a = DateTime(2024, 1, 15);
      final b = DateTime(2024, 2, 15);
      expect(AppDateUtils.isSameMonth(a, b), isFalse);
    });

    test('returns false for the same calendar day across different years', () {
      final a = DateTime(2023, 1, 15);
      final b = DateTime(2024, 1, 15);
      expect(AppDateUtils.isSameMonth(a, b), isFalse);
    });
  });

  group('AppDateUtils.isWeekend', () {
    test('returns true for Saturday', () {
      final saturday = DateTime(2024, 1, 6); // Jan 6 2024 is a Saturday
      expect(AppDateUtils.isWeekend(saturday), isTrue);
    });

    test('returns true for Sunday', () {
      final sunday = DateTime(2024, 1, 7);
      expect(AppDateUtils.isWeekend(sunday), isTrue);
    });

    test('returns false for Monday', () {
      final monday = DateTime(2024, 1, 8);
      expect(AppDateUtils.isWeekend(monday), isFalse);
    });

    test('returns false for Friday', () {
      final friday = DateTime(2024, 1, 12);
      expect(AppDateUtils.isWeekend(friday), isFalse);
    });
  });

  group('AppDateUtils.nMonthsAgo', () {
    test('subtracts the correct number of months', () {
      final result = AppDateUtils.nMonthsAgo(DateTime(2024, 3, 15), 2);
      expect(result, DateTime(2024, 1, 15));
    });

    test('handles month underflow correctly (crossing year boundary)', () {
      final result = AppDateUtils.nMonthsAgo(DateTime(2024, 1, 15), 2);
      expect(result, DateTime(2023, 11, 15));
    });
  });

  group('AppDateUtils.formatFull', () {
    test('formats a datetime as "d MMM yyyy, h:mm a"', () {
      final date = DateTime(2024, 1, 15, 14, 30);
      expect(AppDateUtils.formatFull(date), '15 Jan 2024, 2:30 PM');
    });
  });
}
