// Ported from d3-random v3.0.1 src/poisson.js (ISC, Mike Bostock).

/// Port of `src/poisson.js` of d3-random 3.0.1.
library;

import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/binomial.dart';
import 'package:flutter_d3_random_port/src/defaultSource.dart';
import 'package:flutter_d3_random_port/src/gamma.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// returning RandomIntGenerator with .source(RandomSource).
// DIVERGES(d3-random): adapt-random-fast-forms, zero-allocation sampleOne
// calling RandomGamma.sampleOne, RandomBinomial.sampleOne, and randomLog1m
// without per-draw closure allocations.
/// Factory for Poisson distribution generators with mean `lambda`.
final class RandomPoisson(final RandomSource _source) {
  /// Creates a [RandomPoisson] factory backed by [_source].
  this;

  final RandomGamma _gamma = randomGamma.source(_source);
  final RandomBinomial _binomial = randomBinomial.source(_source);

  @pragma('vm:prefer-inline')
  int _sampleOne(double ld) {
    final src = _source;
    final gamma = _gamma;
    final binomial = _binomial;
    var acc = 0;
    var l = ld;
    while (l > 16.0) {
      final n = (0.875 * l).floor();
      final t = gamma.sampleOne(n.toDouble(), 1);
      if (t > l) return acc + binomial.sampleOne(n - 1, l / t);
      acc += n;
      l -= t;
    }
    var s = -randomLog1m(src());
    var k = 0;
    for (; s <= l; ++k) {
      s -= randomLog1m(src());
    }
    return acc + k;
  }

  /// Returns a generator for Poisson distributed counts with mean [lambda].
  RandomIntGenerator call(num lambda) {
    final ld = lambda.toDouble();
    return () => _sampleOne(ld);
  }

  /// Returns a new [RandomPoisson] factory using [source].
  RandomPoisson source(RandomSource source) => RandomPoisson(source);

  /// Fills [target] with Poisson distributed integer draws.
  void fill(Int32List target, num lambda) {
    final ld = lambda.toDouble();
    final n = target.length;
    for (var i = 0; i < n; ++i) {
      target[i] = _sampleOne(ld);
    }
  }

  /// Allocates an [Int32List] of [count] Poisson distributed draws.
  Int32List sample(int count, num lambda) {
    final out = Int32List(count);
    fill(out, lambda);
    return out;
  }
}

/// Poisson distribution generator factory backed by [defaultRandomSource].
final RandomPoisson randomPoisson = RandomPoisson(defaultRandomSource);
