// Ported from d3-array v3.2.4 src/fsum.js (ISC, Mike Bostock).

/// Port of `src/fsum.js` of d3-array 3.2.4: [Adder], [fsum], and [fcumsum].
///
/// Based on Shewchuk's exact adaptive floating-point summation algorithm
/// (CPython `math.fsum`).
library;

import 'dart:typed_data';

/// A full-precision IEEE-754 floating-point adder implementing Shewchuk's
/// adaptive summation algorithm.
// DIVERGES(d3-array): adapt-array-typed-api, typed double add/valueOf methods
// and guarded partial-array bounds.
final class Adder() {
  /// Creates an empty [Adder].
  this;

  final Float64List _partials = Float64List(32);
  int _n = 0;

  /// Adds [x] to the running sum and returns `this`.
  @pragma('vm:prefer-inline')
  Adder add(double x) {
    final p = _partials;
    final limit = _n < 32 ? _n : 32;
    var i = 0;
    var cur = x;
    for (var j = 0; j < limit; ++j) {
      final y = p[j];
      final hi = cur + y;
      final lo = cur.abs() < y.abs() ? cur - (hi - y) : y - (hi - cur);
      if (lo != 0) p[i++] = lo;
      cur = hi;
    }
    if (i < 32) {
      p[i] = cur;
      _n = i + 1;
    } else {
      _n = 32;
    }
    // Upstream Adder.add returns `this` for fluent chaining.
    // ignore: avoid_returning_this
    return this;
  }

  /// Returns the correctly rounded IEEE-754 sum of all added values.
  double valueOf() => _finalizePartials(_partials, _n);

  /// Alias for [valueOf].
  double get value => _finalizePartials(_partials, _n);
}

@pragma('vm:prefer-inline')
double _finalizePartials(Float64List p, int count) {
  var n = count;
  var hi = 0.0;
  if (n > 0) {
    hi = p[--n];
    var lo = 0.0;
    while (n > 0) {
      final x = hi;
      final y = p[--n];
      hi = x + y;
      lo = y - (hi - x);
      if (lo != 0) break;
    }
    if (n > 0 && ((lo < 0 && p[n - 1] < 0) || (lo > 0 && p[n - 1] > 0))) {
      final y = lo * 2.0;
      final x = hi + y;
      if (y == x - hi) hi = x;
    }
  }
  return hi;
}

double _fsumDoubleList(List<double> values) {
  final p = Float64List(32);
  var pn = 0;
  final n = values.length;
  for (var k = 0; k < n; ++k) {
    var cur = values[k];
    if (cur != 0 && cur == cur) {
      var i = 0;
      for (var j = 0; j < pn; ++j) {
        final y = p[j];
        final hi = cur + y;
        final lo = cur.abs() < y.abs() ? cur - (hi - y) : y - (hi - cur);
        if (lo != 0) p[i++] = lo;
        cur = hi;
      }
      if (i < 32) {
        p[i] = cur;
        pn = i + 1;
      } else {
        pn = 32;
      }
    }
  }
  return _finalizePartials(p, pn);
}

/// Returns a full-precision summation of [values], ignoring `null` and `NaN`.
// DIVERGES(d3-array): adapt-array-fast-forms, inline Shewchuk locals for
// Float64List/List<double> and unboxed fast paths for List<int>/List<num>.
double fsum(Iterable<num?> values) {
  if (values is Float64List) {
    final p = Float64List(32);
    var pn = 0;
    final n = values.length;
    for (var k = 0; k < n; ++k) {
      var cur = values[k];
      if (cur != 0 && cur == cur) {
        var i = 0;
        for (var j = 0; j < pn; ++j) {
          final y = p[j];
          final hi = cur + y;
          final lo = cur.abs() < y.abs() ? cur - (hi - y) : y - (hi - cur);
          if (lo != 0) p[i++] = lo;
          cur = hi;
        }
        if (i < 32) {
          p[i] = cur;
          pn = i + 1;
        } else {
          pn = 32;
        }
      }
    }
    return _finalizePartials(p, pn);
  }
  if (values is List<double>) return _fsumDoubleList(values);
  final adder = Adder();
  if (values is List<int>) {
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      if (v != 0) adder.add(v.toDouble());
    }
    return adder.valueOf();
  }
  if (values is List<num>) {
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final v = values[i].toDouble();
      if (v != 0 && v == v) adder.add(v);
    }
    return adder.valueOf();
  }
  for (final raw in values) {
    if (raw != null) {
      final v = raw.toDouble();
      if (v != 0 && v == v) adder.add(v);
    }
  }
  return adder.valueOf();
}

/// Returns a full-precision summation of values extracted from [values] using
/// [valueof].
double fsumBy<T>(Iterable<T> values, num? Function(T value) valueof) {
  final adder = Adder();
  if (values is List<T>) {
    final n = values.length;
    for (var i = 0; i < n; ++i) {
      final raw = valueof(values[i]);
      if (raw != null) {
        final v = raw.toDouble();
        if (v != 0 && v == v) adder.add(v);
      }
    }
    return adder.valueOf();
  }
  for (final value in values) {
    final raw = valueof(value);
    if (raw != null) {
      final v = raw.toDouble();
      if (v != 0 && v == v) adder.add(v);
    }
  }
  return adder.valueOf();
}

/// Returns a full-precision summation of values extracted from [values] using
/// indexed [valueof].
double fsumByIndexed<T>(
  Iterable<T> values,
  num? Function(T value, int index, Iterable<T> values) valueof,
) {
  final adder = Adder();
  var index = -1;
  for (final value in values) {
    final raw = valueof(value, ++index, values);
    if (raw != null) {
      final v = raw.toDouble();
      if (v != 0 && v == v) adder.add(v);
    }
  }
  return adder.valueOf();
}

/// Returns the full-precision cumulative sum of [values] as a [Float64List].
Float64List fcumsum(Iterable<num?> values) {
  final adder = Adder();
  if (values is Float64List) {
    final n = values.length;
    final out = Float64List(n);
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      adder.add(v == v ? v : 0.0);
      out[i] = adder.valueOf();
    }
    return out;
  }
  if (values is List<double>) {
    final n = values.length;
    final out = Float64List(n);
    for (var i = 0; i < n; ++i) {
      final v = values[i];
      adder.add(v == v ? v : 0.0);
      out[i] = adder.valueOf();
    }
    return out;
  }
  if (values is List<num?>) {
    final n = values.length;
    final out = Float64List(n);
    for (var i = 0; i < n; ++i) {
      final raw = values[i];
      final v = raw?.toDouble() ?? 0.0;
      adder.add(v == v ? v : 0.0);
      out[i] = adder.valueOf();
    }
    return out;
  }
  final list = <double>[];
  for (final raw in values) {
    final v = raw?.toDouble() ?? 0.0;
    adder.add(v == v ? v : 0.0);
    list.add(adder.valueOf());
  }
  return Float64List.fromList(list);
}

/// Returns the full-precision cumulative sum of values extracted from [values]
/// using [valueof] as a [Float64List].
Float64List fcumsumBy<T>(Iterable<T> values, num? Function(T value) valueof) {
  final adder = Adder();
  if (values is List<T>) {
    final n = values.length;
    final out = Float64List(n);
    for (var i = 0; i < n; ++i) {
      final raw = valueof(values[i]);
      final v = raw?.toDouble() ?? 0.0;
      adder.add(v == v ? v : 0.0);
      out[i] = adder.valueOf();
    }
    return out;
  }
  final list = <double>[];
  for (final value in values) {
    final raw = valueof(value);
    final v = raw?.toDouble() ?? 0.0;
    adder.add(v == v ? v : 0.0);
    list.add(adder.valueOf());
  }
  return Float64List.fromList(list);
}

/// Returns the full-precision cumulative sum of values extracted from [values]
/// using indexed [valueof] as a [Float64List].
Float64List fcumsumByIndexed<T>(
  Iterable<T> values,
  num? Function(T value, int index, Iterable<T> values) valueof,
) {
  final adder = Adder();
  if (values is List<T>) {
    final n = values.length;
    final out = Float64List(n);
    for (var i = 0; i < n; ++i) {
      final raw = valueof(values[i], i, values);
      final v = raw?.toDouble() ?? 0.0;
      adder.add(v == v ? v : 0.0);
      out[i] = adder.valueOf();
    }
    return out;
  }
  final list = <double>[];
  var index = -1;
  for (final value in values) {
    final raw = valueof(value, ++index, values);
    final v = raw?.toDouble() ?? 0.0;
    adder.add(v == v ? v : 0.0);
    list.add(adder.valueOf());
  }
  return Float64List.fromList(list);
}
