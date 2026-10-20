// Original code, not ported from Chart.js: the date adapter tests of the VM.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_chartjs/src/core/core.adapters.dart';
import 'package:flutter_chartjs/src/core/date_adapter.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:intl/intl.dart';
import 'package:test/test.dart';

// The cases of the default date adapter (Chart.js ADR 0024) that need
// package:clock, Intl.defaultLocale or a file. A web test file can import
// neither package:clock nor package:intl (check:lib-imports), so these cases
// run on the VM only.

/// The environment variable that names the file of the full corpus of
/// `tool/reference/date_adapter_reference.mjs --full <file>`.
const String _fullCorpus = 'DATE_ADAPTER_FULL';

/// The time of the fields in UTC.
double _at(int y, [int m = 1, int d = 1, int h = 0, int mi = 0]) =>
    DateTime.utc(y, m, d, h, mi).millisecondsSinceEpoch.toDouble();

/// A value of the corpus: `{u: 1}` is undefined, `{n: text}` a number,
/// `{date: ms}` a `DateTime`, `{arr: [...]}` a List and `{obj: {...}}` a
/// Map. A JSON number is a `double`.
Object? _decode(Object? value) => switch (value) {
  {'u': 1} => undefined,
  {'n': final String text} => double.parse(text),
  {'date': final num ms} => DateTime.fromMillisecondsSinceEpoch(
    ms.toInt(),
    isUtc: true,
  ),
  {'arr': final List<Object?> list} => [for (final x in list) _decode(x)],
  {'obj': final Map<String, Object?> map} => {
    for (final MapEntry(:key, :value) in map.entries) key: _decode(value),
  },
  final num number => number.toDouble(),
  _ => value,
};

/// Whether the result [got] of a call equals the corpus result [expected]:
/// a number, `'NaN'`, `null`, a string or `'throw:TypeError'`.
bool _matches(Object? got, Object? expected) => switch (expected) {
  'NaN' => got is double && got.isNaN,
  final num number => got is double && got == number,
  _ => got == expected,
};

/// The result of [run], or `'throw:<type>'`.
Object? _result(Object? Function() run) {
  try {
    return run();
  } on Object catch (error) {
    return error is TypeError ? 'throw:TypeError' : 'throw:$error';
  }
}

void main() {
  String? previousZone;
  setUp(() {
    previousZone = defaultDateZone;
    setDefaultDateZone('Etc/UTC');
  });
  tearDown(() => setDefaultDateZone(previousZone));

  final adapter = DateAdapterBase();
  final now = DateTime.utc(2026, 10, 20, 9, 41, 7, 123);

  group('current-date fill', () {
    // moment fills the first absent fields of year, month and day from the
    // current date (create/from-array.js:79-81). moment `currentDateArray`
    // reads the local date of the process, also under the default zone
    // Etc/UTC of moment-timezone. Thus the expected values take the local
    // date of the machine.
    final local = DateTime.fromMillisecondsSinceEpoch(
      now.millisecondsSinceEpoch,
    );

    test('a pattern without a year takes the current year', () {
      withClock(Clock.fixed(now), () {
        expect(
          adapter.parse('03/04 10:30', 'MM/dd HH:mm'),
          _at(local.year, 3, 4, 10, 30),
        );
      });
    });

    test('a pattern without a year and a month takes both', () {
      withClock(Clock.fixed(now), () {
        expect(
          adapter.parse('04 10:30', 'dd HH:mm'),
          _at(local.year, local.month, 4, 10, 30),
        );
      });
    });

    test('a pattern without a year, a month and a day takes the date', () {
      withClock(Clock.fixed(now), () {
        expect(
          adapter.parse('10:30', 'HH:mm'),
          _at(local.year, local.month, local.day, 10, 30),
        );
        expect(
          adapter.parse("10 o'clock", "HH 'o''clock'"),
          _at(local.year, local.month, local.day, 10),
        );
      });
    });

    test('a pattern with a year takes nothing', () {
      withClock(Clock.fixed(now), () {
        expect(adapter.parse('2015 04', 'yyyy dd'), _at(2015, 1, 4));
        expect(adapter.parse('2015', 'yyyy'), _at(2015));
      });
    });

    test('a letter in quotes is not a field', () {
      withClock(Clock.fixed(now), () {
        expect(
          adapter.parse('y 10:30', "'y' HH:mm"),
          _at(local.year, local.month, local.day, 10, 30),
        );
      });
    });

    test('the current date is the local date, also in UTC', () {
      // In Pacific/Kiritimati (+14:00) at 2026-10-20T12:00Z, moment with the
      // default zone Etc/UTC gives 2026-10-21T10:30Z for '10:30' and
      // 'HH:mm'. Near midnight UTC, the local date differs from the UTC
      // date in most zones.
      for (final instant in [
        DateTime.utc(2026, 10, 20, 0, 30),
        DateTime.utc(2026, 10, 20, 12),
        DateTime.utc(2026, 10, 20, 23, 30),
      ]) {
        final date = DateTime.fromMillisecondsSinceEpoch(
          instant.millisecondsSinceEpoch,
        );
        withClock(Clock.fixed(instant), () {
          expect(
            adapter.parse('10:30', 'HH:mm'),
            _at(date.year, date.month, date.day, 10, 30),
            reason: '$instant',
          );
        });
      }
    });

    test('the date of the filled fields: February 29 and the hour 24', () {
      // moment fills the fields from the current date, then builds the date
      // (moment.js:2627-2655). moment 2.29.4 with chartjs-adapter-moment
      // 1.0.1, the default zone Etc/UTC and the clock at
      // 2028-06-01T12:00Z, on the x64 Node.js v24.12.0 with TZ=UTC: '02/29'
      // with 'MM/DD' gives 2028-02-29T00:00Z, 'Feb 29 10:30' with
      // 'MMM D HH:mm' 2028-02-29T10:30Z, '02/29 24:00' with 'MM/DD HH:mm'
      // 2028-03-01T00:00Z, '12/31 24:00' 2029-01-01T00:00Z, '30 24:00' with
      // 'DD HH:mm' 2028-07-01T00:00Z and '24:00' with 'HH:mm'
      // 2028-06-02T00:00Z.
      final leap = DateTime.utc(2028, 6, 1, 12);
      final date = DateTime.fromMillisecondsSinceEpoch(
        leap.millisecondsSinceEpoch,
      );
      withClock(Clock.fixed(leap), () {
        expect(adapter.parse('02/29', 'MM/dd'), _at(date.year, 2, 29));
        expect(
          adapter.parse('Feb 29 10:30', 'MMM d HH:mm'),
          _at(date.year, 2, 29, 10, 30),
        );
        expect(adapter.parse('02/29 24:00', 'MM/dd HH:mm'), _at(date.year, 3));
        expect(adapter.parse('12/31 24:00', 'MM/dd HH:mm'), _at(date.year + 1));
        expect(
          adapter.parse('30 24:00', 'dd HH:mm'),
          _at(date.year, date.month, 31),
        );
        expect(
          adapter.parse('24:00', 'HH:mm'),
          _at(date.year, date.month, date.day + 1),
        );
      });
    });

    test('a day of the year takes only the current year', () {
      // moment sets the month and the day from the day of the year before
      // it fills the fields (moment.js:2610-2624). The probe of the case
      // before: '100' with 'DDD' gives 2028-04-09T00:00Z, and '100 24:00'
      // with 'DDD HH:mm' 2028-04-10T00:00Z.
      final leap = DateTime.utc(2028, 6, 1, 12);
      final date = DateTime.fromMillisecondsSinceEpoch(
        leap.millisecondsSinceEpoch,
      );
      withClock(Clock.fixed(leap), () {
        expect(adapter.parse('100', 'D'), _at(date.year, 4, 9));
        expect(adapter.parse('100 24:00', 'D HH:mm'), _at(date.year, 4, 10));
      });
    });

    test('the text of the four lower-case patterns parses back', () {
      // moment reads the day period in any case (moment.js:1987-1993). The
      // same probe: '8:05 pm' with 'h:mm a' gives 2028-06-01T20:05Z.
      final clock = DateTime.utc(2028, 6, 1, 12);
      final date = DateTime.fromMillisecondsSinceEpoch(
        clock.millisecondsSinceEpoch,
      );
      final t = _at(date.year, date.month, date.day, 20, 5) + 6007;
      withClock(Clock.fixed(clock), () {
        for (final (pattern, time) in [
          ('MMM d, yyyy, h:mm:ss a', t - 7),
          ('h:mm:ss.SSS a', t),
          ('h:mm:ss a', t - 7),
          ('h:mm a', t - 6007),
        ]) {
          final text = adapter.format(t, pattern)! as String;
          expect(text, endsWith(' pm'));
          expect(adapter.parse(text, pattern), time, reason: text);
        }
        expect(
          adapter.parse('8:05 pm', 'h:mm a'),
          _at(date.year, date.month, date.day, 20, 5),
        );
      });
    });

    test('in the local zone, the fields are a local wall time', () {
      setDefaultDateZone(null);
      withClock(Clock.fixed(now), () {
        expect(
          adapter.parse('10:30', 'HH:mm'),
          DateTime(
            local.year,
            local.month,
            local.day,
            10,
            30,
          ).millisecondsSinceEpoch,
        );
      });
    });
  });

  group('undefined is now', () {
    test('parse(undefined) and format(undefined, pattern)', () {
      withClock(Clock.fixed(now), () {
        expect(adapter.parse(undefined), now.millisecondsSinceEpoch);
        expect(
          adapter.format(undefined, 'yyyy-MM-dd HH:mm'),
          '2026-10-20 09:41',
        );
        expect(
          adapter.startOf(undefined, 'day'),
          _at(2026, 10, 20),
        );
      });
    });
  });

  group('locale', () {
    test('a locale without date data gives the en_US texts', () {
      final previous = Intl.defaultLocale;
      addTearDown(() => Intl.defaultLocale = previous);
      Intl.defaultLocale = 'de';
      final t = _at(2015, 1, 1, 20);
      expect(
        adapter.format(t, 'MMM d, yyyy, h:mm:ss a'),
        'Jan 1, 2015, 8:00:00 pm',
      );
      expect(adapter.format(t, 'MMMM'), 'January');
      expect(adapter.startOf(t, 'week'), _at(2014, 12, 28));
      expect(adapter.parse('2015-03-04', 'yyyy-MM-dd'), _at(2015, 3, 4));
    });
  });

  group('full corpus', () {
    final file = Platform.environment[_fullCorpus];
    test(
      'the corpus of --full',
      () {
        final corpus =
            jsonDecode(File(file!).readAsStringSync()) as Map<String, Object?>;
        final times = (corpus['T']! as List).map(_decode).toList();
        final mismatches = <String>[];
        var calls = 0;
        void check(String label, Object? expected, Object? Function() run) {
          calls++;
          final got = _result(run);
          if (!_matches(got, expected) && mismatches.length < 40) {
            mismatches.add('$label: $got, expected $expected');
          }
        }

        final units = (corpus['U']! as List).map(_decode).toList();
        for (var u = 0; u < units.length; u++) {
          final startOf = (corpus['startOf']! as List)[u] as List;
          final endOf = (corpus['endOf']! as List)[u] as List;
          for (var i = 0; i < times.length; i++) {
            final t = times[i];
            check(
              'startOf($t, ${units[u]})',
              startOf[i],
              () => adapter.startOf(t, units[u]),
            );
            check(
              'endOf($t, ${units[u]})',
              endOf[i],
              () => adapter.endOf(t, units[u]),
            );
          }
        }
        final weekdays = (corpus['W']! as List).map(_decode).toList();
        for (var w = 0; w < weekdays.length; w++) {
          final results = (corpus['isoWeek']! as List)[w] as List;
          for (var i = 0; i < times.length; i++) {
            final t = times[i];
            check(
              'isoWeek($t, ${weekdays[w]})',
              results[i],
              () => adapter.startOf(t, 'isoWeek', weekdays[w]),
            );
          }
        }
        final addTimes = (corpus['TA']! as List).map(_decode).toList();
        final amounts = (corpus['A']! as List).map(_decode).toList();
        final addUnits = (corpus['UA']! as List).map(_decode).toList();
        // moment reads these strings as durations (row
        // adapt-date-parse-fallback).
        const durations = {'P1D', 'PT1H', '1.02:03:04'};
        for (var u = 0; u < addUnits.length; u++) {
          final byAmount = (corpus['add']! as List)[u] as List;
          final unit = addUnits[u];
          for (var a = 0; a < amounts.length; a++) {
            final amount = amounts[a];
            final results = byAmount[a] as List;
            final swaps = unit != null && !jsToNumber(unit).isNaN;
            if (durations.contains(amount) && !swaps) continue;
            for (var i = 0; i < addTimes.length; i++) {
              final t = addTimes[i];
              check(
                'add($t, $amount, $unit)',
                results[i],
                () => adapter.add(t, amount, unit),
              );
            }
          }
        }
        final pairs = (corpus['P']! as List).cast<List<Object?>>();
        final diffUnits = (corpus['UD']! as List).map(_decode).toList();
        for (var u = 0; u < diffUnits.length; u++) {
          final results = (corpus['diff']! as List)[u] as List;
          for (var p = 0; p < pairs.length; p++) {
            final a = _decode(pairs[p][0]);
            final b = _decode(pairs[p][1]);
            check(
              'diff($a, $b, ${diffUnits[u]})',
              results[p],
              () => adapter.diff(a, b, diffUnits[u]),
            );
          }
        }
        final values = (corpus['V']! as List).map(_decode).toList();
        final fallback = (corpus['fallback']! as List).cast<bool>();
        final parsed = corpus['parse']! as List;
        for (var i = 0; i < values.length; i++) {
          final value = values[i];
          // A List and a Map are invalid (row adapt-date-parse-fallback).
          final expected = fallback[i] || value is List || value is Map
              ? null
              : parsed[i];
          check('parse($value)', expected, () => adapter.parse(value));
        }
        final formats = corpus['formats']! as Map<String, Object?>;
        final texts = corpus['format']! as Map<String, Object?>;
        final formatTimes = (corpus['F']! as List).map(_decode).toList();
        final icu = adapter.formats()! as Map<String, Object?>;
        for (final key in formats.keys) {
          final expected = texts[key]! as List;
          for (var i = 0; i < formatTimes.length; i++) {
            check(
              'format(${formatTimes[i]}, $key)',
              expected[i],
              () => adapter.format(formatTimes[i], icu[key]),
            );
          }
        }
        expect(calls, greaterThan(300000));
        expect(mismatches, isEmpty);
      },
      skip: file == null ? 'set $_fullCorpus to the file of --full' : false,
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
