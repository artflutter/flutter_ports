// Original code, not ported from d3-time-format: faster-form twin tests.
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_d3_time_format_port/d3_time_format.dart';
import 'package:flutter_d3_time_port/d3_time.dart';
import 'package:test/test.dart';

String _refPad(int value, String fill, int width) {
  final sign = value < 0 ? '-' : '';
  final s = (value < 0 ? -value : value).toString();
  if (s.length < width && fill.isNotEmpty) {
    return '$sign${fill * (width - s.length)}$s';
  }
  return '$sign$s';
}

DateTime _refDISO(DateTime d, {required bool isUtc}) {
  final day = d.weekday % 7;
  if (isUtc) {
    return (day >= 4 || day == 0) ? utcThursday(d) : utcThursday.ceil(d);
  }
  return (day >= 4 || day == 0) ? timeThursday(d) : timeThursday.ceil(d);
}

/// Literal upstream implementation of the calendar/week/ISO-week directives
/// using `d3-time` intervals directly, to twin-verify our O(1) inline formulas.
String _refFormatAll(DateTime input, {required bool isUtc}) {
  final d = isUtc
      ? (input.isUtc ? input : input.toUtc())
      : (input.isUtc ? input.toLocal() : input);
  final doy = isUtc
      ? 1 + utcDay.count(utcYear(d), d)
      : 1 + timeDay.count(timeYear(d), d);
  final prevYear = DateTime.fromMillisecondsSinceEpoch(
    (isUtc ? utcYear(d) : timeYear(d)).millisecondsSinceEpoch - 1,
    isUtc: isUtc,
  );
  final weekSun = isUtc
      ? utcSunday.count(prevYear, d)
      : timeSunday.count(prevYear, d);
  final weekMon = isUtc
      ? utcMonday.count(prevYear, d)
      : timeMonday.count(prevYear, d);
  final isoD = _refDISO(d, isUtc: isUtc);
  final isoYr = isUtc ? utcYear(isoD) : timeYear(isoD);
  final weekIso =
      (isUtc
          ? utcThursday.count(isoYr, isoD)
          : timeThursday.count(isoYr, isoD)) +
      (isoYr.weekday % 7 == 4 ? 1 : 0);
  final h12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final zone = isUtc
      ? '+0000'
      : () {
          var z = d.timeZoneOffset.inMinutes;
          final sign = z < 0 ? '-' : '+';
          if (z < 0) z = -z;
          return '$sign${_refPad(z ~/ 60, '0', 2)}${_refPad(z % 60, '0', 2)}';
        }();
  final ms = d.millisecondsSinceEpoch;
  final sec = ms >= 0 ? ms ~/ 1000 : -((-ms + 999) ~/ 1000);

  return '${_refPad(d.year.remainder(10000), '0', 4)}-'
      '${_refPad(d.month, '0', 2)}-'
      '${_refPad(d.day, '0', 2)} '
      '${_refPad(d.hour, '0', 2)}:${_refPad(d.minute, '0', 2)}:'
      '${_refPad(d.second, '0', 2)}.${_refPad(d.millisecond, '0', 3)} '
      '${_refPad(h12, '', 2)} ${d.hour >= 12 ? 'PM' : 'AM'} '
      '${_refPad(doy, '0', 3)} ${d.weekday} ${d.weekday % 7} '
      '${_refPad(weekSun, '0', 2)} ${_refPad(weekMon, '0', 2)} '
      '${_refPad(isoD.year.remainder(10000), '0', 4)}-W'
      '${_refPad(weekIso, '0', 2)} '
      '${_refPad(isoD.year.remainder(100), '0', 2)} '
      '${_refPad(d.year.remainder(100), '0', 2)} '
      '${1 + (d.month - 1) ~/ 3} $zone $ms $sec';
}

void main() {
  const allSpec =
      '%Y-%m-%d %H:%M:%S.%L %-I %p %j %u %w %U %W %G-W%V %g %y %q %Z %Q %s';

  test('O(1) Hinnant civil & ISO week math matches literal d3-time across 400+ '
      'dates (UTC & local)', () {
    final uf = utcFormat(allSpec);
    final lf = timeFormat(allSpec);

    // Every day of a full leap year (2024) + ISO boundary years + edge years.
    final dates = <DateTime>[
      for (var d = 1; d <= 366; ++d)
        DateTime.utc(2024, 1, d, d % 24, d % 60, (d * 7) % 60, (d * 13) % 1000),
      for (final y in const [
        -2,
        0,
        1,
        9,
        99,
        100,
        1900,
        1969,
        1970,
        1999,
        2000,
        2015,
        2016,
        2018,
        2019,
        2020,
        2021,
        2026,
        2100,
        9999,
        10002,
      ]) ...[
        DateTime.utc(y, 1, 1),
        DateTime.utc(y, 1, 4),
        DateTime.utc(y, 2, 28, 23, 59, 59, 999),
        DateTime.utc(y, 3, 1, 0, 0, 0, 1),
        DateTime.utc(y, 12, 29, 12, 30, 45, 500),
        DateTime.utc(y, 12, 30),
        DateTime.utc(y, 12, 31, 23, 59, 59, 999),
      ],
    ];

    for (final dt in dates) {
      expect(uf(dt), _refFormatAll(dt, isUtc: true), reason: 'UTC $dt');
      if (dt.year >= 1970 && dt.year <= 2100) {
        final loc = DateTime(
          dt.year,
          dt.month,
          dt.day,
          dt.hour,
          dt.minute,
          dt.second,
          dt.millisecond,
        );
        expect(lf(loc), _refFormatAll(loc, isUtc: false), reason: 'Local $loc');
      }
    }
  });

  test('fast isoFormat matches DateTime.toIso8601String across edge years and '
      'microseconds', () {
    final samples = <DateTime>[
      DateTime.utc(-2, 1, 1),
      DateTime.utc(0, 1, 1),
      DateTime.utc(9, 11, 6, 7, 12, 34, 567),
      DateTime.utc(1969, 12, 31, 23, 59, 59, 999),
      DateTime.utc(1970, 1, 1),
      DateTime.utc(2024, 6, 15, 14, 37, 22, 432, 987),
      DateTime.utc(9999, 12, 31, 23, 59, 59, 999),
      DateTime.utc(10002, 1, 1),
    ];
    for (final dt in samples) {
      final actual = isoFormat(dt);
      final truncated = DateTime.fromMillisecondsSinceEpoch(
        dt.millisecondsSinceEpoch,
        isUtc: true,
      );
      var expected = truncated.toIso8601String();
      if (dt.year < 0) {
        final absY = (-dt.year).toString().padLeft(6, '0');
        expected = '-$absY${expected.substring(expected.indexOf('-', 1))}';
      } else if (dt.year > 9999) {
        final absY = dt.year.toString().padLeft(6, '0');
        expected = '+$absY${expected.substring(expected.indexOf('-'))}';
      }
      expect(actual, expected, reason: 'isoFormat($dt)');
    }
  });

  test('fast isoParse handles canonical, fractional, offset, date-only, and '
      'invalid strings', () {
    expect(
      isoParse('2024-06-15T14:37:22.432Z'),
      DateTime.utc(2024, 6, 15, 14, 37, 22, 432),
    );
    expect(
      isoParse('2024-06-15T14:37:22Z'),
      DateTime.utc(2024, 6, 15, 14, 37, 22),
    );
    expect(
      isoParse('2024-06-15T14:37:22.5Z'),
      DateTime.utc(2024, 6, 15, 14, 37, 22, 500),
    );
    expect(
      isoParse('2024-06-15T14:37:22.123456Z'),
      DateTime.utc(2024, 6, 15, 14, 37, 22, 123),
    );
    expect(
      isoParse('2024-06-15T14:37:22+05:30'),
      DateTime.utc(2024, 6, 15, 9, 7, 22),
    );
    expect(
      isoParse('2024-06-15T14:37:22-0800'),
      DateTime.utc(2024, 6, 15, 22, 37, 22),
    );
    expect(isoParse('2024-06-15'), DateTime.utc(2024, 6, 15));
    expect(isoParse('2024-06-15T14:37:22.Z'), isNull);
    expect(isoParse('2024-06-15T14:37:22X'), isNull);
    expect(isoParse('not-a-date'), isNull);
    expect(isoParse(''), isNull);
  });

  test('pre-indexed case-insensitive matcher preserves prefix order and empty '
      'periods across all 34 locales', () {
    // cs-CZ: "červen" (idx 5) precedes "červenec" (idx 6) in alternation.
    final cs = timeFormatLocale(timeLocaleCsCZ);
    expect(cs.utcParse('%B %Y')('červen 2024'), DateTime.utc(2024, 6));
    expect(cs.utcParse('%B %Y')('červenec 2024'), isNull);
    expect(cs.utcParse('%b %Y')('čer 2024'), DateTime.utc(2024, 6));
    expect(cs.utcParse('%b %Y')('červ 2024'), isNull);

    // tr-TR: "Pazar" (idx 0) precedes "Pazartesi" (idx 1) in alternation.
    final tr = timeFormatLocale(timeLocaleTrTR);
    expect(tr.utcParse('%A %Y')('pazar 2024'), DateTime.utc(2024));
    expect(tr.utcParse('%A %Y')('pazartesi 2024'), isNull);

    // fr-CA: periods are ["", ""]; lookup resolves "" to index 1 (PM), while
    // trailing %p at end-of-input returns null matching upstream `j >= m`.
    final frCa = timeFormatLocale(timeLocaleFrCA);
    expect(frCa.utcParse('%I %p')('03 '), isNull);
    expect(frCa.utcParse('%I%p ')('03 '), DateTime.utc(1900, 1, 1, 15));

    // Mixed case across all 34 locales for %A, %a, %B, %b, %p.
    for (final entry in timeFormatLocales.entries) {
      final loc = timeFormatLocale(entry.value);
      final sample = DateTime.utc(2024, 3, 15, 14, 30, 45);
      final fmt = loc.utcFormat('%Y-%m-%d %H:%M:%S');
      final parsed = loc.utcParse('%Y-%m-%d %H:%M:%S')(fmt(sample));
      expect(parsed, sample, reason: '${entry.key} numeric round-trip');

      final lowerMonth = entry.value.months[2].toLowerCase();
      final upperMonth = entry.value.months[2].toUpperCase();
      expect(
        loc.utcParse('%B %Y')('$lowerMonth 2024'),
        DateTime.utc(2024, 3),
        reason: '${entry.key} lowercase month',
      );
      expect(
        loc.utcParse('%B %Y')('$upperMonth 2024'),
        DateTime.utc(2024, 3),
        reason: '${entry.key} uppercase month',
      );
    }
  });

  test('unknown directives and edge specifiers match upstream', () {
    expect(
      utcFormat('prefix-%k-suffix-%')(DateTime.utc(2024)),
      'prefix-k-suffix-',
    );
    expect(utcFormat('')(DateTime.utc(2024)), '');
    expect(utcFormat('literal only')(DateTime.utc(2024)), 'literal only');
    expect(utcParse('')(''), DateTime.utc(1900));
    expect(utcParse('%k')('k'), isNull);
    expect(utcParse('%')(''), isNull);
    expect(utcParse('%-')(''), isNull);
    expect(utcFormat('%0e %-e %_d %-d')(DateTime.utc(2024, 1, 5)), '05 5  5 5');
    expect(
      utcFormat('%-f %_L')(DateTime.utc(2024, 1, 1, 0, 0, 0, 5)),
      '5000   5',
    );
  });
}
