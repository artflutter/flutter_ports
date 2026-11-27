// Ported from d3-array v3.2.4 src/cumsum.js (ISC, Mike Bostock).

/// Port of `src/cumsum.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

/// Returns the cumulative sum of [values] as a [Float64List] of the same
/// length, treating `null` and `NaN` as `0.0`.
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> returning
// Float64List.
// DIVERGES(d3-array): adapt-array-fast-forms, direct indexed Float64List fill.
Float64List cumsum(Iterable<num?> values) {
  if (values is Float64List) {
    final n = values.length;
    final out = Float64List(n);
    var s = 0.0;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v == v) s += v;
      out[i] = s;
    }
    return out;
  }
  if (values is List<double>) {
    final n = values.length;
    final out = Float64List(n);
    var s = 0.0;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v == v) s += v;
      out[i] = s;
    }
    return out;
  }
  if (values is List<num?>) {
    final n = values.length;
    final out = Float64List(n);
    var s = 0.0;
    for (var i = 0; i < n; ++i) {
      final raw = values[i];
      if (raw != null) {
        final v = raw.toDouble();
        if (v == v) s += v;
      }
      out[i] = s;
    }
    return out;
  }
  final list = <double>[];
  var s = 0.0;
  for (final raw in values) {
    if (raw != null) {
      final v = raw.toDouble();
      if (v == v) s += v;
    }
    list.add(s);
  }
  return Float64List.fromList(list);
}

/// Returns the cumulative sum of values extracted from [values] using
/// [valueof] as a [Float64List].
Float64List cumsumBy<T>(Iterable<T> values, num? Function(T value) valueof) {
  if (values is List<T>) {
    final n = values.length;
    final out = Float64List(n);
    var s = 0.0;
    for (var i = 0; i < n; ++i) {
      final raw = valueof(values[i]);
      if (raw != null) {
        final v = raw.toDouble();
        if (v == v) s += v;
      }
      out[i] = s;
    }
    return out;
  }
  final list = <double>[];
  var s = 0.0;
  for (final value in values) {
    final raw = valueof(value);
    if (raw != null) {
      final v = raw.toDouble();
      if (v == v) s += v;
    }
    list.add(s);
  }
  return Float64List.fromList(list);
}

/// Returns the cumulative sum of values extracted from [values] using indexed
/// [valueof] as a [Float64List].
Float64List cumsumByIndexed<T>(
  Iterable<T> values,
  num? Function(T value, int index, Iterable<T> values) valueof,
) {
  if (values is List<T>) {
    final n = values.length;
    final out = Float64List(n);
    var s = 0.0;
    for (var i = 0; i < n; ++i) {
      final raw = valueof(values[i], i, values);
      if (raw != null) {
        final v = raw.toDouble();
        if (v == v) s += v;
      }
      out[i] = s;
    }
    return out;
  }
  final list = <double>[];
  var s = 0.0;
  var index = -1;
  for (final value in values) {
    final raw = valueof(value, ++index, values);
    if (raw != null) {
      final v = raw.toDouble();
      if (v == v) s += v;
    }
    list.add(s);
  }
  return Float64List.fromList(list);
}
