// Ported from d3-random v3.0.1 src/bernoulli.js (ISC, Mike Bostock).

/// Port of `src/bernoulli.js` of d3-random 3.0.1.
library;

import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// returning RandomIntGenerator with .source(RandomSource).
// DIVERGES(d3-random): adapt-random-fast-forms, direct fill loop and
// branchless double.floor() conversion.
/// Factory for Bernoulli distribution generators returning `1` with probability
/// `p` and `0` with probability `1 - p`.
final class const RandomBernoulli(final RandomSource _source) {
  /// Creates a [RandomBernoulli] factory backed by [_source].
  this;

  /// Returns a generator producing `1` with probability [p] and `0` otherwise.
  ///
  /// Throws a [RangeError] if [p] is outside `[0, 1]`.
  RandomIntGenerator call(num p) {
    final pd = p.toDouble();
    if (pd < 0.0 || pd > 1.0 || pd.isNaN) throw RangeError('invalid p');
    final src = _source;
    return () => (src() + pd).floor();
  }

  /// Returns a new [RandomBernoulli] factory using [source].
  RandomBernoulli source(RandomSource source) => RandomBernoulli(source);

  /// Fills [target] with Bernoulli draws (`0` or `1`).
  void fill(Int32List target, num p) {
    final pd = p.toDouble();
    if (pd < 0.0 || pd > 1.0 || pd.isNaN) throw RangeError('invalid p');
    final src = _source;
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      target[i] = (src() + pd).floor();
    }
  }

  /// Allocates an [Int32List] of [count] Bernoulli draws (`0` or `1`).
  Int32List sample(int count, num p) {
    final out = Int32List(count);
    fill(out, p);
    return out;
  }
}

/// Bernoulli distribution generator factory backed by [defaultRandomSource].
const RandomBernoulli randomBernoulli = RandomBernoulli(defaultRandomSource);
