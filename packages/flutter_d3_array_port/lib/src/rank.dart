// Ported from d3-array v3.2.4 src/rank.js (ISC, Mike Bostock).

/// Port of `src/rank.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

import 'package:flutter_d3_array_port/src/ascending.dart';
import 'package:flutter_d3_array_port/src/sort.dart';

/// Unboxed 3-way quicksort + insertion sort of [index] by finite `double`
/// values in [values] over `[lo, hi]`.
void _sortIndicesByFloat64(
  Uint32List index,
  List<double> values,
  int left,
  int right,
) {
  var lo = left;
  var hi = right;
  while (hi - lo > 20) {
    final mid = (lo + hi) >>> 1;
    final vLo = values[index[lo]];
    final vMid = values[index[mid]];
    final vHi = values[index[hi]];
    double pivot;
    if (vLo < vMid) {
      pivot = vMid < vHi ? vMid : (vLo < vHi ? vHi : vLo);
    } else {
      pivot = vLo < vHi ? vLo : (vMid < vHi ? vHi : vMid);
    }
    var lt = lo;
    var i = lo;
    var gt = hi;
    while (i <= gt) {
      final idx = index[i];
      final v = values[idx];
      if (v < pivot) {
        index[i] = index[lt];
        index[lt] = idx;
        ++lt;
        ++i;
      } else if (v > pivot) {
        index[i] = index[gt];
        index[gt] = idx;
        --gt;
      } else {
        ++i;
      }
    }
    if (lt - lo < hi - gt) {
      if (lo < lt - 1) _sortIndicesByFloat64(index, values, lo, lt - 1);
      lo = gt + 1;
    } else {
      if (gt + 1 < hi) _sortIndicesByFloat64(index, values, gt + 1, hi);
      hi = lt - 1;
    }
  }
  for (var i = lo + 1; i <= hi; ++i) {
    final idx = index[i];
    final v = values[idx];
    var j = i - 1;
    while (j >= lo && values[index[j]] > v) {
      index[j + 1] = index[j];
      --j;
    }
    index[j + 1] = idx;
  }
}

Float64List _rankDoubleList(List<double> values) {
  final n = values.length;
  final r = Float64List(n);
  if (n == 0) return r;
  final index = Uint32List(n);
  var validCount = 0;
  for (var i = 0; i < n; ++i) {
    final v = values[i];
    if (v == v) {
      index[validCount++] = i;
    } else {
      r[i] = double.nan;
    }
  }
  if (validCount == 0) return r;
  if (validCount > 1) {
    _sortIndicesByFloat64(index, values, 0, validCount - 1);
  }
  var prevVal = values[index[0]];
  var rankVal = 0.0;
  r[index[0]] = 0.0;
  for (var i = 1; i < validCount; ++i) {
    final j = index[i];
    final v = values[j];
    if (v > prevVal) {
      prevVal = v;
      rankVal = i.toDouble();
    }
    r[j] = rankVal;
  }
  return r;
}

Float64List _rankWith<T>(
  List<T> values,
  num Function(T a, T b) rawCompare,
  int Function(T a, T b) totalCompare,
) {
  final n = values.length;
  final r = Float64List(n);
  if (n == 0) return r;
  final index = Uint32List(n);
  for (var i = 0; i < n; ++i) {
    index[i] = i;
  }
  // DIVERGES(d3-array): adapt-array-stable-sort, tie-break by original index.
  index.sort((i, j) {
    final c = totalCompare(values[i], values[j]);
    return c != 0 ? c : i - j;
  });
  var k = -1;
  var rankVal = 0.0;
  for (var i = 0; i < n; ++i) {
    final j = index[i];
    final c = rawCompare(values[j], values[k < 0 ? j : k]);
    if (c >= 0) {
      if (k < 0 || c > 0) {
        k = j;
        rankVal = i.toDouble();
      }
      r[j] = rankVal;
    } else {
      r[j] = double.nan;
    }
  }
  return r;
}

/// Returns a [Float64List] with the competition rank of each element in
/// [values] (defaulting to [ascending]), with `double.nan` for unorderable
/// elements.
// DIVERGES(d3-array): adapt-array-typed-api, split rank, rankNullable,
// rankWith, and rankBy instead of JS arity sniffing.
// DIVERGES(d3-array): adapt-array-fast-forms, unboxed 3-way index quicksort
// for Float64List and List<double> avoiding closure dispatch and boxing.
Float64List rank<T extends Comparable<Object>>(
  Iterable<T> values, [
  num Function(T a, T b)? compare,
]) {
  if (compare == null) {
    final Object raw = values;
    if (raw is Float64List) return _rankDoubleList(raw);
    if (raw is List<double>) return _rankDoubleList(raw);
    final list = values is List<T>
        ? values
        : List<T>.of(values, growable: false);
    return _rankWith<T>(list, ascending<T>, ascendingDefined<T>);
  }
  final list = values is List<T> ? values : List<T>.of(values, growable: false);
  return _rankWith<T>(list, compare, compareDefined<T>(compare));
}

/// Returns a [Float64List] with the competition rank of each nullable element
/// in [values], assigning `double.nan` to `null` and `NaN` elements.
Float64List rankNullable<T extends Comparable<Object>>(
  Iterable<T?> values, [
  num Function(T? a, T? b)? compare,
]) {
  final list = values is List<T?>
      ? values
      : List<T?>.of(values, growable: false);
  final raw = compare ?? ascending<T>;
  final total = compare == null
      ? ascendingDefined<T>
      : compareDefined<T?>(compare);
  return _rankWith<T?>(list, raw, total);
}

/// Returns a [Float64List] with the competition rank of each element in
/// [values] according to [compare].
Float64List rankWith<T>(Iterable<T> values, num Function(T a, T b) compare) {
  final list = values is List<T> ? values : List<T>.of(values, growable: false);
  return _rankWith<T>(list, compare, compareDefined<T>(compare));
}

/// Returns a [Float64List] with the competition rank of each element in
/// [values] ordered by ascending key [accessor].
Float64List rankBy<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value) accessor,
) {
  final list = values is List<T> ? values : List<T>.of(values, growable: false);
  final keys = List<K?>.generate(
    list.length,
    (i) => accessor(list[i]),
    growable: false,
  );
  return _rankWith<K?>(keys, ascending<K>, ascendingDefined<K>);
}
