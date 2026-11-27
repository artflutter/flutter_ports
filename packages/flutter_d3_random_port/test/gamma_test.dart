// Ported from d3-random v3.0.1 test/gamma-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'statistics.dart';

void main() {
  test('randomGamma(k) returns random numbers with a mean of k', () {
    final r = randomGamma.source(randomLcg(0.8177609532536807));
    for (final (k, delta) in const <(double, double)>[
      (0.1, 0.01),
      (0.5, 0.05),
      (1, 0.05),
      (2, 0.05),
      (10, 0.05),
    ]) {
      final g = r(k);
      assertInDelta(mean(List<double>.generate(10000, (_) => g())), k, delta);
    }
  });

  test('randomGamma(k) returns random numbers with a variance of k', () {
    final r = randomGamma.source(randomLcg(0.6494198931625885));
    for (final (k, delta) in const <(double, double)>[
      (0.1, 0.005),
      (0.5, 0.05),
      (1, 0.05),
      (2, 0.1),
      (10, 0.5),
    ]) {
      final g = r(k);
      assertInDelta(
        variance(List<double>.generate(10000, (_) => g())),
        k,
        delta,
      );
    }
  });

  test(
    'randomGamma(k) returns random numbers with a skewness of 2 / sqrt(k)',
    () {
      final r = randomGamma.source(randomLcg(0.02223371708142996));
      final g1 = r(0.1);
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g1())),
        math.sqrt(40),
        1,
      );
      final g2 = r(0.5);
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g2())),
        math.sqrt(8),
        0.25,
      );
      final g3 = r(1);
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g3())),
        2,
        0.1,
      );
      final g4 = r(2);
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g4())),
        math.sqrt(2),
        0.1,
      );
      final g5 = r(10);
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g5())),
        math.sqrt(0.4),
        0.05,
      );
    },
  );

  test(
    'randomGamma(k) returns random numbers with an excess kurtosis of 6 / k',
    () {
      final r = randomGamma.source(randomLcg(0.19568718910927974));
      for (final (k, expected, delta) in const <(double, double, double)>[
        (0.1, 60, 15),
        (0.5, 12, 3),
        (1, 6, 1.5),
        (2, 3, 1),
        (10, 0.6, 0.2),
      ]) {
        final g = r(k);
        assertInDelta(
          kurtosis(List<double>.generate(10000, (_) => g())),
          expected,
          delta,
        );
      }
    },
  );

  test('randomGamma(k, theta) returns random numbers with a mean of k * theta '
      'and a variance of k * theta^2', () {
    final r = randomGamma.source(randomLcg(0.9608725416165995));
    final g1 = r(1, 2);
    assertInDelta(mean(List<double>.generate(10000, (_) => g1())), 2, 0.05);
    final g2 = r(2, 4);
    assertInDelta(mean(List<double>.generate(10000, (_) => g2())), 8, 0.2);
    final g3 = r(1, 2);
    assertInDelta(deviation(List<double>.generate(10000, (_) => g3())), 2, 0.1);
    final g4 = r(2, 4);
    assertInDelta(
      deviation(List<double>.generate(10000, (_) => g4())),
      math.sqrt(2) * 4,
      0.1,
    );
  });
}
