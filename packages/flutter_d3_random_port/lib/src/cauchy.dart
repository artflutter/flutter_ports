// Ported from d3-random v3.0.1 src/cauchy.js (ISC, Mike Bostock).

/// Port of `src/cauchy.js` of d3-random 3.0.1.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, direct fill loop.
/// Factory for Cauchy distribution generators with location `a` (default `0`)
/// and scale `b` (default `1`).
final class const RandomCauchy(final RandomSource _source) {
  /// Creates a [RandomCauchy] factory backed by [_source].
  this;

  /// Returns a generator for Cauchy distributed numbers with location [a] and
  /// scale [b].
  RandomGenerator call([num a = 0, num b = 1]) {
    final ad = a.toDouble();
    final bd = b.toDouble();
    final src = _source;
    return () => ad + bd * math.tan(math.pi * src());
  }

  /// Returns a new [RandomCauchy] factory using [source].
  RandomCauchy source(RandomSource source) => RandomCauchy(source);

  /// Fills [target] with Cauchy distributed draws.
  void fill(Float64List target, [num a = 0, num b = 1]) {
    final ad = a.toDouble();
    final bd = b.toDouble();
    final src = _source;
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      target[i] = ad + bd * math.tan(math.pi * src());
    }
  }

  /// Allocates a [Float64List] of [count] Cauchy distributed draws.
  Float64List sample(int count, [num a = 0, num b = 1]) {
    final out = Float64List(count);
    fill(out, a, b);
    return out;
  }
}

/// Cauchy distribution generator factory backed by [defaultRandomSource].
const RandomCauchy randomCauchy = RandomCauchy(defaultRandomSource);
