// Ported from d3-time v3.1.0 src/minute.js (ISC, Mike Bostock).

/// Port of `src/minute.js` of d3-time 3.1.0.
library;

import 'package:flutter_d3_time_port/src/duration.dart';
import 'package:flutter_d3_time_port/src/interval.dart';

DateTime _floorTimeMinute(DateTime date) {
  final d = date.isUtc ? date.toLocal() : date;
  final ms = d.millisecondsSinceEpoch;
  final localMs = ms + d.timeZoneOffset.inMilliseconds;
  return DateTime.fromMillisecondsSinceEpoch(ms - (localMs % durationMinute));
}

DateTime _offsetTimeMinute(DateTime date, int step) =>
    DateTime.fromMillisecondsSinceEpoch(
      date.millisecondsSinceEpoch + step * durationMinute,
    );

num _countMinute(DateTime start, DateTime end) =>
    (end.millisecondsSinceEpoch - start.millisecondsSinceEpoch) /
    durationMinute;

int _fieldTimeMinute(DateTime date) =>
    (date.isUtc ? date.toLocal() : date).minute;

int _fieldUtcMinute(DateTime date) =>
    (date.millisecondsSinceEpoch % (60 * durationMinute)) ~/ durationMinute;

// DIVERGES(d3-time): adapt-time-fast-forms, direct ceil/round/count and
// pre-sized range for local minutes while preserving sub-minute offset safety.
final class const _TimeMinuteInterval() extends CountableTimeInterval {
  this
    : super(
        _floorTimeMinute,
        _offsetTimeMinute,
        _countMinute,
        _fieldTimeMinute,
      );

  @override
  DateTime ceil(DateTime date) {
    final f = _floorTimeMinute(date);
    if (f.millisecondsSinceEpoch == date.millisecondsSinceEpoch) return f;
    return _floorTimeMinute(
      DateTime.fromMillisecondsSinceEpoch(
        f.millisecondsSinceEpoch + durationMinute,
      ),
    );
  }

  @override
  DateTime round(DateTime date) {
    final d0 = _floorTimeMinute(date);
    final ms = date.millisecondsSinceEpoch;
    if (d0.millisecondsSinceEpoch == ms) return d0;
    final d1 = _floorTimeMinute(
      DateTime.fromMillisecondsSinceEpoch(
        d0.millisecondsSinceEpoch + durationMinute,
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
    final stride = step * durationMinute;
    final count = ((stopMs - firstMs - 1) ~/ stride) + 1;
    // Fast path when local TZ offset has no sub-minute seconds (all modern TZ).
    if (first.timeZoneOffset.inSeconds % 60 == 0) {
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
    if (60 % step == 0) return _TimeMultiMinuteInterval(step, this);
    return super.every(step);
  }
}

final class const _TimeMultiMinuteInterval(
  final int _k,
  final CountableTimeInterval _base,
) extends TimeInterval {
  this : super(_unusedMinFloor, _unusedMinOffset);

  int get _period => _k * durationMinute;

  @override
  DateTime floor(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final ms = d.millisecondsSinceEpoch;
    final off = d.timeZoneOffset.inMilliseconds;
    final rem = (ms + off) % _period;
    final cand = DateTime.fromMillisecondsSinceEpoch(ms - rem);
    if (cand.timeZoneOffset.inMilliseconds == off) return cand;
    // Rare DST / offset-change boundary: fall back to exact filter semantics.
    var cur = _floorTimeMinute(d);
    while (cur.minute % _k != 0) {
      cur = _floorTimeMinute(
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
        } while (d.minute % _k != 0);
      }
    } else {
      while (--s >= 0) {
        do {
          d = _base.offset(d);
        } while (d.minute % _k != 0);
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
    if (firstOff % durationMinute == 0 &&
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

DateTime _unusedMinFloor(DateTime d) => d;
DateTime _unusedMinOffset(DateTime d, int s) => d;

/// Minutes in local time (e.g., `01:02:00`).
const CountableTimeInterval timeMinute = _TimeMinuteInterval();

/// Alias for [timeMinute]'s [TimeInterval.range].
final TimeRange timeMinutes = timeMinute.range;

/// Minutes in Coordinated Universal Time (UTC).
// DIVERGES(d3-time): adapt-time-fast-forms, direct O(1) epoch-millisecond
// arithmetic for utcMinute and dividing every(k) multiples.
const CountableTimeInterval utcMinute = FixedPeriodTimeInterval(
  durationMinute,
  cycleSize: 60,
  customField: _fieldUtcMinute,
);

/// Alias for [utcMinute]'s [TimeInterval.range].
final TimeRange utcMinutes = utcMinute.range;
