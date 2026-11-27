// Ported from d3-random v3.0.1 test/logNormal-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('randomLogNormal() returns random numbers with a log-mean of zero', () {
    final r = randomLogNormal.source(randomLcg(0.9575554996277458));
    final g = r();
    assertInDelta(
      meanBy(List<double>.generate(10000, (_) => g()), math.log),
      0,
      0.05,
    );
  });

  test('randomLogNormal() returns random numbers with a log-standard deviation '
      'of one', () {
    final r = randomLogNormal.source(randomLcg(0.7369869597887295));
    final g = r();
    assertInDelta(
      deviationBy(List<double>.generate(10000, (_) => g()), math.log),
      1,
      0.05,
    );
  });

  test(
    'randomLogNormal(mu) returns random numbers with the specified log-mean',
    () {
      final r = randomLogNormal.source(randomLcg(0.2083455771760374));
      final g1 = r(42);
      assertInDelta(
        meanBy(List<double>.generate(10000, (_) => g1()), math.log),
        42,
        0.05,
      );
      final g2 = r(-2);
      assertInDelta(
        meanBy(List<double>.generate(10000, (_) => g2()), math.log),
        -2,
        0.05,
      );
    },
  );

  test(
    'randomLogNormal(mu) returns random numbers with a log-standard deviation '
    'of 1',
    () {
      final r = randomLogNormal.source(randomLcg(0.7805370705171648));
      final g1 = r(42);
      assertInDelta(
        deviationBy(List<double>.generate(10000, (_) => g1()), math.log),
        1,
        0.05,
      );
      final g2 = r(-2);
      assertInDelta(
        deviationBy(List<double>.generate(10000, (_) => g2()), math.log),
        1,
        0.05,
      );
    },
  );

  test('randomLogNormal(mu, sigma) returns random numbers with the specified '
      'log-mean and log-standard deviation', () {
    final r = randomLogNormal.source(randomLcg(0.5178163416754684));
    final g1 = r(42, 2);
    assertInDelta(
      meanBy(List<double>.generate(10000, (_) => g1()), math.log),
      42,
      0.05,
    );
    final g2 = r(-2, 2);
    assertInDelta(
      meanBy(List<double>.generate(10000, (_) => g2()), math.log),
      -2,
      0.05,
    );
    final g3 = r(42, 2);
    assertInDelta(
      deviationBy(List<double>.generate(10000, (_) => g3()), math.log),
      2,
      0.05,
    );
    final g4 = r(-2, 2);
    assertInDelta(
      deviationBy(List<double>.generate(10000, (_) => g4()), math.log),
      2,
      0.05,
    );
  });
}
