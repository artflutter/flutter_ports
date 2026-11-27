// Ported from d3-random v3.0.1 test/asserts.js (ISC, Mike Bostock).

import 'package:test/test.dart';

void assertInDelta(num? actual, num expected, num delta) {
  expect(actual, isNotNull, reason: 'actual should not be null');
  final a = actual!;
  expect(
    expected - delta <= a && a <= expected + delta,
    isTrue,
    reason: '$a should be within $delta of $expected',
  );
}
