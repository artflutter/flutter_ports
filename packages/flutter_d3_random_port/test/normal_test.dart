// Ported from d3-random v3.0.1 test/normal-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('randomNormal() returns random numbers with a mean of zero', () {
    final r = randomNormal.source(randomLcg(0.3193923539476107));
    final g = r();
    assertInDelta(mean(List<double>.generate(10000, (_) => g())), 0, 0.05);
  });

  test(
    'randomNormal() returns random numbers with a standard deviation of one',
    () {
      final r = randomNormal.source(randomLcg(0.5618016004747401));
      final g = r();
      assertInDelta(
        deviation(List<double>.generate(10000, (_) => g())),
        1,
        0.05,
      );
    },
  );

  test('randomNormal(mu) returns random numbers with the specified mean', () {
    final r = randomNormal.source(randomLcg(0.22864660166790118));
    final g1 = r(42);
    assertInDelta(mean(List<double>.generate(10000, (_) => g1())), 42, 0.05);
    final g2 = r(-2);
    assertInDelta(mean(List<double>.generate(10000, (_) => g2())), -2, 0.05);
  });

  test(
    'randomNormal(mu) returns random numbers with a standard deviation of 1',
    () {
      final r = randomNormal.source(randomLcg(0.1274290504810609));
      final g1 = r(42);
      assertInDelta(
        deviation(List<double>.generate(10000, (_) => g1())),
        1,
        0.05,
      );
      final g2 = r(-2);
      assertInDelta(
        deviation(List<double>.generate(10000, (_) => g2())),
        1,
        0.05,
      );
    },
  );

  test('randomNormal(mu, sigma) returns random numbers with the specified mean '
      'and standard deviation', () {
    final r = randomNormal.source(randomLcg(0.49113635631389463));
    final g1 = r(42, 2);
    assertInDelta(mean(List<double>.generate(10000, (_) => g1())), 42, 0.05);
    final g2 = r(-2, 2);
    assertInDelta(mean(List<double>.generate(10000, (_) => g2())), -2, 0.05);
    final g3 = r(42, 2);
    assertInDelta(
      deviation(List<double>.generate(10000, (_) => g3())),
      2,
      0.05,
    );
    final g4 = r(-2, 2);
    assertInDelta(
      deviation(List<double>.generate(10000, (_) => g4())),
      2,
      0.05,
    );
  });
}
