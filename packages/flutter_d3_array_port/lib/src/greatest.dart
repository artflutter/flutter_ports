// Ported from d3-array v3.2.4 src/greatest.js (ISC, Mike Bostock).

/// Port of `src/greatest.js` of d3-array 3.2.4.
library;

import 'package:flutter_d3_array_port/src/ascending.dart';

/// Returns the greatest element of [values] according to [compare] (defaulting
/// to [ascending]), or `null` if no comparable element exists.
// DIVERGES(d3-array): adapt-array-typed-api, split natural-order greatest,
// comparator greatestWith, and accessor greatestBy.
T? greatest<T extends Comparable<Object>>(
  Iterable<T?> values, [
  num Function(T? a, T? b)? compare,
]) {
  final cmp = compare ?? ascending;
  T? maxVal;
  var defined = false;
  for (final value in values) {
    if (defined ? cmp(value, maxVal) > 0 : cmp(value, value) == 0) {
      maxVal = value;
      defined = true;
    }
  }
  return defined ? maxVal : null;
}

/// Returns the greatest element of [values] according to [compare], or `null`
/// if no comparable element exists.
T? greatestWith<T>(Iterable<T> values, num Function(T a, T b) compare) {
  T? maxVal;
  var defined = false;
  for (final value in values) {
    if (defined
        ? compare(value, maxVal as T) > 0
        : compare(value, value) == 0) {
      maxVal = value;
      defined = true;
    }
  }
  return defined ? maxVal : null;
}

/// Returns the element of [values] with the greatest key extracted by
/// [accessor], or `null` if no valid comparable key exists.
T? greatestBy<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value) accessor,
) {
  T? maxElem;
  K? maxKey;
  var defined = false;
  for (final element in values) {
    final key = accessor(element);
    if (defined ? ascending(key, maxKey) > 0 : ascending(key, key) == 0) {
      maxElem = element;
      maxKey = key;
      defined = true;
    }
  }
  return defined ? maxElem : null;
}
