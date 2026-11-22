// Original code, not ported from Chart.js: the zero and NaN test of a number.
import 'package:flutter_chartjs_port/chartjs_core.dart';
import 'package:test/test.dart';

void main() {
  // DDC makes a constant -0.0 a 0: the test makes -0 at run time.
  final negativeZero = double.parse('-0');
  final falsy = <double?>[null, 0, negativeZero, double.nan];
  final truthy = <double>[
    1,
    -1,
    0.001,
    double.infinity,
    double.negativeInfinity,
  ];

  test('isNonZero is the JavaScript truthiness of a number', () {
    for (final value in falsy) {
      expect(value.isNonZero, isFalse, reason: '$value');
    }
    for (final value in truthy) {
      expect(value.isNonZero, isTrue, reason: '$value');
    }
  });
}
