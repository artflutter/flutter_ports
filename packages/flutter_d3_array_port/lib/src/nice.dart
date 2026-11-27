// Ported from d3-array v3.2.4 src/nice.js (ISC, Mike Bostock).

/// Port of `src/nice.js` of d3-array 3.2.4.
library;

import 'package:flutter_d3_array_port/src/ticks.dart';

/// Returns a nicely-rounded `(start, stop)` interval extending `[start, stop]`
/// to clean tick multiples for approximately [count] ticks.
// DIVERGES(d3-array): adapt-array-typed-api, returns a (double, double) record.
(double, double) nice(num start, num stop, num count) {
  var s0 = start.toDouble();
  var s1 = stop.toDouble();
  final c = count.toDouble();
  double? prestep;
  while (true) {
    final step = tickIncrement(s0, s1, c);
    if (step == prestep || step == 0 || !step.isFinite) {
      return (s0, s1);
    } else if (step > 0) {
      s0 = (s0 / step).floorToDouble() * step;
      s1 = (s1 / step).ceilToDouble() * step;
    } else if (step < 0) {
      s0 = (s0 * step).ceilToDouble() / step;
      s1 = (s1 * step).floorToDouble() / step;
    }
    prestep = step;
  }
}
