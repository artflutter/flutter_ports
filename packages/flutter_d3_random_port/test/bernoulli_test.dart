// Ported from d3-random v3.0.1 test/bernoulli-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'statistics.dart';

double _dmean(double p) => p;
double _dvariance(double p) => p * (1 - p);
double _skew(double p) => (1 - 2 * p) / math.sqrt(_dvariance(p));
double _kurt(double p) => (6 * math.pow(p, 2) - 6 * p + 1) / _dvariance(p);

void main() {
  test('randomBernoulli(p) returns random bernoulli distributed numbers '
      'with a mean of p', () {
    final r = randomBernoulli.source(randomLcg(0.48444190806583465));
    for (final p in const <double>[1, 0.5, 0.25, 0]) {
      final g = r(p);
      assertInDelta(
        mean(List<int>.generate(10000, (_) => g())),
        _dmean(p),
        _dvariance(p),
      );
    }
  });

  test('randomBernoulli(p) returns random bernoulli distributed numbers '
      'with a variance of p * (1 - p)', () {
    final r = randomBernoulli.source(randomLcg(0.9781605192898934));
    final g1 = r(1);
    assertInDelta(
      variance(List<int>.generate(10000, (_) => g1())),
      _dvariance(1),
      0,
    );
    final g2 = r(0.5);
    assertInDelta(
      variance(List<int>.generate(10000, (_) => g2())),
      _dvariance(0.5),
      0.05,
    );
    final g3 = r(0.25);
    assertInDelta(
      variance(List<int>.generate(10000, (_) => g3())),
      _dvariance(0.25),
      0.05,
    );
    final g4 = r(0);
    assertInDelta(
      variance(List<int>.generate(10000, (_) => g4())),
      _dvariance(0),
      0,
    );
  });

  test('randomBernoulli(p) returns random bernoulli distributed numbers with a skewness of (1 - 2 * p) / sqrt(p * (1 - p)).', () {
    final r = randomBernoulli.source(randomLcg(0.9776249148208429));
    final g1 = r(0.5);
    assertInDelta(
      skewness(List<int>.generate(10000, (_) => g1())),
      _skew(0.5),
      0.08,
    );
    final g2 = r(0.25);
    assertInDelta(
      skewness(List<int>.generate(10000, (_) => g2())),
      _skew(0.25),
      0.05,
    );
  });

  test('randomBernoulli(p) returns random bernoulli distributed numbers with a kurtosis excess of (6 * p^2 - 6 * p - 1) / (p * (1 - p)).', () {
    final r = randomBernoulli.source(randomLcg(0.8260973119979638));
    for (final p in const <double>[0.05, 0.10, 0.15]) {
      final g = r(p);
      assertInDelta(
        kurtosis(List<int>.generate(10000, (_) => g())),
        _kurt(p),
        _kurt(p) * 0.2,
      );
    }
    final g4 = r(0.20);
    assertInDelta(
      kurtosis(List<int>.generate(50000, (_) => g4())),
      _kurt(0.20),
      _kurt(0.20) * 0.4,
    );
  });
}
