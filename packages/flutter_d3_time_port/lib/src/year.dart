// Ported from d3-time v3.1.0 src/year.js (ISC, Mike Bostock).

/// Port of `src/year.js` of d3-time 3.1.0.
library;

import 'package:flutter_d3_time_port/src/interval.dart';

DateTime _floorTimeYear(DateTime date) {
  final d = date.isUtc ? date.toLocal() : date;
  return DateTime(d.year);
}

DateTime _offsetTimeYear(DateTime date, int step) {
  final d = date.isUtc ? date.toLocal() : date;
  return DateTime(
    d.year + step,
    d.month,
    d.day,
    d.hour,
    d.minute,
    d.second,
    d.millisecond,
  );
}

num _countYear(DateTime start, DateTime end) => end.year - start.year;

int _fieldTimeYear(DateTime date) => (date.isUtc ? date.toLocal() : date).year;

DateTime _floorUtcYear(DateTime date) {
  final d = date.isUtc ? date : date.toUtc();
  return DateTime.utc(d.year);
}

DateTime _offsetUtcYear(DateTime date, int step) {
  final d = date.isUtc ? date : date.toUtc();
  return DateTime.utc(
    d.year + step,
    d.month,
    d.day,
    d.hour,
    d.minute,
    d.second,
    d.millisecond,
  );
}

int _fieldUtcYear(DateTime date) => (date.isUtc ? date : date.toUtc()).year;

// DIVERGES(d3-time): adapt-time-fast-forms, direct zero-allocation count and
// pre-sized range for timeYear, utcYear, and multi-year every(k) intervals.
final class const _MultiYearInterval(final int _k, {required final bool _isUtc})
    extends TimeInterval {
  this : super(_noopYFloor, _noopYOffset);

  static DateTime _noopYFloor(DateTime d) => d;
  static DateTime _noopYOffset(DateTime d, int s) => d;

  @override
  DateTime floor(DateTime date) {
    final d = _isUtc
        ? (date.isUtc ? date : date.toUtc())
        : (date.isUtc ? date.toLocal() : date);
    final y = d.year - (d.year % _k);
    return _isUtc ? DateTime.utc(y) : DateTime(y);
  }

  @override
  DateTime ceil(DateTime date) {
    final d = _isUtc
        ? (date.isUtc ? date : date.toUtc())
        : (date.isUtc ? date.toLocal() : date);
    final y = d.year - (d.year % _k);
    final f = _isUtc ? DateTime.utc(y) : DateTime(y);
    if (f.millisecondsSinceEpoch == d.millisecondsSinceEpoch) return f;
    return _isUtc ? DateTime.utc(y + _k) : DateTime(y + _k);
  }

  @override
  DateTime round(DateTime date) {
    final d = _isUtc
        ? (date.isUtc ? date : date.toUtc())
        : (date.isUtc ? date.toLocal() : date);
    final ms = d.millisecondsSinceEpoch;
    final y = d.year - (d.year % _k);
    final d0 = _isUtc ? DateTime.utc(y) : DateTime(y);
    final d0Ms = d0.millisecondsSinceEpoch;
    if (d0Ms == ms) return d0;
    final d1 = _isUtc ? DateTime.utc(y + _k) : DateTime(y + _k);
    return ms - d0Ms < d1.millisecondsSinceEpoch - ms ? d0 : d1;
  }

  @override
  DateTime offset(DateTime date, [int step = 1]) {
    var d = _isUtc
        ? (date.isUtc ? date : date.toUtc())
        : (date.isUtc ? date.toLocal() : date);
    if (step == 0) return d;
    if (d.month != 2 || d.day != 29) {
      final y = d.year;
      final mod = y % _k;
      final int targetY;
      if (step > 0) {
        targetY = y + (_k - mod) + (step - 1) * _k;
      } else {
        targetY = y - (mod == 0 ? _k : mod) + (step + 1) * _k;
      }
      return _isUtc
          ? DateTime.utc(
              targetY,
              d.month,
              d.day,
              d.hour,
              d.minute,
              d.second,
              d.millisecond,
            )
          : DateTime(
              targetY,
              d.month,
              d.day,
              d.hour,
              d.minute,
              d.second,
              d.millisecond,
            );
    }
    var s = step;
    if (s < 0) {
      while (++s <= 0) {
        do {
          d = _isUtc ? _offsetUtcYear(d, -1) : _offsetTimeYear(d, -1);
        } while (d.year % _k != 0);
      }
    } else {
      while (--s >= 0) {
        do {
          d = _isUtc ? _offsetUtcYear(d, 1) : _offsetTimeYear(d, 1);
        } while (d.year % _k != 0);
      }
    }
    return d;
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final first = ceil(start);
    final stopMs = stop.millisecondsSinceEpoch;
    if (first.millisecondsSinceEpoch >= stopMs) return <DateTime>[];
    final y0 = first.year;
    final stopNorm = _isUtc
        ? (stop.isUtc ? stop : stop.toUtc())
        : (stop.isUtc ? stop.toLocal() : stop);
    final stride = step * _k;
    var diffYears = stopNorm.year - y0;
    final lastCandidate = _isUtc
        ? DateTime.utc(y0 + diffYears)
        : DateTime(y0 + diffYears);
    if (lastCandidate.millisecondsSinceEpoch < stopMs) {
      diffYears += 1;
    }
    if (diffYears <= 0) return <DateTime>[];
    final n = (diffYears - 1) ~/ stride + 1;
    return _isUtc
        ? List<DateTime>.generate(n, (i) => DateTime.utc(y0 + i * stride))
        : List<DateTime>.generate(n, (i) => DateTime(y0 + i * stride));
  }
}

final class const _TimeYearInterval() extends CountableTimeInterval {
  this : super(_floorTimeYear, _offsetTimeYear, _countYear, _fieldTimeYear);

  @override
  DateTime ceil(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final y = d.year;
    final f = DateTime(y);
    if (f.millisecondsSinceEpoch == d.millisecondsSinceEpoch) return f;
    return DateTime(y + 1);
  }

  @override
  DateTime round(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final ms = d.millisecondsSinceEpoch;
    final y = d.year;
    final d0 = DateTime(y);
    final d0Ms = d0.millisecondsSinceEpoch;
    if (d0Ms == ms) return d0;
    final d1 = DateTime(y + 1);
    return ms - d0Ms < d1.millisecondsSinceEpoch - ms ? d0 : d1;
  }

  @override
  int count(DateTime start, DateTime end) {
    final s = start.isUtc ? start.toLocal() : start;
    final e = end.isUtc ? end.toLocal() : end;
    return e.year - s.year;
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final first = ceil(start);
    final stopMs = stop.millisecondsSinceEpoch;
    if (first.millisecondsSinceEpoch >= stopMs) return <DateTime>[];
    final y0 = first.year;
    final stopLoc = stop.isUtc ? stop.toLocal() : stop;
    var diffYears = stopLoc.year - y0;
    if (DateTime(y0 + diffYears).millisecondsSinceEpoch < stopMs) {
      diffYears += 1;
    }
    if (diffYears <= 0) return <DateTime>[];
    final n = (diffYears - 1) ~/ step + 1;
    return List<DateTime>.generate(n, (i) => DateTime(y0 + i * step));
  }

  @override
  TimeInterval? every(int step) {
    if (step <= 0) return null;
    if (step == 1) return this;
    return _MultiYearInterval(step, isUtc: false);
  }
}

final class const _UtcYearInterval() extends CountableTimeInterval {
  this : super(_floorUtcYear, _offsetUtcYear, _countYear, _fieldUtcYear);

  @override
  DateTime ceil(DateTime date) {
    final d = date.isUtc ? date : date.toUtc();
    final y = d.year;
    final f = DateTime.utc(y);
    if (f.millisecondsSinceEpoch == d.millisecondsSinceEpoch) return f;
    return DateTime.utc(y + 1);
  }

  @override
  DateTime round(DateTime date) {
    final d = date.isUtc ? date : date.toUtc();
    final ms = d.millisecondsSinceEpoch;
    final y = d.year;
    final d0 = DateTime.utc(y);
    final d0Ms = d0.millisecondsSinceEpoch;
    if (d0Ms == ms) return d0;
    final d1 = DateTime.utc(y + 1);
    return ms - d0Ms < d1.millisecondsSinceEpoch - ms ? d0 : d1;
  }

  @override
  int count(DateTime start, DateTime end) {
    final s = start.isUtc ? start : start.toUtc();
    final e = end.isUtc ? end : end.toUtc();
    return e.year - s.year;
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final first = ceil(start);
    final stopMs = stop.millisecondsSinceEpoch;
    if (first.millisecondsSinceEpoch >= stopMs) return <DateTime>[];
    final y0 = first.year;
    final stopUtc = stop.isUtc ? stop : stop.toUtc();
    var diffYears = stopUtc.year - y0;
    if (DateTime.utc(y0 + diffYears).millisecondsSinceEpoch < stopMs) {
      diffYears += 1;
    }
    if (diffYears <= 0) return <DateTime>[];
    final n = (diffYears - 1) ~/ step + 1;
    return List<DateTime>.generate(n, (i) => DateTime.utc(y0 + i * step));
  }

  @override
  TimeInterval? every(int step) {
    if (step <= 0) return null;
    if (step == 1) return this;
    return _MultiYearInterval(step, isUtc: true);
  }
}

/// Years in local time (e.g., January 1, `00:00`).
const CountableTimeInterval timeYear = _TimeYearInterval();

/// Alias for [timeYear]'s [TimeInterval.range].
final TimeRange timeYears = timeYear.range;

/// Years in Coordinated Universal Time (UTC).
const CountableTimeInterval utcYear = _UtcYearInterval();

/// Alias for [utcYear]'s [TimeInterval.range].
final TimeRange utcYears = utcYear.range;
