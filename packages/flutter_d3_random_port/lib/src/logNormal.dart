// Ported from d3-random v3.0.1 src/logNormal.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/logNormal.js` of d3-random 3.0.1.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, flat unboxed Marsaglia polar
// state caching sqrt(-2 * log(r) / r) across paired draws and paired batch
// fill.
/// Factory for log-normal distribution generators whose natural logarithm has
/// mean `mu` and standard deviation `sigma`.
final class const RandomLogNormal(final RandomSource _source) {
  /// Creates a [RandomLogNormal] factory backed by [_source].
  this;

  /// Returns a generator for log-normally distributed numbers.
  RandomGenerator call([num mu = 0, num sigma = 1]) {
    final m = mu.toDouble();
    final s = sigma.toDouble();
    final src = _source;
    var spare = 0.0;
    var scale = 0.0;
    var hasSpare = false;
    return () {
      if (hasSpare) {
        hasSpare = false;
        return math.exp(m + s * spare * scale);
      }
      double x;
      double y;
      double r;
      do {
        x = src() * 2.0 - 1.0;
        y = src() * 2.0 - 1.0;
        r = x * x + y * y;
      } while (r == 0.0 || r > 1.0);
      final sc = math.sqrt(-2.0 * math.log(r) / r);
      spare = x;
      scale = sc;
      hasSpare = true;
      return math.exp(m + s * y * sc);
    };
  }

  /// Returns a new [RandomLogNormal] factory using [source].
  RandomLogNormal source(RandomSource source) => RandomLogNormal(source);

  /// Fills [target] with log-normally distributed draws.
  void fill(Float64List target, [num mu = 0, num sigma = 1]) {
    final m = mu.toDouble();
    final s = sigma.toDouble();
    final src = _source;
    final n = target.length;
    var i = 0;
    final pairLimit = n - 1;
    while (i < pairLimit) {
      double x;
      double y;
      double r;
      do {
        x = src() * 2.0 - 1.0;
        y = src() * 2.0 - 1.0;
        r = x * x + y * y;
      } while (r == 0.0 || r > 1.0);
      final scale = math.sqrt(-2.0 * math.log(r) / r);
      target[i++] = math.exp(m + s * y * scale);
      target[i++] = math.exp(m + s * x * scale);
    }
    if (i < n) {
      double x;
      double y;
      double r;
      do {
        x = src() * 2.0 - 1.0;
        y = src() * 2.0 - 1.0;
        r = x * x + y * y;
      } while (r == 0.0 || r > 1.0);
      final scale = math.sqrt(-2.0 * math.log(r) / r);
      target[i] = math.exp(m + s * y * scale);
    }
  }

  /// Allocates a [Float64List] of [count] log-normally distributed draws.
  Float64List sample(int count, [num mu = 0, num sigma = 1]) {
    final out = Float64List(count);
    fill(out, mu, sigma);
    return out;
  }
}

/// Log-normal distribution generator factory backed by [defaultRandomSource].
const RandomLogNormal randomLogNormal = RandomLogNormal(defaultRandomSource);
