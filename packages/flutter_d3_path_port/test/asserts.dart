// Ported from d3-path v3.1.0 test/asserts.js (ISC, Mike Bostock).

/// Port of `test/asserts.js` of d3-path 3.1.0: [assertPathEqual].
library;

import 'package:test/test.dart';

/// `asserts.js:3` `assertPathEqual(actual, expected)`.
void assertPathEqual(Object actual, String expected) {
  expect(_normalizePath('$actual'), _normalizePath(expected));
}

final RegExp _reNumber = RegExp(
  r'[-+]?(?:\d+\.\d+|\d+\.|\.\d+|\d+)(?:[eE][-]?\d+)?',
);

String _normalizePath(String path) =>
    path.replaceAllMapped(_reNumber, (m) => _formatNumber(m.group(0)!));

String _formatNumber(String s) {
  final v = double.parse(s);
  final rounded = v >= 0 ? v.roundToDouble() : (v + 0.5).floorToDouble();
  return (v - rounded).abs() < 1e-6
      ? rounded.toInt().toString()
      : v.toStringAsFixed(6);
}
