// Ported from d3-random v3.0.1 test/lcg-test.js (ISC, Mike Bostock).

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('lcg is the expected deterministic PRNG', () {
    const r1 = 0.6678668977692723;
    final lcg1 = randomLcg(0);
    lcg1();
    lcg1();
    lcg1();
    assertInDelta(lcg1(), r1, 1e-16);
    final lcg2 = randomLcg(0);
    lcg2();
    lcg2();
    lcg2();
    assertInDelta(lcg2(), r1, 1e-16);
  });

  test('lcg is seeded', () {
    const seed = 0.42;
    const r42 = 0.6760216606780887;
    final lcg = randomLcg(seed);
    lcg();
    lcg();
    lcg();
    assertInDelta(lcg(), r42, 1e-16);
  });

  test('lcg is well-distributed', () {
    const seed = 0.2;
    final lcg = randomLcg(seed);
    final run = Float32List(10000);
    for (var i = 0; i < run.length; ++i) {
      run[i] = lcg();
    }
    assertInDelta(mean(run), 1 / 2, 1e-2);
    assertInDelta(deviation(run), math.sqrt(1 / 12), 1e-2);
    final histogram = rollup<double, int, int>(
      run,
      (v) => v.length,
      (d) => (d * 10).floor(),
    );
    for (final h in histogram.entries) {
      assertInDelta(h.value, 1000, 120);
    }
  });

  test('lcg with small fractional seeds is well-distributed', () {
    final g = <RandomSource>[for (var i = 0; i < 100; ++i) randomLcg(i / 100)];
    final means = <double>[];
    final variances = <double>[];
    for (var i = 0; i < 10; ++i) {
      final m = <double>[for (final d in g) d()];
      means.add(mean(m)!);
      variances.add(variance(m)!);
    }
    assertInDelta(mean(means), 0.5, 0.02);
    expect(min(variances), greaterThan(0.75 / 12));
  });
}
