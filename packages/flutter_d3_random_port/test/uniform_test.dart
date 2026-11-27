// Ported from d3-random v3.0.1 test/uniform-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('randomUniform() returns random numbers with a mean of 0.5', () {
    final r = randomUniform.source(randomLcg(0.5233099016390388));
    assertInDelta(mean(List<double>.generate(10000, (_) => r()())), 0.5, 0.05);
  });

  test('randomUniform() returns random numbers within the range [0,1)', () {
    final r = randomUniform.source(randomLcg(0.6458793845385908));
    final g1 = r();
    expect(
      min(List<double>.generate(10000, (_) => g1())),
      greaterThanOrEqualTo(0),
    );
    final g2 = r();
    expect(min(List<double>.generate(10000, (_) => g2())), lessThan(1));
  });

  test('randomUniform(max) returns random numbers with a mean of max / 2', () {
    final r = randomUniform.source(randomLcg(0.678948531603278));
    final g = r(42);
    assertInDelta(mean(List<double>.generate(10000, (_) => g())), 21, 0.5);
  });

  test(
    'randomUniform(max) returns random numbers within the range [0,max)',
    () {
      final r = randomUniform.source(randomLcg(0.48468185818988196));
      final g1 = r(42);
      expect(
        min(List<double>.generate(10000, (_) => g1())),
        greaterThanOrEqualTo(0),
      );
      final g2 = r(42);
      expect(min(List<double>.generate(10000, (_) => g2())), lessThan(42));
    },
  );

  test('randomUniform(min, max) returns random numbers with a mean of (min + max) / 2', () {
    final r = randomUniform.source(randomLcg(0.23751000425183233));
    final g = r(10, 42);
    assertInDelta(mean(List<double>.generate(10000, (_) => g())), 26, 0.5);
  });

  test(
    'randomUniform(min, max) returns random numbers within the range [min,max)',
    () {
      final r = randomUniform.source(randomLcg(0.3607454145271254));
      final g1 = r(10, 42);
      expect(
        min(List<double>.generate(10000, (_) => g1())),
        greaterThanOrEqualTo(10),
      );
      final g2 = r(10, 42);
      expect(min(List<double>.generate(10000, (_) => g2())), lessThan(42));
    },
  );
}
