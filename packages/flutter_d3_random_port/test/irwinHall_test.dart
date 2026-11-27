// Ported from d3-random v3.0.1 test/irwinHall-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';
import 'statistics.dart';

void main() {
  test('randomIrwinHall(n) returns random numbers with a mean of n / 2', () {
    final r = randomIrwinHall.source(randomLcg(0.028699383123896194));
    for (final n in const <num>[1, 10, 1.5, 4.2]) {
      final g = r(n);
      assertInDelta(
        mean(List<double>.generate(10000, (_) => g())),
        n / 2,
        0.05,
      );
    }
  });

  test(
    'randomIrwinHall(n) returns random numbers with a variance of n / 12',
    () {
      final r = randomIrwinHall.source(randomLcg(0.1515471143624345));
      for (final n in const <num>[1, 10, 1.5, 4.2]) {
        final g = r(n);
        assertInDelta(
          variance(List<double>.generate(10000, (_) => g())),
          n / 12,
          0.05,
        );
      }
    },
  );

  test('randomIrwinHall(n) returns random numbers with a skewness of 0', () {
    final r = randomIrwinHall.source(randomLcg(0.47334122849782845));
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
    'randomIrwinHall(n) returns random numbers with a kurtosis of -6 / (5 * n)',
    () {
      final r = randomIrwinHall.source(randomLcg(0.8217913599574529));
      final g1 = r(1);
      assertInDelta(
        kurtosis(List<double>.generate(10000, (_) => g1())),
        -6 / 5,
        0.1,
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
}
