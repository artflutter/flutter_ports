// Ported from d3-array v3.2.4 src/threshold/sturges.js (ISC, Mike Bostock).

/// Port of `src/threshold/sturges.js` of d3-array 3.2.4.
library;

import 'dart:math' as math;

import 'package:flutter_d3_array_port/src/count.dart';

/// Returns the number of bins according to Sturges' formula.
// DIVERGES(d3-array): adapt-array-typed-api, accepts optional unused min/max
// so it can be passed directly as a BinThresholdCount callback, and guards
// count == 0 where Dart's (-Infinity).ceil() would throw.
int thresholdSturges(Iterable<num?> values, [num? min, num? max]) {
  final c = count(values);
  if (c <= 0) return 1;
  final k = (math.log(c) / math.ln2).ceil() + 1;
  return k > 1 ? k : 1;
}
