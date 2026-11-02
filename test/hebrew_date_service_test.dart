import 'dart:convert';

import 'package:churban_counter/services/hebrew_date_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kosher_dart/kosher_dart.dart';

JewishDate _date(int year, int month, int day) =>
    JewishDate()..setJewishDate(year, month, day);

void main() {
  group('durationSinceChurban', () {
    test('21 Cheshvan 5787 shows 714,502 days', () {
      final duration = HebrewDateService.durationSinceChurban(
        _date(5787, JewishDate.CHESHVAN, 21),
      );

      expect(duration.totalDays, 714502);
      expect(duration.years, 1956);
      expect(duration.months, 3);
      expect(duration.days, 12);
    });

    test('9 Av is an exact anniversary', () {
      final duration = HebrewDateService.durationSinceChurban(
        _date(5787, JewishDate.AV, 9),
      );

      expect(duration.years, 1957);
      expect(duration.months, 0);
      expect(duration.days, 0);
    });

    test('the day before 9 Av is short of a full year', () {
      final regularYear = HebrewDateService.durationSinceChurban(
        _date(5786, JewishDate.AV, 8),
      );
      final leapYear = HebrewDateService.durationSinceChurban(
        _date(5787, JewishDate.AV, 8),
      );

      expect(regularYear.years, 1955);
      expect(regularYear.months, 11);
      expect(leapYear.years, 1956);
      expect(leapYear.months, 12);
    });

    test('Tishrei does not add a year', () {
      final duration = HebrewDateService.durationSinceChurban(
        _date(5787, JewishDate.TISHREI, 1),
      );

      expect(duration.years, 1956);
      expect(duration.months, 1);
    });

    test('early Nissan after a year without Adar II', () {
      final duration = HebrewDateService.durationSinceChurban(
        _date(5786, JewishDate.NISSAN, 1),
      );

      expect(duration.years, 1955);
      expect(duration.months, 7);
    });

    test('moves forward one day at a time across a full 19-year cycle', () {
      final date = _date(5780, JewishDate.TISHREI, 1);
      var previous = HebrewDateService.durationSinceChurban(date);

      for (var i = 0; i < 7000; i++) {
        date.forward(Calendar.DATE, 1);
        final current = HebrewDateService.durationSinceChurban(date);

        expect(current.totalDays, previous.totalDays + 1);
        expect(current.months, inInclusiveRange(0, 12));
        expect(current.days, inInclusiveRange(0, 29));
        final stayedInMonth = current.years == previous.years &&
            current.months == previous.months &&
            current.days == previous.days + 1;
        final startedMonth = current.days == 0;
        expect(stayedInMonth || startedMonth, isTrue, reason: '$current');
        previous = current;
      }
    });
  });

  group('formatYearsAndMonths', () {
    String format(int months) => HebrewDateService.formatYearsAndMonths(
          ChurbanDuration(totalDays: 0, years: 1956, months: months, days: 0),
        );

    test('uses the Hebrew forms for each month count', () {
      expect(format(0), '‏1,956 שנים');
      expect(format(1), '‏1,956 שנים וחודש');
      expect(format(2), '‏1,956 שנים וחודשיים');
      expect(format(3), '‏1,956 שנים ו-3 חודשים');
    });
  });

  group('getUpcomingDays', () {
    String key(DateTime date) => date.toIso8601String().substring(0, 10);

    test('21 Cheshvan 5787 falls on 1 November 2026', () {
      final days = HebrewDateService.getUpcomingDays(DateTime(2026, 11, 1));

      expect(days['2026-11-01'], {
        'total_days': '714,502',
        'years_months': '‏1,956 שנים ו-3 חודשים',
        'hebrew_date': HebrewDateService.formatHebrewDate(
          _date(5787, JewishDate.CHESHVAN, 21),
        ),
        'is_tisha_bav': 'false',
      });
    });

    test('covers consecutive dates starting from the given day', () {
      final days = HebrewDateService.getUpcomingDays(DateTime(2026, 11, 1));

      expect(days.length, HebrewDateService.upcomingDaysCount);
      expect(days.keys.first, '2026-11-01');
      var expected = DateTime.utc(2026, 11, 1);
      for (final date in days.keys) {
        expect(date, key(expected));
        expected = expected.add(const Duration(days: 1));
      }
    });

    test('a time late in the day still starts from that date', () {
      final days = HebrewDateService.getUpcomingDays(
        DateTime(2026, 11, 1, 23, 59, 59),
      );

      expect(days.keys.first, '2026-11-01');
    });

    test('every entry matches the service for that date', () {
      final days = HebrewDateService.getUpcomingDays(DateTime(2027, 7, 1));

      days.forEach((date, values) {
        final jewishDate = JewishDate.fromDateTime(DateTime.parse(date));
        final duration = HebrewDateService.durationSinceChurban(jewishDate);

        expect(
          values['total_days'],
          HebrewDateService.formatNumberHebrew(duration.totalDays),
        );
        expect(
          values['years_months'],
          HebrewDateService.formatYearsAndMonths(duration),
        );
        expect(
          values['hebrew_date'],
          HebrewDateService.formatHebrewDate(jewishDate),
        );
      });
    });

    test('total days rises by one each day across the Gregorian year', () {
      final days = HebrewDateService.getUpcomingDays(DateTime(2026, 12, 30));
      final totals = days.values
          .map((day) => int.parse(day['total_days']!.replaceAll(',', '')))
          .toList();

      for (var i = 1; i < totals.length; i++) {
        expect(totals[i], totals[i - 1] + 1);
      }
    });

    test('only 9 Av is marked as Tisha B\'Av', () {
      final tishaBAv = _date(5787, JewishDate.AV, 9).getGregorianCalendar();
      final days = HebrewDateService.getUpcomingDays(DateTime(2027, 1, 1));
      final marked = days.entries
          .where((day) => day.value['is_tisha_bav'] == 'true')
          .map((day) => day.key);

      expect(marked.first, key(DateTime.utc(
        tishaBAv.year,
        tishaBAv.month,
        tishaBAv.day,
      )));
      expect(marked.length, 2);
    });
  });

  group('getWidgetData', () {
    test('the saved values match today in the upcoming days', () {
      final data = HebrewDateService.getWidgetData();
      final days = jsonDecode(data['upcoming_days']!) as Map<String, dynamic>;
      final today = days.values.first as Map<String, dynamic>;

      expect(days.length, HebrewDateService.upcomingDaysCount);
      for (final key in today.keys) {
        expect(today[key], data[key], reason: key);
      }
    });
  });
}
