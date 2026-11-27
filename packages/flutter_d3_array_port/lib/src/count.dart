// Ported from d3-array v3.2.4 src/count.js (ISC, Mike Bostock).

/// Port of `src/count.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

/// Returns the number of valid (non-null, non-NaN) numeric values in [values].
// DIVERGES(d3-array): adapt-array-typed-api, typed Iterable<num?> without JS
// string/object coercion.
// DIVERGES(d3-array): adapt-array-fast-forms, unboxed fast paths for
// Float64List, List<double>, List<int>, and List<num>.
int count(Iterable<num?> values) {
  if (values is List<int>) return values.length;
  if (values is Float64List) {
    var c = 0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) ++c;
    }
    return c;
  }
  if (values is List<double>) {
    var c = 0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) ++c;
    }
    return c;
  }
  if (values is List<num>) {
    var c = 0;
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v >= v) ++c;
    }
    return c;
  }
  var c = 0;
  for (final value in values) {
    if (value != null && value >= value) ++c;
  }
  return c;
}

/// Returns the number of valid numeric values extracted from [values] using
/// [valueof].
int countBy<T>(Iterable<T> values, num? Function(T value) valueof) {
  var c = 0;
  if (values is List<T>) {
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = valueof(values[i]);
      if (v != null && v >= v) ++c;
    }
    return c;
  }
  for (final value in values) {
    final v = valueof(value);
    if (v != null && v >= v) ++c;
  }
  return c;
}

/// Returns the number of valid numeric values extracted from [values] using
/// indexed [valueof].
int countByIndexed<T>(
  Iterable<T> values,
  num? Function(T value, int index, Iterable<T> values) valueof,
) {
  var c = 0;
  var index = -1;
  for (final value in values) {
    final v = valueof(value, ++index, values);
    if (v != null && v >= v) ++c;
  }
  return c;
}
