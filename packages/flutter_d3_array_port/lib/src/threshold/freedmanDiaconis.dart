// Ported from d3-array v3.2.4 src/threshold/freedmanDiaconis.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/threshold/freedmanDiaconis.js` of d3-array 3.2.4.
library;

import 'dart:math' as math;

import 'package:flutter_d3_array_port/src/count.dart';
import 'package:flutter_d3_array_port/src/quantile.dart';

/// Returns the number of bins according to the Freedman-Diaconis rule.
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> returning
// int and guarding non-finite spreads.
int thresholdFreedmanDiaconis(Iterable<num?> values, num min, num max) {
  final c = count(values);
  if (c == 0) return 1;
  final q3 = quantile(values, 0.75);
  final q1 = quantile(values, 0.25);
  if (q3 == null || q1 == null) return 1;
  final d = q3 - q1;
  if (d != 0) {
    final raw = (max - min) / (2.0 * d * math.pow(c, -1.0 / 3.0));
    if (raw.isFinite) return raw.ceil();
  }
  return 1;
}
