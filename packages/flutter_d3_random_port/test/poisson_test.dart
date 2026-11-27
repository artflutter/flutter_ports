// Ported from d3-random v3.0.1 test/poisson-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'statistics.dart';

void main() {
  test(
    'randomPoisson(lambda) returns random numbers with a mean of lambda',
    () {
      final r = randomPoisson.source(randomLcg(0.48758044703454373));
      final g0 = r(0.001);
      assertInDelta(
        mean(List<int>.generate(100000, (_) => g0())),
        0.001,
        0.0005,
      );
      for (final (lambda, delta) in const <(double, double)>[
        (0.1, 0.01),
        (0.5, 0.05),
        (1, 0.05),
        (2, 0.1),
        (10, 0.5),
        (1000, 20),
      ]) {
        final g = r(lambda);
        assertInDelta(
          mean(List<int>.generate(10000, (_) => g())),
          lambda,
          delta,
        );
      }
    },
  );

  test(
    'randomPoisson(lambda) returns random numbers with a variance of lambda',
    () {
      final r = randomPoisson.source(randomLcg(0.4777559867161436));
      final g0 = r(0.001);
      assertInDelta(
        variance(List<int>.generate(100000, (_) => g0())),
        0.001,
        0.0005,
      );
      for (final (lambda, delta) in const <(double, double)>[
        (0.1, 0.01),
        (0.5, 0.05),
        (1, 0.05),
        (2, 0.1),
        (10, 0.5),
        (1000, 20),
      ]) {
        final g = r(lambda);
        assertInDelta(
          variance(List<int>.generate(10000, (_) => g())),
          lambda,
          delta,
        );
      }
    },
  );

  test('randomPoisson(lambda) returns random numbers with a skewness of 1 / sqrt(lambda)', () {
    final r = randomPoisson.source(randomLcg(0.09357670133206075));
    final g0 = r(0.001);
    assertInDelta(skewness(List<int>.generate(100000, (_) => g0())), 31.6, 5);
    for (final (lambda, expected, delta) in const <(double, double, double)>[
      (0.1, 3.16, 0.2),
      (0.5, 1.414, 0.1),
      (1, 1, 0.1),
      (2, 0.707, 0.05),
      (10, 0.316, 0.05),
      (1000, 0.0316, 0.05),
    ]) {
      final g = r(lambda);
      assertInDelta(
        skewness(List<int>.generate(10000, (_) => g())),
        expected,
        delta,
      );
    }
  });

  test('randomPoisson(lambda) returns random numbers with a kurtosis excess of 1 / lambda', () {
    final r = randomPoisson.source(randomLcg(0.3299530136090847));
    final g0 = r(0.001);
    assertInDelta(kurtosis(List<int>.generate(100000, (_) => g0())), 1000, 200);
    for (final (lambda, expected, delta) in const <(double, double, double)>[
      (0.1, 10, 2),
      (0.5, 2, 0.5),
      (1, 1, 0.5),
      (2, 0.5, 0.2),
      (10, 0.1, 0.1),
      (1000, 0.001, 0.1),
    ]) {
      final g = r(lambda);
      assertInDelta(
        kurtosis(List<int>.generate(10000, (_) => g())),
        expected,
        delta,
      );
    }
  });
}
