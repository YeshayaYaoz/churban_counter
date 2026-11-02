import 'dart:convert';

import 'package:kosher_dart/kosher_dart.dart';

/// Service for calculating days since the destruction of the Beit HaMikdash.
///
/// The Second Temple was destroyed on Tisha B'Av (9 Av) 3830 in the Hebrew
/// calendar, corresponding to August 4, 70 CE in the Julian calendar.
class HebrewDateService {
  /// The Hebrew year of the destruction of the Second Temple.
  static const int churbanYear = 3830;

  /// Month of Av in the Hebrew calendar.
  static const int monthAv = JewishDate.AV;

  /// Day of Tisha B'Av.
  static const int dayTishaBAv = 9;

  /// Days taken off the total count, so that 21 Cheshvan 5787 shows 714,502.
  ///
  /// Years and months are not affected and stay anchored to 9 Av.
  static const int totalDaysAdjustment = 3;

  /// Number of days covered by [getUpcomingDays], starting from today.
  ///
  /// The widgets keep advancing for this long without the app being opened.
  static const int upcomingDaysCount = 731;

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

  /// Returns the JewishDate for the Churban (9 Av 3830).
  static JewishDate getChurbanDate() {
    final date = JewishDate();
    date.setJewishDate(churbanYear, monthAv, dayTishaBAv);
    return date;
  }

  /// Calculates the total number of days since the Churban.
  ///
  /// Uses the absolute date (Julian Day Number) difference between
  /// 9 Av 3830 and [date], which defaults to today, less [totalDaysAdjustment].
  static int daysSinceChurban([JewishDate? date]) {
    final churbanDate = getChurbanDate();
    final today = date ?? getToday();
    final diff = today.getAbsDate() - churbanDate.getAbsDate();
    return diff - totalDaysAdjustment;
  }

  /// Calculates years, months, and days since the Churban.
  ///
  /// Counts whole Hebrew years up to the last 9 Av, then whole Hebrew months
  /// from there, so every 9 Av is an exact anniversary.
  static ChurbanDuration durationSinceChurban([JewishDate? date]) {
    final today = date ?? getToday();
    final todayAbs = today.getAbsDate();
    final currentMonth = today.getJewishMonth();

    // The Hebrew year turns over at Tishrei, so 9 Av has passed in the current
    // Hebrew year only between 9 Av and the end of Elul.
    final passedAvThisYear = currentMonth == JewishDate.ELUL ||
        (currentMonth == monthAv && today.getJewishDayOfMonth() >= dayTishaBAv);
    final lastAvYear = today.getJewishYear() - (passedAvThisYear ? 0 : 1);

    final cursor = JewishDate()
      ..setJewishDate(lastAvYear, monthAv, dayTishaBAv);
    int months = 0;
    int lastMonthAbs = cursor.getAbsDate();
    while (true) {
      cursor.forward(Calendar.MONTH, 1);
      if (cursor.getAbsDate() > todayAbs) break;
      months += 1;
      lastMonthAbs = cursor.getAbsDate();
    }

    return ChurbanDuration(
      totalDays: daysSinceChurban(today),
      years: lastAvYear - churbanYear,
      months: months,
      days: todayAbs - lastMonthAbs,
    );
  }

  /// Returns the Hebrew-formatted date string for [date].
  static String formatHebrewDate(JewishDate date) {
    final formatter = HebrewDateFormatter()
      ..hebrewFormat = true
      ..useGershGershayim = true;
    return formatter.format(date);
  }

  /// Returns the Hebrew-formatted date string for today.
  static String getTodayHebrewFormatted() {
    return formatHebrewDate(getToday());
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

  /// Checks if [date] is Tisha B'Av.
  static bool isTishaBAv(JewishDate date) {
    return date.getJewishMonth() == monthAv &&
        date.getJewishDayOfMonth() == dayTishaBAv;
  }

  /// Checks if today is Tisha B'Av.
  static bool isTodayTishaBAv() {
    return isTishaBAv(getToday());
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
    final today = getToday();
    final duration = durationSinceChurban(today);

    return {
      ..._widgetDay(today),
      'total_days_raw': duration.totalDays.toString(),
      'years': duration.years.toString(),
      'months': duration.months.toString(),
      'days': duration.days.toString(),
      'gregorian_date': getTodayGregorianFormatted(),
      'is_three_weeks': isInThreeWeeks().toString(),
      'is_nine_days': isInNineDays().toString(),
      'upcoming_days': jsonEncode(getUpcomingDays()),
    };
  }

  /// Returns what the widgets show on each of the next [upcomingDaysCount]
  /// days, starting from [from], which defaults to today.
  ///
  /// Keyed by Gregorian date (yyyy-MM-dd), since the date here turns over at
  /// midnight rather than at nightfall, like [getToday]. The native widgets
  /// can't run this code, so they look up the current date here instead.
  static Map<String, Map<String, String>> getUpcomingDays([DateTime? from]) {
    final start = from ?? DateTime.now();
    final days = <String, Map<String, String>>{};

    for (var i = 0; i < upcomingDaysCount; i++) {
      // UTC so that daylight saving can't skip or repeat a date.
      final day = DateTime.utc(start.year, start.month, start.day + i);
      days[day.toIso8601String().substring(0, 10)] =
          _widgetDay(JewishDate.fromDateTime(day));
    }

    return days;
  }

  /// Returns the values that change from day to day in the widgets.
  static Map<String, String> _widgetDay(JewishDate date) {
    final duration = durationSinceChurban(date);

    return {
      'total_days': _formatNumber(duration.totalDays),
      'years_months': formatYearsAndMonths(duration),
      'hebrew_date': formatHebrewDate(date),
      'is_tisha_bav': isTishaBAv(date).toString(),
    };
  }

  /// Formats years and months in Hebrew, e.g. "1,956 שנים ו-3 חודשים".
  ///
  /// Starts with a right-to-left mark so the leading number stays on the right
  /// on devices set to a left-to-right language.
  static String formatYearsAndMonths(ChurbanDuration duration) {
    final months = switch (duration.months) {
      0 => '',
      1 => ' וחודש',
      2 => ' וחודשיים',
      final count => ' ו-$count חודשים',
    };
    return '‏${_formatNumber(duration.years)} שנים$months';
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
