// Ported from d3-time v3.1.0 src/week.js (ISC, Mike Bostock).

/// Port of `src/week.js` of d3-time 3.1.0.
library;

import 'package:flutter_d3_time_port/src/duration.dart';
import 'package:flutter_d3_time_port/src/interval.dart';

// DIVERGES(d3-time): adapt-time-fast-forms, direct calendar stepping for local
// weekday intervals and O(1) epoch-millisecond arithmetic for UTC weekday
// intervals (1970-01-01T00:00:00Z was Thursday, index 4).
final class const _TimeWeekdayInterval(final int _weekdayIndex)
    extends CountableTimeInterval {
  this : super(_unusedFloor, _unusedOffset, _unusedCount);

  @override
  DateTime floor(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    return DateTime(
      d.year,
      d.month,
      d.day - ((d.weekday % 7) + 7 - _weekdayIndex) % 7,
    );
  }

  @override
  DateTime ceil(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final delta = ((d.weekday % 7) + 7 - _weekdayIndex) % 7;
    final f = DateTime(d.year, d.month, d.day - delta);
    if (f.millisecondsSinceEpoch == d.millisecondsSinceEpoch) return f;
    return DateTime(d.year, d.month, d.day - delta + 7);
  }

  @override
  DateTime round(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final ms = d.millisecondsSinceEpoch;
    final delta = ((d.weekday % 7) + 7 - _weekdayIndex) % 7;
    final d0 = DateTime(d.year, d.month, d.day - delta);
    if (d0.millisecondsSinceEpoch == ms) return d0;
    final d1 = DateTime(d.year, d.month, d.day - delta + 7);
    return ms - d0.millisecondsSinceEpoch < d1.millisecondsSinceEpoch - ms
        ? d0
        : d1;
  }

  @override
  DateTime offset(DateTime date, [int step = 1]) {
    final d = date.isUtc ? date.toLocal() : date;
    return DateTime(
      d.year,
      d.month,
      d.day + step * 7,
      d.hour,
      d.minute,
      d.second,
      d.millisecond,
    );
  }

  @override
  int count(DateTime start, DateTime end) {
    final t0 = floor(start);
    final t1 = floor(end);
    return ((t1.millisecondsSinceEpoch -
                t0.millisecondsSinceEpoch +
                (t1.timeZoneOffset.inMinutes - t0.timeZoneOffset.inMinutes) *
                    durationMinute) /
            durationWeek)
        .floor();
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final first = ceil(start);
    final stopMs = stop.millisecondsSinceEpoch;
    if (first.millisecondsSinceEpoch >= stopMs) return <DateTime>[];
    final y = first.year;
    final m = first.month;
    var day = first.day;
    final stride = step * 7;
    final values = <DateTime>[first];
    var prevMs = first.millisecondsSinceEpoch;
    while (true) {
      day += stride;
      final next = DateTime(y, m, day);
      final nextMs = next.millisecondsSinceEpoch;
      if (nextMs <= prevMs || nextMs >= stopMs) break;
      values.add(next);
      prevMs = nextMs;
    }
    return values;
  }
}

DateTime _unusedFloor(DateTime date) => date;
DateTime _unusedOffset(DateTime date, int step) => date;
num _unusedCount(DateTime start, DateTime end) => 0;

/// Sunday-based weeks in local time.
const CountableTimeInterval timeSunday = _TimeWeekdayInterval(0);

/// Monday-based weeks in local time.
const CountableTimeInterval timeMonday = _TimeWeekdayInterval(1);

/// Tuesday-based weeks in local time.
const CountableTimeInterval timeTuesday = _TimeWeekdayInterval(2);

/// Wednesday-based weeks in local time.
const CountableTimeInterval timeWednesday = _TimeWeekdayInterval(3);

/// Thursday-based weeks in local time.
const CountableTimeInterval timeThursday = _TimeWeekdayInterval(4);

/// Friday-based weeks in local time.
const CountableTimeInterval timeFriday = _TimeWeekdayInterval(5);

/// Saturday-based weeks in local time.
const CountableTimeInterval timeSaturday = _TimeWeekdayInterval(6);

/// Alias for [timeSunday].
const CountableTimeInterval timeWeek = timeSunday;

/// Alias for [timeSunday]'s [TimeInterval.range].
final TimeRange timeSundays = timeSunday.range;

/// Alias for [timeWeek]'s [TimeInterval.range] (and [timeSundays]).
final TimeRange timeWeeks = timeSundays;

/// Alias for [timeMonday]'s [TimeInterval.range].
final TimeRange timeMondays = timeMonday.range;

/// Alias for [timeTuesday]'s [TimeInterval.range].
final TimeRange timeTuesdays = timeTuesday.range;

/// Alias for [timeWednesday]'s [TimeInterval.range].
final TimeRange timeWednesdays = timeWednesday.range;

/// Alias for [timeThursday]'s [TimeInterval.range].
final TimeRange timeThursdays = timeThursday.range;

/// Alias for [timeFriday]'s [TimeInterval.range].
final TimeRange timeFridays = timeFriday.range;

/// Alias for [timeSaturday]'s [TimeInterval.range].
final TimeRange timeSaturdays = timeSaturday.range;

/// Sunday-based weeks in UTC (`1970-01-04` = day 3).
const CountableTimeInterval utcSunday = FixedPeriodTimeInterval(
  durationWeek,
  epochOffset: 3 * durationDay,
  epochCountEvery: true,
);

/// Monday-based weeks in UTC (`1970-01-05` = day 4).
const CountableTimeInterval utcMonday = FixedPeriodTimeInterval(
  durationWeek,
  epochOffset: 4 * durationDay,
  epochCountEvery: true,
);

/// Tuesday-based weeks in UTC (`1970-01-06` = day 5).
const CountableTimeInterval utcTuesday = FixedPeriodTimeInterval(
  durationWeek,
  epochOffset: 5 * durationDay,
  epochCountEvery: true,
);

/// Wednesday-based weeks in UTC (`1970-01-07` = day 6).
const CountableTimeInterval utcWednesday = FixedPeriodTimeInterval(
  durationWeek,
  epochOffset: 6 * durationDay,
  epochCountEvery: true,
);

/// Thursday-based weeks in UTC (`1970-01-01` = day 0).
const CountableTimeInterval utcThursday = FixedPeriodTimeInterval(
  durationWeek,
  epochCountEvery: true,
);

/// Friday-based weeks in UTC (`1970-01-02` = day 1).
const CountableTimeInterval utcFriday = FixedPeriodTimeInterval(
  durationWeek,
  epochOffset: durationDay,
  epochCountEvery: true,
);

/// Saturday-based weeks in UTC (`1970-01-03` = day 2).
const CountableTimeInterval utcSaturday = FixedPeriodTimeInterval(
  durationWeek,
  epochOffset: 2 * durationDay,
  epochCountEvery: true,
);

/// Alias for [utcSunday].
const CountableTimeInterval utcWeek = utcSunday;

/// Alias for [utcSunday]'s [TimeInterval.range].
final TimeRange utcSundays = utcSunday.range;

/// Alias for [utcWeek]'s [TimeInterval.range] (and [utcSundays]).
final TimeRange utcWeeks = utcSundays;

/// Alias for [utcMonday]'s [TimeInterval.range].
final TimeRange utcMondays = utcMonday.range;

/// Alias for [utcTuesday]'s [TimeInterval.range].
final TimeRange utcTuesdays = utcTuesday.range;

/// Alias for [utcWednesday]'s [TimeInterval.range].
final TimeRange utcWednesdays = utcWednesday.range;

/// Alias for [utcThursday]'s [TimeInterval.range].
final TimeRange utcThursdays = utcThursday.range;

/// Alias for [utcFriday]'s [TimeInterval.range].
final TimeRange utcFridays = utcFriday.range;

/// Alias for [utcSaturday]'s [TimeInterval.range].
final TimeRange utcSaturdays = utcSaturday.range;
