// Ported from d3-array v3.2.4 src/extent.js (ISC, Mike Bostock).

/// Port of `src/extent.js` of d3-array 3.2.4.
library;

import 'dart:typed_data';

@pragma('vm:prefer-inline')
bool _isLess<T extends Comparable<Object>>(T a, T b) {
  if (a is num && b is num) return a < b;
  return a.compareTo(b) < 0;
}

@pragma('vm:prefer-inline')
bool _isGreater<T extends Comparable<Object>>(T a, T b) {
  if (a is num && b is num) return a > b;
  return a.compareTo(b) > 0;
}

@pragma('vm:prefer-inline')
bool _isDefined<T extends Comparable<Object>>(T a) {
  if (a is num) return a >= a;
  return true;
}

/// Returns the `(min, max)` record of [values] using natural order, ignoring
/// `null` and `NaN`, or `null` if no valid comparable value exists.
// DIVERGES(d3-array): adapt-array-typed-api, returns typed (T, T)? record
// instead of [min, max] with undefined elements.
// DIVERGES(d3-array): adapt-array-fast-forms, unboxed fast paths for
// Float64List, List<double>, and List<int>.
(T, T)? extent<T extends Comparable<Object>>(Iterable<T?> values) {
  final Object raw = values;
  if (raw is Float64List) {
    final n = raw.length;
    var i = 0;
    while (i < n && !(raw[i] >= raw[i])) {
      ++i;
    }
    if (i == n) return null;
    var lo = raw[i];
    var hi = lo;
    for (++i; i < n; ++i) {
      final v = raw[i];
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    return (lo as T, hi as T);
  }
  if (raw is List<double>) {
    final n = raw.length;
    var i = 0;
    while (i < n && !(raw[i] >= raw[i])) {
      ++i;
    }
    if (i == n) return null;
    var lo = raw[i];
    var hi = lo;
    for (++i; i < n; ++i) {
      final v = raw[i];
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    return (lo as T, hi as T);
  }
  if (raw is List<int>) {
    final n = raw.length;
    if (n == 0) return null;
    var lo = raw[0];
    var hi = lo;
    for (var i = 1; i < n; ++i) {
      final v = raw[i];
      if (v < lo) lo = v;
      if (v > hi) hi = v;
    }
    return (lo as T, hi as T);
  }
  T? lo;
  T? hi;
  for (final value in values) {
    if (value != null) {
      if (lo == null) {
        if (_isDefined(value)) {
          lo = value;
          hi = value;
        }
      } else {
        if (_isLess(value, lo)) lo = value;
        if (_isGreater(value, hi!)) hi = value;
      }
    }
  }
  return lo == null ? null : (lo, hi!);
}

/// Returns the `(min, max)` record of values extracted from [values] using
/// [valueof], or `null` if no valid comparable value exists.
(K, K)? extentBy<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value) valueof,
) {
  K? lo;
  K? hi;
  if (values is List<T>) {
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final value = valueof(values[i]);
      if (value != null) {
        if (lo == null) {
          if (_isDefined(value)) {
            lo = value;
            hi = value;
          }
        } else {
          if (_isLess(value, lo)) lo = value;
          if (_isGreater(value, hi!)) hi = value;
        }
      }
    }
    return lo == null ? null : (lo, hi!);
  }
  for (final element in values) {
    final value = valueof(element);
    if (value != null) {
      if (lo == null) {
        if (_isDefined(value)) {
          lo = value;
          hi = value;
        }
      } else {
        if (_isLess(value, lo)) lo = value;
        if (_isGreater(value, hi!)) hi = value;
      }
    }
  }
  return lo == null ? null : (lo, hi!);
}

/// Returns the `(min, max)` record of values extracted from [values] using
/// indexed [valueof], or `null` if no valid comparable value exists.
(K, K)? extentByIndexed<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value, int index, Iterable<T> values) valueof,
) {
  K? lo;
  K? hi;
  var index = -1;
  for (final element in values) {
    final value = valueof(element, ++index, values);
    if (value != null) {
      if (lo == null) {
        if (_isDefined(value)) {
          lo = value;
          hi = value;
        }
      } else {
        if (_isLess(value, lo)) lo = value;
        if (_isGreater(value, hi!)) hi = value;
      }
    }
  }
  return lo == null ? null : (lo, hi!);
}
