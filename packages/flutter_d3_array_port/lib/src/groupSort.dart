// Ported from d3-array v3.2.4 src/groupSort.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/groupSort.js` of d3-array 3.2.4.
library;

import 'package:flutter_d3_array_port/src/ascending.dart';
import 'package:flutter_d3_array_port/src/group.dart';
import 'package:flutter_d3_array_port/src/sort.dart';

/// Groups [values] by [key], reduces each group with [reduce], and returns the
/// keys sorted in ascending order of the reduced value (tie-breaking by
/// ascending key).
// DIVERGES(d3-array): adapt-array-typed-api, split reducer-based groupSort and
// comparator-based groupSortCompare instead of JS Function.length sniffing.
List<K>
groupSort<T, K extends Comparable<Object>, R extends Comparable<Object>>(
  Iterable<T> values,
  R? Function(List<T> group) reduce,
  K Function(T value) key,
) {
  final rolled = rollups<T, K, R?>(values, reduce, key);
  final sorted = sortWith<(K, R?)>(rolled, (a, b) {
    final c = ascending<R>(a.$2, b.$2);
    if (c != 0) return c;
    return ascending<K>(a.$1, b.$1);
  });
  return <K>[for (final entry in sorted) entry.$1];
}

/// Groups [values] by [key] and returns the keys sorted according to [compare]
/// on the grouped element lists (tie-breaking by ascending key).
List<K> groupSortCompare<T, K extends Comparable<Object>>(
  Iterable<T> values,
  num Function(List<T> a, List<T> b) compare,
  K Function(T value) key,
) {
  final grouped = groups<T, K>(values, key);
  final sorted = sortWith<(K, List<T>)>(grouped, (a, b) {
    final c = compare(a.$2, b.$2);
    if (c != 0) return c;
    return ascending<K>(a.$1, b.$1);
  });
  return <K>[for (final entry in sorted) entry.$1];
}
