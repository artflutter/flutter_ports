// Ported from d3-array v3.2.4 src/minIndex.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/minIndex.js` of d3-array 3.2.4.
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

/// Returns the index of the minimum value in [values] using natural order,
/// ignoring `null` and `NaN`, or `-1` if no valid value exists.
// DIVERGES(d3-array): adapt-array-typed-api, typed Comparable<Object> generic.
int minIndex<T extends Comparable<Object>>(Iterable<T?> values) {
  final Object raw = values;
  if (raw is Float64List) {
    final n = raw.length;
    var i = 0;
    while (i < n && !(raw[i] >= raw[i])) {
      ++i;
    }
    if (i == n) return -1;
    var m = raw[i];
    var best = i;
    for (++i; i < n; ++i) {
      final v = raw[i];
      if (v < m) {
        m = v;
        best = i;
      }
    }
    return best;
  }
  T? bestVal;
  var bestIdx = -1;
  var index = -1;
  for (final value in values) {
    ++index;
    if (value != null) {
      if (bestVal == null) {
        if (_isDefined(value)) {
          bestVal = value;
          bestIdx = index;
        }
      } else if (_isLess(value, bestVal)) {
        bestVal = value;
        bestIdx = index;
      }
    }
  }
  return bestIdx;
}

/// Returns the index of the minimum value extracted from [values] using
/// [valueof], or `-1` if no valid value exists.
int minIndexBy<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value) valueof,
) {
  K? bestVal;
  var bestIdx = -1;
  var index = -1;
  for (final element in values) {
    ++index;
    final value = valueof(element);
    if (value != null) {
      if (bestVal == null) {
        if (_isDefined(value)) {
          bestVal = value;
          bestIdx = index;
        }
      } else if (_isLess(value, bestVal)) {
        bestVal = value;
        bestIdx = index;
      }
    }
  }
  return bestIdx;
}

/// Returns the index of the minimum value extracted from [values] using
/// indexed [valueof], or `-1` if no valid value exists.
int minIndexByIndexed<T, K extends Comparable<Object>>(
  Iterable<T> values,
  K? Function(T value, int index, Iterable<T> values) valueof,
) {
  K? bestVal;
  var bestIdx = -1;
  var index = -1;
  for (final element in values) {
    final value = valueof(element, ++index, values);
    if (value != null) {
      if (bestVal == null) {
        if (_isDefined(value)) {
          bestVal = value;
          bestIdx = index;
        }
      } else if (_isLess(value, bestVal)) {
        bestVal = value;
        bestIdx = index;
      }
    }
  }
  return bestIdx;
}
