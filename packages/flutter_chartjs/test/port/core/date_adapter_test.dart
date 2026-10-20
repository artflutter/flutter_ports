// Original code, not ported from Chart.js: the default date adapter tests.
import 'package:flutter_chartjs/src/core/core.adapters.dart';
import 'package:flutter_chartjs/src/core/date_adapter.dart';
import 'package:flutter_chartjs/src/core/date_calendar.dart';
import 'package:flutter_chartjs/src/core/date_format.dart';
import 'package:flutter_chartjs/src/core/date_parse.dart';
import 'package:flutter_chartjs/src/core/date_zone.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:test/test.dart';

import 'date_adapter_reference.dart';
import 'date_table_zone.dart';

// The default date adapter of Chart.js ADR 0024. The reference values come
// from chartjs-adapter-moment 1.0.1 on moment 2.29.4 with moment-timezone
// 0.5.42 in Node.js v24.12.0 on x64 (tool/reference/date_adapter_reference.mjs).
// The tests run on the VM, dart2js and dart2wasm. The cases that need
// package:clock or Intl.defaultLocale are in date_adapter_vm_test.dart.

/// The mismatches of one test, at most [_shown] of them in the report.
final class _Mismatches {
  final List<String> _lines = [];
  int count = 0;

  /// Records a mismatch.
  void add(String line) {
    count++;
    if (_lines.length < _shown) _lines.add(line);
  }

  /// Fails the test when it recorded a mismatch.
  void check() {
    expect(count, 0, reason: _lines.join('\n'));
  }
}

/// The number of mismatches that a report shows.
const int _shown = 20;

/// Whether [actual] is the number [expected]: `==`, or both NaN.
bool _same(Object? actual, double expected) =>
    actual is double && (expected.isNaN ? actual.isNaN : actual == expected);

/// Compares the call [run] with the reference [expected]: a difference to
/// [base], or [dateReferenceTypeError].
void _time(
  _Mismatches mismatches,
  String label,
  double base,
  Object expected,
  Object? Function() run,
) {
  if (expected == dateReferenceTypeError) {
    try {
      final result = run();
      mismatches.add('$label: $result, expected a TypeError');
    } on Object catch (error) {
      if (error is! TypeError) {
        mismatches.add('$label: threw $error, expected a TypeError');
      }
    }
    return;
  }
  final want = timeClip(base) + (expected as double);
  final Object? got;
  try {
    got = run();
  } on Object catch (error) {
    mismatches.add('$label: threw $error, expected $want');
    return;
  }
  if (!_same(got, want)) mismatches.add('$label: $got, expected $want');
}

/// The wall time [wall] (the wall fields as UTC ms) as an ISO 8601 string
/// with minutes and no zone.
String _wallText(int wall) {
  final date = DateTime.fromMillisecondsSinceEpoch(wall, isUtc: true);
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-${two(date.month)}-'
      '${two(date.day)}T${two(date.hour)}:${two(date.minute)}';
}

void main() {
  String? previousZone;
  setUp(() {
    previousZone = defaultDateZone;
    setDefaultDateZone('Etc/UTC');
  });
  tearDown(() => setDefaultDateZone(previousZone));

  test('the reference comes from an x64 Node.js v24.12.0', () {
    expect(dateReferenceNode, 'v24.12.0');
    expect(dateReferenceArch, 'x64');
    expect(dateReferencePackages, [
      'moment 2.29.4',
      'moment-timezone 0.5.42',
      'chartjs-adapter-moment 1.0.1',
    ]);
  });

  group('reference UTC', () {
    final adapter = DateAdapterBase();

    test('startOf and endOf', () {
      final mismatches = _Mismatches();
      const units = dateReferenceUnits;
      for (var i = 0; i < dateReferenceTimes.length; i++) {
        final t = dateReferenceTimes[i];
        for (var j = 0; j < units.length; j++) {
          final u = units[j];
          _time(
            mismatches,
            'startOf($t, $u)',
            t,
            dateReferenceStartOf[i * units.length + j],
            () => adapter.startOf(t, u),
          );
          _time(
            mismatches,
            'endOf($t, $u)',
            t,
            dateReferenceEndOf[i * units.length + j],
            () => adapter.endOf(t, u),
          );
        }
      }
      mismatches.check();
    });

    test('startOf and endOf of the unit aliases', () {
      final mismatches = _Mismatches();
      const aliases = dateReferenceAliases;
      for (var i = 0; i < dateReferenceAliasTimes.length; i++) {
        final t = dateReferenceAliasTimes[i];
        for (var j = 0; j < aliases.length; j++) {
          final u = aliases[j];
          _time(
            mismatches,
            'startOf($t, $u)',
            t,
            dateReferenceAliasStartOf[i * aliases.length + j],
            () => adapter.startOf(t, u),
          );
          _time(
            mismatches,
            'endOf($t, $u)',
            t,
            dateReferenceAliasEndOf[i * aliases.length + j],
            () => adapter.endOf(t, u),
          );
        }
      }
      mismatches.check();
    });

    test("startOf(time, 'isoWeek', weekday)", () {
      final mismatches = _Mismatches();
      const weekdays = dateReferenceWeekdays;
      for (var i = 0; i < dateReferenceTimes.length; i++) {
        final t = dateReferenceTimes[i];
        for (var j = 0; j < weekdays.length; j++) {
          final w = weekdays[j];
          _time(
            mismatches,
            "startOf($t, 'isoWeek', $w)",
            t,
            dateReferenceIsoWeek[i * weekdays.length + j],
            () => adapter.startOf(t, 'isoWeek', w),
          );
        }
      }
      mismatches.check();
    });

    test('add', () {
      final mismatches = _Mismatches();
      const amounts = dateReferenceAmounts;
      const units = dateReferenceAddUnits;
      var index = 0;
      for (final t in dateReferenceAddTimes) {
        for (final n in amounts) {
          for (final u in units) {
            final expected = dateReferenceAdd[index++];
            // moment reads 'P1D' as a duration (row
            // adapt-date-parse-fallback), unless it exchanges the amount
            // and the unit.
            final swaps = u != null && !jsToNumber(u).isNaN;
            if (n == 'P1D' && !swaps) continue;
            _time(
              mismatches,
              'add($t, $n, $u)',
              t,
              expected,
              () => adapter.add(t, n, u),
            );
          }
        }
      }
      mismatches.check();
    });

    test('diff on the month-end grid', () {
      final mismatches = _Mismatches();
      const grid = dateReferenceDiffGrid;
      const units = dateReferenceGridUnits;
      var index = 0;
      for (final a in grid) {
        for (final b in grid) {
          for (final u in units) {
            final expected = dateReferenceDiffGridResults[index++];
            final got = adapter.diff(a, b, u);
            if (!_same(got, expected)) {
              mismatches.add('diff($a, $b, $u): $got, expected $expected');
            }
          }
        }
      }
      mismatches.check();
    });

    test('diff of pairs', () {
      final mismatches = _Mismatches();
      const pairs = dateReferenceDiffPairs;
      const units = dateReferenceDiffUnits;
      var index = 0;
      for (var i = 0; i < pairs.length; i += 2) {
        for (final u in units) {
          final expected = dateReferenceDiffPairResults[index++];
          final got = adapter.diff(pairs[i], pairs[i + 1], u);
          if (!_same(got, expected)) {
            mismatches.add(
              'diff(${pairs[i]}, ${pairs[i + 1]}, $u): $got, expected '
              '$expected',
            );
          }
        }
      }
      mismatches.check();
    });

    test('parse without a format', () {
      final mismatches = _Mismatches();
      for (final (value, expected) in dateReferenceParse) {
        final got = adapter.parse(value);
        final same = expected == null ? got == null : _same(got, expected);
        if (!same) mismatches.add('parse($value): $got, expected $expected');
      }
      mismatches.check();
    });

    test('format with the ICU patterns of formats()', () {
      final mismatches = _Mismatches();
      const keys = dateReferenceFormatKeys;
      final formats = adapter.formats()! as Map<String, Object?>;
      expect(formats.keys, keys);
      var index = 0;
      for (final t in dateReferenceFormatTimes) {
        for (final key in keys) {
          final expected = dateReferenceFormatTexts[index++];
          final got = adapter.format(t, formats[key]);
          if (got != expected) {
            mismatches.add('format($t, $key): $got, expected $expected');
          }
        }
      }
      mismatches.check();
    });

    test('format edges', () {
      final mismatches = _Mismatches();
      for (final (time, format, expected) in dateReferenceFormatEdges) {
        // A moment format string is not an ICU pattern. The cases with such
        // a string have an invalid time.
        final label = 'format($time, $format)';
        if (expected == dateReferenceTypeError) {
          try {
            mismatches.add('$label: ${adapter.format(time, format)}');
          } on Object catch (error) {
            if (error is! TypeError) mismatches.add('$label: threw $error');
          }
        } else if (adapter.format(time, format) != expected) {
          mismatches.add(
            '$label: ${adapter.format(time, format)}, expected $expected',
          );
        }
      }
      mismatches.check();
    });
  });

  group('reference local', () {
    for (final reference in dateReferenceZones) {
      group(reference.name, () {
        final zone = TableZone.of(reference);
        final times = reference.times;

        test('startOf and endOf', () {
          final mismatches = _Mismatches();
          const units = dateReferenceLocalUnits;
          for (var i = 0; i < times.length; i++) {
            final t = times[i];
            for (var j = 0; j < units.length; j++) {
              final unit = normalizeDateUnit(units[j]);
              _time(
                mismatches,
                'startOf($t, ${units[j]})',
                t,
                reference.startOf[i * units.length + j],
                () => startOfUnit(t, unit, zone, 0),
              );
              _time(
                mismatches,
                'endOf($t, ${units[j]})',
                t,
                reference.endOf[i * units.length + j],
                () => endOfUnit(t, unit, zone, 0),
              );
            }
          }
          mismatches.check();
        });

        test("startOf(time, 'isoWeek', weekday)", () {
          final mismatches = _Mismatches();
          const weekdays = dateReferenceLocalWeekdays;
          for (var i = 0; i < times.length; i++) {
            final t = times[i];
            for (var j = 0; j < weekdays.length; j++) {
              _time(
                mismatches,
                'isoWeek($t, ${weekdays[j]})',
                t,
                reference.isoWeek[i * weekdays.length + j],
                () => startOfIsoWeekday(t, weekdays[j], zone),
              );
            }
          }
          mismatches.check();
        });

        test('add', () {
          final mismatches = _Mismatches();
          const adds = dateReferenceLocalAdds;
          for (var i = 0; i < times.length; i++) {
            final t = times[i];
            for (var j = 0; j < adds.length; j++) {
              final (amount, unit) = adds[j];
              _time(
                mismatches,
                'add($t, $amount, $unit)',
                t,
                reference.add[i * adds.length + j],
                () => addUnit(t, amount, normalizeDateUnit(unit), zone),
              );
            }
          }
          mismatches.check();
        });

        test('diff', () {
          final mismatches = _Mismatches();
          const units = dateReferenceLocalDiffUnits;
          final others = reference.diffOthers.length ~/ times.length;
          var index = 0;
          for (var i = 0; i < times.length; i++) {
            for (var k = 0; k < others; k++) {
              final a = times[i];
              final b = reference.diffOthers[i * others + k];
              for (final unit in units) {
                final expected = reference.diff[index++];
                final got = diffUnit(a, b, normalizeDateUnit(unit), zone);
                if (!_same(got, expected)) {
                  mismatches.add(
                    'diff($a, $b, $unit): $got, expected $expected',
                  );
                }
              }
            }
          }
          mismatches.check();
        });

        test('format', () {
          final mismatches = _Mismatches();
          for (var i = 0; i < times.length; i++) {
            final t = times[i];
            final iso = formatDate(t, undefined, zone, 'en_US');
            if (iso != reference.formatDefault[i]) {
              mismatches.add(
                'format($t): $iso, expected ${reference.formatDefault[i]}',
              );
            }
            final fields = formatDate(
              t,
              'yyyy-MM-dd HH:mm:ss.SSS',
              zone,
              'en_US',
            );
            if (fields != reference.formatFields[i]) {
              mismatches.add(
                'format($t, $dateReferenceLocalFieldsFormat): $fields, '
                'expected ${reference.formatFields[i]}',
              );
            }
          }
          mismatches.check();
        });

        test('parse of the wall times near the offset changes', () {
          final mismatches = _Mismatches();
          for (var i = 0; i < reference.walls.length; i++) {
            final text = _wallText(reference.walls[i]);
            final got = dateInput(text, zone);
            final expected = reference.wallInstants[i].toDouble();
            if (got != expected) {
              mismatches.add('parse($text): $got, expected $expected');
            }
          }
          mismatches.check();
        });
      });
    }
  });

  group('reference hour 24', () {
    // moment gives the hour 24 of an ISO string to `new Date(y, m, d, 24)`
    // or `Date.UTC(y, m, d, 24)`: the wall time 00:00 of the next day, then
    // the offset of the string or the rule of JS Date. It adds no day after
    // that (moment.js:2640-2655, :2942-2951).
    for (final reference in dateReferenceHour24Zones) {
      test('${reference.name}: parse of 24:00 near the offset changes', () {
        final zone = TableZone(
          reference.initialOffset,
          reference.changes,
          reference.offsets,
        );
        final mismatches = _Mismatches();
        for (var i = 0; i < reference.texts.length; i++) {
          final text = reference.texts[i];
          final got = dateInput(text, zone);
          final expected = reference.results[i];
          if (!_same(got, expected)) {
            mismatches.add('parse($text): $got, expected $expected');
          }
        }
        mismatches.check();
      });
    }
  });

  group('adapt-date-default-adapter', () {
    tearDown(
      () => DateAdapterBase.prototype
        ..clear()
        ..addAll(dateAdapterMembers),
    );

    test('the prototype starts with the default members', () {
      expect(dateAdapterMembers.keys, [
        'formats',
        'parse',
        'format',
        'add',
        'diff',
        'startOf',
        'endOf',
      ]);
      expect(DateAdapterBase.prototype.keys, dateAdapterMembers.keys);
      for (final key in dateAdapterMembers.keys) {
        expect(
          DateAdapterBase.prototype[key],
          same(dateAdapterMembers[key]),
          reason: key,
        );
      }
      expect(() => dateAdapterMembers['init'] = null, throwsUnsupportedError);
    });

    test('_date stays the class value of DateAdapterBase', () {
      expect(adapters['_date'], same(DateAdapterBase.jsClass));
    });

    test('a new adapter gives the default results', () {
      final adapter = DateAdapterBase();
      final t = DateTime.utc(2015, 1, 1, 20).millisecondsSinceEpoch.toDouble();
      expect(adapter.parse('2015-01-01T20:00:00Z'), t);
      expect(adapter.startOf(t, 'day'), t - 20 * 3600000);
      expect(adapter.endOf(t, 'day'), t + 4 * 3600000 - 1);
      expect(adapter.add(t, 1, 'day'), t + 86400000);
      expect(adapter.diff(t + 86400000, t, 'day'), 1);
      expect(adapter.format(t, 'yyyy-MM-dd'), '2015-01-01');
      expect(adapter.formats(), same(dateFormats));
      adapter.init(<String, Object?>{});
    });

    test('an int time is a JS number', () {
      final adapter = DateAdapterBase();
      const t = 1420142400000;
      expect(adapter.parse(t), t.toDouble());
      expect(adapter.startOf(t, 'day'), t - 20 * 3600000);
      expect(adapter.format(t, 'yyyy-MM-dd HH'), '2015-01-01 20');
    });

    test('an override replaces only its own members', () {
      DateAdapterBase.override({'parse': (Object? value) => 42.0});
      final adapter = DateAdapterBase();
      expect(adapter.parse('2015'), 42.0);
      expect(adapter.add(0.0, 1, 'second'), 1000);
      expect(adapter.formats(), same(dateFormats));
    });

    test('an override of init keeps the default members', () {
      Object? received;
      DateAdapterBase.override({
        'init': (Object? options) {
          received = options;
        },
      });
      final options = <String, Object?>{'locale': 'es'};
      DateAdapterBase().init(options);
      expect(received, same(options));
      expect(DateAdapterBase().startOf(1.5, 'second'), 0);
    });

    test('a cleared prototype gives the abstract error', () {
      DateAdapterBase.prototype.clear();
      expect(DateAdapterBase().formats, throwsStateError);
      expect(() => DateAdapterBase().parse('2015'), throwsStateError);
    });
  });

  group('adapt-date-moment-format', () {
    final adapter = DateAdapterBase();
    double at(int y, [int m = 1, int d = 1, int h = 0, int mi = 0]) =>
        DateTime.utc(y, m, d, h, mi).millisecondsSinceEpoch.toDouble();

    test('formats() gives the ten ICU patterns', () {
      expect(adapter.formats(), {
        'datetime': 'MMM d, yyyy, h:mm:ss a',
        'millisecond': 'h:mm:ss.SSS a',
        'second': 'h:mm:ss a',
        'minute': 'h:mm a',
        'hour': 'ha',
        'day': 'MMM d',
        'week': 'MMM d, yyyy',
        'month': 'MMM yyyy',
        'quarter': "'Q'Q - yyyy",
        'year': 'yyyy',
      });
      expect(adapter.formats(), same(adapter.formats()));
    });

    test('the four patterns with a day period write it in lower case', () {
      final t = at(2015, 1, 1, 20, 5) + 6007;
      expect(
        adapter.format(t, 'MMM d, yyyy, h:mm:ss a'),
        'Jan 1, 2015, 8:05:06 pm',
      );
      expect(adapter.format(t, 'h:mm:ss.SSS a'), '8:05:06.007 pm');
      expect(adapter.format(t, 'h:mm:ss a'), '8:05:06 pm');
      expect(adapter.format(t, 'h:mm a'), '8:05 pm');
      expect(adapter.format(at(2015, 1, 1, 9), 'h:mm a'), '9:00 am');
      expect(adapter.format(at(2015), 'h:mm a'), '12:00 am');
      expect(adapter.format(at(2015, 1, 1, 12), 'h:mm a'), '12:00 pm');
    });

    test('other patterns keep the ICU day period', () {
      expect(adapter.format(at(2015, 1, 1, 20), 'ha'), '8PM');
      expect(adapter.format(at(2015, 1, 1, 8), 'ha'), '8AM');
      expect(adapter.format(at(2015, 1, 1, 20), 'h:mm  a'), '8:00  PM');
      expect(adapter.format(at(2015, 1, 1, 20), "h 'a' a"), '8 a PM');
    });

    test("'Q'Q and yyyy", () {
      expect(adapter.format(at(2015, 5, 4), "'Q'Q - yyyy"), 'Q2 - 2015');
      expect(adapter.format(at(5, 3, 4), 'yyyy'), '0005');
      // intl `yyyy` drops the sign of a negative year. moment `YYYY` gives
      // '-0005' (the row adapt-date-moment-format).
      expect(adapter.format(at(-5, 3, 4), 'yyyy'), '0005');
      expect(adapter.format(at(99, 3, 4), 'MMM yyyy'), 'Mar 0099');
      expect(adapter.format(at(10000), 'yyyy'), '10000');
    });

    test('parse with a pattern with a year', () {
      expect(adapter.parse('2015', 'yyyy'), at(2015));
      expect(
        adapter.parse('2015-03-04 10:30', 'yyyy-MM-dd HH:mm'),
        at(2015, 3, 4, 10, 30),
      );
      // intl does not check the field ranges: 2016-01-01.
      expect(adapter.parse('2015-13-01 00:00', 'yyyy-MM-dd HH:mm'), at(2016));
      // intl accepts text after the date.
      expect(
        adapter.parse('2015-03-04 10:30xyz', 'yyyy-MM-dd HH:mm'),
        at(2015, 3, 4, 10, 30),
      );
      // intl does not skip text before the date.
      expect(adapter.parse(' 2015-03-04 10:30', 'yyyy-MM-dd HH:mm'), isNull);
      expect(adapter.parse('abc', 'yyyy'), isNull);
      expect(adapter.parse('275761', 'yyyy'), isNull);
    });

    test('the names of the text fields match in any case', () {
      // moment reads the names of the months and the weekdays and the day
      // period in any case (moment.js:1209-1220, :1847-1862, :1987-1993).
      // moment 2.29.4 with chartjs-adapter-moment 1.0.1 and the default zone
      // Etc/UTC, on the x64 Node.js v24.12.0: 'jan 1 2015' and 'JAN 1 2015'
      // with 'MMM D YYYY' give 2015-01-01T00:00Z, 'Jan 1 2015 8 pm' with
      // 'MMM D YYYY h a' 2015-01-01T20:00Z, 'thu, jan 1 2015' with
      // 'ddd, MMM D YYYY' 2015-01-01T00:00Z and 'mar 4 2015 10 AM' with
      // 'MMM D YYYY h A' 2015-03-04T10:00Z.
      expect(adapter.parse('jan 1 2015', 'MMM d yyyy'), at(2015));
      expect(adapter.parse('JAN 1 2015', 'MMM d yyyy'), at(2015));
      expect(
        adapter.parse('Jan 1 2015 8 pm', 'MMM d yyyy h a'),
        at(2015, 1, 1, 20),
      );
      expect(
        adapter.parse('Jan 1 2015 8 Pm', 'MMM d yyyy h a'),
        at(2015, 1, 1, 20),
      );
      expect(adapter.parse('january 1, 2015', 'MMMM d, yyyy'), at(2015));
      expect(adapter.parse('MARCH 4 2015', 'MMMM d yyyy'), at(2015, 3, 4));
      expect(adapter.parse('thu, jan 1 2015', 'EEE, MMM d yyyy'), at(2015));
      expect(
        adapter.parse('THURSDAY, january 1 2015', 'EEEE, MMMM d yyyy'),
        at(2015),
      );
      expect(
        adapter.parse('mar 4 2015 10 AM', 'MMM d yyyy h a'),
        at(2015, 3, 4, 10),
      );
      expect(adapter.parse('xyz 1 2015', 'MMM d yyyy'), isNull);
    });

    test('the text of a lower-case pattern parses back', () {
      final t = at(2015, 1, 1, 20, 5) + 6000;
      const pattern = 'MMM d, yyyy, h:mm:ss a';
      final text = adapter.format(t, pattern)! as String;
      expect(text, 'Jan 1, 2015, 8:05:06 pm');
      expect(adapter.parse(text, pattern), t);
    });

    test(
      'an empty format and a format that is not a string use the input rule',
      () {
        expect(adapter.parse('2015-03-04', ''), at(2015, 3, 4));
        expect(adapter.parse('2015-03-04', 5.0), at(2015, 3, 4));
        expect(adapter.parse(5.0, 'yyyy'), 5);
      },
    );

    test('a parse with a pattern reads the wall time in the zone', () {
      final zone = TableZone(-5 * 3600000, const [], const []);
      expect(
        parseWithFormat('2015-01-01 10:00', 'yyyy-MM-dd HH:mm', zone, 'en_US'),
        at(2015, 1, 1, 15),
      );
    });
  });

  group('adapt-date-parse-fallback', () {
    final adapter = DateAdapterBase();

    test('strings of the new Date(string) fallback are invalid', () {
      for (final s in ['Jan 1, 2015', '1/2/2015', '2015-1-2', 'abc', 'true']) {
        expect(adapter.parse(s), isNull, reason: s);
      }
      for (final s in dateReferenceFallbackStrings) {
        expect(adapter.parse(s), isNull, reason: s);
      }
    });

    test('a List, a Map and a bool are invalid', () {
      for (final value in [
        <Object?>[2015.0, 0.0, 1.0],
        <Object?>[],
        <String, Object?>{},
        <String, Object?>{'year': 2015.0},
        true,
        false,
      ]) {
        expect(adapter.parse(value), isNull, reason: '$value');
        expect(adapter.startOf(value, 'day'), isNaN, reason: '$value');
      }
    });

    test('a duration string or object adds nothing', () {
      const t = 1420142400000.0;
      expect(adapter.add(t, 'P1D', 'day'), t);
      expect(adapter.add(t, '1.02:03:04', 'day'), t);
      expect(adapter.add(t, <String, Object?>{'days': 2.0}, undefined), t);
      // A numeric string is an amount.
      expect(adapter.add(t, '2', 'day'), t + 2 * 86400000);
    });
  });

  group('format edges', () {
    final adapter = DateAdapterBase();
    const t = 1420142400000.0;

    test("'Invalid date' for an invalid time", () {
      expect(adapter.format(null, 'yyyy'), 'Invalid date');
      expect(adapter.format(double.nan, 'yyyy'), 'Invalid date');
      expect(adapter.format(double.nan, 5.0), 'Invalid date');
      expect(adapter.format('abc', undefined), 'Invalid date');
    });

    test('the ISO default text in UTC and in a zone', () {
      for (final format in [undefined, null, '', false, 0.0, double.nan]) {
        expect(adapter.format(t, format), '2015-01-01T20:00:00Z');
      }
      final zone = TableZone(-5 * 3600000, const [], const []);
      expect(formatDate(t, null, zone, 'en_US'), '2015-01-01T15:00:00-05:00');
      final seconds = TableZone(12344000, const [], const []);
      expect(
        formatDate(t, null, seconds, 'en_US'),
        '2015-01-01T23:25:44+03:25',
      );
      final negative = TableZone(-17762000, const [], const []);
      expect(
        formatDate(t, null, negative, 'en_US'),
        '2015-01-01T15:03:58-04:56',
      );
    });

    test('a format that is not a string throws a TypeError', () {
      for (final format in [
        5.0,
        <String, Object?>{},
        <Object?>['yyyy'],
        true,
      ]) {
        expect(
          () => adapter.format(t, format),
          throwsA(isA<TypeError>()),
          reason: '$format',
        );
      }
    });

    test('a DateTime time', () {
      final date = DateTime.utc(2015, 1, 1, 20);
      expect(adapter.format(date, 'yyyy-MM-dd HH'), '2015-01-01 20');
      expect(adapter.parse(date), t);
    });
  });

  group('isoWeek', () {
    final adapter = DateAdapterBase();
    final thursday = DateTime.utc(2015, 1, 1, 20).millisecondsSinceEpoch;
    final sunday = DateTime.utc(2015, 1, 4, 13).millisecondsSinceEpoch;
    const day = 86400000;

    test('a NaN weekday throws a TypeError on Monday to Saturday', () {
      for (var i = -3; i <= 2; i++) {
        final t = (thursday + i * day).toDouble();
        for (final weekday in [undefined, double.nan, 'abc']) {
          expect(
            () => adapter.startOf(t, 'isoWeek', weekday),
            throwsA(isA<TypeError>()),
            reason: '$t $weekday',
          );
        }
      }
    });

    test('a NaN weekday on a Sunday gives the Sunday one week before', () {
      final start = sunday - 13 * 3600000;
      expect(adapter.startOf(sunday.toDouble(), 'isoWeek'), start - 7 * day);
    });

    test('the weekday stays in the ISO week of the time', () {
      final monday = thursday - 20 * 3600000 - 3 * day;
      expect(adapter.startOf(thursday.toDouble(), 'isoWeek', 1.0), monday);
      expect(
        adapter.startOf(thursday.toDouble(), 'isoWeek', 6.0),
        monday + 5 * day,
      );
      expect(
        adapter.startOf(thursday.toDouble(), 'isoWeek', 0.0),
        monday - day,
      );
      expect(adapter.startOf(thursday.toDouble(), 'isoWeek', true), monday);
      expect(
        adapter.startOf(thursday.toDouble(), 'isoWeek', 9.0),
        monday + 5 * day,
      );
    });

    test("only the exact string 'isoWeek' takes the weekday", () {
      final monday = thursday - 20 * 3600000 - 3 * day;
      expect(adapter.startOf(thursday.toDouble(), 'isoweek', 6.0), monday);
      expect(adapter.startOf(thursday.toDouble(), 'W'), monday);
    });
  });

  group('formats() clears the zone cache', () {
    test('formats() and the zone setter clear the cached interval', () {
      final zone = LocalZone.instance..offsetAt(0);
      expect(zone.cachedInterval, isNotNull);
      DateAdapterBase().formats();
      expect(zone.cachedInterval, isNull);
      zone.offsetAt(0);
      setDefaultDateZone('UTC');
      expect(zone.cachedInterval, isNull);
    });
  });

  group('zone setter', () {
    test('null, UTC and Etc/UTC', () {
      setDefaultDateZone(null);
      expect(defaultDateZone, isNull);
      setDefaultDateZone('UTC');
      expect(defaultDateZone, 'UTC');
      expect(DateAdapterBase().parse('2015-01-01T00:00'), 1420070400000);
      setDefaultDateZone('Etc/UTC');
      expect(defaultDateZone, 'Etc/UTC');
    });

    test('another name throws an ArgumentError', () {
      expect(() => setDefaultDateZone('Europe/Kyiv'), throwsArgumentError);
      expect(defaultDateZone, 'Etc/UTC');
    });

    test('the local zone gives the offsets of the platform', () {
      setDefaultDateZone(null);
      final local = DateTime(2015, 6, 1, 10, 30);
      expect(
        DateAdapterBase().parse('2015-06-01T10:30'),
        local.millisecondsSinceEpoch,
      );
    });
  });

  test('weekStartOf(en_US) is Sunday', () {
    expect(weekStartOf('en_US'), 0);
  });
}
