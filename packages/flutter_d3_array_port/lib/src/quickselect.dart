// Ported from d3-array v3.2.4 src/quickselect.js (ISC, Mike Bostock).

/// Port of `src/quickselect.js` of d3-array 3.2.4.
///
/// Based on https://github.com/mourner/quickselect
/// (ISC license, Copyright 2018 Vladimir Agafonkin).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_array_port/src/sort.dart';

/// Fast internal Floyd-Rivest selection on a [Float64List] guaranteed to
/// contain no `NaN` values.
void quickselectFloat64NoNaN(Float64List array, int k, int left, int right) {
  var l = left;
  var r = right;
  while (r > l) {
    if (r - l > 600) {
      final n = r - l + 1;
      final m = k - l + 1;
      final z = math.log(n);
      final s = 0.5 * math.exp(2 * z / 3);
      final sd =
          0.5 * math.sqrt(z * s * (n - s) / n) * (m - n / 2 < 0 ? -1 : 1);
      final newLeft = math.max(l, (k - m * s / n + sd).floor());
      final newRight = math.min(r, (k + (n - m) * s / n + sd).floor());
      quickselectFloat64NoNaN(array, k, newLeft, newRight);
    }

    final t = array[k];
    var i = l;
    var j = r;

    array[k] = array[l];
    array[l] = t;
    if (array[r] > t) {
      final tmp = array[l];
      array[l] = array[r];
      array[r] = tmp;
    }

    while (i < j) {
      final tmp = array[i];
      array[i] = array[j];
      array[j] = tmp;
      ++i;
      --j;
      while (array[i] < t) {
        ++i;
      }
      while (array[j] > t) {
        --j;
      }
    }

    if (array[l] == t) {
      final tmp = array[l];
      array[l] = array[j];
      array[j] = tmp;
    } else {
      ++j;
      final tmp = array[j];
      array[j] = array[r];
      array[r] = tmp;
    }

    if (j <= k) l = j + 1;
    if (k <= j) r = j - 1;
  }
}

void _quickselectDoubleDefined(List<double> array, int k, int left, int right) {
  var l = left;
  var r = right;
  while (r > l) {
    if (r - l > 600) {
      final n = r - l + 1;
      final m = k - l + 1;
      final z = math.log(n);
      final s = 0.5 * math.exp(2 * z / 3);
      final sd =
          0.5 * math.sqrt(z * s * (n - s) / n) * (m - n / 2 < 0 ? -1 : 1);
      final newLeft = math.max(l, (k - m * s / n + sd).floor());
      final newRight = math.min(r, (k + (n - m) * s / n + sd).floor());
      _quickselectDoubleDefined(array, k, newLeft, newRight);
    }

    final t = array[k];
    var i = l;
    var j = r;

    array[k] = array[l];
    array[l] = t;
    if (ascendingDefinedDouble(array[r], t) > 0) {
      final tmp = array[l];
      array[l] = array[r];
      array[r] = tmp;
    }

    while (i < j) {
      final tmp = array[i];
      array[i] = array[j];
      array[j] = tmp;
      ++i;
      --j;
      while (ascendingDefinedDouble(array[i], t) < 0) {
        ++i;
      }
      while (ascendingDefinedDouble(array[j], t) > 0) {
        --j;
      }
    }

    if (ascendingDefinedDouble(array[l], t) == 0) {
      final tmp = array[l];
      array[l] = array[j];
      array[j] = tmp;
    } else {
      ++j;
      final tmp = array[j];
      array[j] = array[r];
      array[r] = tmp;
    }

    if (j <= k) l = j + 1;
    if (k <= j) r = j - 1;
  }
}

void _quickselectGeneric<T>(
  List<T> array,
  int k,
  int left,
  int right,
  int Function(T a, T b) cmp,
) {
  var l = left;
  var r = right;
  while (r > l) {
    if (r - l > 600) {
      final n = r - l + 1;
      final m = k - l + 1;
      final z = math.log(n);
      final s = 0.5 * math.exp(2 * z / 3);
      final sd =
          0.5 * math.sqrt(z * s * (n - s) / n) * (m - n / 2 < 0 ? -1 : 1);
      final newLeft = math.max(l, (k - m * s / n + sd).floor());
      final newRight = math.min(r, (k + (n - m) * s / n + sd).floor());
      _quickselectGeneric(array, k, newLeft, newRight, cmp);
    }

    final t = array[k];
    var i = l;
    var j = r;

    array[k] = array[l];
    array[l] = t;
    if (cmp(array[r], t) > 0) {
      final tmp = array[l];
      array[l] = array[r];
      array[r] = tmp;
    }

    while (i < j) {
      final tmp = array[i];
      array[i] = array[j];
      array[j] = tmp;
      ++i;
      --j;
      while (cmp(array[i], t) < 0) {
        ++i;
      }
      while (cmp(array[j], t) > 0) {
        --j;
      }
    }

    if (cmp(array[l], t) == 0) {
      final tmp = array[l];
      array[l] = array[j];
      array[j] = tmp;
    } else {
      ++j;
      final tmp = array[j];
      array[j] = array[r];
      array[r] = tmp;
    }

    if (j <= k) l = j + 1;
    if (k <= j) r = j - 1;
  }
}

/// Rearranges elements in [array] in-place between [left] and [right]
/// (inclusive) such that `array[k]` is in its sorted position, all elements
/// before `k` are `<= array[k]`, and all elements after `k` are `>= array[k]`.
// DIVERGES(d3-array): adapt-array-typed-api, typed Comparable<Object> generic
// with quickselectNullable and quickselectWith for nullable/custom types.
// DIVERGES(d3-array): adapt-array-fast-forms, specialized Float64List and
// List<double> Floyd-Rivest loops without closure boxing.
List<T> quickselect<T extends Comparable<Object>>(
  List<T> array,
  int k, [
  int left = 0,
  int? right,
  num Function(T a, T b)? compare,
]) {
  final l = math.max(0, left);
  final r = math.min(array.length - 1, right ?? array.length - 1);
  if (!(l <= k && k <= r)) return array;
  if (compare == null) {
    final Object raw = array;
    if (raw is Float64List) {
      _quickselectDoubleDefined(raw, k, l, r);
      return array;
    }
    if (raw is List<double>) {
      _quickselectDoubleDefined(raw, k, l, r);
      return array;
    }
    _quickselectGeneric<T>(array, k, l, r, ascendingDefined<T>);
    return array;
  }
  _quickselectGeneric<T>(array, k, l, r, compareDefined<T>(compare));
  return array;
}

/// Rearranges nullable elements in [array] in-place placing `null` and `NaN`
/// elements last.
List<T?> quickselectNullable<T extends Comparable<Object>>(
  List<T?> array,
  int k, [
  int left = 0,
  int? right,
  num Function(T? a, T? b)? compare,
]) {
  final l = math.max(0, left);
  final r = math.min(array.length - 1, right ?? array.length - 1);
  if (!(l <= k && k <= r)) return array;
  final cmp = compare == null
      ? ascendingDefined<T>
      : compareDefined<T?>(compare);
  _quickselectGeneric<T?>(array, k, l, r, cmp);
  return array;
}

/// Rearranges elements in [array] in-place according to [compare].
List<T> quickselectWith<T>(
  List<T> array,
  int k,
  num Function(T a, T b) compare, [
  int left = 0,
  int? right,
]) {
  final l = math.max(0, left);
  final r = math.min(array.length - 1, right ?? array.length - 1);
  if (!(l <= k && k <= r)) return array;
  _quickselectGeneric<T>(array, k, l, r, compareDefined<T>(compare));
  return array;
}
