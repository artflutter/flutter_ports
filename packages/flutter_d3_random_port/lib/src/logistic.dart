// Ported from d3-random v3.0.1 src/logistic.js (ISC, Mike Bostock).

/// Port of `src/logistic.js` of d3-random 3.0.1.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, direct fill loop.
/// Factory for logistic distribution generators with location `a` (default `0`)
/// and scale `b` (default `1`).
final class const RandomLogistic(final RandomSource _source) {
  /// Creates a [RandomLogistic] factory backed by [_source].
  this;

  /// Returns a generator for logistically distributed numbers with location [a]
  /// and scale [b].
  RandomGenerator call([num a = 0, num b = 1]) {
    final ad = a.toDouble();
    final bd = b.toDouble();
    final src = _source;
    return () {
      final u = src();
      return ad + bd * math.log(u / (1.0 - u));
    };
  }

  /// Returns a new [RandomLogistic] factory using [source].
  RandomLogistic source(RandomSource source) => RandomLogistic(source);

  /// Fills [target] with logistically distributed draws.
  void fill(Float64List target, [num a = 0, num b = 1]) {
    final ad = a.toDouble();
    final bd = b.toDouble();
    final src = _source;
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      final u = src();
      target[i] = ad + bd * math.log(u / (1.0 - u));
    }
  }

  /// Allocates a [Float64List] of [count] logistically distributed draws.
  Float64List sample(int count, [num a = 0, num b = 1]) {
    final out = Float64List(count);
    fill(out, a, b);
    return out;
  }
}

/// Logistic distribution generator factory backed by [defaultRandomSource].
const RandomLogistic randomLogistic = RandomLogistic(defaultRandomSource);
