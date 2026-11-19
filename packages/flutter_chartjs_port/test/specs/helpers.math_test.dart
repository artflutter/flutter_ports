// Ported from Chart.js v4.6.1 test/specs/helpers.math.tests.js (MIT, Chart.js Contributors).
import 'dart:math' as js_math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/chartjs_core.dart';
// The locals factorize and decimalPlaces hide the helpers.
import 'package:flutter_chartjs_port/chartjs_core.dart' as helpers;
import 'package:test/test.dart';

// The spec names Chart.helpers `math` and the JavaScript global `Math`. Here
// `math` is helpers.math and `js_math` is dart:math.

/// A JavaScript object literal `{x, y}`, passed as a [Point].
final class const _Point(@override final double? x, @override final double? y)
    implements Point;

void main() {
  setUpSpecs();
  group('Chart.helpers.math', () {
    const factorize = helpers.factorize;
    const decimalPlaces = helpers.decimalPlaces;

    test('should factorize', () {
      expect(factorize(1000), <double>[
        1,
        2,
        4,
        5,
        8,
        10,
        20,
        25,
        40,
        50,
        100,
        125,
        200,
        250,
        500,
      ]);
      expect(factorize(60), <double>[1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30]);
      expect(factorize(30), <double>[1, 2, 3, 5, 6, 10, 15]);
      expect(factorize(24), <double>[1, 2, 3, 4, 6, 8, 12]);
      expect(factorize(12), <double>[1, 2, 3, 4, 6]);
      expect(factorize(4), <double>[1, 2]);
      expect(factorize(-1), <double>[]);
      expect(factorize(2.76), <double>[]);
    });

    test('should do a log10 operation', () {
      expect(log10(0), double.negativeInfinity);

      // Check all allowed powers of 10, which should return integer values
      final maxPowerOf10 = log10(double.maxFinite).floorToDouble();
      for (var i = 0.0; i < maxPowerOf10; i += 1) {
        expect(log10(js_math.pow(10.0, i).toDouble()), i);
      }
    });

    test('should get the correct number of decimal places', () {
      expect(decimalPlaces(100.0), 0);
      expect(decimalPlaces(1.0), 0);
      expect(decimalPlaces(0.0), 0);
      expect(decimalPlaces(0.01), 2);
      expect(decimalPlaces(-0.01), 2);
      expect(decimalPlaces('1'), isNull);
      expect(decimalPlaces(''), isNull);
      // decimalPlaces gives Dart null where upstream gives undefined.
      expect(decimalPlaces(undefined), isNull);
      expect(decimalPlaces(12345678.1234), 4);
      expect(decimalPlaces(1234567890.1234567), 7);
    });

    test('should get an angle from a point', () {
      const center = _Point(0, 0);

      expect(getAngleFromPoint(center, const _Point(0, 10)), (
        angle: js_math.pi / 2,
        distance: 10.0,
      ));

      expect(
        getAngleFromPoint(center, _Point(js_math.sqrt(2), js_math.sqrt(2))),
        (angle: js_math.pi / 4, distance: 2.0),
      );

      expect(
        getAngleFromPoint(
          center,
          _Point(-1.0 * js_math.sqrt(2), -1.0 * js_math.sqrt(2)),
        ),
        (angle: js_math.pi * 1.25, distance: 2.0),
      );
    });

    test('should convert between radians and degrees', () {
      expect(toRadians(180), js_math.pi);
      expect(toRadians(90), 0.5 * js_math.pi);
      expect(toDegrees(js_math.pi), 180);
      expect(toDegrees(js_math.pi * 3 / 2), 270);
    });

    test('should correctly determine if two numbers are essentially equal', () {
      expect(almostEquals(0, numberEpsilon, 2 * numberEpsilon), true);
      expect(almostEquals(1, 1.1, 0.0001), false);
      expect(almostEquals(1e30, 1e30 + numberEpsilon, 0), false);
      expect(almostEquals(1e30, 1e30 + numberEpsilon, 2 * numberEpsilon), true);
    });

    test('should get the correct sign', () {
      expect(sign(0), 0);
      expect(sign(10), 1);
      expect(sign(-5), -1);
    });

    test('should correctly determine if a numbers are essentially whole', () {
      expect(almostWhole(0.99999, 0.0001), true);
      expect(almostWhole(0.9, 0.0001), false);
      expect(almostWhole(1234567890123, 0.0001), true);
      expect(almostWhole(1234567890123.001, 0.0001), false);
    });

    test('should detect a number', () {
      expect(isNumber(123.0), true);
      // DIVERGES(chartjs): adapt-typed-number-test, a string is no number.
      expect(isNumber('123'), false);
      expect(isNumber(null), false);
      expect(isNumber(double.nan), false);
      expect(isNumber(undefined), false);
      expect(isNumber('cbc'), false);
      // Symbol(): a symbol without a description.
      expect(isNumber(Symbol.empty), false);
      // Object.create(null): a Map is the Dart value of a JavaScript object.
      expect(isNumber(<String, Object?>{}), false);
    });

    test('should compute shortest distance between angles', () {
      expect(angleDiff(1, 2), -1);
      expect(angleDiff(2, 1), 1);
      expect(angleDiff(0, 3.15), closeTo(3.13, 5e-3));
      expect(angleDiff(0, 3.13), -3.13);
      expect(angleDiff(6.2, 0), closeTo(-0.08, 5e-3));
      expect(angleDiff(6.3, 0), closeTo(0.02, 5e-3));
      expect(angleDiff(4 * js_math.pi, -4 * js_math.pi), closeTo(0, 5e-5));
      expect(angleDiff(4 * js_math.pi, -3 * js_math.pi), closeTo(-3.14, 5e-3));
      expect(angleDiff(6.28, 3.1), closeTo(-3.1, 5e-3));
      expect(angleDiff(6.28, 3.2), closeTo(3.08, 5e-3));
    });

    test('should normalize angles correctly', () {
      expect(normalizeAngle(-js_math.pi), js_math.pi);
      expect(normalizeAngle(js_math.pi), js_math.pi);
      expect(normalizeAngle(2), 2);
      expect(normalizeAngle(5 * js_math.pi), js_math.pi);
      expect(normalizeAngle(-50 * js_math.pi), closeTo(6.28, 5e-3));
    });

    test('should determine if angle is between boundaries', () {
      expect(angleBetween(2, 1, 3), isTrue);
      expect(angleBetween(2, 3, 1), isFalse);
      expect(angleBetween(-3.14, 2, 4), isTrue);
      expect(angleBetween(-3.14, 4, 2), isFalse);
      expect(angleBetween(0, -1, 1), isTrue);
      expect(angleBetween(-1, 0, 1), isFalse);
      expect(angleBetween(-15 * js_math.pi, 3.1, 3.2), isTrue);
      expect(angleBetween(15 * js_math.pi, -3.2, -3.1), isTrue);
    });
  });
}
