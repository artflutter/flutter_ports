// Ported from d3-random v3.0.1 src/int.js (ISC, Mike Bostock).

/// Port of `src/int.js` of d3-random 3.0.1.
library;

import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// returning RandomIntGenerator with .source(RandomSource).
// DIVERGES(d3-random): adapt-random-fast-forms, pre-converted double bounds
// and direct fill loop.
/// Factory for discrete uniform integer distribution generators on
/// `[floor(min), floor(max) - 1]`.
final class const RandomInt(final RandomSource _source) {
  /// Creates a [RandomInt] factory backed by [_source].
  this;

  static (double, double) _resolveBounds(num min, num? max) {
    final int lo;
    final int span;
    if (max == null) {
      lo = 0;
      span = min.floor();
    } else {
      lo = min.floor();
      span = max.floor() - lo;
    }
    return (lo.toDouble(), span.toDouble());
  }

  /// Returns a generator for uniformly distributed integers.
  ///
  /// - `randomInt(max)` draws integers in `[0, floor(max) - 1]`.
  /// - `randomInt(min, max)` draws integers in `[floor(min), floor(max) - 1]`.
  RandomIntGenerator call(num min, [num? max]) {
    final (lo, span) = _resolveBounds(min, max);
    final src = _source;
    return () => (src() * span + lo).floor();
  }

  /// Returns a new [RandomInt] factory using [source].
  RandomInt source(RandomSource source) => RandomInt(source);

  /// Fills [target] with uniform integer draws.
  void fill(Int32List target, num min, [num? max]) {
    final (lo, span) = _resolveBounds(min, max);
    final src = _source;
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      target[i] = (src() * span + lo).floor();
    }
  }

  /// Allocates an [Int32List] of [count] uniform integer draws.
  Int32List sample(int count, num min, [num? max]) {
    final out = Int32List(count);
    fill(out, min, max);
    return out;
  }
}

/// Discrete uniform integer distribution generator factory backed by
/// [defaultRandomSource].
const RandomInt randomInt = RandomInt(defaultRandomSource);
