// Ported from d3-array v3.2.4 src/median.js (ISC, Mike Bostock).

/// Port of `src/median.js` of d3-array 3.2.4.
library;

import 'package:flutter_d3_array_port/src/quantile.dart';

/// Returns the median (`0.5`-quantile) of [values] using the R-7 method,
/// ignoring `null` and `NaN`, or `null` if no valid numbers exist.
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> returning
// double?.
double? median(Iterable<num?> values) => quantile(values, 0.5);

/// Returns the median of numeric values extracted from [values] using
/// [valueof].
double? medianBy<T>(Iterable<T> values, num? Function(T value) valueof) =>
    quantileBy(values, 0.5, valueof);

/// Returns the median of numeric values extracted from [values] using indexed
/// [valueof].
double? medianByIndexed<T>(
  Iterable<T> values,
  num? Function(T value, int index, Iterable<T> values) valueof,
) => quantileByIndexed(values, 0.5, valueof);

/// Returns the index of the median element of [values], or `-1` if no valid
/// value exists.
int? medianIndex(List<num?> values) => quantileIndex(values, 0.5);

/// Returns the index of the median element of [values] using [valueof].
int? medianIndexBy<T>(List<T> values, num? Function(T value) valueof) =>
    quantileIndexBy(values, 0.5, valueof);

/// Returns the index of the median element of [values] using indexed [valueof].
int? medianIndexByIndexed<T>(
  List<T> values,
  num? Function(T value, int index, List<T> values) valueof,
) => quantileIndexByIndexed(values, 0.5, valueof);
