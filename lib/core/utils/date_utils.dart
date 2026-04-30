import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dayFormatter = DateFormat('d MMM yyyy');
  static final _shortDayFormatter = DateFormat('d MMM');
  static final _monthFormatter = DateFormat('MMMM yyyy');
  static final _shortMonthFormatter = DateFormat('MMM yyyy');
  static final _timeFormatter = DateFormat('h:mm a');
  static final _fullFormatter = DateFormat('d MMM yyyy, h:mm a');

  static String formatDay(DateTime date) => _dayFormatter.format(date);
  static String formatShortDay(DateTime date) =>
      _shortDayFormatter.format(date);
  static String formatMonth(DateTime date) => _monthFormatter.format(date);
  static String formatShortMonth(DateTime date) =>
      _shortMonthFormatter.format(date);
  static String formatTime(DateTime date) => _timeFormatter.format(date);
  static String formatFull(DateTime date) => _fullFormatter.format(date);

  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final diff = today.difference(dateOnly).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return formatDay(date);
  }

  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59);

  static int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime nMonthsAgo(DateTime from, int n) =>
      DateTime(from.year, from.month - n, from.day);

  static bool isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  static bool isWeekend(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
}
