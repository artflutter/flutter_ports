// Ported from d3-array v3.2.4 src/leastIndex.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/leastIndex.js` of d3-array 3.2.4.
library;

import 'package:flutter_d3_array_port/src/ascending.dart';
import 'package:flutter_d3_array_port/src/minIndex.dart';

/// Returns the index of the least element of [values] according to [compare]
/// (defaulting to [ascending]), or `-1` if no comparable element exists.
// DIVERGES(d3-array): adapt-array-typed-api, split natural-order leastIndex,
// comparator leastIndexWith, and accessor leastIndexBy.
int leastIndex<T extends Comparable<Object>>(
  Iterable<T?> values, [
  num Function(T? a, T? b)? compare,
]) {
  final cmp = compare ?? ascending;
  T? minValue;
  var minIdx = -1;
  var index = -1;
  for (final value in values) {
    ++index;
    if (minIdx < 0 ? cmp(value, value) == 0 : cmp(value, minValue) < 0) {
      minValue = value;
      minIdx = index;
    }
  }
  return minIdx;
}

/// Returns the index of the least element of [values] according to [compare],
/// or `-1` if no comparable element exists.
int leastIndexWith<T>(Iterable<T> values, num Function(T a, T b) compare) {
  T? minValue;
  var minIdx = -1;
  var index = -1;
  for (final value in values) {
    ++index;
    if (minIdx < 0
        ? compare(value, value) == 0
        : compare(value, minValue as T) < 0) {
      minValue = value;
      minIdx = index;
    }
  }
  return minIdx;
}

/// Returns the index of the element of [values] with the least key extracted
/// by [accessor], or `-1` if no valid comparable key exists.
int leastIndexBy<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value) accessor,
) => minIndexBy(values, accessor);
