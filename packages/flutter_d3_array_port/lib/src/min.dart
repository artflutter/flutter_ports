// Ported from d3-array v3.2.4 src/min.js (ISC, Mike Bostock).

/// Port of `src/min.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

@pragma('vm:prefer-inline')
bool _isLess<T extends Comparable<Object>>(T a, T b) {
  if (a is num && b is num) return a < b;
  return a.compareTo(b) < 0;
}

@pragma('vm:prefer-inline')
bool _isDefined<T extends Comparable<Object>>(T a) {
  if (a is num) return a >= a;
  return true;
}

/// Returns the minimum value in [values] using natural order, ignoring `null`
/// and `NaN`, or `null` if no valid value exists.
// DIVERGES(d3-array): adapt-array-typed-api, typed Comparable<Object> generic.
// DIVERGES(d3-array): adapt-array-fast-forms, unboxed fast paths for
// Float64List, List<double>, and List<int>.
T? min<T extends Comparable<Object>>(Iterable<T?> values) {
  final Object raw = values;
  if (raw is Float64List) {
    final n = raw.length;
    var i = 0;
    while (i < n && !(raw[i] >= raw[i])) {
      ++i;
    }
    if (i == n) return null;
    var m = raw[i];
    for (++i; i < n; ++i) {
      final v = raw[i];
      if (v < m) m = v;
    }
    return m as T;
  }
  if (raw is List<double>) {
    final n = raw.length;
    var i = 0;
    while (i < n && !(raw[i] >= raw[i])) {
      ++i;
    }
    if (i == n) return null;
    var m = raw[i];
    for (++i; i < n; ++i) {
      final v = raw[i];
      if (v < m) m = v;
    }
    return m as T;
  }
  if (raw is List<int>) {
    final n = raw.length;
    if (n == 0) return null;
    var m = raw[0];
    for (var i = 1; i < n; ++i) {
      final v = raw[i];
      if (v < m) m = v;
    }
    return m as T;
  }
  T? result;
  for (final value in values) {
    if (value != null) {
      if (result == null) {
        if (_isDefined(value)) result = value;
      } else if (_isLess(value, result)) {
        result = value;
      }
    }
  }
  return result;
}

/// Returns the minimum value extracted from [values] using [valueof].
K? minBy<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value) valueof,
) {
  K? result;
  if (values is List<T>) {
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final value = valueof(values[i]);
      if (value != null) {
        if (result == null) {
          if (_isDefined(value)) result = value;
        } else if (_isLess(value, result)) {
          result = value;
        }
      }
    }
    return result;
  }
  for (final element in values) {
    final value = valueof(element);
    if (value != null) {
      if (result == null) {
        if (_isDefined(value)) result = value;
      } else if (_isLess(value, result)) {
        result = value;
      }
    }
  }
  return result;
}

/// Returns the minimum value extracted from [values] using indexed [valueof].
K? minByIndexed<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value, int index, Iterable<T> values) valueof,
) {
  K? result;
  var index = -1;
  for (final element in values) {
    final value = valueof(element, ++index, values);
    if (value != null) {
      if (result == null) {
        if (_isDefined(value)) result = value;
      } else if (_isLess(value, result)) {
        result = value;
      }
    }
  }
  return result;
}
