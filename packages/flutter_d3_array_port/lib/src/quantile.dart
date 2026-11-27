// Ported from d3-array v3.2.4 src/quantile.js (ISC, Mike Bostock).

/// Port of `src/quantile.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

import 'package:flutter_d3_array_port/src/maxIndex.dart';
import 'package:flutter_d3_array_port/src/minIndex.dart';
import 'package:flutter_d3_array_port/src/quickselect.dart';
import 'package:flutter_d3_array_port/src/sort.dart';

Float64List _extractValidDoubles(Iterable<num?> values) {
  if (values is Float64List) {
    final n = values.length;
    var count = 0;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) ++count;
    }
    if (count == n) return Float64List.fromList(values);
    final out = Float64List(count);
    var k = 0;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) out[k++] = v;
    }
    return out;
  }
  if (values is List<double>) {
    final n = values.length;
    var count = 0;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) ++count;
    }
    final out = Float64List(count);
    var k = 0;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) out[k++] = v;
    }
    return out;
  }
  if (values is List<int>) {
    final n = values.length;
    final out = Float64List(n);
    for (var i = 0; i < n; ++i) {
      out[i] = values[i].toDouble();
    }
    return out;
  }
  final list = <double>[];
  for (final raw in values) {
    if (raw != null) {
      final v = raw.toDouble();
      if (v >= v) list.add(v);
    }
  }
  return Float64List.fromList(list);
}

double? _quantileFromClean(Float64List buf, double p) {
  final n = buf.length;
  if (n == 0 || p.isNaN) return null;
  if (p <= 0 || n < 2) {
    var m = buf[0];
    for (var i = 1; i < n; ++i) {
      if (buf[i] < m) m = buf[i];
    }
    return m;
  }
  if (p >= 1) {
    var m = buf[0];
    for (var i = 1; i < n; ++i) {
      if (buf[i] > m) m = buf[i];
    }
    return m;
  }
  final i = (n - 1) * p;
  final i0 = i.floor();
  quickselectFloat64NoNaN(buf, i0, 0, n - 1);
  var value0 = buf[0];
  for (var k = 1; k <= i0; ++k) {
    if (buf[k] > value0) value0 = buf[k];
  }
  var value1 = buf[i0 + 1];
  for (var k = i0 + 2; k < n; ++k) {
    if (buf[k] < value1) value1 = buf[k];
  }
  return value0 + (value1 - value0) * (i - i0);
}

/// Returns the [p]-quantile of [values] using the R-7 method (`p` in `[0, 1]`),
/// ignoring `null` and `NaN`, or `null` if no valid numbers exist or [p] is
/// `NaN`.
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> returning
// double?.
// DIVERGES(d3-array): adapt-array-fast-forms, direct Float64List extraction
// and unboxed NaN-free Floyd-Rivest quickselect.
double? quantile(Iterable<num?> values, double p) {
  if (p.isNaN) return null;
  return _quantileFromClean(_extractValidDoubles(values), p);
}

/// Returns the [p]-quantile of numeric values extracted from [values] using
/// [valueof].
double? quantileBy<T>(
  Iterable<T> values,
  double p,
  num? Function(T value) valueof,
) {
  if (p.isNaN) return null;
  final list = <double>[];
  for (final element in values) {
    final raw = valueof(element);
    if (raw != null) {
      final v = raw.toDouble();
      if (v >= v) list.add(v);
    }
  }
  return _quantileFromClean(Float64List.fromList(list), p);
}

/// Returns the [p]-quantile of numeric values extracted from [values] using
/// indexed [valueof].
double? quantileByIndexed<T>(
  Iterable<T> values,
  double p,
  num? Function(T value, int index, Iterable<T> values) valueof,
) {
  if (p.isNaN) return null;
  final list = <double>[];
  var index = -1;
  for (final element in values) {
    final raw = valueof(element, ++index, values);
    if (raw != null) {
      final v = raw.toDouble();
      if (v >= v) list.add(v);
    }
  }
  return _quantileFromClean(Float64List.fromList(list), p);
}

/// Returns the [p]-quantile of already-sorted numeric [values] without copying
/// or partitioning.
double? quantileSorted(List<num?> values, double p) {
  final n = values.length;
  if (n == 0 || p.isNaN) return null;
  if (p <= 0 || n < 2) {
    final v = values[0];
    return v == null ? double.nan : v.toDouble();
  }
  if (p >= 1) {
    final v = values[n - 1];
    return v == null ? double.nan : v.toDouble();
  }
  final i = (n - 1) * p;
  final i0 = i.floor();
  final raw0 = values[i0];
  final raw1 = values[i0 + 1];
  final value0 = raw0 == null ? double.nan : raw0.toDouble();
  final value1 = raw1 == null ? double.nan : raw1.toDouble();
  return value0 + (value1 - value0) * (i - i0);
}

/// Returns the [p]-quantile of already-sorted [values] using [valueof].
double? quantileSortedBy<T>(
  List<T> values,
  double p,
  num? Function(T value) valueof,
) {
  final n = values.length;
  if (n == 0 || p.isNaN) return null;
  if (p <= 0 || n < 2) {
    final v = valueof(values[0]);
    return v == null ? double.nan : v.toDouble();
  }
  if (p >= 1) {
    final v = valueof(values[n - 1]);
    return v == null ? double.nan : v.toDouble();
  }
  final i = (n - 1) * p;
  final i0 = i.floor();
  final raw0 = valueof(values[i0]);
  final raw1 = valueof(values[i0 + 1]);
  final value0 = raw0 == null ? double.nan : raw0.toDouble();
  final value1 = raw1 == null ? double.nan : raw1.toDouble();
  return value0 + (value1 - value0) * (i - i0);
}

/// Returns the [p]-quantile of already-sorted [values] using indexed [valueof].
double? quantileSortedByIndexed<T>(
  List<T> values,
  double p,
  num? Function(T value, int index, List<T> values) valueof,
) {
  final n = values.length;
  if (n == 0 || p.isNaN) return null;
  if (p <= 0 || n < 2) {
    final v = valueof(values[0], 0, values);
    return v == null ? double.nan : v.toDouble();
  }
  if (p >= 1) {
    final v = valueof(values[n - 1], n - 1, values);
    return v == null ? double.nan : v.toDouble();
  }
  final i = (n - 1) * p;
  final i0 = i.floor();
  final raw0 = valueof(values[i0], i0, values);
  final raw1 = valueof(values[i0 + 1], i0 + 1, values);
  final value0 = raw0 == null ? double.nan : raw0.toDouble();
  final value1 = raw1 == null ? double.nan : raw1.toDouble();
  return value0 + (value1 - value0) * (i - i0);
}

int? _quantileIndexFromNumbers(Float64List numbers, double p) {
  if (p.isNaN) return null;
  final n = numbers.length;
  if (p <= 0) return minIndex(numbers);
  if (p >= 1) return maxIndex(numbers);
  if (n == 0) return -1;
  final index = Uint32List(n);
  for (var k = 0; k < n; ++k) {
    index[k] = k;
  }
  final j = n - 1;
  final i = (j * p).floor();
  quickselectWith<int>(
    index,
    i,
    (a, b) => ascendingDefinedDouble(numbers[a], numbers[b]),
    0,
    j,
  );
  var bestIdx = -1;
  var bestVal = double.negativeInfinity;
  var defined = false;
  for (var k = 0; k <= i; ++k) {
    final idx = index[k];
    final v = numbers[idx];
    if (v >= v && (!defined || v > bestVal)) {
      bestVal = v;
      bestIdx = idx;
      defined = true;
    }
  }
  return defined ? bestIdx : -1;
}

/// Returns the index of the element corresponding to the [p]-quantile of
/// [values], `null` if [p] is `NaN`, or `-1` if no valid value exists.
int? quantileIndex(List<num?> values, double p) {
  if (p.isNaN) return null;
  final n = values.length;
  final numbers = Float64List(n);
  for (var i = 0; i < n; ++i) {
    final v = values[i];
    numbers[i] = v == null ? double.nan : v.toDouble();
  }
  return _quantileIndexFromNumbers(numbers, p);
}

/// Returns the index of the element corresponding to the [p]-quantile of
/// [values] using [valueof].
int? quantileIndexBy<T>(
  List<T> values,
  double p,
  num? Function(T value) valueof,
) {
  if (p.isNaN) return null;
  final n = values.length;
  final numbers = Float64List(n);
  for (var i = 0; i < n; ++i) {
    final v = valueof(values[i]);
    numbers[i] = v == null ? double.nan : v.toDouble();
  }
  return _quantileIndexFromNumbers(numbers, p);
}

/// Returns the index of the element corresponding to the [p]-quantile of
/// [values] using indexed [valueof].
int? quantileIndexByIndexed<T>(
  List<T> values,
  double p,
  num? Function(T value, int index, List<T> values) valueof,
) {
  if (p.isNaN) return null;
  final n = values.length;
  final numbers = Float64List(n);
  for (var i = 0; i < n; ++i) {
    final v = valueof(values[i], i, values);
    numbers[i] = v == null ? double.nan : v.toDouble();
  }
  return _quantileIndexFromNumbers(numbers, p);
}
