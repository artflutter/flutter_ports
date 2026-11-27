// Ported from d3-array v3.2.4 src/threshold/scott.js (ISC, Mike Bostock).

/// Port of `src/threshold/scott.js` of d3-array 3.2.4.
library;

import 'dart:math' as math;

import 'package:flutter_d3_array_port/src/count.dart';
import 'package:flutter_d3_array_port/src/deviation.dart';

/// Returns the number of bins according to Scott's normal reference rule.
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> returning
// int and guarding non-finite spreads.
int thresholdScott(Iterable<num?> values, num min, num max) {
  final c = count(values);
  final d = deviation(values);
  if (c > 0 && d != null && d != 0) {
    final raw = (max - min) * math.pow(c, 1.0 / 3.0) / (3.49 * d);
    if (raw.isFinite) return raw.ceil();
  }
  return 1;
}
