// Ported from d3-random v3.0.1 test/geometric-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'statistics.dart';

double _dmean(double p) => 1 / p;
double _dvariance(double p) => (1 - p) / math.pow(p, 2);
double _skew(double p) => (2 - p) / math.sqrt(1 - p);
double _kurt(double p) => (math.pow(p, 2) - 6 * p + 6) / (1 - p);

void main() {
  test('randomGeometric(p) returns random geometrically distributed numbers with a mean of 1 / p.', () {
    final r = randomGeometric.source(randomLcg(0.7687729138471455));
    for (final p in const <double>[1, 0.5, 0.25, 0.125]) {
      final g = r(p);
      assertInDelta(
        mean(List<int>.generate(10000, (_) => g())),
        _dmean(p),
        _dvariance(p),
      );
    }
  });

  test('randomGeometric(p) returns random geometrically distributed numbers with a dvariance of (1 - p) / p^2.', () {
    final r = randomGeometric.source(randomLcg(0.7194220774328326));
    for (final p in const <double>[1, 0.5, 0.25, 0.125]) {
      final g = r(p);
      assertInDelta(
        variance(List<int>.generate(10000, (_) => g())),
        _dvariance(p),
        _dvariance(p) * 0.05,
      );
    }
  });

  test('randomGeometric(p) returns random geometrically distributed numbers with a skewness of (2 - p) / sqrt(1 - p).', () {
    final r = randomGeometric.source(randomLcg(0.016030992648006448));
    final g1 = r(0.5);
    assertInDelta(
      skewness(List<int>.generate(10000, (_) => g1())),
      _skew(0.5),
      0.05 * _skew(0.5),
    );
    final g2 = r(0.25);
    assertInDelta(
      skewness(List<int>.generate(10000, (_) => g2())),
      _skew(0.25),
      0.05 * _skew(0.25),
    );
    final g3 = r(0.125);
    assertInDelta(
      skewness(List<int>.generate(10000, (_) => g3())),
      _skew(0.125),
      0.1 * _skew(0.125),
    );
  });

  test('randomGeometric(p) returns random geometrically distributed numbers with a kurtosis excess of (p^2 - 6 * p + 6) / (1 - p).', () {
    final r = randomGeometric.source(randomLcg(0.4039802168183795));
    final g1 = r(0.5);
    assertInDelta(
      kurtosis(List<int>.generate(20000, (_) => g1())),
      _kurt(0.5),
      0.2 * _kurt(0.5),
    );
    final g2 = r(0.25);
    assertInDelta(
      kurtosis(List<int>.generate(20000, (_) => g2())),
      _kurt(0.25),
      0.3 * _kurt(0.25),
    );
    final g3 = r(0.125);
    assertInDelta(
      kurtosis(List<int>.generate(20000, (_) => g3())),
      _kurt(0.125),
      0.3 * _kurt(0.125),
    );
  });
}
