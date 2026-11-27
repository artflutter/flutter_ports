// Ported from d3-contour v4.0.2 test/asserts.js (ISC, Mike Bostock).

/// Port of `test/asserts.js` of d3-contour 4.0.2.
library;

import 'package:test/test.dart';

/// Asserts that [actual] is within [delta] of [expected].
void assertInDelta(double actual, double expected, [double delta = 1e-6]) {
  expect(
    actual >= expected - delta && actual <= expected + delta,
    isTrue,
    reason: 'Expected $actual to be within $delta of $expected',
  );
}

/// Asserts that each element of [actual] is within [delta] of [expected].
void assertInDeltaList(
  List<double> actual,
  List<double> expected, [
  double delta = 1e-6,
]) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    assertInDelta(actual[i], expected[i], delta);
  }
}
