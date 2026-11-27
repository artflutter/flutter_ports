// Ported from d3-time v3.1.0 src/hour.js (ISC, Mike Bostock).

/// Port of `src/hour.js` of d3-time 3.1.0.
library;

import 'package:flutter_d3_time_port/src/duration.dart';
import 'package:flutter_d3_time_port/src/interval.dart';

DateTime _floorTimeHour(DateTime date) {
  final d = date.isUtc ? date.toLocal() : date;
  final ms = d.millisecondsSinceEpoch;
  final localMs = ms + d.timeZoneOffset.inMilliseconds;
  return DateTime.fromMillisecondsSinceEpoch(ms - (localMs % durationHour));
}

DateTime _offsetTimeHour(DateTime date, int step) =>
    DateTime.fromMillisecondsSinceEpoch(
      date.millisecondsSinceEpoch + step * durationHour,
    );

num _countHour(DateTime start, DateTime end) =>
    (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / durationHour;

int _fieldTimeHour(DateTime date) => (date.isUtc ? date.toLocal() : date).hour;

int _fieldUtcHour(DateTime date) =>
    (date.millisecondsSinceEpoch % durationDay) ~/ durationHour;

// DIVERGES(d3-time): adapt-time-fast-forms, direct ceil/round/range for local
// hours preserving DST fall-back fold and fractional-hour UTC offsets.
final class const _TimeHourInterval() extends CountableTimeInterval {
  this : super(_floorTimeHour, _offsetTimeHour, _countHour, _fieldTimeHour);

  @override
  DateTime ceil(DateTime date) {
    final f = _floorTimeHour(date);
    if (f.millisecondsSinceEpoch == date.millisecondsSinceEpoch) return f;
    return _floorTimeHour(
      DateTime.fromMillisecondsSinceEpoch(
        f.millisecondsSinceEpoch + durationHour,
      ),
    );
  }

  @override
  DateTime round(DateTime date) {
    final d0 = _floorTimeHour(date);
    final ms = date.millisecondsSinceEpoch;
    if (d0.millisecondsSinceEpoch == ms) return d0;
    final d1 = _floorTimeHour(
      DateTime.fromMillisecondsSinceEpoch(
        d0.millisecondsSinceEpoch + durationHour,
      ),
    );
    return ms - d0.millisecondsSinceEpoch < d1.millisecondsSinceEpoch - ms
        ? d0
        : d1;
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final first = ceil(start);
    final firstMs = first.millisecondsSinceEpoch;
    final stopMs = stop.millisecondsSinceEpoch;
    if (firstMs >= stopMs) return <DateTime>[];
    final stride = step * durationHour;
    final count = ((stopMs - firstMs - 1) ~/ stride) + 1;
    final lastCandidate = DateTime.fromMillisecondsSinceEpoch(
      firstMs + (count - 1) * stride,
    );
    // Fast path when start and end share the same minute-of-hour offset
    // (holds across all whole-hour DST transitions and constant-offset zones).
    if (first.minute == 0 &&
        first.second == 0 &&
        lastCandidate.minute == 0 &&
        lastCandidate.second == 0) {
      return List<DateTime>.generate(
        count,
        (i) => DateTime.fromMillisecondsSinceEpoch(firstMs + i * stride),
      );
    }
    return super.range(start, stop, step);
  }

  @override
  TimeInterval? every(int step) {
    if (step <= 0) return null;
    if (step == 1) return this;
    if (24 % step == 0) return _TimeMultiHourInterval(step, this);
    return super.every(step);
  }
}

final class const _TimeMultiHourInterval(
  final int _k,
  final CountableTimeInterval _base,
) extends TimeInterval {
  this : super(_unusedHourFloor, _unusedHourOffset);

  int get _period => _k * durationHour;

  @override
  DateTime floor(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final ms = d.millisecondsSinceEpoch;
    final off = d.timeZoneOffset.inMilliseconds;
    final rem = (ms + off) % _period;
    final cand = DateTime.fromMillisecondsSinceEpoch(ms - rem);
    if (cand.timeZoneOffset.inMilliseconds == off) return cand;
    var cur = _floorTimeHour(d);
    while (cur.hour % _k != 0) {
      cur = _floorTimeHour(
        DateTime.fromMillisecondsSinceEpoch(cur.millisecondsSinceEpoch - 1),
      );
    }
    return cur;
  }

  @override
  DateTime ceil(DateTime date) {
    final f = floor(date);
    if (f.millisecondsSinceEpoch == date.millisecondsSinceEpoch) return f;
    final next = DateTime.fromMillisecondsSinceEpoch(
      f.millisecondsSinceEpoch + _period,
    );
    if (next.timeZoneOffset.inMilliseconds == f.timeZoneOffset.inMilliseconds) {
      return next;
    }
    return floor(offset(f));
  }

  @override
  DateTime round(DateTime date) {
    final d0 = floor(date);
    final ms = date.millisecondsSinceEpoch;
    if (d0.millisecondsSinceEpoch == ms) return d0;
    final d1 = ceil(date);
    return ms - d0.millisecondsSinceEpoch < d1.millisecondsSinceEpoch - ms
        ? d0
        : d1;
  }

  @override
  DateTime offset(DateTime date, [int step = 1]) {
    var d = date.isUtc ? date.toLocal() : date;
    var s = step;
    if (s < 0) {
      while (++s <= 0) {
        do {
          d = _base.offset(d, -1);
        } while (d.hour % _k != 0);
      }
    } else {
      while (--s >= 0) {
        do {
          d = _base.offset(d);
        } while (d.hour % _k != 0);
      }
    }
    return d;
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final first = ceil(start);
    final firstMs = first.millisecondsSinceEpoch;
    final stopMs = stop.millisecondsSinceEpoch;
    if (firstMs >= stopMs) return <DateTime>[];
    final stride = step * _period;
    final count = ((stopMs - firstMs - 1) ~/ stride) + 1;
    final firstOff = first.timeZoneOffset.inMilliseconds;
    final lastCand = DateTime.fromMillisecondsSinceEpoch(
      firstMs + (count - 1) * stride,
    );
    if (firstOff % durationHour == 0 &&
        lastCand.timeZoneOffset.inMilliseconds == firstOff &&
        stopMs - firstMs < 30 * durationDay) {
      return List<DateTime>.generate(
        count,
        (i) => DateTime.fromMillisecondsSinceEpoch(firstMs + i * stride),
      );
    }
    return super.range(start, stop, step);
  }
}

DateTime _unusedHourFloor(DateTime d) => d;
DateTime _unusedHourOffset(DateTime d, int s) => d;

/// Hours in local time (e.g., `01:00`).
const CountableTimeInterval timeHour = _TimeHourInterval();

/// Alias for [timeHour]'s [TimeInterval.range].
final TimeRange timeHours = timeHour.range;

/// Hours in Coordinated Universal Time (UTC).
// DIVERGES(d3-time): adapt-time-fast-forms, direct O(1) epoch-millisecond
// arithmetic for utcHour and dividing every(k) multiples.
const CountableTimeInterval utcHour = FixedPeriodTimeInterval(
  durationHour,
  cycleSize: 24,
  customField: _fieldUtcHour,
);

/// Alias for [utcHour]'s [TimeInterval.range].
final TimeRange utcHours = utcHour.range;
