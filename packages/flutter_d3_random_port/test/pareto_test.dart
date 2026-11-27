// Ported from d3-random v3.0.1 test/pareto-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';

double _ddeviation(num n) => math.sqrt(n / ((n - 1) * (n - 1) * (n - 2)));

void main() {
  test('randomPareto() returns randoms with specified mean', () {
    final r = randomPareto.source(randomLcg(0.6165632948194271));
    final g0 = r(0);
    expect(mean(List<double>.generate(10000, (_) => g0())), double.infinity);
    final g1 = r(1);
    expect(mean(List<double>.generate(10000, (_) => g1())), greaterThan(8));
    final g3 = r(3);
    assertInDelta(mean(List<double>.generate(10000, (_) => g3())), 1.5, 0.4);
    final g5 = r(5);
    assertInDelta(mean(List<double>.generate(10000, (_) => g5())), 1.25, 0.1);
    final g11 = r(11);
    assertInDelta(mean(List<double>.generate(10000, (_) => g11())), 1.1, 0.1);
  });

  test('randomPareto() returns randoms with specified deviation', () {
    final r = randomPareto.source(randomLcg(0.5733127851951378));
    final g0 = r(0);
    expect(deviation(List<double>.generate(10000, (_) => g0()))!.isNaN, isTrue);
    final g1 = r(1);
    expect(
      deviation(List<double>.generate(10000, (_) => g1())),
      greaterThan(70),
    );
    final g3 = r(3);
    assertInDelta(
      deviation(List<double>.generate(10000, (_) => g3())),
      _ddeviation(3),
      0.5,
    );
    final g5 = r(5);
    assertInDelta(
      deviation(List<double>.generate(10000, (_) => g5())),
      _ddeviation(5),
      0.05,
    );
    final g11 = r(11);
    assertInDelta(
      deviation(List<double>.generate(10000, (_) => g11())),
      _ddeviation(11),
      0.05,
    );
  });

  test(
    'randomPareto(3) returns randoms with mean of 1.5 and deviation of 0.9',
    () {
      final r = randomPareto.source(randomLcg(0.9341538627900958));
      final g1 = r(3);
      assertInDelta(
        deviation(List<double>.generate(10000, (_) => g1())),
        0.9,
        0.2,
      );
      final g2 = r(3);
      assertInDelta(mean(List<double>.generate(10000, (_) => g2())), 1.5, 0.05);
    },
  );
}
