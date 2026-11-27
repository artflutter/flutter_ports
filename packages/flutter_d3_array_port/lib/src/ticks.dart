// Ported from d3-array v3.2.4 src/ticks.js (ISC, Mike Bostock).

/// Port of `src/ticks.js` of d3-array 3.2.4.
library;

import 'dart:math' as math;
import 'dart:typed_data';

const double _e10 = 7.0710678118654755; // sqrt(50)
const double _e5 = 3.1622776601683795; // sqrt(10)
const double _e2 = 1.4142135623730951; // sqrt(2)

/// Precomputed exact IEEE-754 powers of 10 from 1e-22 to 1e+22 (index p + 22).
const List<double> _pow10Table = <double>[
  1e-22,
  1e-21,
  1e-20,
  1e-19,
  1e-18,
  1e-17,
  1e-16,
  1e-15,
  1e-14,
  1e-13,
  1e-12,
  1e-11,
  1e-10,
  1e-9,
  1e-8,
  1e-7,
  1e-6,
  1e-5,
  1e-4,
  1e-3,
  1e-2,
  1e-1,
  1,
  10,
  100,
  1000,
  10000,
  100000,
  1000000,
  10000000,
  100000000,
  1000000000,
  10000000000,
  100000000000,
  1000000000000,
  10000000000000,
  100000000000000,
  1000000000000000,
  10000000000000000,
  100000000000000000,
  1000000000000000000,
  1e19,
  1e20,
  1e21,
  1e22,
];

/// JavaScript `Math.round(x)`: rounds halves toward `+∞`.
@pragma('vm:prefer-inline')
double _jsRound(double x) {
  if (!x.isFinite || x == 0) return x;
  if (x > 0) return x.roundToDouble();
  final f = x.floorToDouble();
  if (x - f >= 0.5) {
    final r = f + 1.0;
    return r == 0 ? 0.0 : r;
  }
  return f;
}

@pragma('vm:prefer-inline')
double _pow10(int p) {
  if (p >= -22 && p <= 22) return _pow10Table[p + 22];
  return math.pow(10.0, p).toDouble();
}

/// Exact base-10 floor exponent matching JS `Math.floor(Math.log10(x))` for
/// positive finite [x].
@pragma('vm:prefer-inline')
int _floorLog10(double x) {
  if (x >= 1e-22 && x < 1e22) {
    var lo = 0;
    var hi = 44;
    while (lo + 1 < hi) {
      final mid = (lo + hi) >>> 1;
      if (_pow10Table[mid] <= x) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo - 22;
  }
  var p = (math.log(x) * math.log10e).floor();
  if (_pow10(p + 1) <= x) {
    ++p;
  } else if (_pow10(p) > x) {
    --p;
  }
  return p;
}

@pragma('vm:prefer-inline')
(double, double, double) _tickSpec(double start, double stop, double count) {
  if (start.isNaN || stop.isNaN || count.isNaN) {
    return (double.nan, double.nan, double.nan);
  }
  var c = count;
  while (true) {
    final step = (stop - start) / (c <= 0 ? 0.0 : c);
    if (step == 0) {
      return (0.0, -1.0, double.negativeInfinity);
    }
    if (!step.isFinite || step < 0) {
      if (step.isInfinite && step > 0) {
        return (0.0, -1.0, double.infinity);
      }
      return (double.nan, double.nan, double.nan);
    }
    final power = _floorLog10(step);
    final error = step / _pow10(power);
    final factor = error >= _e10
        ? 10.0
        : error >= _e5
        ? 5.0
        : error >= _e2
        ? 2.0
        : 1.0;
    double i1;
    double i2;
    double inc;
    if (power < 0) {
      inc = _pow10(-power) / factor;
      i1 = _jsRound(start * inc);
      i2 = _jsRound(stop * inc);
      if (i1 / inc < start) i1 += 1.0;
      if (i2 / inc > stop) i2 -= 1.0;
      inc = -inc;
    } else {
      inc = _pow10(power) * factor;
      i1 = _jsRound(start / inc);
      i2 = _jsRound(stop / inc);
      if (i1 * inc < start) i1 += 1.0;
      if (i2 * inc > stop) i2 -= 1.0;
    }
    if (i2 < i1 && 0.5 <= c && c < 2) {
      c *= 2;
      continue;
    }
    return (i1, i2, inc);
  }
}

/// Returns approximately [count] + 1 uniformly-spaced, nicely-rounded values
/// between [start] and [stop] (inclusive).
// DIVERGES(d3-array): adapt-array-fast-forms, precomputed sqrt/pow10 lookup
// tables, Float64List output, and exact floor(log10) avoiding Dart
// double.floor() throws on non-finite steps.
List<double> ticks(num start, num stop, num count) {
  final s0 = start.toDouble();
  final s1 = stop.toDouble();
  final c = count.toDouble();
  if (!(c > 0)) return <double>[];
  if (s0 == s1) return <double>[s0];
  final reverse = s1 < s0;
  final (i1, i2, inc) = reverse ? _tickSpec(s1, s0, c) : _tickSpec(s0, s1, c);
  if (!(i2 >= i1)) return <double>[];
  final n = (i2 - i1 + 1).toInt();
  final out = Float64List(n);
  if (reverse) {
    if (inc < 0) {
      final negInc = -inc;
      for (var i = 0; i < n; ++i) {
        out[i] = (i2 - i) / negInc;
      }
    } else {
      for (var i = 0; i < n; ++i) {
        out[i] = (i2 - i) * inc;
      }
    }
  } else {
    if (inc < 0) {
      final negInc = -inc;
      for (var i = 0; i < n; ++i) {
        out[i] = (i1 + i) / negInc;
      }
    } else {
      for (var i = 0; i < n; ++i) {
        out[i] = (i1 + i) * inc;
      }
    }
  }
  return out;
}

/// Returns the tick increment for [start], [stop], and [count] (negative when
/// the step is `< 1`, representing `-1 / step`).
double tickIncrement(num start, num stop, num count) {
  final s0 = start.toDouble();
  final s1 = stop.toDouble();
  final c = count.toDouble();
  if (s1 < s0) return double.nan;
  return _tickSpec(s0, s1, c).$3;
}

/// Returns the signed difference between adjacent tick values for [start],
/// [stop], and [count].
double tickStep(num start, num stop, num count) {
  final s0 = start.toDouble();
  final s1 = stop.toDouble();
  final c = count.toDouble();
  final reverse = s1 < s0;
  final inc = reverse ? tickIncrement(s1, s0, c) : tickIncrement(s0, s1, c);
  return (reverse ? -1.0 : 1.0) * (inc < 0 ? 1.0 / -inc : inc);
}
