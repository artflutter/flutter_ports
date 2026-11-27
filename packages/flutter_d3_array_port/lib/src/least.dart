// Ported from d3-array v3.2.4 src/least.js (ISC, Mike Bostock).

/// Port of `src/least.js` of d3-array 3.2.4.
library;

import 'package:flutter_d3_array_port/src/ascending.dart';

/// Returns the least element of [values] according to [compare] (defaulting to
/// [ascending]), or `null` if no comparable element exists.
// DIVERGES(d3-array): adapt-array-typed-api, split natural-order least,
// comparator leastWith, and accessor leastBy instead of arity sniffing.
T? least<T extends Comparable<Object>>(
  Iterable<T?> values, [
  num Function(T? a, T? b)? compare,
]) {
  final cmp = compare ?? ascending;
  T? minVal;
  var defined = false;
  for (final value in values) {
    if (defined ? cmp(value, minVal) < 0 : cmp(value, value) == 0) {
      minVal = value;
      defined = true;
    }
  }
  return defined ? minVal : null;
}

/// Returns the least element of [values] according to [compare], or `null` if
/// no comparable element exists.
T? leastWith<T>(Iterable<T> values, num Function(T a, T b) compare) {
  T? minVal;
  var defined = false;
  for (final value in values) {
    if (defined
        ? compare(value, minVal as T) < 0
        : compare(value, value) == 0) {
      minVal = value;
      defined = true;
    }
  }
  return defined ? minVal : null;
}

/// Returns the element of [values] with the least key extracted by [accessor],
/// or `null` if no valid comparable key exists.
T? leastBy<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value) accessor,
) {
  T? minElem;
  K? minKey;
  var defined = false;
  for (final element in values) {
    final key = accessor(element);
    if (defined ? ascending(key, minKey) < 0 : ascending(key, key) == 0) {
      minElem = element;
      minKey = key;
      defined = true;
    }
  }
  return defined ? minElem : null;
}
