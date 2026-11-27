// Ported from d3-random v3.0.1 src/exponential.js (ISC, Mike Bostock).

/// Port of `src/exponential.js` of d3-random 3.0.1.
library;

import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, uses specialized randomLog1m
// and direct fill loop.
/// Factory for exponential distribution generators with rate `lambda`.
final class const RandomExponential(final RandomSource _source) {
  /// Creates a [RandomExponential] factory backed by [_source].
  this;

  /// Returns a generator for exponentially distributed numbers with rate
  /// [lambda] (mean `1 / lambda`).
  RandomGenerator call(num lambda) {
    final l = lambda.toDouble();
    final src = _source;
    return () => -randomLog1m(src()) / l;
  }

  /// Returns a new [RandomExponential] factory using [source].
  RandomExponential source(RandomSource source) => RandomExponential(source);

  /// Fills [target] with exponentially distributed draws.
  void fill(Float64List target, num lambda) {
    final l = lambda.toDouble();
    final src = _source;
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      target[i] = -randomLog1m(src()) / l;
    }
  }

  /// Allocates a [Float64List] of [count] exponentially distributed draws.
  Float64List sample(int count, num lambda) {
    final out = Float64List(count);
    fill(out, lambda);
    return out;
  }
}

/// Exponential distribution generator factory backed by [defaultRandomSource].
const RandomExponential randomExponential = RandomExponential(
  defaultRandomSource,
);
