// Ported from d3-random v3.0.1 test/int-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test(
    'randomInt(max) returns random integers with a mean of (max - 1) / 2',
    () {
      final r = randomInt.source(randomLcg(0.7350864698209636));
      final g1 = r(3);
      assertInDelta(mean(List<int>.generate(10000, (_) => g1())), 1.0, 0.05);
      final g2 = r(21);
      assertInDelta(mean(List<int>.generate(10000, (_) => g2())), 10.0, 0.5);
    },
  );

  test('randomInt(max) returns random integers in the range [0, max - 1]', () {
    final r = randomInt.source(randomLcg(0.17809137433591848));
    final g1 = r(3);
    expect(extent(List<int>.generate(10000, (_) => g1())), (0, 2));
    final g2 = r(21);
    expect(extent(List<int>.generate(10000, (_) => g2())), (0, 20));
  });

  test('randomInt(min, max) returns random integers with a mean of (min + max - 1) / 2', () {
    final r = randomInt.source(randomLcg(0.46394764422984647));
    final g = r(10, 43);
    assertInDelta(mean(List<int>.generate(10000, (_) => g())), 26, 0.5);
  });

  test(
    'randomInt(min, max) returns random integers in the range [min, max - 1]',
    () {
      final r = randomInt.source(randomLcg(0.9598431138570096));
      final g = r(10, 42);
      expect(extent(List<int>.generate(10000, (_) => g())), (10, 41));
    },
  );
}
