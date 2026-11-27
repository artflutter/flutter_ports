// Ported from d3-random v3.0.1 test/binomial-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'statistics.dart';

double _dmean(int n, double p) => n * p;
double _dvariance(int n, double p) => n * p * (1 - p);
double _skew(int n, double p) => (1 - 2 * p) / math.sqrt(_dvariance(n, p));
double _kurt(int n, double p) =>
    (6 * math.pow(p, 2) - 6 * p + 1) / _dvariance(n, p);

void main() {
  test('randomBinomial(n, p) returns random binomial distributed numbers '
      'with a mean of n * p', () {
    final r = randomBinomial.source(randomLcg(0.3994478770613372));
    for (final (n, p) in const <(int, double)>[
      (100, 1),
      (100, 0.5),
      (100, 0.25),
      (100, 0),
      (0, 0),
    ]) {
      final g = r(n, p);
      assertInDelta(
        mean(List<int>.generate(10000, (_) => g())),
        _dmean(n, p),
        _dvariance(n, p),
      );
    }
  });

  test('randomBinomial(n, p) returns random binomial distributed numbers '
      'with a variance of n * p * (1 - p)', () {
    final r = randomBinomial.source(randomLcg(0.7214876234380256));
    for (final (n, p, delta) in const <(int, double, double)>[
      (100, 1, 0),
      (100, 0.5, 0.5),
      (100, 0.25, 1),
      (100, 0, 0),
      (0, 0, 0),
    ]) {
      final g = r(n, p);
      assertInDelta(
        variance(List<int>.generate(10000, (_) => g())),
        _dvariance(n, p),
        delta,
      );
    }
  });

  test('randomBinomial(n, p) returns random binomial distributed numbers with a skewness of (1 - 2 * p) / sqrt(n * p * (1 - p))', () {
    final r = randomBinomial.source(randomLcg(0.0646181509291679));
    for (final p in const <double>[
      0.05,
      0.10,
      0.15,
      0.20,
      0.25,
      0.30,
      0.35,
      0.40,
      0.45,
    ]) {
      final g = r(100, p);
      assertInDelta(
        skewness(List<int>.generate(10000, (_) => g())),
        _skew(100, p),
        0.05,
      );
    }
  });

  test('randomBinomial(n, p) returns random binomial distributed numbers with a kurtosis excess of (6 * p^2 - 6 * p - 1) / (n * p * (1 - p))', () {
    final r = randomBinomial.source(randomLcg(0.6451552018202751));
    for (final (p, delta) in const <(double, double)>[
      (0.05, 0.2),
      (0.10, 0.1),
      (0.15, 0.1),
      (0.20, 0.1),
      (0.25, 0.1),
      (0.30, 0.1),
      (0.35, 0.1),
      (0.40, 0.1),
      (0.45, 0.05),
    ]) {
      final g = r(100, p);
      assertInDelta(
        kurtosis(List<int>.generate(10000, (_) => g())),
        _kurt(100, p),
        delta,
      );
    }
  });
}
