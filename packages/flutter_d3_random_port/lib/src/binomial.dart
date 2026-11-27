// Ported from d3-random v3.0.1 src/binomial.js (ISC, Mike Bostock).

/// Port of `src/binomial.js` of d3-random 3.0.1.
library;

import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/beta.dart';
import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// returning RandomIntGenerator with .source(RandomSource).
// DIVERGES(d3-random): adapt-random-fast-forms, zero-allocation sampleOne
// calling RandomBeta.sampleOne and inlined geometric loop without per-draw
// closure allocations.
/// Factory for binomial distribution generators with `n >= 0` trials and
/// success probability `p` in `[0, 1]`.
final class RandomBinomial(final RandomSource _source) {
  /// Creates a [RandomBinomial] factory backed by [_source].
  this;

  final RandomBeta _beta = randomBeta.source(_source);

  /// Draws a single binomial variate with [n] trials and probability [pd]
  /// without allocating intermediate beta or geometric closures.
  @pragma('vm:prefer-inline')
  int sampleOne(int n, double pd) {
    if (pd >= 1.0) return n;
    if (pd <= 0.0) return 0;
    final src = _source;
    final beta = _beta;
    var acc = 0;
    var nn = n;
    var pp = pd;
    while (nn * pp > 16.0 && nn * (1.0 - pp) > 16.0) {
      final i = ((nn + 1) * pp).floor();
      final y = beta.sampleOne(i.toDouble(), (nn - i + 1).toDouble());
      if (y <= pp) {
        acc += i;
        nn -= i;
        pp = (pp - y) / (1.0 - y);
      } else {
        nn = i - 1;
        pp /= y;
      }
    }
    final sign = pp < 0.5;
    final pFinal = sign ? pp : 1.0 - pp;
    int k;
    if (pFinal == 1.0) {
      k = nn >= 1 ? nn : 0;
    } else {
      final log1mp = randomLog1p(-pFinal);
      var s = 1 + (randomLog1m(src()) / log1mp).floor();
      k = 0;
      for (; s <= nn; ++k) {
        s += 1 + (randomLog1m(src()) / log1mp).floor();
      }
    }
    return acc + (sign ? k : nn - k);
  }

  /// Returns a generator for binomially distributed success counts with [n]
  /// trials and success probability [p].
  RandomIntGenerator call(int n, num p) {
    final pd = p.toDouble();
    if (pd >= 1.0) return () => n;
    if (pd <= 0.0) return () => 0;
    return () => sampleOne(n, pd);
  }

  /// Returns a new [RandomBinomial] factory using [source].
  RandomBinomial source(RandomSource source) => RandomBinomial(source);

  /// Fills [target] with binomially distributed integer draws.
  void fill(Int32List target, int n, num p) {
    final pd = p.toDouble();
    final len = target.length;
    if (pd >= 1.0) {
      target.fillRange(0, len, n);
      return;
    }
    if (pd <= 0.0) {
      target.fillRange(0, len, 0);
      return;
    }
    for (var i = 0; i < len; ++i) {
      target[i] = sampleOne(n, pd);
    }
  }

  /// Allocates an [Int32List] of [count] binomially distributed draws.
  Int32List sample(int count, int n, num p) {
    final out = Int32List(count);
    fill(out, n, p);
    return out;
  }
}

/// Binomial distribution generator factory backed by [defaultRandomSource].
final RandomBinomial randomBinomial = RandomBinomial(defaultRandomSource);
