// Ported from d3-time v3.1.0 src/ticks.js (ISC, Mike Bostock).

/// Port of `src/ticks.js` of d3-time 3.1.0.
library;

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart' show tickStep;
import 'package:flutter_d3_time_port/src/day.dart';
import 'package:flutter_d3_time_port/src/duration.dart';
import 'package:flutter_d3_time_port/src/hour.dart';
import 'package:flutter_d3_time_port/src/interval.dart';
import 'package:flutter_d3_time_port/src/millisecond.dart';
import 'package:flutter_d3_time_port/src/minute.dart';
import 'package:flutter_d3_time_port/src/month.dart';
import 'package:flutter_d3_time_port/src/second.dart';
import 'package:flutter_d3_time_port/src/week.dart';
import 'package:flutter_d3_time_port/src/year.dart';

// DIVERGES(d3-time): adapt-time-fast-forms, precomputed standard interval
// table, cached every(step) instances, inline binary search avoiding bisector
// closures, and in-place reversal for descending domains.
const List<int> _tickDurations = <int>[
  durationSecond,
  5 * durationSecond,
  15 * durationSecond,
  30 * durationSecond,
  durationMinute,
  5 * durationMinute,
  15 * durationMinute,
  30 * durationMinute,
  durationHour,
  3 * durationHour,
  6 * durationHour,
  12 * durationHour,
  durationDay,
  2 * durationDay,
  durationWeek,
  durationMonth,
  3 * durationMonth,
  durationYear,
];

@pragma('vm:prefer-inline')
int _bisectRightDuration(double target) {
  // Matches d3-array bisector.right: NaN returns length (18).
  if (target.isNaN) return _tickDurations.length;
  var lo = 0;
  var hi = _tickDurations.length;
  while (lo < hi) {
    final mid = (lo + hi) >>> 1;
    if (_tickDurations[mid] <= target) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

@pragma('vm:prefer-inline')
void _reverseInPlace(List<DateTime> list) {
  var i = 0;
  var j = list.length - 1;
  while (i < j) {
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
    ++i;
    --j;
  }
}

final class _Ticker(
  final CountableTimeInterval _year,
  CountableTimeInterval month,
  CountableTimeInterval week,
  CountableTimeInterval day,
  CountableTimeInterval hour,
  CountableTimeInterval minute, {
  required final bool isUtc,
}) {
  final List<TimeInterval> _intervals = <TimeInterval>[
    timeSecond,
    timeSecond.every(5)!,
    timeSecond.every(15)!,
    timeSecond.every(30)!,
    minute,
    minute.every(5)!,
    minute.every(15)!,
    minute.every(30)!,
    hour,
    hour.every(3)!,
    hour.every(6)!,
    hour.every(12)!,
    day,
    day.every(2)!,
    week,
    month,
    month.every(3)!,
    _year,
  ];

  TimeInterval? tickInterval(DateTime start, DateTime stop, num count) {
    final startMs = start.millisecondsSinceEpoch;
    final stopMs = stop.millisecondsSinceEpoch;
    final target = (stopMs - startMs).abs() / count;
    final i = _bisectRightDuration(target);
    if (i == _tickDurations.length) {
      final step = tickStep(
        startMs / durationYear,
        stopMs / durationYear,
        count,
      );
      if (!step.isFinite) return null;
      return _year.every(step.floor());
    }
    if (i == 0) {
      final step = math.max(tickStep(startMs, stopMs, count), 1);
      if (!step.isFinite) return null;
      return timeMillisecond.every(step.floor());
    }
    final prevDur = _tickDurations[i - 1];
    final nextDur = _tickDurations[i];
    final idx = target / prevDur < nextDur / target ? i - 1 : i;
    return _intervals[idx];
  }

  List<DateTime> ticks(DateTime start, DateTime stop, num count) {
    final reverse = stop.millisecondsSinceEpoch < start.millisecondsSinceEpoch;
    var a = reverse ? stop : start;
    var b = reverse ? start : stop;
    if (isUtc) {
      if (!a.isUtc) a = a.toUtc();
      if (!b.isUtc) b = b.toUtc();
    } else {
      if (a.isUtc) a = a.toLocal();
      if (b.isUtc) b = b.toLocal();
    }
    final interval = tickInterval(a, b, count);
    if (interval == null) return <DateTime>[];
    final values = interval.range(
      a,
      DateTime.fromMillisecondsSinceEpoch(
        b.millisecondsSinceEpoch + 1,
        isUtc: isUtc,
      ),
    );
    if (reverse) _reverseInPlace(values);
    return values;
  }

  List<DateTime> ticksWith(
    DateTime start,
    DateTime stop,
    TimeInterval? interval,
  ) {
    if (interval == null) return <DateTime>[];
    final reverse = stop.millisecondsSinceEpoch < start.millisecondsSinceEpoch;
    var a = reverse ? stop : start;
    var b = reverse ? start : stop;
    if (isUtc) {
      if (!a.isUtc) a = a.toUtc();
      if (!b.isUtc) b = b.toUtc();
    } else {
      if (a.isUtc) a = a.toLocal();
      if (b.isUtc) b = b.toLocal();
    }
    final values = interval.range(
      a,
      DateTime.fromMillisecondsSinceEpoch(
        b.millisecondsSinceEpoch + 1,
        isUtc: isUtc,
      ),
    );
    if (reverse) _reverseInPlace(values);
    return values;
  }
}

final _Ticker _utcTicker = _Ticker(
  utcYear,
  utcMonth,
  utcSunday,
  unixDay,
  utcHour,
  utcMinute,
  isUtc: true,
);

final _Ticker _timeTicker = _Ticker(
  timeYear,
  timeMonth,
  timeSunday,
  timeDay,
  timeHour,
  timeMinute,
  isUtc: false,
);

/// Returns approximately [count] uniformly-spaced, nicely-rounded UTC dates
/// between [start] and [stop] (inclusive).
// DIVERGES(d3-time): adapt-time-typed-api, split numeric count (utcTicks) and
// explicit interval (utcTicksWith) instead of untyped union parameter.
List<DateTime> utcTicks(DateTime start, DateTime stop, num count) =>
    _utcTicker.ticks(start, stop, count);

/// Returns UTC dates between [start] and [stop] (inclusive) generated using an
/// explicit [interval] (or an empty list if [interval] is `null`).
// DIVERGES(d3-time): adapt-time-typed-api, typed explicit-interval companion
// to utcTicks.
List<DateTime> utcTicksWith(
  DateTime start,
  DateTime stop,
  TimeInterval? interval,
) => _utcTicker.ticksWith(start, stop, interval);

/// Returns the UTC [TimeInterval] that would be used by [utcTicks] for the
/// given [start], [stop], and target [count], or `null` when [count] is
/// invalid.
TimeInterval? utcTickInterval(DateTime start, DateTime stop, num count) =>
    _utcTicker.tickInterval(start, stop, count);

/// Returns approximately [count] uniformly-spaced, nicely-rounded local dates
/// between [start] and [stop] (inclusive).
// DIVERGES(d3-time): adapt-time-typed-api, split numeric count (timeTicks) and
// explicit interval (timeTicksWith) instead of untyped union parameter.
List<DateTime> timeTicks(DateTime start, DateTime stop, num count) =>
    _timeTicker.ticks(start, stop, count);

/// Returns local dates between [start] and [stop] (inclusive) generated using
/// an explicit [interval] (or an empty list if [interval] is `null`).
// DIVERGES(d3-time): adapt-time-typed-api, typed explicit-interval companion
// to timeTicks.
List<DateTime> timeTicksWith(
  DateTime start,
  DateTime stop,
  TimeInterval? interval,
) => _timeTicker.ticksWith(start, stop, interval);

/// Returns the local [TimeInterval] that would be used by [timeTicks] for the
/// given [start], [stop], and target [count], or `null` when [count] is
/// invalid.
TimeInterval? timeTickInterval(DateTime start, DateTime stop, num count) =>
    _timeTicker.tickInterval(start, stop, count);
