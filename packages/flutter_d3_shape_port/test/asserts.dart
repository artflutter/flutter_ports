// Ported from d3-shape v3.2.0 test/asserts.js (ISC, Mike Bostock).

import 'package:test/test.dart';

final RegExp _reNumber = RegExp(
  r'[-+]?(?:\d+\.\d+|\d+\.|\.\d+|\d+)(?:[eE][-]?\d+)?',
);

String _normalizePath(String path) => path.replaceAllMapped(_reNumber, (m) {
  final s = double.parse(m.group(0)!);
  final r = s.roundToDouble();
  return (s - r).abs() < 1e-6 ? r.toInt().toString() : s.toStringAsFixed(3);
});

/// `asserts.js:3` `assertPathEqual`: compares two SVG path strings with 1e-6
/// integer / 3-decimal normalization matching upstream `test/asserts.js`.
void assertPathEqual(Object? actual, String expected) {
  expect(_normalizePath('$actual'), _normalizePath(expected));
}

/// `asserts.js:17` `assertInDelta`: asserts [actual] is within [delta] of
/// [expected].
void assertInDelta(double actual, double expected, [double delta = 1e-6]) {
  expect(
    actual >= expected - delta && actual <= expected + delta,
    isTrue,
    reason: '$actual should be within $delta of $expected',
  );
}
