// Original code, not ported from d3-time: Node.js reference parity tests.

import 'package:flutter_d3_time_port/flutter_d3_time_port.dart';
import 'package:test/test.dart';

import 'd3_time_reference.dart';

final Map<String, CountableTimeInterval> _intervals = {
  'utcMillisecond': utcMillisecond,
  'utcSecond': utcSecond,
  'utcMinute': utcMinute,
  'utcHour': utcHour,
  'utcDay': utcDay,
  'unixDay': unixDay,
  'utcSunday': utcSunday,
  'utcMonday': utcMonday,
  'utcTuesday': utcTuesday,
  'utcWednesday': utcWednesday,
  'utcThursday': utcThursday,
  'utcFriday': utcFriday,
  'utcSaturday': utcSaturday,
  'utcMonth': utcMonth,
  'utcYear': utcYear,
};

void main() {
  test('floor/ceil/round/offset match Node.js d3-time v3.1.0 across all UTC intervals', () {
    for (final (name, ms, f, c, r, om3, o0, o5) in refUnary) {
      final iv = _intervals[name]!;
      final d = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      expect(iv.floor(d).millisecondsSinceEpoch, f, reason: '$name.floor($ms)');
      expect(iv.ceil(d).millisecondsSinceEpoch, c, reason: '$name.ceil($ms)');
      expect(iv.round(d).millisecondsSinceEpoch, r, reason: '$name.round($ms)');
      expect(
        iv.offset(d, -3).millisecondsSinceEpoch,
        om3,
        reason: '$name.offset($ms, -3)',
      );
      expect(
        iv.offset(d, 0).millisecondsSinceEpoch,
        o0,
        reason: '$name.offset($ms, 0)',
      );
      expect(
        iv.offset(d, 5).millisecondsSinceEpoch,
        o5,
        reason: '$name.offset($ms, 5)',
      );
    }
  });

  test('count matches Node.js d3-time v3.1.0 across all UTC intervals', () {
    for (final (name, startMs, endMs, expected) in refCounts) {
      final iv = _intervals[name]!;
      final a = DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true);
      final b = DateTime.fromMillisecondsSinceEpoch(endMs, isUtc: true);
      expect(iv.count(a, b), expected, reason: '$name.count($startMs, $endMs)');
    }
  });

  test('range and every(k).range match Node.js d3-time v3.1.0', () {
    for (final (name, everyK, startMs, stopMs, step, expected) in refRanges) {
      final base = _intervals[name]!;
      final iv = everyK > 1 ? base.every(everyK)! : base;
      final a = DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true);
      final b = DateTime.fromMillisecondsSinceEpoch(stopMs, isUtc: true);
      expect(
        iv.range(a, b, step).map((d) => d.millisecondsSinceEpoch).toList(),
        equals(expected),
        reason: '$name.every($everyK).range($startMs, $stopMs, $step)',
      );
    }
  });

  test('utcTicks matches Node.js d3-time v3.1.0', () {
    for (final (startMs, stopMs, count, expected) in refUtcTicks) {
      final a = DateTime.fromMillisecondsSinceEpoch(startMs, isUtc: true);
      final b = DateTime.fromMillisecondsSinceEpoch(stopMs, isUtc: true);
      expect(
        utcTicks(a, b, count).map((d) => d.millisecondsSinceEpoch).toList(),
        equals(expected),
        reason: 'utcTicks($startMs, $stopMs, $count)',
      );
    }
  });
}
