// Ported from d3-array v3.2.4 src/greatestIndex.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/greatestIndex.js` of d3-array 3.2.4.
library;

import 'package:flutter_d3_array_port/src/ascending.dart';
import 'package:flutter_d3_array_port/src/maxIndex.dart';

/// Returns the index of the greatest element of [values] according to [compare]
/// (defaulting to [ascending]), or `-1` if no comparable element exists.
// DIVERGES(d3-array): adapt-array-typed-api, split natural-order greatestIndex,
// comparator greatestIndexWith, and accessor greatestIndexBy.
int greatestIndex<T extends Comparable<Object>>(
  Iterable<T?> values, [
  num Function(T? a, T? b)? compare,
]) {
  final cmp = compare ?? ascending;
  T? maxValue;
  var maxIdx = -1;
  var index = -1;
  for (final value in values) {
    ++index;
    if (maxIdx < 0 ? cmp(value, value) == 0 : cmp(value, maxValue) > 0) {
      maxValue = value;
      maxIdx = index;
    }
  }
  return maxIdx;
}

/// Returns the index of the greatest element of [values] according to
/// [compare], or `-1` if no comparable element exists.
int greatestIndexWith<T>(Iterable<T> values, num Function(T a, T b) compare) {
  T? maxValue;
  var maxIdx = -1;
  var index = -1;
  for (final value in values) {
    ++index;
    if (maxIdx < 0
        ? compare(value, value) == 0
        : compare(value, maxValue as T) > 0) {
      maxValue = value;
      maxIdx = index;
    }
  }
  return maxIdx;
}

/// Returns the index of the element of [values] with the greatest key extracted
/// by [accessor], or `-1` if no valid comparable key exists.
int greatestIndexBy<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value) accessor,
) => maxIndexBy(values, accessor);
