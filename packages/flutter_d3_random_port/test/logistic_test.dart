// Ported from d3-random v3.0.1 test/logistic-test.js (ISC, Mike Bostock).
// Upstream test explicitly passes default b = 1 in r(3, 1).
// ignore_for_file: avoid_redundant_argument_values

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'statistics.dart';

double _dvariance(double a, double b) => math.pow(math.pi * b, 2) / 3;

void main() {
  test('randomLogistic(a, b) returns random numbers with a mean of a', () {
    final r = randomLogistic.source(randomLcg(0.8792712826844997));
    final g1 = r();
    assertInDelta(mean(List<double>.generate(10000, (_) => g1())), 0, 0.05);
    final g2 = r(5);
    assertInDelta(mean(List<double>.generate(10000, (_) => g2())), 5, 0.05);
    final g3 = r(0, 4);
    assertInDelta(mean(List<double>.generate(10000, (_) => g3())), 0, 0.1);
    final g4 = r(1, 3);
    assertInDelta(mean(List<double>.generate(10000, (_) => g4())), 1, 0.1);
    final g5 = r(3, 1);
    assertInDelta(mean(List<double>.generate(10000, (_) => g5())), 3, 0.05);
  });

  test('randomLogistic(a, b) returns random numbers with a variance of (b * pi)^2 / 3', () {
    final r = randomLogistic.source(randomLcg(0.5768515852192524));
    final g1 = r();
    assertInDelta(
      variance(List<double>.generate(10000, (_) => g1())),
      _dvariance(0, 1),
      0.2,
    );
    final g2 = r(5);
    assertInDelta(
      variance(List<double>.generate(10000, (_) => g2())),
      _dvariance(5, 1),
      0.2,
    );
    final g3 = r(0, 4);
    assertInDelta(
      variance(List<double>.generate(10000, (_) => g3())),
      _dvariance(0, 4),
      2,
    );
    final g4 = r(1, 3);
    assertInDelta(
      variance(List<double>.generate(10000, (_) => g4())),
      _dvariance(1, 3),
      2,
    );
    final g5 = r(3, 1);
    assertInDelta(
      variance(List<double>.generate(10000, (_) => g5())),
      _dvariance(3, 1),
      2,
    );
  });

  test(
    'randomLogistic(a, b) returns random numbers with a skewness of zero',
    () {
      final r = randomLogistic.source(randomLcg(0.8835033777589203));
      final g1 = r();
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g1())),
        0,
        0.1,
      );
      final g2 = r(5);
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g2())),
        0,
        0.1,
      );
      final g3 = r(0, 4);
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g3())),
        0,
        0.1,
      );
      final g4 = r(1, 3);
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g4())),
        0,
        0.1,
      );
      final g5 = r(3, 1);
      assertInDelta(
        skewness(List<double>.generate(10000, (_) => g5())),
        0,
        0.1,
      );
    },
  );

  test('randomLogistic(a, b) returns random numbers with an excess kurtosis '
      'of 1.2', () {
    final r = randomLogistic.source(randomLcg(0.8738996292947383));
    final g1 = r();
    assertInDelta(
      kurtosis(List<double>.generate(10000, (_) => g1())),
      1.2,
      0.6,
    );
    final g2 = r(5);
    assertInDelta(
      kurtosis(List<double>.generate(10000, (_) => g2())),
      1.2,
      0.6,
    );
    final g3 = r(0, 4);
    assertInDelta(
      kurtosis(List<double>.generate(10000, (_) => g3())),
      1.2,
      0.6,
    );
    final g4 = r(1, 3);
    assertInDelta(
      kurtosis(List<double>.generate(10000, (_) => g4())),
      1.2,
      0.6,
    );
    final g5 = r(3, 1);
    assertInDelta(
      kurtosis(List<double>.generate(10000, (_) => g5())),
      1.2,
      0.6,
    );
  });
}
