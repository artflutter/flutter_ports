// Original code, not ported from Chart.js: the date calendar tests.
import 'dart:math' as math;

import 'package:flutter_chartjs/src/core/date_calendar.dart';
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
double _startOf(double t, String unit) {
  final d = _utc(t);
  return _ms(switch (unit) {
    'second' => DateTime.utc(
      d.year,
      d.month,
      d.day,
      d.hour,
      d.minute,
      d.second,
    ),
    'minute' => DateTime.utc(d.year, d.month, d.day, d.hour, d.minute),
    'hour' => DateTime.utc(d.year, d.month, d.day, d.hour),
    'day' || 'date' => DateTime.utc(d.year, d.month, d.day),
    'week' => DateTime.utc(d.year, d.month, d.day - d.weekday % 7),
    'isoWeek' => DateTime.utc(d.year, d.month, d.day - (d.weekday - 1)),
    'month' => DateTime.utc(d.year, d.month),
    'quarter' => DateTime.utc(d.year, d.month - (d.month - 1) % 3),
    'year' => DateTime.utc(d.year),
    _ => throw ArgumentError(unit),
  });
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
double _add(double t, int amount, String unit) {
  final d = _utc(t);
  return switch (unit) {
    'millisecond' => t + amount,
    'second' => t + amount * 1000,
    'minute' => t + amount * 60000,
    'hour' => t + amount * 3600000,
    'day' => _ms(
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
    'week' => _add(t, amount * 7, 'day'),
    'month' => _addMonths(t, amount),
    'quarter' => _addMonths(t, amount * 3),
    'year' => _addMonths(t, amount * 12),
    _ => throw ArgumentError(unit),
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
    const startUnits = [
      'second',
      'minute',
      'hour',
      'day',
      'date',
      'week',
      'isoWeek',
      'month',
      'quarter',
      'year',
    ];
    const addUnits = [
      'millisecond',
      'second',
      'minute',
      'hour',
      'day',
      'week',
      'month',
      'quarter',
      'year',
    ];
    const amounts = [-13, -1, 1, 2, 13, 400];

    test('startOfUnit', () {
      final mismatches = <String>[];
      for (final t in times) {
        for (final unit in startUnits) {
          final got = startOfUnit(t, unit, null, 0);
          if (got != _startOf(t, unit)) mismatches.add('$t $unit');
        }
      }
      expect(mismatches, isEmpty);
    });

    test('addUnit with whole amounts', () {
      final mismatches = <String>[];
      for (final t in times) {
        for (final unit in addUnits) {
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
      expect(startOfUnit(t, 'week', null, 0), _ms(DateTime.utc(2014, 12, 28)));
      expect(startOfUnit(t, 'week', null, 1), _ms(DateTime.utc(2014, 12, 29)));
      expect(startOfUnit(t, 'week', null, 4), _ms(DateTime.utc(2015)));
      expect(startOfUnit(t, 'week', null, 6), _ms(DateTime.utc(2014, 12, 27)));
      expect(
        endOfUnit(t, 'week', null, 6),
        _ms(DateTime.utc(2015, 1, 3)) - 1,
      );
    });
  });

  group('normalizeDateUnit', () {
    test('gives each unit for its name, plural and short name', () {
      const table = {
        'millisecond': 'ms',
        'second': 's',
        'minute': 'm',
        'hour': 'h',
        'day': 'd',
        'date': 'D',
        'week': 'w',
        'isoWeek': 'W',
        'month': 'M',
        'quarter': 'Q',
        'year': 'y',
        'weekday': 'e',
        'isoWeekday': 'E',
        'dayOfYear': 'DDD',
        'weekYear': 'gg',
        'isoWeekYear': 'GG',
      };
      for (final MapEntry(key: unit, value: short) in table.entries) {
        final lower = unit.toLowerCase();
        expect(normalizeDateUnit(lower), unit);
        expect(normalizeDateUnit('${lower}s'), unit);
        expect(normalizeDateUnit(short), unit);
        expect(normalizeDateUnit(unit), unit);
        expect(normalizeDateUnit(unit.toUpperCase()), unit);
      }
    });

    test('tries the string, then its lower case', () {
      expect(normalizeDateUnit('MS'), 'millisecond');
      expect(normalizeDateUnit('Days'), 'day');
      expect(normalizeDateUnit('M'), 'month');
      expect(normalizeDateUnit('m'), 'minute');
      expect(normalizeDateUnit('Y'), 'year');
      expect(normalizeDateUnit('q'), isNull);
      expect(normalizeDateUnit('ddd'), isNull);
      expect(normalizeDateUnit('foo'), isNull);
      expect(normalizeDateUnit(''), isNull);
    });

    test('lowers the case as JS does', () {
      // JS toLowerCase gives 'i' and U+0307 for U+0130. The Dart VM gives
      // 'i' alone.
      expect(normalizeDateUnit('M\u0130NUTE'), isNull);
      expect(normalizeDateUnit('\u0130SOWEEK'), isNull);
      expect(normalizeDateUnit('MILLISECOND'), 'millisecond');
      // The Kelvin sign U+212A gives 'k' in JS and on the VM.
      expect(normalizeDateUnit('WEE\u212A'), 'week');
    });

    test('a value that is not a String is unknown', () {
      for (final value in [
        null,
        1.0,
        true,
        <Object?>['day'],
      ]) {
        expect(normalizeDateUnit(value), isNull, reason: '$value');
      }
    });

    test('a name of an Object.prototype member is a unit no case knows', () {
      const names = [
        'constructor',
        'CONSTRUCTOR',
        '__proto__',
        'toString',
        'valueOf',
        'hasOwnProperty',
        '__lookupSetter__',
      ];
      const t = 1420142400000.0;
      for (final name in names) {
        final unit = normalizeDateUnit(name);
        expect(unit, isNotNull, reason: name);
        expect(startOfUnit(t, unit, null, 0), isNaN, reason: name);
        expect(endOfUnit(t, unit, null, 0), isNaN, reason: name);
        expect(addUnit(t, 2, unit, null), t, reason: name);
        expect(diffUnit(t, 0, unit, null), t, reason: name);
      }
      expect(normalizeDateUnit('ToString'), isNull);
      expect(normalizeDateUnit('tostring'), isNull);
    });
  });
}
