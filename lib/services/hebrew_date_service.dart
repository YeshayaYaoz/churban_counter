import 'package:kosher_dart/kosher_dart.dart';

/// Service for calculating days since the destruction of the Beit HaMikdash.
///
/// The Second Temple was destroyed on Tisha B'Av (9 Av) 3828 in the Hebrew
/// calendar, corresponding to approximately August 4, 70 CE.
class HebrewDateService {
  /// The Hebrew year of the destruction of the Second Temple.
  static const int churbanYear = 3828;

  /// Month of Av in the Hebrew calendar.
  static const int monthAv = JewishDate.AV;

  /// Day of Tisha B'Av.
  static const int dayTishaBAv = 9;

  /// Returns today's Jewish date.
  static JewishDate getToday() {
    return JewishDate();
  }

  /// Returns the JewishCalendar for today.
  static JewishCalendar getTodayCalendar() {
    final cal = JewishCalendar();
    cal.inIsrael = true;
    return cal;
  }

  /// Returns the JewishDate for the Churban (9 Av 3828).
  static JewishDate getChurbanDate() {
    final date = JewishDate();
    date.setJewishDate(churbanYear, monthAv, dayTishaBAv);
    return date;
  }

  /// Calculates the total number of days since the Churban.
  ///
  /// Uses the absolute date (Julian Day Number) difference between
  /// 9 Av 3828 and today.
  static int daysSinceChurban() {
    final churbanDate = getChurbanDate();
    final today = getToday();
    final diff = today.getAbsDate() - churbanDate.getAbsDate();
    return diff;
  }

  /// Calculates years, months, and days since the Churban.
  static ChurbanDuration durationSinceChurban() {
    final today = getToday();
    final currentYear = today.getJewishYear();
    final currentMonth = today.getJewishMonth();
    final currentDay = today.getJewishDayOfMonth();

    int years = currentYear - churbanYear;
    int months = currentMonth - monthAv;
    int days = currentDay - dayTishaBAv;

    if (days < 0) {
      months -= 1;
      // Get days in previous month by creating a JewishDate for that month
      final prevMonthDate = JewishDate();
      int prevMonth = currentMonth > 1 ? currentMonth - 1 : 13;
      int prevYear = currentMonth > 1 ? currentYear : currentYear - 1;
      prevMonthDate.setJewishDate(prevYear, prevMonth, 1);
      days += prevMonthDate.getDaysInJewishMonth();
    }

    if (months < 0) {
      years -= 1;
      // Check if current year is a leap year (has 13 months)
      final yearDate = JewishDate();
      yearDate.setJewishDate(currentYear, 1, 1);
      months += yearDate.isJewishLeapYear() ? 13 : 12;
    }

    return ChurbanDuration(
      totalDays: daysSinceChurban(),
      years: years,
      months: months,
      days: days,
    );
  }

  /// Returns the Hebrew-formatted date string for today.
  static String getTodayHebrewFormatted() {
    final formatter = HebrewDateFormatter()
      ..hebrewFormat = true
      ..useGershGershayim = true;
    return formatter.format(getToday());
  }

  /// Returns the Gregorian-formatted date string for today.
  static String getTodayGregorianFormatted() {
    final today = DateTime.now();
    return '${today.day}/${today.month}/${today.year}';
  }

  /// Returns the Hebrew year as Hebrew numerals (e.g., ה'תשפ"ו).
  static String getHebrewYear() {
    final formatter = HebrewDateFormatter()
      ..hebrewFormat = true
      ..useGershGershayim = true;
    return formatter.formatHebrewNumber(getToday().getJewishYear());
  }

  /// Checks if today is Tisha B'Av.
  static bool isTodayTishaBAv() {
    final today = getToday();
    return today.getJewishMonth() == monthAv &&
        today.getJewishDayOfMonth() == dayTishaBAv;
  }

  /// Checks if we are currently in the Three Weeks
  /// (17 Tammuz to 9 Av).
  static bool isInThreeWeeks() {
    final today = getToday();
    final month = today.getJewishMonth();
    final day = today.getJewishDayOfMonth();

    if (month == JewishDate.TAMMUZ && day >= 17) return true;
    if (month == JewishDate.AV && day <= 9) return true;
    return false;
  }

  /// Checks if we are in the Nine Days (1 Av to 9 Av).
  static bool isInNineDays() {
    final today = getToday();
    return today.getJewishMonth() == JewishDate.AV &&
        today.getJewishDayOfMonth() <= 9;
  }

  /// Returns formatted data for the home widget.
  static Map<String, String> getWidgetData() {
    final duration = durationSinceChurban();
    final totalDays = duration.totalDays;

    return {
      'total_days': _formatNumber(totalDays),
      'total_days_raw': totalDays.toString(),
      'years': duration.years.toString(),
      'months': duration.months.toString(),
      'days': duration.days.toString(),
      'hebrew_date': getTodayHebrewFormatted(),
      'gregorian_date': getTodayGregorianFormatted(),
      'is_tisha_bav': isTodayTishaBAv().toString(),
      'is_three_weeks': isInThreeWeeks().toString(),
      'is_nine_days': isInNineDays().toString(),
    };
  }

  /// Formats a large number with comma separators.
  static String _formatNumber(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  /// Formats number with comma separators (public).
  static String formatNumberHebrew(int number) {
    return _formatNumber(number);
  }
}

/// Represents the duration since the Churban.
class ChurbanDuration {
  final int totalDays;
  final int years;
  final int months;
  final int days;

  const ChurbanDuration({
    required this.totalDays,
    required this.years,
    required this.months,
    required this.days,
  });

  @override
  String toString() =>
      '$years years, $months months, $days days (total: $totalDays days)';
}
