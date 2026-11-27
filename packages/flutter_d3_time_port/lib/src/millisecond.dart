// Ported from d3-time v3.1.0 src/millisecond.js (ISC, Mike Bostock).

/// Port of `src/millisecond.js` of d3-time 3.1.0.
library;

import 'package:flutter_d3_time_port/src/interval.dart';

// DIVERGES(d3-time): adapt-time-fast-forms, direct O(1) epoch-ms arithmetic
// for millisecond and millisecond.every(k) preserving DateTime.isUtc.
final class const _MillisecondInterval() extends FixedPeriodTimeInterval {
  this : super(1, preserveUtc: true);

  @override
  TimeInterval? every(int step) {
    if (step <= 0) return null;
    if (step == 1) return this;
    return FixedPeriodTimeInterval(step, preserveUtc: true);
  }
}

/// Milliseconds; the shortest available time interval (identical to
/// [utcMillisecond]).
const CountableTimeInterval timeMillisecond = _MillisecondInterval();

/// Alias for [timeMillisecond].
const CountableTimeInterval utcMillisecond = timeMillisecond;

/// Alias for [timeMillisecond]'s [TimeInterval.range].
final TimeRange timeMilliseconds = timeMillisecond.range;

/// Alias for [utcMillisecond]'s [TimeInterval.range].
final TimeRange utcMilliseconds = utcMillisecond.range;
