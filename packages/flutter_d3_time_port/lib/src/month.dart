// Ported from d3-time v3.1.0 src/month.js (ISC, Mike Bostock).

/// Port of `src/month.js` of d3-time 3.1.0.
library;

import 'package:flutter_d3_time_port/src/interval.dart';

DateTime _floorTimeMonth(DateTime date) {
  final d = date.isUtc ? date.toLocal() : date;
  return DateTime(d.year, d.month);
}

DateTime _offsetTimeMonth(DateTime date, int step) {
  final d = date.isUtc ? date.toLocal() : date;
  return DateTime(
    d.year,
    d.month + step,
    d.day,
    d.hour,
    d.minute,
    d.second,
    d.millisecond,
  );
}

num _countMonth(DateTime start, DateTime end) =>
    end.month - start.month + (end.year - start.year) * 12;

int _fieldTimeMonth(DateTime date) =>
    (date.isUtc ? date.toLocal() : date).month - 1;

DateTime _floorUtcMonth(DateTime date) {
  final d = date.isUtc ? date : date.toUtc();
  return DateTime.utc(d.year, d.month);
}

DateTime _offsetUtcMonth(DateTime date, int step) {
  final d = date.isUtc ? date : date.toUtc();
  return DateTime.utc(
    d.year,
    d.month + step,
    d.day,
    d.hour,
    d.minute,
    d.second,
    d.millisecond,
  );
}

int _fieldUtcMonth(DateTime date) =>
    (date.isUtc ? date : date.toUtc()).month - 1;

// DIVERGES(d3-time): adapt-time-fast-forms, direct ceil/round/count and
// pre-sized calendar-stepped range for timeMonth and utcMonth (plus dividing
// every(k) sub-intervals such as quarterly every(3)).
final class const _TimeMonthInterval() extends CountableTimeInterval {
  this : super(_floorTimeMonth, _offsetTimeMonth, _countMonth, _fieldTimeMonth);

  @override
  DateTime ceil(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final f = DateTime(d.year, d.month);
    if (f.millisecondsSinceEpoch == d.millisecondsSinceEpoch) return f;
    return DateTime(d.year, d.month + 1);
  }

  @override
  DateTime round(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final ms = d.millisecondsSinceEpoch;
    final d0 = DateTime(d.year, d.month);
    if (d0.millisecondsSinceEpoch == ms) return d0;
    final d1 = DateTime(d.year, d.month + 1);
    return ms - d0.millisecondsSinceEpoch < d1.millisecondsSinceEpoch - ms
        ? d0
        : d1;
  }

  @override
  int count(DateTime start, DateTime end) {
    final a = start.isUtc ? start.toLocal() : start;
    final b = end.isUtc ? end.toLocal() : end;
    return b.month - a.month + (b.year - a.year) * 12;
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final first = ceil(start);
    final stopMs = stop.millisecondsSinceEpoch;
    if (first.millisecondsSinceEpoch >= stopMs) return <DateTime>[];
    final y = first.year;
    final m = first.month;
    final stopLocal = stop.isUtc ? stop.toLocal() : stop;
    final stopFloor = DateTime(stopLocal.year, stopLocal.month);
    final total =
        (stopLocal.year - y) * 12 +
        (stopLocal.month - m) +
        (stopFloor.millisecondsSinceEpoch < stopMs ? 1 : 0);
    if (total <= 0) return <DateTime>[];
    final count = (total + step - 1) ~/ step;
    return List<DateTime>.generate(count, (i) => DateTime(y, m + i * step));
  }

  @override
  TimeInterval? every(int step) {
    if (step <= 0) return null;
    if (step == 1) return this;
    if (12 % step == 0) return _TimeMultiMonthInterval(step);
    return super.every(step);
  }
}

final class const _TimeMultiMonthInterval(final int _k) extends TimeInterval {
  this : super(_unusedFloor, _unusedOffset);

  @override
  DateTime floor(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final m0 = d.month - 1;
    return DateTime(d.year, m0 - (m0 % _k) + 1);
  }

  @override
  DateTime ceil(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final m0 = d.month - 1;
    final fm0 = m0 - (m0 % _k);
    final f = DateTime(d.year, fm0 + 1);
    if (f.millisecondsSinceEpoch == d.millisecondsSinceEpoch) return f;
    return DateTime(d.year, fm0 + _k + 1);
  }

  @override
  DateTime round(DateTime date) {
    final d = date.isUtc ? date.toLocal() : date;
    final ms = d.millisecondsSinceEpoch;
    final m0 = d.month - 1;
    final fm0 = m0 - (m0 % _k);
    final d0 = DateTime(d.year, fm0 + 1);
    if (d0.millisecondsSinceEpoch == ms) return d0;
    final d1 = DateTime(d.year, fm0 + _k + 1);
    return ms - d0.millisecondsSinceEpoch < d1.millisecondsSinceEpoch - ms
        ? d0
        : d1;
  }

  @override
  DateTime offset(DateTime date, [int step = 1]) {
    var d = date.isUtc ? date.toLocal() : date;
    if (step == 0) return d;
    if (d.day <= 28) {
      final m0 = d.month - 1;
      final mod = m0 % _k;
      final int targetM0;
      if (step > 0) {
        targetM0 = m0 + (_k - mod) + (step - 1) * _k;
      } else {
        targetM0 = m0 - (mod == 0 ? _k : mod) + (step + 1) * _k;
      }
      return DateTime(
        d.year,
        targetM0 + 1,
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
          d = _offsetTimeMonth(d, -1);
        } while ((d.month - 1) % _k != 0);
      }
    } else {
      while (--s >= 0) {
        do {
          d = _offsetTimeMonth(d, 1);
        } while ((d.month - 1) % _k != 0);
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
    final y = first.year;
    final m = first.month;
    final stopLocal = stop.isUtc ? stop.toLocal() : stop;
    final stopFloor = DateTime(stopLocal.year, stopLocal.month);
    final total =
        (stopLocal.year - y) * 12 +
        (stopLocal.month - m) +
        (stopFloor.millisecondsSinceEpoch < stopMs ? 1 : 0);
    if (total <= 0) return <DateTime>[];
    final stride = step * _k;
    final count = (total + stride - 1) ~/ stride;
    return List<DateTime>.generate(count, (i) => DateTime(y, m + i * stride));
  }
}

final class const _UtcMonthInterval() extends CountableTimeInterval {
  this : super(_floorUtcMonth, _offsetUtcMonth, _countMonth, _fieldUtcMonth);

  @override
  DateTime ceil(DateTime date) {
    final d = date.isUtc ? date : date.toUtc();
    final f = DateTime.utc(d.year, d.month);
    if (f.millisecondsSinceEpoch == d.millisecondsSinceEpoch) return f;
    return DateTime.utc(d.year, d.month + 1);
  }

  @override
  DateTime round(DateTime date) {
    final d = date.isUtc ? date : date.toUtc();
    final ms = d.millisecondsSinceEpoch;
    final d0 = DateTime.utc(d.year, d.month);
    if (d0.millisecondsSinceEpoch == ms) return d0;
    final d1 = DateTime.utc(d.year, d.month + 1);
    return ms - d0.millisecondsSinceEpoch < d1.millisecondsSinceEpoch - ms
        ? d0
        : d1;
  }

  @override
  int count(DateTime start, DateTime end) {
    final a = start.isUtc ? start : start.toUtc();
    final b = end.isUtc ? end : end.toUtc();
    return b.month - a.month + (b.year - a.year) * 12;
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final first = ceil(start);
    final stopMs = stop.millisecondsSinceEpoch;
    if (first.millisecondsSinceEpoch >= stopMs) return <DateTime>[];
    final y = first.year;
    final m = first.month;
    final stopUtc = stop.isUtc ? stop : stop.toUtc();
    final stopFloor = DateTime.utc(stopUtc.year, stopUtc.month);
    final total =
        (stopUtc.year - y) * 12 +
        (stopUtc.month - m) +
        (stopFloor.millisecondsSinceEpoch < stopMs ? 1 : 0);
    if (total <= 0) return <DateTime>[];
    final count = (total + step - 1) ~/ step;
    return List<DateTime>.generate(count, (i) => DateTime.utc(y, m + i * step));
  }

  @override
  TimeInterval? every(int step) {
    if (step <= 0) return null;
    if (step == 1) return this;
    if (12 % step == 0) return _UtcMultiMonthInterval(step);
    return super.every(step);
  }
}

final class const _UtcMultiMonthInterval(final int _k) extends TimeInterval {
  this : super(_unusedFloor, _unusedOffset);

  @override
  DateTime floor(DateTime date) {
    final d = date.isUtc ? date : date.toUtc();
    final m0 = d.month - 1;
    return DateTime.utc(d.year, m0 - (m0 % _k) + 1);
  }

  @override
  DateTime ceil(DateTime date) {
    final d = date.isUtc ? date : date.toUtc();
    final m0 = d.month - 1;
    final fm0 = m0 - (m0 % _k);
    final f = DateTime.utc(d.year, fm0 + 1);
    if (f.millisecondsSinceEpoch == d.millisecondsSinceEpoch) return f;
    return DateTime.utc(d.year, fm0 + _k + 1);
  }

  @override
  DateTime round(DateTime date) {
    final d = date.isUtc ? date : date.toUtc();
    final ms = d.millisecondsSinceEpoch;
    final m0 = d.month - 1;
    final fm0 = m0 - (m0 % _k);
    final d0 = DateTime.utc(d.year, fm0 + 1);
    if (d0.millisecondsSinceEpoch == ms) return d0;
    final d1 = DateTime.utc(d.year, fm0 + _k + 1);
    return ms - d0.millisecondsSinceEpoch < d1.millisecondsSinceEpoch - ms
        ? d0
        : d1;
  }

  @override
  DateTime offset(DateTime date, [int step = 1]) {
    var d = date.isUtc ? date : date.toUtc();
    if (step == 0) return d;
    if (d.day <= 28) {
      final m0 = d.month - 1;
      final mod = m0 % _k;
      final int targetM0;
      if (step > 0) {
        targetM0 = m0 + (_k - mod) + (step - 1) * _k;
      } else {
        targetM0 = m0 - (mod == 0 ? _k : mod) + (step + 1) * _k;
      }
      return DateTime.utc(
        d.year,
        targetM0 + 1,
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
          d = _offsetUtcMonth(d, -1);
        } while ((d.month - 1) % _k != 0);
      }
    } else {
      while (--s >= 0) {
        do {
          d = _offsetUtcMonth(d, 1);
        } while ((d.month - 1) % _k != 0);
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
    final y = first.year;
    final m = first.month;
    final stopUtc = stop.isUtc ? stop : stop.toUtc();
    final stopFloor = DateTime.utc(stopUtc.year, stopUtc.month);
    final total =
        (stopUtc.year - y) * 12 +
        (stopUtc.month - m) +
        (stopFloor.millisecondsSinceEpoch < stopMs ? 1 : 0);
    if (total <= 0) return <DateTime>[];
    final stride = step * _k;
    final count = (total + stride - 1) ~/ stride;
    return List<DateTime>.generate(
      count,
      (i) => DateTime.utc(y, m + i * stride),
    );
  }
}

DateTime _unusedFloor(DateTime date) => date;
DateTime _unusedOffset(DateTime date, int step) => date;

/// Months in local time (e.g., February 1, `00:00`).
const CountableTimeInterval timeMonth = _TimeMonthInterval();

/// Alias for [timeMonth]'s [TimeInterval.range].
final TimeRange timeMonths = timeMonth.range;

/// Months in Coordinated Universal Time (UTC).
const CountableTimeInterval utcMonth = _UtcMonthInterval();

/// Alias for [utcMonth]'s [TimeInterval.range].
final TimeRange utcMonths = utcMonth.range;
