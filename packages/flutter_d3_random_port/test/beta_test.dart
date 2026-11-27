// Ported from d3-random v3.0.1 test/beta-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';

double _dmean(double alpha, double beta) => alpha / (alpha + beta);

double _dvariance(double alpha, double beta) =>
    (alpha * beta) / math.pow(alpha + beta, 2) / (alpha + beta + 1);

void main() {
  test('randomBeta(alpha, beta) returns random numbers with a mean of alpha / (alpha + beta)', () {
    final r = randomBeta.source(randomLcg(0.8275880644751501));
    for (final (a, b) in const <(double, double)>[
      (1, 1),
      (1, 2),
      (2, 1),
      (3, 4),
      (0.5, 0.5),
      (2.7, 0.3),
    ]) {
      final g = r(a, b);
      assertInDelta(
        mean(List<double>.generate(10000, (_) => g())),
        _dmean(a, b),
        0.05,
      );
    }
  });

  test('randomBeta(alpha, beta) returns random numbers with a variance of (alpha * beta) / (alpha + beta)^2 / (alpha + beta + 1)', () {
    final r = randomBeta.source(randomLcg(0.8272345925494458));
    for (final (a, b) in const <(double, double)>[
      (1, 1),
      (1, 2),
      (2, 1),
      (3, 4),
      (0.5, 0.5),
      (2.7, 0.3),
    ]) {
      final g = r(a, b);
      assertInDelta(
        variance(List<double>.generate(10000, (_) => g())),
        _dvariance(a, b),
        0.05,
      );
    }
  });
}
