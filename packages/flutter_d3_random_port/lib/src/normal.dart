// Ported from d3-random v3.0.1 src/normal.js (ISC, Mike Bostock).

/// Port of `src/normal.js` of d3-random 3.0.1.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';

/// Stateful Marsaglia polar sampler with unboxed fields and cached radial
/// scaling factor (reused across the paired draw for bit-exact output with half
/// the `log` and `sqrt` evaluations).
final class NormalPolarState(
  final RandomSource _source,
  final double _mu,
  final double _sigma,
) {
  /// Creates a [NormalPolarState] with mean [_mu] and standard deviation
  /// [_sigma] drawing from [_source].
  this;

  double _spare = 0;
  double _scale = 0;
  bool _hasSpare = false;

  /// Draws the next standard normal variate (`mu = 0, sigma = 1`).
  @pragma('vm:prefer-inline')
  double nextStandard() {
    if (_hasSpare) {
      _hasSpare = false;
      return _spare * _scale;
    }
    final src = _source;
    double x;
    double y;
    double r;
    do {
      x = src() * 2.0 - 1.0;
      y = src() * 2.0 - 1.0;
      r = x * x + y * y;
    } while (r == 0.0 || r > 1.0);
    final scale = math.sqrt(-2.0 * math.log(r) / r);
    _spare = x;
    _scale = scale;
    _hasSpare = true;
    return y * scale;
  }

  /// Draws the next normal variate with mean `_mu` and standard deviation
  /// `_sigma`.
  @pragma('vm:prefer-inline')
  double next() {
    if (_hasSpare) {
      _hasSpare = false;
      return _mu + _sigma * _spare * _scale;
    }
    final src = _source;
    double x;
    double y;
    double r;
    do {
      x = src() * 2.0 - 1.0;
      y = src() * 2.0 - 1.0;
      r = x * x + y * y;
    } while (r == 0.0 || r > 1.0);
    final scale = math.sqrt(-2.0 * math.log(r) / r);
    _spare = x;
    _scale = scale;
    _hasSpare = true;
    return _mu + _sigma * y * scale;
  }
}

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) and typed batch helpers.
// DIVERGES(d3-random): adapt-random-fast-forms, unboxed Marsaglia polar state
// caching sqrt(-2 * log(r) / r) across paired draws and paired batch fill.
/// Factory for normal (Gaussian) distribution generators with mean `mu` and
/// standard deviation `sigma`.
final class const RandomNormal(final RandomSource _source) {
  /// Creates a [RandomNormal] factory backed by [_source].
  this;

  /// Returns a generator for normally distributed numbers with mean [mu] and
  /// standard deviation [sigma].
  RandomGenerator call([num mu = 0, num sigma = 1]) =>
      NormalPolarState(_source, mu.toDouble(), sigma.toDouble()).next;

  /// Returns a new [RandomNormal] factory using [source].
  RandomNormal source(RandomSource source) => RandomNormal(source);

  /// Fills [target] with normally distributed draws in paired Marsaglia polar
  /// steps.
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
      target[i++] = m + s * y * scale;
      target[i++] = m + s * x * scale;
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
      target[i] = m + s * y * scale;
    }
  }

  /// Allocates a [Float64List] of [count] normally distributed draws.
  Float64List sample(int count, [num mu = 0, num sigma = 1]) {
    final out = Float64List(count);
    fill(out, mu, sigma);
    return out;
  }
}

/// Normal (Gaussian) distribution generator factory backed by
/// [defaultRandomSource].
const RandomNormal randomNormal = RandomNormal(defaultRandomSource);
