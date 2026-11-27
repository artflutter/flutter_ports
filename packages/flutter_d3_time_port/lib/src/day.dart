// Ported from d3-time v3.1.0 src/day.js (ISC, Mike Bostock).

/// Port of `src/day.js` of d3-time 3.1.0.
library;

import 'package:flutter_d3_time_port/src/duration.dart';
import 'package:flutter_d3_time_port/src/interval.dart';

DateTime _floorTimeDay(DateTime date) {
  final d = date.isUtc ? date.toLocal() : date;
  return DateTime(d.year, d.month, d.day);
}

DateTime _offsetTimeDay(DateTime date, int step) {
  final d = date.isUtc ? date.toLocal() : date;
  return DateTime(
    d.year,
    d.month,
    d.day + step,
    d.hour,
    d.minute,
    d.second,
    d.millisecond,
  );
}

num _countTimeDay(DateTime start, DateTime end) =>
    (end.millisecondsSinceEpoch -
        start.millisecondsSinceEpoch +
        (end.timeZoneOffset.inMinutes - start.timeZoneOffset.inMinutes) *
            durationMinute) /
    durationDay;

int _fieldTimeDay(DateTime date) =>
    (date.isUtc ? date.toLocal() : date).day - 1;

int _fieldUtcDay(DateTime date) => (date.isUtc ? date : date.toUtc()).day - 1;

// DIVERGES(d3-time): adapt-time-fast-forms, direct ceil/round and single-call
// calendar stepping in timeDay.range avoiding repeated field extraction and
// redundant floor calls across DST boundaries.
final class const _TimeDayInterval() extends CountableTimeInterval {
  this : super(_floorTimeDay, _offsetTimeDay, _countTimeDay, _fieldTimeDay);

  @override
  DateTime ceil(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final f = DateTime(d.year, d.month, d.day);
    if (f.millisecondsSinceEpoch == d.millisecondsSinceEpoch) return f;
    return DateTime(d.year, d.month, d.day + 1);
  }

  @override
  DateTime round(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final ms = d.millisecondsSinceEpoch;
    final d0 = DateTime(d.year, d.month, d.day);
    if (d0.millisecondsSinceEpoch == ms) return d0;
    final d1 = DateTime(d.year, d.month, d.day + 1);
    return ms - d0.millisecondsSinceEpoch < d1.millisecondsSinceEpoch - ms
        ? d0
        : d1;
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final first = ceil(start);
    final stopMs = stop.millisecondsSinceEpoch;
    var prev = first;
    var prevMs = first.millisecondsSinceEpoch;
    if (prevMs >= stopMs) return <DateTime>[];
    var prevOff = first.timeZoneOffset.inMilliseconds;
    var isMidnight = (prevMs + prevOff) % durationDay == 0;
    final strideMs = step * durationDay;
    final values = <DateTime>[first];
    while (true) {
      final DateTime next;
      if (isMidnight) {
        final candMs = prevMs + strideMs;
        if (candMs >= stopMs + durationDay) break;
        final cand = DateTime.fromMillisecondsSinceEpoch(candMs);
        final candOff = cand.timeZoneOffset.inMilliseconds;
        if (candOff == prevOff) {
          if (candMs >= stopMs) break;
          values.add(cand);
          prev = cand;
          prevMs = candMs;
          continue;
        }
        next = DateTime(prev.year, prev.month, prev.day + step);
        prevOff = next.timeZoneOffset.inMilliseconds;
        isMidnight = (next.millisecondsSinceEpoch + prevOff) % durationDay == 0;
      } else {
        next = DateTime(prev.year, prev.month, prev.day + step);
        prevOff = next.timeZoneOffset.inMilliseconds;
        isMidnight = (next.millisecondsSinceEpoch + prevOff) % durationDay == 0;
      }
      final nextMs = next.millisecondsSinceEpoch;
      if (nextMs <= prevMs || nextMs >= stopMs) break;
      values.add(next);
      prev = next;
      prevMs = nextMs;
    }
    return values;
  }

  @override
  TimeInterval? every(int step) {
    if (step <= 0) return null;
    if (step == 1) return this;
    return _TimeMultiDayInterval(step, this);
  }
}

int _daysInMonth(int year, int month) {
  switch (month) {
    case 2:
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    case 4:
    case 6:
    case 9:
    case 11:
      return 30;
    default:
      return 31;
  }
}

final class const _TimeMultiDayInterval(
  final int _k,
  final CountableTimeInterval _base,
) extends TimeInterval {
  this : super(_unusedDayFloor, _unusedDayOffset);

  @override
  DateTime floor(DateTime date) {
    var d = _floorTimeDay(date);
    while ((d.day - 1) % _k != 0) {
      d = _floorTimeDay(
        DateTime.fromMillisecondsSinceEpoch(d.millisecondsSinceEpoch - 1),
      );
    }
    return d;
  }

  @override
  DateTime ceil(DateTime date) {
    final prev = DateTime.fromMillisecondsSinceEpoch(
      date.millisecondsSinceEpoch - 1,
      isUtc: date.isUtc,
    );
    return floor(offset(floor(prev)));
  }

  @override
  DateTime offset(DateTime date, [int step = 1]) {
    var d = date.isUtc ? date.toLocal() : date;
    var s = step;
    if (s < 0) {
      while (++s <= 0) {
        do {
          d = _base.offset(d, -1);
        } while ((d.day - 1) % _k != 0);
      }
    } else {
      while (--s >= 0) {
        do {
          d = _base.offset(d);
        } while ((d.day - 1) % _k != 0);
      }
    }
    return d;
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final first = ceil(start);
    final stopMs = stop.millisecondsSinceEpoch;
    var prevMs = first.millisecondsSinceEpoch;
    if (prevMs >= stopMs) return <DateTime>[];
    var y = first.year;
    var m = first.month;
    var dom = first.day;
    var dim = _daysInMonth(y, m);
    var prevOff = first.timeZoneOffset.inMilliseconds;
    var isMidnight = (prevMs + prevOff) % durationDay == 0;
    final values = <DateTime>[first];
    var matchCount = 0;
    while (true) {
      dom += 1;
      if (dom > dim) {
        dom = 1;
        m += 1;
        if (m > 12) {
          m = 1;
          y += 1;
        }
        dim = _daysInMonth(y, m);
      }
      final DateTime next;
      if (isMidnight) {
        final candMs = prevMs + durationDay;
        if (candMs >= stopMs + durationDay) break;
        final cand = DateTime.fromMillisecondsSinceEpoch(candMs);
        final candOff = cand.timeZoneOffset.inMilliseconds;
        if (candOff == prevOff) {
          next = cand;
        } else {
          next = DateTime(y, m, dom);
          prevOff = next.timeZoneOffset.inMilliseconds;
          isMidnight =
              (next.millisecondsSinceEpoch + prevOff) % durationDay == 0;
        }
      } else {
        next = DateTime(y, m, dom);
        prevOff = next.timeZoneOffset.inMilliseconds;
        isMidnight = (next.millisecondsSinceEpoch + prevOff) % durationDay == 0;
      }
      final nextMs = next.millisecondsSinceEpoch;
      if (nextMs <= prevMs || nextMs >= stopMs) break;
      prevMs = nextMs;
      if ((dom - 1) % _k == 0) {
        matchCount += 1;
        if (matchCount % step == 0) {
          values.add(next);
        }
      }
    }
    return values;
  }
}

DateTime _unusedDayFloor(DateTime d) => d;
DateTime _unusedDayOffset(DateTime d, int s) => d;

/// Days in local time (midnight `00:00`, DST-aware).
const CountableTimeInterval timeDay = _TimeDayInterval();

/// Alias for [timeDay]'s [TimeInterval.range].
final TimeRange timeDays = timeDay.range;

/// Days in UTC (starts each month at day 1 for [CountableTimeInterval.every]).
// DIVERGES(d3-time): adapt-time-fast-forms, direct O(1) epoch-millisecond
// arithmetic for utcDay floor/ceil/round/offset/count/range.
const CountableTimeInterval utcDay = FixedPeriodTimeInterval(
  durationDay,
  customField: _fieldUtcDay,
);

/// Alias for [utcDay]'s [TimeInterval.range].
final TimeRange utcDays = utcDay.range;

/// Days in UTC counted continuously from the Unix epoch (1970-01-01T00:00:00Z).
// DIVERGES(d3-time): adapt-time-fast-forms, direct O(1) epoch-millisecond
// arithmetic for unixDay and unixDay.every(k).
const CountableTimeInterval unixDay = FixedPeriodTimeInterval(
  durationDay,
  epochCountEvery: true,
);

/// Alias for [unixDay]'s [TimeInterval.range].
final TimeRange unixDays = unixDay.range;

/// Alias for [unixDay].
// DIVERGES(d3-time): adapt-time-typed-api, provides timeUnixDay/timeUnixDays
// aliases alongside upstream unixDay/unixDays.
const CountableTimeInterval timeUnixDay = unixDay;

/// Alias for [unixDays].
final TimeRange timeUnixDays = unixDays;
