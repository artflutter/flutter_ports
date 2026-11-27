// Ported from d3-array v3.2.4 src/sort.js (ISC, Mike Bostock).

/// Port of `src/sort.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

import 'package:flutter_d3_array_port/src/ascending.dart';
import 'package:flutter_d3_array_port/src/permute.dart';

/// Total-order ascending comparator placing `null` and `NaN` values at the end.
@pragma('vm:prefer-inline')
int ascendingDefined<T extends Comparable<Object>>(T? a, T? b) {
  final aUndef = (a == null || (a is num && !(a >= a))) ? 1 : 0;
  final bUndef = (b == null || (b is num && !(b >= b))) ? 1 : 0;
  if (aUndef != bUndef) return aUndef - bUndef;
  if (aUndef == 1) return 0;
  if (a is num && b is num) {
    return a < b ? -1 : (a > b ? 1 : 0);
  }
  final c = a!.compareTo(b!);
  return c < 0 ? -1 : (c > 0 ? 1 : 0);
}

/// Promotes a partial comparator [compare] (which may return `double.nan` for
/// unorderable elements) into a total-order comparator compatible with
/// [List.sort], placing unorderable elements at the end.
int Function(T a, T b) compareDefined<T>(num Function(T a, T b) compare) {
  return (T a, T b) {
    final x = compare(a, b);
    if (x < 0) return -1;
    if (x > 0) return 1;
    if (x == 0) return 0;
    final bDef = compare(b, b) == 0 ? 1 : 0;
    final aDef = compare(a, a) == 0 ? 1 : 0;
    return bDef - aDef;
  };
}

/// Fast ascending comparator for `double` values placing `NaN` at the end.
@pragma('vm:prefer-inline')
int ascendingDefinedDouble(double a, double b) {
  final aNaN = a == a ? 0 : 1;
  final bNaN = b == b ? 0 : 1;
  if (aNaN != bNaN) return aNaN - bNaN;
  if (aNaN == 1) return 0;
  return a < b ? -1 : (a > b ? 1 : 0);
}

/// Unboxed 3-way quicksort + insertion sort over finite `Float64List` range
/// `[lo, hi]` with zero closure calls and zero boxing.
void _sortFloat64Range(Float64List a, int left, int right) {
  var lo = left;
  var hi = right;
  while (hi - lo > 24) {
    final mid = (lo + hi) >>> 1;
    // Median-of-three pivot selection.
    if (a[mid] < a[lo]) {
      final t = a[lo];
      a[lo] = a[mid];
      a[mid] = t;
    }
    if (a[hi] < a[lo]) {
      final t = a[lo];
      a[lo] = a[hi];
      a[hi] = t;
    }
    if (a[hi] < a[mid]) {
      final t = a[mid];
      a[mid] = a[hi];
      a[hi] = t;
    }
    final pivot = a[mid];
    var lt = lo;
    var i = lo;
    var gt = hi;
    while (i <= gt) {
      final v = a[i];
      if (v < pivot) {
        a[i] = a[lt];
        a[lt] = v;
        ++lt;
        ++i;
      } else if (v > pivot) {
        a[i] = a[gt];
        a[gt] = v;
        --gt;
      } else {
        ++i;
      }
    }
    if (lt - lo < hi - gt) {
      if (lo < lt - 1) _sortFloat64Range(a, lo, lt - 1);
      lo = gt + 1;
    } else {
      if (gt + 1 < hi) _sortFloat64Range(a, gt + 1, hi);
      hi = lt - 1;
    }
  }
  for (var i = lo + 1; i <= hi; ++i) {
    final v = a[i];
    var j = i - 1;
    while (j >= lo && a[j] > v) {
      a[j + 1] = a[j];
      --j;
    }
    a[j + 1] = v;
  }
}

Float64List _sortFloat64Copy(List<double> src) {
  final n = src.length;
  final out = Float64List(n);
  var write = 0;
  var nanCount = 0;
  for (var i = 0; i < n; ++i) {
    final v = src[i];
    if (v == v) {
      out[write++] = v;
    } else {
      ++nanCount;
    }
  }
  if (write > 1) _sortFloat64Range(out, 0, write - 1);
  for (var i = 0; i < nanCount; ++i) {
    out[write + i] = double.nan;
  }
  return out;
}

/// Stable index sort over [n] items using [cmp] on indices `(i, j)`.
Uint32List _stableSortIndices(int n, int Function(int i, int j) cmp) {
  final index = Uint32List(n);
  for (var i = 0; i < n; ++i) {
    index[i] = i;
  }
  // DIVERGES(d3-array): adapt-array-stable-sort, tie-break by original index.
  if (n <= 32) {
    for (var i = 1; i < n; ++i) {
      final idx = index[i];
      var j = i - 1;
      while (j >= 0 && cmp(index[j], idx) > 0) {
        index[j + 1] = index[j];
        --j;
      }
      index[j + 1] = idx;
    }
    return index;
  }
  index.sort((i, j) {
    final c = cmp(i, j);
    return c != 0 ? c : i - j;
  });
  return index;
}

/// Returns a sorted copy of [values] in ascending natural order (or using
/// [compare]), placing `NaN` values last.
// DIVERGES(d3-array): adapt-array-typed-api, typed Comparable<Object> generic;
// use sortNullable, sortWith, or sortBy* for nullable/custom types/accessors.
// DIVERGES(d3-array): adapt-array-fast-forms, unboxed 3-way quicksort on
// Float64List/List<double> avoiding closure calls and double boxing.
List<T> sort<T extends Comparable<Object>>(
  Iterable<T> values, [
  num Function(T a, T b)? compare,
]) {
  if (compare == null) {
    final Object raw = values;
    if (raw is Float64List) {
      return _sortFloat64Copy(raw) as List<T>;
    }
    if (raw is List<double>) {
      return _sortFloat64Copy(raw) as List<T>;
    }
    if (raw is List<int>) {
      final out = List<int>.of(raw)..sort();
      return out as List<T>;
    }
    final list = List<T>.of(values);
    if (list.length <= 1) return list;
    final idx = _stableSortIndices(
      list.length,
      (i, j) => ascendingDefined<T>(list[i], list[j]),
    );
    return permute(list, idx);
  }
  return sortWith<T>(values, compare);
}

/// Returns a sorted copy of nullable [values] in ascending natural order (or
/// using [compare]), placing `null` and `NaN` values last while preserving
/// ES2019 stability.
List<T?> sortNullable<T extends Comparable<Object>>(
  Iterable<T?> values, [
  num Function(T? a, T? b)? compare,
]) {
  final list = List<T?>.of(values);
  if (list.length <= 1) return list;
  final cmp = compare == null
      ? ascendingDefined<T>
      : compareDefined<T?>(compare);
  final idx = _stableSortIndices(list.length, (i, j) => cmp(list[i], list[j]));
  return permute(list, idx);
}

/// Returns a sorted copy of [values] according to [compare], placing
/// unorderable elements last while preserving ES2019 stability.
List<T> sortWith<T>(Iterable<T> values, num Function(T a, T b) compare) {
  final list = List<T>.of(values);
  if (list.length <= 1) return list;
  final cmp = compareDefined<T>(compare);
  final idx = _stableSortIndices(list.length, (i, j) => cmp(list[i], list[j]));
  return permute(list, idx);
}

/// Returns a sorted copy of [values] ordered by ascending key [accessor],
/// placing `null` and `NaN` keys last while preserving stability.
List<T> sortBy<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value) accessor,
) {
  final list = List<T>.of(values);
  final n = list.length;
  if (n <= 1) return list;
  final keys = List<K?>.generate(n, (i) => accessor(list[i]), growable: false);
  final idx = _stableSortIndices(
    n,
    (i, j) => ascendingDefined<K>(keys[i], keys[j]),
  );
  return permute(list, idx);
}

/// Returns a sorted copy of [values] ordered by [key1], then [key2].
List<T> sortBy2<
  T,
  K1 extends Comparable<Object>,
  K2 extends Comparable<Object>
>(Iterable<T> values, K1? Function(T value) key1, K2? Function(T value) key2) {
  final list = List<T>.of(values);
  final n = list.length;
  if (n <= 1) return list;
  final k1 = List<K1?>.generate(n, (i) => key1(list[i]), growable: false);
  final k2 = List<K2?>.generate(n, (i) => key2(list[i]), growable: false);
  final idx = _stableSortIndices(n, (i, j) {
    final c = ascendingDefined<K1>(k1[i], k1[j]);
    return c != 0 ? c : ascendingDefined<K2>(k2[i], k2[j]);
  });
  return permute(list, idx);
}

/// Returns a sorted copy of [values] ordered by [key1], then [key2], then
/// [key3].
List<T> sortBy3<
  T,
  K1 extends Comparable<Object>,
  K2 extends Comparable<Object>,
  K3 extends Comparable<Object>
>(
  Iterable<T> values,
  K1? Function(T value) key1,
  K2? Function(T value) key2,
  K3? Function(T value) key3,
) {
  final list = List<T>.of(values);
  final n = list.length;
  if (n <= 1) return list;
  final k1 = List<K1?>.generate(n, (i) => key1(list[i]), growable: false);
  final k2 = List<K2?>.generate(n, (i) => key2(list[i]), growable: false);
  final k3 = List<K3?>.generate(n, (i) => key3(list[i]), growable: false);
  final idx = _stableSortIndices(n, (i, j) {
    var c = ascendingDefined<K1>(k1[i], k1[j]);
    if (c != 0) return c;
    c = ascendingDefined<K2>(k2[i], k2[j]);
    return c != 0 ? c : ascendingDefined<K3>(k3[i], k3[j]);
  });
  return permute(list, idx);
}

/// Returns a sorted copy of [values] ordered by a homogeneous list of
/// [accessors] in priority order.
List<T> sortByAll<T, K extends Comparable<Object>>(
  Iterable<T> values,
  List<K? Function(T value)> accessors,
) {
  final list = List<T>.of(values);
  final n = list.length;
  if (n <= 1 || accessors.isEmpty) return list;
  final m = accessors.length;
  final keys = List<List<K?>>.generate(
    m,
    (k) => List<K?>.generate(n, (i) => accessors[k](list[i]), growable: false),
    growable: false,
  );
  final idx = _stableSortIndices(n, (i, j) {
    for (var k = 0; k < m; ++k) {
      final c = ascendingDefined<K>(keys[k][i], keys[k][j]);
      if (c != 0) return c;
    }
    return 0;
  });
  return permute(list, idx);
}

/// Reference export kept for callers referencing [ascending] via `sort.dart`.
double Function(T? a, T? b)
ascendingComparator<T extends Comparable<Object>>() => ascending<T>;
