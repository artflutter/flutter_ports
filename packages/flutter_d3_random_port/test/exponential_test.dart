// Ported from d3-random v3.0.1 test/exponential-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:flutter_d3_random_port/flutter_d3_random_port.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('randomExponential(lambda) returns random exponentially distributed numbers with a mean of 1/lambda.', () {
    final r = randomExponential.source(randomLcg(0.42));
    const period = 20;
    const lambda = 1 / period;
    final g = r(lambda);
    final times = List<double>.generate(10000, (_) => g());

    assertInDelta(mean(times), period, period * 0.05);

    for (final elapsed in range(10, 100, 10)) {
      final within = times.where((t) => t <= elapsed).length;
      final expected = 1 - math.exp(-elapsed * lambda);
      assertInDelta(within / times.length, expected, expected * 0.02);
    }
  });
}
