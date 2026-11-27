// Original code, not ported from d3-random: faster-form twin tests.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

/// Literal upstream Marsaglia polar normal generator (recomputes `sqrt`/`log`
/// on every draw and captures nullable `double? x`).
RandomGenerator _literalNormal(
  RandomSource source, [
  double mu = 0,
  double sigma = 1,
]) {
  double? x;
  var r = 0.0;
  return () {
    double y;
    if (x != null) {
      y = x!;
      x = null;
    } else {
      do {
        x = source() * 2.0 - 1.0;
        y = source() * 2.0 - 1.0;
        r = x! * x! + y * y;
      } while (r == 0.0 || r > 1.0);
    }
    return mu + sigma * y * math.sqrt(-2.0 * math.log(r) / r);
  };
}

/// Literal upstream gamma generator factory.
RandomGenerator Function(double, [double]) _literalGammaFactory(
  RandomSource source,
) {
  final normal = _literalNormal(source);
  return (double k, [double theta = 1]) {
    if (k == 0.0) return () => 0.0;
    if (k == 1.0) return () => -randomLog1p(-source()) * theta;
    final d = (k < 1.0 ? k + 1.0 : k) - 1.0 / 3.0;
    final c = 1.0 / (3.0 * math.sqrt(d));
    final multiplier = k < 1.0
        ? () => math.pow(source(), 1.0 / k).toDouble()
        : () => 1.0;
    return () {
      double x;
      double v;
      double u;
      do {
        do {
          x = normal();
          v = 1.0 + c * x;
        } while (v <= 0.0);
        v *= v * v;
        u = 1.0 - source();
      } while (u >= 1.0 - 0.0331 * x * x * x * x &&
          math.log(u) >= 0.5 * x * x + d * (1.0 - v + math.log(v)));
      return d * v * multiplier() * theta;
    };
  };
}

/// Literal upstream beta generator factory.
RandomGenerator Function(double, double) _literalBetaFactory(
  RandomSource source,
) {
  final g = _literalGammaFactory(source);
  return (double a, double b) {
    final gx = g(a);
    final gy = g(b);
    return () {
      final x = gx();
      return x == 0.0 ? 0.0 : x / (x + gy());
    };
  };
}

/// Literal upstream geometric generator factory.
RandomIntGenerator Function(double) _literalGeometricFactory(
  RandomSource source,
) => (p) {
  if (p == 1.0) return () => 1;
  final lp = randomLog1p(-p);
  return () => 1 + (randomLog1p(-source()) / lp).floor();
};

/// Literal upstream binomial generator factory.
RandomIntGenerator Function(int, double) _literalBinomialFactory(
  RandomSource source,
) {
  final gFactory = _literalGeometricFactory(source);
  final bFactory = _literalBetaFactory(source);
  return (int n, double p) {
    if (p >= 1.0) return () => n;
    if (p <= 0.0) return () => 0;
    return () {
      var acc = 0;
      var nn = n;
      var pp = p;
      while (nn * pp > 16.0 && nn * (1.0 - pp) > 16.0) {
        final i = ((nn + 1) * pp).floor();
        final y = bFactory(i.toDouble(), (nn - i + 1).toDouble())();
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
      final g = gFactory(pFinal);
      var s = g();
      var k = 0;
      for (; s <= nn; ++k) {
        s += g();
      }
      return acc + (sign ? k : nn - k);
    };
  };
}

/// Literal upstream Poisson generator factory.
RandomIntGenerator Function(double) _literalPoissonFactory(
  RandomSource source,
) {
  final gFactory = _literalGammaFactory(source);
  final bFactory = _literalBinomialFactory(source);
  return (double lambda) => () {
    var acc = 0;
    var l = lambda;
    while (l > 16.0) {
      final n = (0.875 * l).floor();
      final t = gFactory(n.toDouble())();
      if (t > l) return acc + bFactory(n - 1, l / t)();
      acc += n;
      l -= t;
    }
    var s = -randomLog1p(-source());
    var k = 0;
    for (; s <= l; ++k) {
      s -= randomLog1p(-source());
    }
    return acc + k;
  };
}

/// Literal upstream Irwin-Hall generator.
RandomGenerator _literalIrwinHall(RandomSource source, double n) {
  if (n <= 0.0) return () => 0.0;
  return () {
    var sum = 0.0;
    var i = n;
    for (; i > 1.0; --i) {
      sum += source();
    }
    return sum + i * source();
  };
}

void main() {
  test('optimized randomNormal and randomLogNormal are bit-exact with '
      'literal twins', () {
    for (final (mu, sigma) in const <(double, double)>[
      (0, 1),
      (42, 2.5),
      (-3.5, 0.25),
    ]) {
      final opt = randomNormal.source(randomLcg(0.42))(mu, sigma);
      final lit = _literalNormal(randomLcg(0.42), mu, sigma);
      for (var i = 0; i < 500; ++i) {
        expect(opt(), lit(), reason: 'normal($mu, $sigma)[$i]');
      }

      final optLog = randomLogNormal.source(randomLcg(0.42))(mu, sigma);
      final litLog = _literalNormal(randomLcg(0.42), mu, sigma);
      for (var i = 0; i < 500; ++i) {
        expect(
          optLog(),
          math.exp(litLog()),
          reason: 'logNormal($mu, $sigma)[$i]',
        );
      }
    }
  });

  test(
    'optimized randomGamma and randomBeta are bit-exact with literal twins',
    () {
      for (final (k, theta) in const <(double, double)>[
        (0, 1),
        (0.3, 2),
        (1, 2.5),
        (5, 1.5),
      ]) {
        final opt = randomGamma.source(randomLcg(0.42))(k, theta);
        final lit = _literalGammaFactory(randomLcg(0.42))(k, theta);
        for (var i = 0; i < 300; ++i) {
          expect(opt(), lit(), reason: 'gamma($k, $theta)[$i]');
        }
      }

      for (final (a, b) in const <(double, double)>[
        (0.5, 0.5),
        (2.7, 0.3),
        (3, 4),
      ]) {
        final opt = randomBeta.source(randomLcg(0.42))(a, b);
        final lit = _literalBetaFactory(randomLcg(0.42))(a, b);
        for (var i = 0; i < 300; ++i) {
          expect(opt(), lit(), reason: 'beta($a, $b)[$i]');
        }
      }
    },
  );

  test(
    'optimized randomBinomial and randomPoisson are exact with literal twins',
    () {
      for (final (n, p) in const <(int, double)>[
        (100, 0),
        (100, 1),
        (20, 0.3),
        (200, 0.37),
        (500, 0.85),
      ]) {
        final opt = randomBinomial.source(randomLcg(0.42))(n, p);
        final lit = _literalBinomialFactory(randomLcg(0.42))(n, p);
        for (var i = 0; i < 200; ++i) {
          expect(opt(), lit(), reason: 'binomial($n, $p)[$i]');
        }
      }

      for (final lambda in const <double>[0.5, 4.5, 16, 40, 250]) {
        final opt = randomPoisson.source(randomLcg(0.42))(lambda);
        final lit = _literalPoissonFactory(randomLcg(0.42))(lambda);
        for (var i = 0; i < 200; ++i) {
          expect(opt(), lit(), reason: 'poisson($lambda)[$i]');
        }
      }
    },
  );

  test('optimized randomIrwinHall, randomBates, randomWeibull, and '
      'randomBernoulli match literal twins', () {
    for (final n in const <double>[0, 1, 4, 4.2, 10]) {
      final optIh = randomIrwinHall.source(randomLcg(0.42))(n);
      final litIh = _literalIrwinHall(randomLcg(0.42), n);
      for (var i = 0; i < 200; ++i) {
        expect(optIh(), litIh(), reason: 'irwinHall($n)[$i]');
      }

      if (n > 0) {
        final optBates = randomBates.source(randomLcg(0.42))(n);
        final litBates = _literalIrwinHall(randomLcg(0.42), n);
        for (var i = 0; i < 200; ++i) {
          expect(optBates(), litBates() / n, reason: 'bates($n)[$i]');
        }
      }
    }

    for (final p in const <double>[0, 0.25, 0.5, 0.9, 1]) {
      final opt = randomBernoulli.source(randomLcg(0.42))(p);
      final src = randomLcg(0.42);
      for (var i = 0; i < 200; ++i) {
        expect(opt(), (src() + p).floor(), reason: 'bernoulli($p)[$i]');
      }
    }

    for (final k in const <double>[-3, 0, 3]) {
      final opt = randomWeibull.source(randomLcg(0.42))(k, 1, 2);
      final src = randomLcg(0.42);
      for (var i = 0; i < 200; ++i) {
        final e = -randomLog1p(-src());
        final lit = k == 0
            ? 1.0 + 2.0 * -math.log(e)
            : 1.0 + 2.0 * math.pow(e, 1.0 / k);
        expect(opt(), lit, reason: 'weibull($k)[$i]');
      }
    }
  });

  test(
    'typed batch fill and sample helpers match per-call generators bit-for-bit',
    () {
      const count = 127; // Odd count verifies paired-loop tail handling.

      void checkDouble(
        String label,
        RandomGenerator single,
        Float64List batch,
      ) {
        expect(batch, hasLength(count));
        for (var i = 0; i < count; ++i) {
          expect(batch[i], single(), reason: '$label[$i]');
        }
      }

      void checkInt(String label, RandomIntGenerator single, Int32List batch) {
        expect(batch, hasLength(count));
        for (var i = 0; i < count; ++i) {
          expect(batch[i], single(), reason: '$label[$i]');
        }
      }

      checkDouble('lcg', randomLcg(0.42), randomLcg(0.42).sample(count));
      checkDouble(
        'uniform',
        randomUniform.source(randomLcg(0.42))(-5, 10),
        randomUniform.source(randomLcg(0.42)).sample(count, -5, 10),
      );
      checkDouble(
        'normal',
        randomNormal.source(randomLcg(0.42))(10, 3),
        randomNormal.source(randomLcg(0.42)).sample(count, 10, 3),
      );
      checkDouble(
        'logNormal',
        randomLogNormal.source(randomLcg(0.42))(1, 0.5),
        randomLogNormal.source(randomLcg(0.42)).sample(count, 1, 0.5),
      );
      checkDouble(
        'bates',
        randomBates.source(randomLcg(0.42))(4.2),
        randomBates.source(randomLcg(0.42)).sample(count, 4.2),
      );
      checkDouble(
        'irwinHall',
        randomIrwinHall.source(randomLcg(0.42))(4),
        randomIrwinHall.source(randomLcg(0.42)).sample(count, 4),
      );
      checkDouble(
        'exponential',
        randomExponential.source(randomLcg(0.42))(0.25),
        randomExponential.source(randomLcg(0.42)).sample(count, 0.25),
      );
      checkDouble(
        'pareto',
        randomPareto.source(randomLcg(0.42))(3),
        randomPareto.source(randomLcg(0.42)).sample(count, 3),
      );
      checkDouble(
        'gamma',
        randomGamma.source(randomLcg(0.42))(0.5, 2),
        randomGamma.source(randomLcg(0.42)).sample(count, 0.5, 2),
      );
      checkDouble(
        'beta',
        randomBeta.source(randomLcg(0.42))(2.7, 0.3),
        randomBeta.source(randomLcg(0.42)).sample(count, 2.7, 0.3),
      );
      checkDouble(
        'weibull',
        randomWeibull.source(randomLcg(0.42))(3, 1, 2),
        randomWeibull.source(randomLcg(0.42)).sample(count, 3, 1, 2),
      );
      checkDouble(
        'cauchy',
        randomCauchy.source(randomLcg(0.42))(2, 3),
        randomCauchy.source(randomLcg(0.42)).sample(count, 2, 3),
      );
      checkDouble(
        'logistic',
        randomLogistic.source(randomLcg(0.42))(2, 3),
        randomLogistic.source(randomLcg(0.42)).sample(count, 2, 3),
      );
      checkInt(
        'int',
        randomInt.source(randomLcg(0.42))(10, 42),
        randomInt.source(randomLcg(0.42)).sample(count, 10, 42),
      );
      checkInt(
        'bernoulli',
        randomBernoulli.source(randomLcg(0.42))(0.35),
        randomBernoulli.source(randomLcg(0.42)).sample(count, 0.35),
      );
      checkInt(
        'geometric',
        randomGeometric.source(randomLcg(0.42))(0.25),
        randomGeometric.source(randomLcg(0.42)).sample(count, 0.25),
      );
      checkInt(
        'binomial',
        randomBinomial.source(randomLcg(0.42))(200, 0.37),
        randomBinomial.source(randomLcg(0.42)).sample(count, 200, 0.37),
      );
      checkInt(
        'poisson',
        randomPoisson.source(randomLcg(0.42))(50),
        randomPoisson.source(randomLcg(0.42)).sample(count, 50),
      );
    },
  );

  test(
    'randomLog1m matches randomLog1p(-u) on 32-bit LCG and 53-bit tiny values',
    () {
      final lcg = randomLcg(0.42);
      for (var i = 0; i < 1000; ++i) {
        final u = lcg();
        expect(randomLog1m(u), randomLog1p(-u));
      }
      for (final u in const <double>[
        0,
        1e-18,
        1e-12,
        1e-7,
        0.25,
        0.5,
        0.999999,
      ]) {
        expect(randomLog1m(u), closeTo(randomLog1p(-u), 1e-15));
      }
    },
  );
}
