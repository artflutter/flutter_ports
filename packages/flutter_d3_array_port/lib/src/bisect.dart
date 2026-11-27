// Ported from d3-array v3.2.4 src/bisect.js (ISC, Mike Bostock).

/// Port of `src/bisect.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

import 'package:flutter_d3_array_port/src/ascending.dart';

/// Returns the insertion point for [x] in sorted [a] after any existing equal
/// entries.
// DIVERGES(d3-array): adapt-array-typed-api, generic Comparable<Object>
// bisect functions instead of untyped JS bisector.
// DIVERGES(d3-array): adapt-array-fast-forms, unboxed fast paths for
// Float64List, List<double>, and List<int>.
int bisectRight<T extends Comparable<Object>>(
  List<T?> a,
  T? x, [
  int lo = 0,
  int? hi,
]) {
  var l = lo;
  var h = hi ?? a.length;
  if (l >= h) return l;
  if (x == null) return h;
  final Object raw = a;
  if (raw is Float64List && x is num) {
    final xd = x.toDouble();
    if (xd.isNaN) return h;
    do {
      final mid = (l + h) >>> 1;
      if (raw[mid] <= xd) {
        l = mid + 1;
      } else {
        h = mid;
      }
    } while (l < h);
    return l;
  }
  if (raw is List<double> && x is num) {
    final xd = x.toDouble();
    if (xd.isNaN) return h;
    do {
      final mid = (l + h) >>> 1;
      if (raw[mid] <= xd) {
        l = mid + 1;
      } else {
        h = mid;
      }
    } while (l < h);
    return l;
  }
  if (raw is List<int> && x is int) {
    do {
      final mid = (l + h) >>> 1;
      if (raw[mid] <= x) {
        l = mid + 1;
      } else {
        h = mid;
      }
    } while (l < h);
    return l;
  }
  if (x is num && x.isNaN) return h;
  do {
    final mid = (l + h) >>> 1;
    if (ascending<T>(a[mid], x) <= 0) {
      l = mid + 1;
    } else {
      h = mid;
    }
  } while (l < h);
  return l;
}

/// Alias for [bisectRight].
int bisect<T extends Comparable<Object>>(
  List<T?> a,
  T? x, [
  int lo = 0,
  int? hi,
]) => bisectRight<T>(a, x, lo, hi);

/// Returns the insertion point for [x] in sorted [a] before any existing equal
/// entries.
int bisectLeft<T extends Comparable<Object>>(
  List<T?> a,
  T? x, [
  int lo = 0,
  int? hi,
]) {
  var l = lo;
  var h = hi ?? a.length;
  if (l >= h) return l;
  if (x == null) return h;
  final Object raw = a;
  if (raw is Float64List && x is num) {
    final xd = x.toDouble();
    if (xd.isNaN) return h;
    do {
      final mid = (l + h) >>> 1;
      if (raw[mid] < xd) {
        l = mid + 1;
      } else {
        h = mid;
      }
    } while (l < h);
    return l;
  }
  if (raw is List<double> && x is num) {
    final xd = x.toDouble();
    if (xd.isNaN) return h;
    do {
      final mid = (l + h) >>> 1;
      if (raw[mid] < xd) {
        l = mid + 1;
      } else {
        h = mid;
      }
    } while (l < h);
    return l;
  }
  if (raw is List<int> && x is int) {
    do {
      final mid = (l + h) >>> 1;
      if (raw[mid] < x) {
        l = mid + 1;
      } else {
        h = mid;
      }
    } while (l < h);
    return l;
  }
  if (x is num && x.isNaN) return h;
  do {
    final mid = (l + h) >>> 1;
    if (ascending<T>(a[mid], x) < 0) {
      l = mid + 1;
    } else {
      h = mid;
    }
  } while (l < h);
  return l;
}

/// Returns the index of the numeric value closest to [x] in sorted [a].
int bisectCenter(List<num?> a, num? x, [int lo = 0, int? hi]) {
  final h = hi ?? a.length;
  final i = bisectLeft<num>(a, x, lo, h - 1);
  if (i <= lo || x == null) return i;
  final prev = a[i - 1];
  final curr = a[i];
  if (prev == null || curr == null) return i;
  final xd = x.toDouble();
  return (prev.toDouble() - xd) > -(curr.toDouble() - xd) ? i - 1 : i;
}

/// Returns the index of the [DateTime] closest to [x] in sorted [a].
int bisectCenterDate(List<DateTime?> a, DateTime? x, [int lo = 0, int? hi]) {
  final h = hi ?? a.length;
  final i = bisectLeft<DateTime>(a, x, lo, h - 1);
  if (i <= lo || x == null) return i;
  final prev = a[i - 1];
  final curr = a[i];
  if (prev == null || curr == null) return i;
  final xm = x.millisecondsSinceEpoch;
  return (prev.millisecondsSinceEpoch - xm) >
          -(curr.millisecondsSinceEpoch - xm)
      ? i - 1
      : i;
}
