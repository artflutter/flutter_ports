// Ported from d3-random v3.0.1 src/weibull.js (ISC, Mike Bostock).

/// Port of `src/weibull.js` of d3-random 3.0.1.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, specialized k == 0 (Gumbel)
// vs k != 0 (Weibull/Fréchet) closures eliminating outerFunc indirection,
// specialized randomLog1m, and direct fill loop.
/// Factory for generalized extreme value distribution generators:
/// Weibull (`k > 0`), Gumbel (`k == 0`), and Fréchet (`k < 0`), with location
/// `a` (default `0`) and scale `b` (default `1`).
final class const RandomWeibull(final RandomSource _source) {
  /// Creates a [RandomWeibull] factory backed by [_source].
  this;

  /// Returns a generator for Weibull (`k > 0`), Gumbel (`k == 0`), or Fréchet
  /// (`k < 0`) distributed numbers with location [a] and scale [b].
  RandomGenerator call(num k, [num a = 0, num b = 1]) {
    final kd = k.toDouble();
    final ad = a.toDouble();
    final bd = b.toDouble();
    final src = _source;
    if (kd == 0.0) {
      return () => ad + bd * -math.log(-randomLog1m(src()));
    }
    final invK = 1.0 / kd;
    return () => ad + bd * math.pow(-randomLog1m(src()), invK).toDouble();
  }

  /// Returns a new [RandomWeibull] factory using [source].
  RandomWeibull source(RandomSource source) => RandomWeibull(source);

  /// Fills [target] with Weibull/Gumbel/Fréchet distributed draws.
  void fill(Float64List target, num k, [num a = 0, num b = 1]) {
    final kd = k.toDouble();
    final ad = a.toDouble();
    final bd = b.toDouble();
    final src = _source;
    final n = target.length;
    if (kd == 0.0) {
      for (var i = 0; i < n; ++i) {
        target[i] = ad + bd * -math.log(-randomLog1m(src()));
      }
    } else {
      final invK = 1.0 / kd;
      for (var i = 0; i < n; ++i) {
        target[i] = ad + bd * math.pow(-randomLog1m(src()), invK).toDouble();
      }
    }
  }

  /// Allocates a [Float64List] of [count] Weibull/Gumbel/Fréchet draws.
  Float64List sample(int count, num k, [num a = 0, num b = 1]) {
    final out = Float64List(count);
    fill(out, k, a, b);
    return out;
  }
}

/// Weibull/Gumbel/Fréchet distribution generator factory backed by
/// [defaultRandomSource].
const RandomWeibull randomWeibull = RandomWeibull(defaultRandomSource);
