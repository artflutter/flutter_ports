// Ported from d3-array v3.2.4 src/scan.js (ISC, Mike Bostock).

/// Port of `src/scan.js` of d3-array 3.2.4.
library;

import 'package:flutter_d3_array_port/src/leastIndex.dart';

/// Deprecated alias for [leastIndex] returning `null` instead of `-1` when no
/// comparable element exists.
// DIVERGES(d3-array): adapt-array-typed-api, typed Comparable<Object> generic.
@Deprecated('Use leastIndex instead.')
int? scan<T extends Comparable<Object>>(
  Iterable<T?> values, [
  num Function(T? a, T? b)? compare,
]) {
  final index = leastIndex(values, compare);
  return index < 0 ? null : index;
}

/// Deprecated comparator form of [scan] for arbitrary types `T`.
@Deprecated('Use leastIndexWith instead.')
int? scanWith<T>(Iterable<T> values, num Function(T a, T b) compare) {
  final index = leastIndexWith(values, compare);
  return index < 0 ? null : index;
}
