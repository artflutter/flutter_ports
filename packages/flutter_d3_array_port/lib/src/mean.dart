// Ported from d3-array v3.2.4 src/mean.js (ISC, Mike Bostock).

/// Port of `src/mean.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

/// Returns the arithmetic mean of [values], ignoring `null` and `NaN`, or
/// `null` if [values] contains no valid numbers.
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> returning
// double?.
// DIVERGES(d3-array): adapt-array-fast-forms, unboxed fast paths for
// Float64List, List<double>, List<int>, and List<num>.
double? mean(Iterable<num?> values) {
  if (values is Float64List) {
    var count = 0;
    var sum = 0.0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) {
        ++count;
        sum += v;
      }
    }
    return count > 0 ? sum / count : null;
  }
  if (values is List<double>) {
    var count = 0;
    var sum = 0.0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) {
        ++count;
        sum += v;
      }
    }
    return count > 0 ? sum / count : null;
  }
  if (values is List<int>) {
    final n = values.length;
    if (n == 0) return null;
    var sum = 0.0;
    for (var i = 0; i < n; ++i) {
      sum += values[i];
    }
    return sum / n;
  }
  if (values is List<num>) {
    var count = 0;
    var sum = 0.0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i].toDouble();
      if (v >= v) {
        ++count;
        sum += v;
      }
    }
    return count > 0 ? sum / count : null;
  }
  var count = 0;
  var sum = 0.0;
  for (final raw in values) {
    if (raw != null) {
      final v = raw.toDouble();
      if (v >= v) {
        ++count;
        sum += v;
      }
    }
  }
  return count > 0 ? sum / count : null;
}

/// Returns the arithmetic mean of numeric values extracted from [values] using
/// [valueof].
double? meanBy<T>(Iterable<T> values, num? Function(T value) valueof) {
  var count = 0;
  var sum = 0.0;
  if (values is List<T>) {
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final raw = valueof(values[i]);
      if (raw != null) {
        final v = raw.toDouble();
        if (v >= v) {
          ++count;
          sum += v;
        }
      }
    }
    return count > 0 ? sum / count : null;
  }
  for (final value in values) {
    final raw = valueof(value);
    if (raw != null) {
      final v = raw.toDouble();
      if (v >= v) {
        ++count;
        sum += v;
      }
    }
  }
  return count > 0 ? sum / count : null;
}

/// Returns the arithmetic mean of numeric values extracted from [values] using
/// indexed [valueof].
double? meanByIndexed<T>(
  Iterable<T> values,
  num? Function(T value, int index, Iterable<T> values) valueof,
) {
  var count = 0;
  var sum = 0.0;
  var index = -1;
  for (final value in values) {
    final raw = valueof(value, ++index, values);
    if (raw != null) {
      final v = raw.toDouble();
      if (v >= v) {
        ++count;
        sum += v;
      }
    }
  }
  return count > 0 ? sum / count : null;
}
