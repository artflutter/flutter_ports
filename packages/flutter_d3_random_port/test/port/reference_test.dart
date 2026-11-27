// Original code, not ported from d3-random: Node.js reference parity tests.

import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'd3_random_reference.dart';

final Map<String, RandomGenerator Function()> _continuousFactories = {
  'uniform_default': () => randomUniform.source(randomLcg(0.42))(),
  'uniform_max': () => randomUniform.source(randomLcg(0.42))(6),
  'uniform_minmax': () => randomUniform.source(randomLcg(0.42))(-5, 10),
  'normal_default': () => randomNormal.source(randomLcg(0.44871573888282423))(),
  'normal_params': () => randomNormal.source(randomLcg(0.42))(42, 2.5),
  'logNormal_default': () => randomLogNormal.source(randomLcg(0.42))(),
  'logNormal_params': () => randomLogNormal.source(randomLcg(0.42))(1.5, 0.5),
  'bates_0': () => randomBates.source(randomLcg(0.42))(0),
  'bates_4': () => randomBates.source(randomLcg(0.42))(4),
  'bates_frac': () => randomBates.source(randomLcg(0.42))(4.2),
  'irwinHall_0': () => randomIrwinHall.source(randomLcg(0.42))(0),
  'irwinHall_4': () => randomIrwinHall.source(randomLcg(0.42))(4),
  'irwinHall_frac': () => randomIrwinHall.source(randomLcg(0.42))(4.2),
  'exponential': () => randomExponential.source(randomLcg(0.42))(0.25),
  'pareto_3': () => randomPareto.source(randomLcg(0.42))(3),
  'gamma_0': () => randomGamma.source(randomLcg(0.42))(0),
  'gamma_0_5': () => randomGamma.source(randomLcg(0.42))(0.5, 2),
  'gamma_1': () => randomGamma.source(randomLcg(0.42))(1, 2.5),
  'gamma_5': () => randomGamma.source(randomLcg(0.42))(5, 1.5),
  'beta_sym': () => randomBeta.source(randomLcg(0.42))(0.5, 0.5),
  'beta_skew': () => randomBeta.source(randomLcg(0.42))(2.7, 0.3),
  'weibull_pos': () => randomWeibull.source(randomLcg(0.42))(3, 1, 2),
  'weibull_gumbel': () => randomWeibull.source(randomLcg(0.42))(0, 1, 2),
  'weibull_frechet': () => randomWeibull.source(randomLcg(0.42))(-3, 1, 2),
  'cauchy': () => randomCauchy.source(randomLcg(0.42))(2, 3),
  'logistic': () => randomLogistic.source(randomLcg(0.42))(2, 3),
};

final Map<String, RandomIntGenerator Function()> _discreteFactories = {
  'int_max': () => randomInt.source(randomLcg(0.42))(10),
  'int_minmax': () => randomInt.source(randomLcg(0.42))(10, 42),
  'int_frac': () => randomInt.source(randomLcg(0.42))(1.7, 5.9),
  'bernoulli_0': () => randomBernoulli.source(randomLcg(0.42))(0),
  'bernoulli_half': () => randomBernoulli.source(randomLcg(0.42))(0.35),
  'bernoulli_1': () => randomBernoulli.source(randomLcg(0.42))(1),
  'geometric_1': () => randomGeometric.source(randomLcg(0.42))(1),
  'geometric_half': () => randomGeometric.source(randomLcg(0.42))(0.25),
  'binomial_0': () => randomBinomial.source(randomLcg(0.42))(100, 0),
  'binomial_1': () => randomBinomial.source(randomLcg(0.42))(100, 1),
  'binomial_small': () => randomBinomial.source(randomLcg(0.42))(20, 0.3),
  'binomial_large': () => randomBinomial.source(randomLcg(0.42))(200, 0.37),
  'poisson_small': () => randomPoisson.source(randomLcg(0.42))(4.5),
  'poisson_large': () => randomPoisson.source(randomLcg(0.42))(250),
};

void main() {
  test(
    'randomLcg produces bit-exact sequences matching Node.js d3-random v3.0.1',
    () {
      for (final (seed, expected) in refLcgSequences) {
        final g = randomLcg(seed);
        for (var i = 0; i < expected.length; ++i) {
          expect(g(), expected[i], reason: 'seed=$seed index=$i');
        }
      }
    },
  );

  test(
    'continuous distributions match Node.js d3-random v3.0.1 seeded draws',
    () {
      for (final (name, expected) in refContinuousDraws) {
        final g = _continuousFactories[name]!();
        for (var i = 0; i < expected.length; ++i) {
          final actual = g();
          final exp = expected[i];
          if (exp == 0.0) {
            expect(actual, 0.0, reason: '$name[$i]');
          } else {
            // Allow <= 1e-12 relative tolerance for libm transcendental ULP
            // differences across V8 / macOS / Linux / Wasm / dart2js.
            final tol = exp.abs() * 1e-12 + 1e-15;
            expect(actual, closeTo(exp, tol), reason: '$name[$i]');
          }
        }
      }
    },
  );

  test('discrete distributions match Node.js d3-random v3.0.1 seeded draws '
      'exactly', () {
    for (final (name, expected) in refDiscreteDraws) {
      final g = _discreteFactories[name]!();
      for (var i = 0; i < expected.length; ++i) {
        expect(g(), expected[i], reason: '$name[$i]');
      }
    }
  });

  test('parameter validation throws RangeError for out-of-range inputs', () {
    expect(() => randomPareto(-0.1), throwsRangeError);
    expect(() => randomBernoulli(-0.1), throwsRangeError);
    expect(() => randomBernoulli(1.1), throwsRangeError);
    expect(() => randomBernoulli(double.nan), throwsRangeError);
    expect(() => randomGeometric(-0.1), throwsRangeError);
    expect(() => randomGeometric(0), throwsRangeError);
    expect(() => randomGeometric(1.1), throwsRangeError);
    expect(() => randomGeometric(double.nan), throwsRangeError);
    expect(() => randomGamma(-1), throwsRangeError);
  });

  test('randomLog1p edge cases and small-magnitude precision', () {
    expect(randomLog1p(0), 0.0);
    expect(randomLog1p(-1), double.negativeInfinity);
    expect(randomLog1p(-2).isNaN, isTrue);
    expect(randomLog1p(double.nan).isNaN, isTrue);
    expect(randomLog1p(double.infinity), double.infinity);
    expect(randomLog1p(1e-17), 1e-17);
    expect(randomLog1p(-1e-12), closeTo(-1e-12 - 5e-25, 1e-24));
  });
}
