// Ported from d3-random v3.0.1 src/gamma.js (ISC, Mike Bostock).

/// Port of `src/gamma.js` of d3-random 3.0.1.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_random_port/src/defaultSource.dart';
import 'package:flutter_d3_random_port/src/normal.dart';

// DIVERGES(d3-random): adapt-random-typed-api, typed callable factory class
// with .source(RandomSource) preserving upstream's shared normal generator.
// DIVERGES(d3-random): adapt-random-fast-forms, direct NormalPolarState calls
// eliminating closure dispatch, specialized k < 1 vs k >= 1 branches removing
// multiplier closures, and zero-allocation sampleOne/sampleMarsagliaTsang
// entry points for beta and poisson.
/// Factory for gamma distribution generators with shape `k >= 0` and scale
/// `theta` (default `1`).
final class RandomGamma(final RandomSource _source) {
  /// Creates a [RandomGamma] factory backed by [_source].
  this;

  final NormalPolarState _normal = NormalPolarState(_source, 0, 1);

  /// Draws a single Marsaglia-Tsang variate for precomputed [d] and [c]
  /// (`k > 1`, `theta = 1`).
  @pragma('vm:prefer-inline')
  double sampleMarsagliaTsang(double d, double c) {
    final src = _source;
    final normal = _normal;
    double x;
    double v;
    double u;
    do {
      do {
        x = normal.nextStandard();
        v = 1.0 + c * x;
      } while (v <= 0.0);
      v *= v * v;
      u = 1.0 - src();
    } while (u >= 1.0 - 0.0331 * x * x * x * x &&
        math.log(u) >= 0.5 * x * x + d * (1.0 - v + math.log(v)));
    return d * v;
  }

  /// Draws a single gamma variate with shape [kd] and scale [td] without
  /// allocating a generator closure.
  @pragma('vm:prefer-inline')
  double sampleOne(double kd, double td) {
    if (kd < 0.0) throw RangeError('invalid k');
    if (kd == 0.0) return 0;
    if (kd == 1.0) return -randomLog1m(_source()) * td;
    final d = (kd < 1.0 ? kd + 1.0 : kd) - 1.0 / 3.0;
    final c = 1.0 / (3.0 * math.sqrt(d));
    final dv = sampleMarsagliaTsang(d, c);
    if (kd < 1.0) {
      return dv * math.pow(_source(), 1.0 / kd).toDouble() * td;
    }
    return dv * td;
  }

  /// Returns a generator for gamma distributed numbers with shape [k] and
  /// scale [theta].
  ///
  /// Throws a [RangeError] if [k] is negative.
  RandomGenerator call(num k, [num theta = 1]) {
    final kd = k.toDouble();
    if (kd < 0.0) throw RangeError('invalid k');
    if (kd == 0.0) return () => 0.0;
    final td = theta.toDouble();
    final src = _source;
    if (kd == 1.0) return () => -randomLog1m(src()) * td;

    final d = (kd < 1.0 ? kd + 1.0 : kd) - 1.0 / 3.0;
    final c = 1.0 / (3.0 * math.sqrt(d));
    if (kd < 1.0) {
      final invK = 1.0 / kd;
      return () =>
          sampleMarsagliaTsang(d, c) * math.pow(src(), invK).toDouble() * td;
    }
    return () => sampleMarsagliaTsang(d, c) * td;
  }

  /// Returns a new [RandomGamma] factory using [source].
  RandomGamma source(RandomSource source) => RandomGamma(source);

  /// Fills [target] with gamma distributed draws.
  void fill(Float64List target, num k, [num theta = 1]) {
    final kd = k.toDouble();
    if (kd < 0.0) throw RangeError('invalid k');
    final n = target.length;
    if (kd == 0.0) {
      target.fillRange(0, n, 0);
      return;
    }
    final td = theta.toDouble();
    final src = _source;
    if (kd == 1.0) {
      for (var i = 0; i < n; ++i) {
        target[i] = -randomLog1m(src()) * td;
      }
      return;
    }
    final d = (kd < 1.0 ? kd + 1.0 : kd) - 1.0 / 3.0;
    final c = 1.0 / (3.0 * math.sqrt(d));
    if (kd < 1.0) {
      final invK = 1.0 / kd;
      for (var i = 0; i < n; ++i) {
        target[i] =
            sampleMarsagliaTsang(d, c) * math.pow(src(), invK).toDouble() * td;
      }
    } else {
      for (var i = 0; i < n; ++i) {
        target[i] = sampleMarsagliaTsang(d, c) * td;
      }
    }
  }

  /// Allocates a [Float64List] of [count] gamma distributed draws.
  Float64List sample(int count, num k, [num theta = 1]) {
    final out = Float64List(count);
    fill(out, k, theta);
    return out;
  }
}

/// Gamma distribution generator factory backed by [defaultRandomSource].
final RandomGamma randomGamma = RandomGamma(defaultRandomSource);
