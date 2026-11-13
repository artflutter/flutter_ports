// Original code, not ported from Chart.js: the date calendar tests.
import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/core/core.adapters.dart' show TimeUnit;
import 'package:flutter_chartjs_port/src/core/date_calendar.dart';
import 'package:test/test.dart';

// The integer calendar of the default date adapter (Chart.js ADR 0024,
// decision 4) against `DateTime.utc` in the range where `DateTime.utc` does
// not wrap. The reference values of moment are in date_adapter_test.dart.

/// One day in ms.
const int _day = 86400000;

/// The time of a UTC `DateTime` as a `double`.
double _ms(DateTime date) => date.millisecondsSinceEpoch.toDouble();

/// The UTC `DateTime` of the time [t].
DateTime _utc(double t) =>
    DateTime.fromMillisecondsSinceEpoch(t.toInt(), isUtc: true);

/// `startOf(unit)` in UTC with the `DateTime` constructor.
double _startOf(double t, TimeUnit unit) {
  final d = _utc(t);
  return _ms(switch (unit) {
    TimeUnit.millisecond => d,
    TimeUnit.second => DateTime.utc(
      d.year,
      d.month,
      d.day,
      d.hour,
      d.minute,
      d.second,
    ),
    TimeUnit.minute => DateTime.utc(d.year, d.month, d.day, d.hour, d.minute),
    TimeUnit.hour => DateTime.utc(d.year, d.month, d.day, d.hour),
    TimeUnit.day => DateTime.utc(d.year, d.month, d.day),
    TimeUnit.week => DateTime.utc(d.year, d.month, d.day - d.weekday % 7),
    TimeUnit.month => DateTime.utc(d.year, d.month),
    TimeUnit.quarter => DateTime.utc(d.year, d.month - (d.month - 1) % 3),
    TimeUnit.year => DateTime.utc(d.year),
  });
}

/// The start of the ISO week (Monday) of [t] in UTC.
double _startOfIsoWeek(double t) {
  final d = _utc(t);
  return _ms(DateTime.utc(d.year, d.month, d.day - (d.weekday - 1)));
}

/// [t] plus [months] months with the month-end clamp, with the `DateTime`
/// constructor.
double _addMonths(double t, int months) {
  final d = _utc(t);
  final target = d.month - 1 + months;
  final year = d.year + (target - target % 12) ~/ 12;
  final month = target % 12 + 1;
  final last = DateTime.utc(year, month + 1, 0).day;
  return _ms(
    DateTime.utc(
      year,
      month,
      math.min(d.day, last),
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
    ),
  );
}

/// `add(amount, unit)` in UTC with the `DateTime` constructor, for a whole
/// amount.
double _add(double t, int amount, TimeUnit unit) {
  final d = _utc(t);
  return switch (unit) {
    TimeUnit.millisecond => t + amount,
    TimeUnit.second => t + amount * 1000,
    TimeUnit.minute => t + amount * 60000,
    TimeUnit.hour => t + amount * 3600000,
    TimeUnit.day => _ms(
      DateTime.utc(
        d.year,
        d.month,
        d.day + amount,
        d.hour,
        d.minute,
        d.second,
        d.millisecond,
      ),
    ),
    TimeUnit.week => _add(t, amount * 7, TimeUnit.day),
    TimeUnit.month => _addMonths(t, amount),
    TimeUnit.quarter => _addMonths(t, amount * 3),
    TimeUnit.year => _addMonths(t, amount * 12),
  };
}

void main() {
  group('day numbers', () {
    test('every day of 1600-2400', () {
      final first = DateTime.utc(1600).millisecondsSinceEpoch ~/ _day;
      final last = DateTime.utc(2400, 12, 31).millisecondsSinceEpoch ~/ _day;
      final mismatches = <int>[];
      for (var days = first; days <= last; days++) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          days * _day,
          isUtc: true,
        );
        final civil = civilFromDays(days);
        if (civil != (year: date.year, month: date.month, day: date.day) ||
            daysFromCivil(date.year, date.month, date.day) != days ||
            weekdayOfDays(days) != date.weekday % 7) {
          mismatches.add(days);
        }
      }
      expect(mismatches, isEmpty);
    });

    test('random days in the range of a Date', () {
      final random = math.Random(7);
      final mismatches = <int>[];
      for (var i = 0; i < 20000; i++) {
        final days = random.nextInt(200000001) - 100000000;
        final date = DateTime.fromMillisecondsSinceEpoch(
          days * _day,
          isUtc: true,
        );
        final civil = civilFromDays(days);
        if (civil != (year: date.year, month: date.month, day: date.day) ||
            daysFromCivil(date.year, date.month, date.day) != days) {
          mismatches.add(days);
        }
      }
      expect(mismatches, isEmpty);
    });

    test('a day outside the month counts on from day 1', () {
      expect(daysFromCivil(2015, 1, 32), daysFromCivil(2015, 2, 1));
      expect(daysFromCivil(2015, 3, 0), daysFromCivil(2015, 2, 28));
      expect(daysFromCivil(1970, 1, 1), 0);
    });

    test('daysInMonth', () {
      expect(
        [for (var m = 1; m <= 12; m++) daysInMonth(2015, m)],
        [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31],
      );
      expect(daysInMonth(2016, 2), 29);
      expect(daysInMonth(1900, 2), 28);
      expect(daysInMonth(2000, 2), 29);
      expect(daysInMonth(-4, 2), 29);
    });
  });

  group('timeClip', () {
    test('truncates toward zero inside ±8.64e15', () {
      expect(timeClip(1.7), 1);
      expect(timeClip(-1.7), -1);
      expect(timeClip(-0.5).isNegative, isFalse);
      expect(timeClip(8640000000000000), 8.64e15);
      expect(timeClip(-8640000000000000), -8.64e15);
    });

    test('gives NaN outside', () {
      expect(timeClip(8.64e15 + 1), isNaN);
      expect(timeClip(-8.64e15 - 1), isNaN);
      expect(timeClip(double.infinity), isNaN);
      expect(timeClip(double.nan), isNaN);
    });
  });

  group('startOfUnit and addUnit against DateTime.utc', () {
    final random = math.Random(13);
    final from = DateTime.utc(1900).millisecondsSinceEpoch;
    final to = DateTime.utc(2100).millisecondsSinceEpoch;
    final times = [
      for (var i = 0; i < 4096; i++)
        (from + (random.nextDouble() * (to - from)).floor()).toDouble(),
    ];
    const units = TimeUnit.values;
    const amounts = [-13, -1, 1, 2, 13, 400];

    test('startOfUnit', () {
      final mismatches = <String>[];
      for (final t in times) {
        for (final unit in units) {
          final got = startOfUnit(t, unit, null, 0);
          if (got != _startOf(t, unit)) mismatches.add('$t $unit');
        }
        // Weekday 1 of the ISO week is its Monday.
        if (startOfIsoWeekday(t, 1.0, null) != _startOfIsoWeek(t)) {
          mismatches.add('$t isoWeek');
        }
      }
      expect(mismatches, isEmpty);
    });

    test('addUnit with whole amounts', () {
      final mismatches = <String>[];
      for (final t in times) {
        for (final unit in units) {
          for (final amount in amounts) {
            final got = addUnit(t, amount.toDouble(), unit, null);
            if (got != _add(t, amount, unit)) {
              mismatches.add('$t $amount $unit');
            }
          }
        }
      }
      expect(mismatches, isEmpty);
    });

    test('the week starts on the day of the locale', () {
      // 2015-01-01 is a Thursday.
      final t = _ms(DateTime.utc(2015, 1, 1, 20));
      const week = TimeUnit.week;
      expect(startOfUnit(t, week, null, 0), _ms(DateTime.utc(2014, 12, 28)));
      expect(startOfUnit(t, week, null, 1), _ms(DateTime.utc(2014, 12, 29)));
      expect(startOfUnit(t, week, null, 4), _ms(DateTime.utc(2015)));
      expect(startOfUnit(t, week, null, 6), _ms(DateTime.utc(2014, 12, 27)));
      expect(endOfUnit(t, week, null, 6), _ms(DateTime.utc(2015, 1, 3)) - 1);
    });
  });

  group('a value that is not a unit', () {
    // The member gives Dart `null` for a value that is not a TimeUnit (row
    // adapt-time-unit-enum): moment gives the time for an unknown unit in
    // startOf and endOf, and the difference in ms in diff.
    test('gives the time, and the difference in ms', () {
      const t = 1420142400000.0;
      expect(startOfUnit(t, null, null, 0), t);
      expect(endOfUnit(t, null, null, 0), t);
      expect(diffUnit(t, 0, null, null), t);
    });
  });
}
