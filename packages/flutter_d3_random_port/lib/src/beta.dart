// Ported from d3-random v3.0.1 src/beta.js (ISC, Mike Bostock).

/// Port of `src/beta.js` of d3-random 3.0.1.
library;

import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';
import 'package:flutter_d3_random_port/src/gamma.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, zero-allocation sampleOne
// entry point for RandomBinomial and direct fill loop.
/// Factory for beta distribution generators with positive shape parameters
/// `alpha` and `beta`.
final class RandomBeta(RandomSource source) {
  /// Creates a [RandomBeta] factory backed by [source].
  this;

  final RandomGamma _gamma = randomGamma.source(source);

  /// Draws a single beta variate with parameters [alpha] and [beta] without
  /// allocating intermediate gamma closures.
  @pragma('vm:prefer-inline')
  double sampleOne(double alpha, double beta) {
    final x = _gamma.sampleOne(alpha, 1);
    return x == 0.0 ? 0.0 : x / (x + _gamma.sampleOne(beta, 1));
  }

  /// Returns a generator for beta distributed numbers with shape parameters
  /// [alpha] and [beta].
  RandomGenerator call(num alpha, num beta) {
    final gx = _gamma(alpha);
    final gy = _gamma(beta);
    return () {
      final x = gx();
      return x == 0.0 ? 0.0 : x / (x + gy());
    };
  }

  /// Returns a new [RandomBeta] factory using [source].
  RandomBeta source(RandomSource source) => RandomBeta(source);

  /// Fills [target] with beta distributed draws.
  void fill(Float64List target, num alpha, num beta) {
    final gx = _gamma(alpha);
    final gy = _gamma(beta);
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      final x = gx();
      target[i] = x == 0.0 ? 0.0 : x / (x + gy());
    }
  }

  /// Allocates a [Float64List] of [count] beta distributed draws.
  Float64List sample(int count, num alpha, num beta) {
    final out = Float64List(count);
    fill(out, alpha, beta);
    return out;
  }
}

/// Beta distribution generator factory backed by [defaultRandomSource].
final RandomBeta randomBeta = RandomBeta(defaultRandomSource);
