// Ported from d3-time v3.1.0 src/interval.js (ISC, Mike Bostock).

/// Port of `src/interval.js` of d3-time 3.1.0.
library;

/// Rounds [date] down to the start of a time interval boundary.
typedef TimeFloor = DateTime Function(DateTime date);

/// Offsets [date] by [step] intervals without rounding.
typedef TimeOffset = DateTime Function(DateTime date, int step);

/// Returns the number of interval boundaries between already-floored [start]
/// and [end].
typedef TimeCount = num Function(DateTime start, DateTime end);

/// Extracts the periodic field index of [date] used by
/// [CountableTimeInterval.every].
typedef TimeField = int Function(DateTime date);

/// Predicate used by [TimeInterval.filter] to select interval boundaries.
typedef TimeFilter = bool Function(DateTime date);

/// Signature of a convenience range alias (such as `timeDays` or `utcMonths`).
typedef TimeRange = List<DateTime> Function(
  DateTime start,
  DateTime stop, [
  int step,
]);

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

/// A calendar time interval supporting flooring, ceiling, rounding, offsetting,
/// range generation, and predicate filtering over immutable native [DateTime]
/// values (D3 ADR 0021).
// DIVERGES(d3-time): adapt-time-typed-api, native immutable DateTime interval
// class with typed callbacks and int step instead of mutable JS Date and
// untyped function expando methods.
class const TimeInterval(final TimeFloor _floor, final TimeOffset _offset) {
  /// Creates a [TimeInterval] from [floor] and [offset] functions.
  this;

  /// Equivalent to [floor], defaulting to `DateTime.now()` when [date] is
  /// omitted.
  DateTime call([DateTime? date]) => floor(date ?? DateTime.now());

  /// Returns a new [DateTime] representing the latest interval boundary less
  /// than or equal to [date].
  DateTime floor(DateTime date) => _floor(date);

  /// Returns a new [DateTime] representing the earliest interval boundary
  /// greater than or equal to [date].
  DateTime ceil(DateTime date) {
    final prev = DateTime.fromMillisecondsSinceEpoch(
      date.millisecondsSinceEpoch - 1,
      isUtc: date.isUtc,
    );
    return _floor(_offset(_floor(prev), 1));
  }

  /// Returns a new [DateTime] representing the closest interval boundary to
  /// [date], rounding ties upward.
  DateTime round(DateTime date) {
    final d0 = floor(date);
    final d1 = ceil(date);
    final ms = date.millisecondsSinceEpoch;
    return ms - d0.millisecondsSinceEpoch < d1.millisecondsSinceEpoch - ms
        ? d0
        : d1;
  }

  /// Returns a new [DateTime] equal to [date] plus [step] intervals without
  /// rounding.
  DateTime offset(DateTime date, [int step = 1]) => _offset(date, step);

  /// Returns an array of dates representing every interval boundary after or
  /// equal to [start] (inclusive) and before [stop] (exclusive), optionally
  /// taking every [step]th boundary.
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    final values = <DateTime>[];
    var current = ceil(start);
    final stopMs = stop.millisecondsSinceEpoch;
    if (!(current.millisecondsSinceEpoch < stopMs) || !(step > 0)) {
      return values;
    }
    int previousMs;
    do {
      values.add(current);
      previousMs = current.millisecondsSinceEpoch;
      current = _floor(_offset(current, step));
    } while (previousMs < current.millisecondsSinceEpoch &&
        current.millisecondsSinceEpoch < stopMs);
    return values;
  }

  /// Returns a new [TimeInterval] that is a filtered subset of this interval
  /// containing only dates for which [test] returns `true`.
  TimeInterval filter(TimeFilter test) => TimeInterval(
    (date) {
      var d = floor(date);
      while (!test(d)) {
        d = floor(
          DateTime.fromMillisecondsSinceEpoch(
            d.millisecondsSinceEpoch - 1,
            isUtc: d.isUtc,
          ),
        );
      }
      return d;
    },
    (date, step) {
      var d = date;
      var s = step;
      if (s < 0) {
        while (++s <= 0) {
          do {
            d = offset(d, -1);
          } while (!test(d));
        }
      } else {
        while (--s >= 0) {
          do {
            d = offset(d);
          } while (!test(d));
        }
      }
      return d;
    },
  );
}

/// A [TimeInterval] that additionally supports counting interval boundaries
/// between two dates ([count]) and deriving periodic sub-intervals ([every]).
// DIVERGES(d3-time): adapt-time-typed-api, static CountableTimeInterval
// subclass replacing JS dynamic attachment of .count and .every.
class const CountableTimeInterval(
  super._floor,
  super._offset,
  final TimeCount _count, [
  final TimeField? _field,
]) extends TimeInterval {
  /// Creates a [CountableTimeInterval] from floor, offset, count, and an
  /// optional field extractor.
  this;

  /// Returns the number of interval boundaries after [start] (exclusive) and
  /// before or equal to [end] (inclusive).
  int count(DateTime start, DateTime end) {
    final t0 = floor(start);
    final t1 = floor(end);
    return _count(t0, t1).floor();
  }

  /// Returns a filtered view of this interval representing every [step]th
  /// interval, or `null` if [step] is not positive.
  TimeInterval? every(int step) {
    if (step <= 0) return null;
    if (step == 1) return this;
    final f = _field;
    return filter(
      f != null ? (d) => f(d) % step == 0 : (d) => count(_epoch, d) % step == 0,
    );
  }
}

/// Constructs a custom [TimeInterval] (or [CountableTimeInterval] when [count]
/// is provided) from [floor] and [offset] functions.
// DIVERGES(d3-time): adapt-time-typed-api, typed factory returning
// CountableTimeInterval when count is provided and TimeInterval otherwise.
TimeInterval timeInterval(
  TimeFloor floor,
  TimeOffset offset, [
  TimeCount? count,
  TimeField? field,
]) => count != null
    ? CountableTimeInterval(floor, offset, count, field)
    : TimeInterval(floor, offset);

/// Constructs a statically typed [CountableTimeInterval] from [floor],
/// [offset], [count], and an optional [field] extractor.
// DIVERGES(d3-time): adapt-time-typed-api, typed CountableTimeInterval factory
// avoiding downcasts when a caller statically needs count() and every().
CountableTimeInterval countableTimeInterval(
  TimeFloor floor,
  TimeOffset offset,
  TimeCount count, [
  TimeField? field,
]) => CountableTimeInterval(floor, offset, count, field);

/// Internal fixed-period non-countable interval created by `every(k)` when
/// `k` evenly divides the parent cycle (e.g., `utcSecond.every(15)`,
/// `utcMinute.every(5)`, `utcHour.every(6)`, `unixDay.every(k)`,
/// `utcWeek.every(k)`).
///
/// Uses direct O(1) epoch-millisecond arithmetic for `floor`, `ceil`, `round`,
/// `offset` (preserving upstream `filter` stepping semantics), and pre-sized
/// `range`.
// DIVERGES(d3-time): adapt-time-fast-forms, O(1) epoch-millisecond arithmetic
// and pre-sized range allocation for periodic fixed-length sub-intervals.
final class const FixedEveryTimeInterval(
  final int _basePeriod,
  final int _k, {
  int epochOffset = 0,
  bool preserveUtc = false,
}) extends TimeInterval {
  /// Creates a fixed-period sub-interval of `k` multiples of `basePeriod`.
  this : super(_unusedFloor, _unusedOffset);

  final int _period = _basePeriod * _k;
  final int _epochOffset = epochOffset;
  final bool _preserveUtc = preserveUtc;

  @pragma('vm:prefer-inline')
  bool _outUtc(DateTime date) => !_preserveUtc || date.isUtc;

  @override
  DateTime floor(DateTime date) {
    final ms = date.millisecondsSinceEpoch;
    final rem = _epochOffset == 0
        ? ms % _period
        : (ms - _epochOffset) % _period;
    return DateTime.fromMillisecondsSinceEpoch(ms - rem, isUtc: _outUtc(date));
  }

  @override
  DateTime ceil(DateTime date) {
    final ms = date.millisecondsSinceEpoch;
    final rem = _epochOffset == 0
        ? ms % _period
        : (ms - _epochOffset) % _period;
    return DateTime.fromMillisecondsSinceEpoch(
      rem == 0 ? ms : ms + (_period - rem),
      isUtc: _outUtc(date),
    );
  }

  @override
  DateTime round(DateTime date) {
    final ms = date.millisecondsSinceEpoch;
    final rem = _epochOffset == 0
        ? ms % _period
        : (ms - _epochOffset) % _period;
    return DateTime.fromMillisecondsSinceEpoch(
      rem * 2 < _period ? ms - rem : ms + (_period - rem),
      isUtc: _outUtc(date),
    );
  }

  @override
  DateTime offset(DateTime date, [int step = 1]) {
    final outUtc = _outUtc(date);
    final ms = date.millisecondsSinceEpoch;
    if (step == 0) {
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: outUtc);
    }
    final shifted = ms - _epochOffset;
    final subRem = shifted % _basePeriod;
    final baseIdx = (shifted - subRem) ~/ _basePeriod;
    final mod = baseIdx % _k;
    final int targetIdx;
    if (step > 0) {
      targetIdx = baseIdx + (_k - mod) + (step - 1) * _k;
    } else {
      targetIdx = baseIdx - (mod == 0 ? _k : mod) + (step + 1) * _k;
    }
    return DateTime.fromMillisecondsSinceEpoch(
      _epochOffset + targetIdx * _basePeriod + subRem,
      isUtc: outUtc,
    );
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final startMs = start.millisecondsSinceEpoch;
    final stopMs = stop.millisecondsSinceEpoch;
    final rem = _epochOffset == 0
        ? startMs % _period
        : (startMs - _epochOffset) % _period;
    final firstMs = rem == 0 ? startMs : startMs + (_period - rem);
    if (firstMs >= stopMs) return <DateTime>[];
    final stride = step * _period;
    final count = ((stopMs - firstMs - 1) ~/ stride) + 1;
    final outUtc = _outUtc(start);
    return List<DateTime>.generate(
      count,
      (i) => DateTime.fromMillisecondsSinceEpoch(
        firstMs + i * stride,
        isUtc: outUtc,
      ),
    );
  }
}

/// Internal fixed-period countable interval using direct O(1) epoch-millisecond
/// Euclidean arithmetic for `floor`, `ceil`, `round`, `offset`, `count`, and
/// pre-sized `range`.
// DIVERGES(d3-time): adapt-time-fast-forms, O(1) epoch-millisecond arithmetic,
// zero-allocation count, and pre-sized range allocation for fixed-length UTC
// and timezone-independent intervals.
class const FixedPeriodTimeInterval(
  final int _period, {
  int epochOffset = 0,
  bool preserveUtc = false,
  int cycleSize = 0,
  bool epochCountEvery = false,
  TimeField? customField,
}) extends CountableTimeInterval {
  /// Creates a fixed-period countable interval.
  this : super(_unusedFloor, _unusedOffset, _unusedCount, customField);

  final int _epochOffset = epochOffset;
  final bool _preserveUtc = preserveUtc;
  final int _cycleSize = cycleSize;
  final bool _epochCountEvery = epochCountEvery;

  @pragma('vm:prefer-inline')
  bool _outUtc(DateTime date) => !_preserveUtc || date.isUtc;

  @override
  DateTime floor(DateTime date) {
    final ms = date.millisecondsSinceEpoch;
    if (_period == 1) {
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: _outUtc(date));
    }
    final rem = _epochOffset == 0
        ? ms % _period
        : (ms - _epochOffset) % _period;
    return DateTime.fromMillisecondsSinceEpoch(ms - rem, isUtc: _outUtc(date));
  }

  @override
  DateTime ceil(DateTime date) {
    final ms = date.millisecondsSinceEpoch;
    if (_period == 1) {
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: _outUtc(date));
    }
    final rem = _epochOffset == 0
        ? ms % _period
        : (ms - _epochOffset) % _period;
    return DateTime.fromMillisecondsSinceEpoch(
      rem == 0 ? ms : ms + (_period - rem),
      isUtc: _outUtc(date),
    );
  }

  @override
  DateTime round(DateTime date) {
    final ms = date.millisecondsSinceEpoch;
    if (_period == 1) {
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: _outUtc(date));
    }
    final rem = _epochOffset == 0
        ? ms % _period
        : (ms - _epochOffset) % _period;
    return DateTime.fromMillisecondsSinceEpoch(
      rem * 2 < _period ? ms - rem : ms + (_period - rem),
      isUtc: _outUtc(date),
    );
  }

  @override
  DateTime offset(DateTime date, [int step = 1]) =>
      DateTime.fromMillisecondsSinceEpoch(
        date.millisecondsSinceEpoch + step * _period,
        isUtc: _outUtc(date),
      );

  @override
  int count(DateTime start, DateTime end) {
    final a = start.millisecondsSinceEpoch - _epochOffset;
    final b = end.millisecondsSinceEpoch - _epochOffset;
    if (_period == 1) return b - a;
    final fa = a - (a % _period);
    final fb = b - (b % _period);
    return (fb ~/ _period) - (fa ~/ _period);
  }

  @override
  List<DateTime> range(DateTime start, DateTime stop, [int step = 1]) {
    if (step <= 0) return <DateTime>[];
    final startMs = start.millisecondsSinceEpoch;
    final stopMs = stop.millisecondsSinceEpoch;
    final int firstMs;
    if (_period == 1) {
      firstMs = startMs;
    } else {
      final rem = _epochOffset == 0
          ? startMs % _period
          : (startMs - _epochOffset) % _period;
      firstMs = rem == 0 ? startMs : startMs + (_period - rem);
    }
    if (firstMs >= stopMs) return <DateTime>[];
    final stride = step * _period;
    final count = ((stopMs - firstMs - 1) ~/ stride) + 1;
    final outUtc = _outUtc(start);
    return List<DateTime>.generate(
      count,
      (i) => DateTime.fromMillisecondsSinceEpoch(
        firstMs + i * stride,
        isUtc: outUtc,
      ),
    );
  }

  @override
  TimeInterval? every(int step) {
    if (step <= 0) return null;
    if (step == 1) return this;
    if (_epochCountEvery) {
      final epochAlign = _epochOffset == 0 ? 0 : -((-_epochOffset) % _period);
      return FixedEveryTimeInterval(
        _period,
        step,
        epochOffset: epochAlign,
        preserveUtc: _preserveUtc,
      );
    }
    if (_cycleSize > 0 && _cycleSize % step == 0) {
      return FixedEveryTimeInterval(
        _period,
        step,
        epochOffset: _epochOffset,
        preserveUtc: _preserveUtc,
      );
    }
    return super.every(step);
  }
}

DateTime _unusedFloor(DateTime date) => date;
DateTime _unusedOffset(DateTime date, int step) => date;
num _unusedCount(DateTime start, DateTime end) => 0;
