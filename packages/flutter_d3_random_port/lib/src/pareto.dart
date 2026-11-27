// Ported from d3-random v3.0.1 src/pareto.js (ISC, Mike Bostock).

/// Port of `src/pareto.js` of d3-random 3.0.1.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, direct fill loop.
/// Factory for Pareto distribution generators with shape `alpha >= 0`.
final class const RandomPareto(final RandomSource _source) {
  /// Creates a [RandomPareto] factory backed by [_source].
  this;

  /// Returns a generator for Pareto distributed numbers with shape [alpha].
  ///
  /// Throws a [RangeError] if [alpha] is negative.
  RandomGenerator call(num alpha) {
    final a = alpha.toDouble();
    if (a < 0.0) throw RangeError('invalid alpha');
    final invNegAlpha = 1.0 / -a;
    final src = _source;
    return () => math.pow(1.0 - src(), invNegAlpha).toDouble();
  }

  /// Returns a new [RandomPareto] factory using [source].
  RandomPareto source(RandomSource source) => RandomPareto(source);

  /// Fills [target] with Pareto distributed draws.
  void fill(Float64List target, num alpha) {
    final a = alpha.toDouble();
    if (a < 0.0) throw RangeError('invalid alpha');
    final invNegAlpha = 1.0 / -a;
    final src = _source;
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      target[i] = math.pow(1.0 - src(), invNegAlpha).toDouble();
    }
  }

  /// Allocates a [Float64List] of [count] Pareto distributed draws.
  Float64List sample(int count, num alpha) {
    final out = Float64List(count);
    fill(out, alpha);
    return out;
  }
}

/// Pareto distribution generator factory backed by [defaultRandomSource].
const RandomPareto randomPareto = RandomPareto(defaultRandomSource);
