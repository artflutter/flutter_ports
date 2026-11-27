// Ported from d3-random v3.0.1 test/cauchy-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('randomCauchy(a, b) returns random numbers with a median of a', () {
    final r = randomCauchy.source(randomLcg(0.42));
    final g1 = r();
    assertInDelta(median(List<double>.generate(10000, (_) => g1())), 0, 0.05);
    final g2 = r(5);
    assertInDelta(median(List<double>.generate(10000, (_) => g2())), 5, 0.05);
    final g3 = r(0, 4);
    assertInDelta(median(List<double>.generate(10000, (_) => g3())), 0, 0.1);
    final g4 = r(1, 3);
    assertInDelta(median(List<double>.generate(10000, (_) => g4())), 1, 0.1);
    // Upstream test explicitly passes default b = 1.
    // ignore: avoid_redundant_argument_values
    final g5 = r(3, 1);
    assertInDelta(median(List<double>.generate(10000, (_) => g5())), 3, 0.05);
  });
}
