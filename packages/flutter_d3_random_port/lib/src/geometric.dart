// Ported from d3-random v3.0.1 src/geometric.js (ISC, Mike Bostock).

/// Port of `src/geometric.js` of d3-random 3.0.1.
library;

import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// returning RandomIntGenerator; throws RangeError for p == 0 because Dart int
// cannot represent Infinity.
// DIVERGES(d3-random): adapt-random-fast-forms, uses specialized randomLog1m
// and direct fill loop.
/// Factory for geometric distribution generators with success probability
/// `p` in `(0, 1]`.
final class const RandomGeometric(final RandomSource _source) {
  /// Creates a [RandomGeometric] factory backed by [_source].
  this;

  /// Returns a generator for geometrically distributed trial counts (`>= 1`)
  /// with success probability [p].
  ///
  /// Throws a [RangeError] if [p] is outside `(0, 1]`.
  RandomIntGenerator call(num p) {
    final pd = p.toDouble();
    if (pd <= 0.0 || pd > 1.0 || pd.isNaN) throw RangeError('invalid p');
    if (pd == 1.0) return () => 1;
    final log1mp = randomLog1p(-pd);
    final src = _source;
    return () => 1 + (randomLog1m(src()) / log1mp).floor();
  }

  /// Returns a new [RandomGeometric] factory using [source].
  RandomGeometric source(RandomSource source) => RandomGeometric(source);

  /// Fills [target] with geometrically distributed integer draws.
  void fill(Int32List target, num p) {
    final pd = p.toDouble();
    if (pd <= 0.0 || pd > 1.0 || pd.isNaN) throw RangeError('invalid p');
    final n = target.length;
    if (pd == 1.0) {
      target.fillRange(0, n, 1);
      return;
    }
    final log1mp = randomLog1p(-pd);
    final src = _source;
    for (var i = 0; i < n; ++i) {
      target[i] = 1 + (randomLog1m(src()) / log1mp).floor();
    }
  }

  /// Allocates an [Int32List] of [count] geometrically distributed draws.
  Int32List sample(int count, num p) {
    final out = Int32List(count);
    fill(out, p);
    return out;
  }
}

/// Geometric distribution generator factory backed by [defaultRandomSource].
const RandomGeometric randomGeometric = RandomGeometric(defaultRandomSource);
