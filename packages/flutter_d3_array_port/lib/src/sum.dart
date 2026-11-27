// Ported from d3-array v3.2.4 src/sum.js (ISC, Mike Bostock).

/// Port of `src/sum.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

/// Returns the sum of the given numeric [values], ignoring `null` and `NaN`.
/// Returns `0.0` if [values] contains no valid numbers.
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> without JS
// string/object coercion.
// DIVERGES(d3-array): adapt-array-fast-forms, unboxed fast paths for
// Float64List, List<double>, List<int>, and List<num>.
double sum(Iterable<num?> values) {
  if (values is Float64List) {
    var s = 0.0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v != 0 && v == v) s += v;
    }
    return s;
  }
  if (values is List<double>) {
    var s = 0.0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v != 0 && v == v) s += v;
    }
    return s;
  }
  if (values is List<int>) {
    var s = 0.0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      s += values[i];
    }
    return s;
  }
  if (values is List<num>) {
    var s = 0.0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i].toDouble();
      if (v != 0 && v == v) s += v;
    }
    return s;
  }
  var s = 0.0;
  for (final value in values) {
    if (value != null) {
      final v = value.toDouble();
      if (v != 0 && v == v) s += v;
    }
  }
  return s;
}

/// Returns the sum of numeric values extracted from [values] using [valueof].
double sumBy<T>(Iterable<T> values, num? Function(T value) valueof) {
  var s = 0.0;
  if (values is List<T>) {
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final raw = valueof(values[i]);
      if (raw != null) {
        final v = raw.toDouble();
        if (v != 0 && v == v) s += v;
      }
    }
    return s;
  }
  for (final value in values) {
    final raw = valueof(value);
    if (raw != null) {
      final v = raw.toDouble();
      if (v != 0 && v == v) s += v;
    }
  }
  return s;
}

/// Returns the sum of numeric values extracted from [values] using indexed
/// [valueof].
double sumByIndexed<T>(
  Iterable<T> values,
  num? Function(T value, int index, Iterable<T> values) valueof,
) {
  var s = 0.0;
  var index = -1;
  for (final value in values) {
    final raw = valueof(value, ++index, values);
    if (raw != null) {
      final v = raw.toDouble();
      if (v != 0 && v == v) s += v;
    }
  }
  return s;
}
