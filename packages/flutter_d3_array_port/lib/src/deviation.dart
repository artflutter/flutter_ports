// Ported from d3-array v3.2.4 src/deviation.js (ISC, Mike Bostock).

/// Port of `src/deviation.js` of d3-array 3.2.4.
library;

import 'dart:math' as math;

import 'package:flutter_d3_array_port/src/variance.dart';

/// Returns the sample standard deviation (square root of [variance]) of
/// [values], or `null` if fewer than 2 valid numbers exist.
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> returning
// double?.
double? deviation(Iterable<num?> values) {
  final v = variance(values);
  return v != null && v != 0 ? math.sqrt(v) : v;
}

/// Returns the sample standard deviation of values extracted from [values]
/// using [valueof].
double? deviationBy<T>(Iterable<T> values, num? Function(T value) valueof) {
  final v = varianceBy(values, valueof);
  return v != null && v != 0 ? math.sqrt(v) : v;
}

/// Returns the sample standard deviation of values extracted from [values]
/// using indexed [valueof].
double? deviationByIndexed<T>(
  Iterable<T> values,
  num? Function(T value, int index, Iterable<T> values) valueof,
) {
  final v = varianceByIndexed(values, valueof);
  return v != null && v != 0 ? math.sqrt(v) : v;
}
