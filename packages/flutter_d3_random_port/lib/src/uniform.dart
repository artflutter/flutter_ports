// Ported from d3-random v3.0.1 src/uniform.js (ISC, Mike Bostock).

/// Port of `src/uniform.js` of d3-random 3.0.1.
library;

import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, specialized direct fill loop
// and zero-overhead bounds resolution.
/// Factory for continuous uniform distribution generators on `[min, max)`.
final class const RandomUniform(final RandomSource _source) {
  /// Creates a [RandomUniform] factory backed by [_source].
  this;

  static (double, double) _resolveBounds(num? min, num? max) {
    if (min == null && max == null) return (0.0, 1.0);
    if (max == null) return (0.0, min!.toDouble());
    final lo = min == null ? 0.0 : min.toDouble();
    return (lo, max.toDouble() - lo);
  }

  /// Returns a generator for uniformly distributed numbers on `[min, max)`.
  ///
  /// - `randomUniform()` draws from `[0, 1)`.
  /// - `randomUniform(max)` draws from `[0, max)`.
  /// - `randomUniform(min, max)` draws from `[min, max)`.
  RandomGenerator call([num? min, num? max]) {
    final (lo, span) = _resolveBounds(min, max);
    final src = _source;
    return () => src() * span + lo;
  }

  /// Returns a new [RandomUniform] factory using [source].
  RandomUniform source(RandomSource source) => RandomUniform(source);

  /// Fills [target] with uniform draws on `[min, max)`.
  void fill(Float64List target, [num? min, num? max]) {
    final (lo, span) = _resolveBounds(min, max);
    final src = _source;
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      target[i] = src() * span + lo;
    }
  }

  /// Allocates a [Float64List] of [count] uniform draws on `[min, max)`.
  Float64List sample(int count, [num? min, num? max]) {
    final out = Float64List(count);
    fill(out, min, max);
    return out;
  }
}

/// Continuous uniform distribution generator factory backed by
/// [defaultRandomSource].
const RandomUniform randomUniform = RandomUniform(defaultRandomSource);
