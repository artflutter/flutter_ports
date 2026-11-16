// Ported from d3-interpolate v3.0.1 test/number-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('interpolateNumber(a, b) interpolates between two numbers a and b', () {
    final i = interpolateNumber(10, 42);
    assertInDelta(i(0), 10.0);
    assertInDelta(i(0.1), 13.2);
    assertInDelta(i(0.2), 16.4);
    assertInDelta(i(0.3), 19.6);
    assertInDelta(i(0.4), 22.8);
    assertInDelta(i(0.5), 26.0);
    assertInDelta(i(0.6), 29.2);
    assertInDelta(i(0.7), 32.4);
    assertInDelta(i(0.8), 35.6);
    assertInDelta(i(0.9), 38.8);
    assertInDelta(i(1), 42.0);
  });

  test('interpolateNumber(a, b) gives exact ends for t=0 and t=1', () {
    const a = 2e+42;
    const b = 335.0;
    expect(interpolateNumber(a, b)(1), b);
    expect(interpolateNumber(a, b)(0), a);
  });
}
