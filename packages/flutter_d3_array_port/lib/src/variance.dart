// Ported from d3-array v3.2.4 src/variance.js (ISC, Mike Bostock).

/// Port of `src/variance.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

/// Returns the unbiased sample variance (Bessel's correction) of [values] using
/// Welford's algorithm, ignoring `null` and `NaN`, or `null` if fewer than 2
/// valid numbers exist.
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> returning
// double?.
// DIVERGES(d3-array): adapt-array-fast-forms, unboxed fast paths for
// Float64List, List<double>, List<int>, and List<num>.
double? variance(Iterable<num?> values) {
  if (values is Float64List) {
    var count = 0;
    var mean = 0.0;
    var sum = 0.0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) {
        final delta = v - mean;
        mean += delta / ++count;
        sum += delta * (v - mean);
      }
    }
    return count > 1 ? sum / (count - 1) : null;
  }
  if (values is List<double>) {
    var count = 0;
    var mean = 0.0;
    var sum = 0.0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) {
        final delta = v - mean;
        mean += delta / ++count;
        sum += delta * (v - mean);
      }
    }
    return count > 1 ? sum / (count - 1) : null;
  }
  if (values is List<int>) {
    final n = values.length;
    if (n <= 1) return null;
    var count = 0;
    var mean = 0.0;
    var sum = 0.0;
    for (var i = 0; i < n; ++i) {
      final v = values[i].toDouble();
      final delta = v - mean;
      mean += delta / ++count;
      sum += delta * (v - mean);
    }
    return sum / (count - 1);
  }
  var count = 0;
  var mean = 0.0;
  var sum = 0.0;
  for (final raw in values) {
    if (raw != null) {
      final v = raw.toDouble();
      if (v >= v) {
        final delta = v - mean;
        mean += delta / ++count;
        sum += delta * (v - mean);
      }
    }
  }
  return count > 1 ? sum / (count - 1) : null;
}

/// Returns the sample variance of numeric values extracted from [values] using
/// [valueof].
double? varianceBy<T>(Iterable<T> values, num? Function(T value) valueof) {
  var count = 0;
  var mean = 0.0;
  var sum = 0.0;
  if (values is List<T>) {
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final raw = valueof(values[i]);
      if (raw != null) {
        final v = raw.toDouble();
        if (v >= v) {
          final delta = v - mean;
          mean += delta / ++count;
          sum += delta * (v - mean);
        }
      }
    }
    return count > 1 ? sum / (count - 1) : null;
  }
  for (final value in values) {
    final raw = valueof(value);
    if (raw != null) {
      final v = raw.toDouble();
      if (v >= v) {
        final delta = v - mean;
        mean += delta / ++count;
        sum += delta * (v - mean);
      }
    }
  }
  return count > 1 ? sum / (count - 1) : null;
}

/// Returns the sample variance of numeric values extracted from [values] using
/// indexed [valueof].
double? varianceByIndexed<T>(
  Iterable<T> values,
  num? Function(T value, int index, Iterable<T> values) valueof,
) {
  var count = 0;
  var mean = 0.0;
  var sum = 0.0;
  var index = -1;
  for (final value in values) {
    final raw = valueof(value, ++index, values);
    if (raw != null) {
      final v = raw.toDouble();
      if (v >= v) {
        final delta = v - mean;
        mean += delta / ++count;
        sum += delta * (v - mean);
      }
    }
  }
  return count > 1 ? sum / (count - 1) : null;
}
