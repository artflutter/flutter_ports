// Ported from Chart.js v4.5.1 test/specs/helpers.math.tests.js (MIT, Chart.js Contributors).
import 'dart:math' as js_math;

import 'package:flutter_chartjs/src/helpers/helpers.math.dart' as math;
import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:test/test.dart';

// The spec names Chart.helpers `math` and the JavaScript global `Math`. Here
// `math` is helpers.math and `js_math` is dart:math.

/// A JavaScript object literal `{x, y}`, passed as a [Point].
final class _Point implements Point {
  const _Point(this.x, this.y);

  @override
  final double? x;

  @override
  final double? y;
}

/// Jasmine `toBeCloseTo(expected, precision)`: within half a unit in the
/// `precision`-th decimal place.
///
/// Jasmine 3.99 rounds the difference to `precision + 1` places before it
/// compares, so it also accepts differences up to about 1.1 times this bound.
/// The spec always passes `precision`, so it has no default here.
Matcher _toBeCloseTo(double expected, int precision) =>
    // js-ok: the exponent is an int, as in Jasmine's Math.pow(10, -precision).
    closeTo(expected, js_math.pow(10.0, -precision) / 2);

void main() {
  group('Chart.helpers.math', () {
    const factorize = math.factorize;
    const decimalPlaces = math.decimalPlaces;

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
      expect(math.log10(0), double.negativeInfinity);

      // Check all allowed powers of 10, which should return integer values
      final maxPowerOf10 = math.log10(double.maxFinite).floorToDouble();
      for (var i = 0.0; i < maxPowerOf10; i += 1) {
        // js-ok: i is an integer, as in the upstream Math.pow(10, i).
        expect(math.log10(js_math.pow(10.0, i).toDouble()), i);
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
      // undefined: Dart has no undefined, and null gives the same result.
      expect(decimalPlaces(null), isNull);
      expect(decimalPlaces(12345678.1234), 4);
      expect(decimalPlaces(1234567890.1234567), 7);
    });

    test('should get an angle from a point', () {
      const center = _Point(0, 0);

      expect(math.getAngleFromPoint(center, const _Point(0, 10)), (
        angle: js_math.pi / 2,
        distance: 10.0,
      ));

      expect(
        math.getAngleFromPoint(
          center,
          _Point(js_math.sqrt(2), js_math.sqrt(2)),
        ),
        (angle: js_math.pi / 4, distance: 2.0),
      );

      expect(
        math.getAngleFromPoint(
          center,
          _Point(-1.0 * js_math.sqrt(2), -1.0 * js_math.sqrt(2)),
        ),
        (angle: js_math.pi * 1.25, distance: 2.0),
      );
    });

    test('should convert between radians and degrees', () {
      expect(math.toRadians(180), js_math.pi);
      expect(math.toRadians(90), 0.5 * js_math.pi);
      expect(math.toDegrees(js_math.pi), 180);
      expect(math.toDegrees(js_math.pi * 3 / 2), 270);
    });

    test('should correctly determine if two numbers are essentially equal', () {
      expect(math.almostEquals(0, numberEpsilon, 2 * numberEpsilon), true);
      expect(math.almostEquals(1, 1.1, 0.0001), false);
      expect(math.almostEquals(1e30, 1e30 + numberEpsilon, 0), false);
      expect(
        math.almostEquals(1e30, 1e30 + numberEpsilon, 2 * numberEpsilon),
        true,
      );
    });

    test('should get the correct sign', () {
      expect(math.sign(0), 0);
      expect(math.sign(10), 1);
      expect(math.sign(-5), -1);
    });

    test('should correctly determine if a numbers are essentially whole', () {
      expect(math.almostWhole(0.99999, 0.0001), true);
      expect(math.almostWhole(0.9, 0.0001), false);
      expect(math.almostWhole(1234567890123, 0.0001), true);
      expect(math.almostWhole(1234567890123.001, 0.0001), false);
    });

    test('should detect a number', () {
      expect(math.isNumber(123.0), true);
      expect(math.isNumber('123'), true);
      expect(math.isNumber(null), false);
      expect(math.isNumber(double.nan), false);
      // undefined: Dart has no undefined, and null gives the same result.
      expect(math.isNumber(null), false);
      expect(math.isNumber('cbc'), false);
      // Symbol(): a symbol without a description.
      expect(math.isNumber(Symbol.empty), false);
      // Object.create(null): a Map is the Dart value of a JavaScript object.
      expect(math.isNumber(<String, Object?>{}), false);
    });

    test('should compute shortest distance between angles', () {
      expect(math.angleDiff(1, 2), -1);
      expect(math.angleDiff(2, 1), 1);
      expect(math.angleDiff(0, 3.15), _toBeCloseTo(3.13, 2));
      expect(math.angleDiff(0, 3.13), -3.13);
      expect(math.angleDiff(6.2, 0), _toBeCloseTo(-0.08, 2));
      expect(math.angleDiff(6.3, 0), _toBeCloseTo(0.02, 2));
      expect(
        math.angleDiff(4 * js_math.pi, -4 * js_math.pi),
        _toBeCloseTo(0, 4),
      );
      expect(
        math.angleDiff(4 * js_math.pi, -3 * js_math.pi),
        _toBeCloseTo(-3.14, 2),
      );
      expect(math.angleDiff(6.28, 3.1), _toBeCloseTo(-3.1, 2));
      expect(math.angleDiff(6.28, 3.2), _toBeCloseTo(3.08, 2));
    });

    test('should normalize angles correctly', () {
      expect(math.normalizeAngle(-js_math.pi), js_math.pi);
      expect(math.normalizeAngle(js_math.pi), js_math.pi);
      expect(math.normalizeAngle(2), 2);
      expect(math.normalizeAngle(5 * js_math.pi), js_math.pi);
      expect(math.normalizeAngle(-50 * js_math.pi), _toBeCloseTo(6.28, 2));
    });

    test('should determine if angle is between boundaries', () {
      expect(math.angleBetween(2, 1, 3), isTrue);
      expect(math.angleBetween(2, 3, 1), isFalse);
      expect(math.angleBetween(-3.14, 2, 4), isTrue);
      expect(math.angleBetween(-3.14, 4, 2), isFalse);
      expect(math.angleBetween(0, -1, 1), isTrue);
      expect(math.angleBetween(-1, 0, 1), isFalse);
      expect(math.angleBetween(-15 * js_math.pi, 3.1, 3.2), isTrue);
      expect(math.angleBetween(15 * js_math.pi, -3.2, -3.1), isTrue);
    });
  });
}
