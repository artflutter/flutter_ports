// Ported from d3-random v3.0.1 test/bates-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'statistics.dart';

void main() {
  test('randomBates(n) returns random numbers with a mean of one-half', () {
    final r = randomBates.source(randomLcg(0.6351090615932817));
    for (final n in const <num>[1, 10, 1.5, 4.2]) {
      final g = r(n);
      assertInDelta(mean(List<double>.generate(10000, (_) => g())), 0.5, 0.05);
    }
  });

  test(
    'randomBates(n) returns random numbers with a variance of 1 / (12 * n)',
    () {
      final r = randomBates.source(randomLcg(0.1284832084868286));
      final g1 = r(1);
      assertInDelta(
        variance(List<double>.generate(10000, (_) => g1())),
        1 / 12,
        0.05,
      );
      final g2 = r(10);
      assertInDelta(
        variance(List<double>.generate(10000, (_) => g2())),
        1 / 120,
        0.05,
      );
      final g3 = r(1.5);
      assertInDelta(
        variance(List<double>.generate(10000, (_) => g3())),
        1 / 18,
        0.05,
      );
      final g4 = r(4.2);
      assertInDelta(
        variance(List<double>.generate(10000, (_) => g4())),
        1 / 50.4,
        0.05,
      );
    },
  );

  test('randomBates(n) returns random numbers with a skewness of 0', () {
    final r = randomBates.source(randomLcg(0.051567609139606674));
    for (final n in const <num>[1, 10, 1.5, 4.2]) {
      final g = r(n);
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g())),
        0,
        0.05,
      );
    }
  });

  test(
    'randomBates(n) returns random numbers with a kurtosis of -6 / (5 * n)',
    () {
      final r = randomBates.source(randomLcg(0.696913354780724));
      final g1 = r(1);
      assertInDelta(
        kurtosis(List<double>.generate(10000, (_) => g1())),
        -6 / 5,
        0.05,
      );
      final g2 = r(10);
      assertInDelta(
        kurtosis(List<double>.generate(10000, (_) => g2())),
        -6 / 50,
        0.1,
      );
      final g3 = r(1.5);
      assertInDelta(
        kurtosis(List<double>.generate(10000, (_) => g3())),
        -6 / 7.5,
        0.05,
      );
      final g4 = r(4.2);
      assertInDelta(
        kurtosis(List<double>.generate(10000, (_) => g4())),
        -6 / 21,
        0.05,
      );
    },
  );

  test('randomBates(0) is equivalent to randomUniform()', () {
    final r = randomBates.source(randomLcg(0.7717596603725383));
    final g1 = r(0);
    assertInDelta(mean(List<double>.generate(10000, (_) => g1())), 0.5, 0.05);
    final g2 = r(0);
    assertInDelta(
      variance(List<double>.generate(10000, (_) => g2())),
      1 / 12,
      0.05,
    );
    final g3 = r(0);
    assertInDelta(skewness(List<double>.generate(10000, (_) => g3())), 0, 0.05);
    final g4 = r(0);
    assertInDelta(
      kurtosis(List<double>.generate(10000, (_) => g4())),
      -6 / 5,
      0.05,
    );
  });
}
