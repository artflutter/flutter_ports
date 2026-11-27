// Ported from d3-time v3.1.0 src/second.js (ISC, Mike Bostock).

/// Port of `src/second.js` of d3-time 3.1.0.
library;

import 'package:flutter_d3_time_port/src/duration.dart';
import 'package:flutter_d3_time_port/src/interval.dart';

int _fieldSecond(DateTime date) =>
    (date.millisecondsSinceEpoch % (60 * durationSecond)) ~/ durationSecond;

/// Seconds (e.g., `01:23:45.000`); identical to [utcSecond].
// DIVERGES(d3-time): adapt-time-fast-forms, direct O(1) epoch-millisecond
// arithmetic for second and dividing every(k) multiples while preserving
// DateTime.isUtc.
const CountableTimeInterval timeSecond = FixedPeriodTimeInterval(
  durationSecond,
  preserveUtc: true,
  cycleSize: 60,
  customField: _fieldSecond,
);

/// Alias for [timeSecond].
const CountableTimeInterval utcSecond = timeSecond;

/// Alias for [timeSecond]'s [TimeInterval.range].
final TimeRange timeSeconds = timeSecond.range;

/// Alias for [utcSecond]'s [TimeInterval.range].
final TimeRange utcSeconds = utcSecond.range;
