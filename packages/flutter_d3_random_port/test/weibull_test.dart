// Ported from d3-random v3.0.1 test/weibull-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('randomWeibull() returns random numbers with the specified mean', () {
    final r = randomWeibull.source(randomLcg(0.28845828610535373));
    for (final (k, expected, delta) in const <(double, double, double)>[
      (9, 0.947, 0.1),
      (3, 0.893, 0.1),
      (1, 1, 0.1),
      (0.3, 9.260, 1),
      (0, 0.577, 0.1),
      (-3, 1.354, 0.1),
      (-9, 1.078, 0.1),
    ]) {
      final g = r(k);
      assertInDelta(
        mean(List<double>.generate(10000, (_) => g())),
        expected,
        delta,
      );
    }
    final g8 = r(4, 1, 2);
    assertInDelta(mean(List<double>.generate(10000, (_) => g8())), 2.813, 0.2);
    final g9 = r(-4, 1, 2);
    assertInDelta(mean(List<double>.generate(10000, (_) => g9())), 3.451, 0.2);
  });

  test(
    'randomWeibull() returns random numbers with the specified deviation',
    () {
      final r = randomWeibull.source(randomLcg(0.6675582430306972));
      for (final (k, expected, delta) in const <(double, double, double)>[
        (9, 0.126, 0.02),
        (3, 0.324, 0.06),
        (1, 1, 0.2),
      ]) {
        final g = r(k);
        assertInDelta(
          deviation(List<double>.generate(10000, (_) => g())),
          expected,
          delta,
        );
      }
      final g4 = r(0.3);
      expect(
        deviation(List<double>.generate(10000, (_) => g4())),
        greaterThan(30),
      );
      for (final (k, expected, delta) in const <(double, double, double)>[
        (0, 1.282, 0.05),
        (-3, 0.919, 0.4),
        (-9, 0.169, 0.02),
      ]) {
        final g = r(k);
        assertInDelta(
          deviation(List<double>.generate(10000, (_) => g())),
          expected,
          delta,
        );
      }
      final g8 = r(4, 1, 2);
      assertInDelta(
        deviation(List<double>.generate(10000, (_) => g8())),
        0.509,
        0.1,
      );
      final g9 = r(-4, 1, 2);
      assertInDelta(
        deviation(List<double>.generate(10000, (_) => g9())),
        1.0408,
        0.1,
      );
    },
  );
}
