// Original code, not ported from Chart.js: helpers.math cases with no spec.
import 'dart:math' as js_math;
import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart' as math;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:test/test.dart';

// Upstream behaviour that test/specs/helpers.math.tests.js does not check
// (AGENTS.md rule 3). The expected values come from the helpers of the
// chart.js 4.5.1 npm package (dist/chart.umd.js) in Node.js v24.12.0 on x64.

/// A JavaScript object literal `{x, y}`, passed as a [Point].
final class _Point implements Point {
  const _Point(this.x, this.y);

  @override
  final double? x;

  @override
  final double? y;
}

/// A JavaScript object literal `{min, max}`, passed as a [math.MinMax].
final class _Target implements math.MinMax {
  _Target(this.min, this.max);

  @override
  double min;

  @override
  double max;
}

/// A tick `{value}` of a scale, passed as a [types.Tick].
final class _Tick implements types.Tick {
  _Tick(this.value);

  @override
  final double value;

  @override
  double? get significand => null;
}

/// Matches a double with the same value as [expected], where -0 differs from
/// +0 and NaN matches NaN, as `Object.is` does.
Matcher _isSameNumber(double expected) => predicate<double>(
  (actual) => expected.isNaN
      ? actual.isNaN
      : actual == expected && actual.isNegative == expected.isNegative,
  'Object.is($expected)',
);

/// The IEEE 754 bit pattern of [x] in hex, from two 32-bit halves (dart2js
/// has no 64-bit int). All NaN values give `NaN`: JS has one NaN value.
String _bits(double x) {
  if (x.isNaN) return 'NaN';
  final data = ByteData(8)..setFloat64(0, x);
  String half(int offset) =>
      data.getUint32(offset).toRadixString(16).padLeft(8, '0');
  return '${half(0)}${half(4)}';
}

/// Point coordinates for the tests that compare a function with its earlier
/// `jsToNumber` and `Math.pow` form: JS `null`, the signed zeros, NaN (a
/// copied `undefined`), the infinities, a subnormal, values whose square
/// overflows, and seeded random finites.
List<double?> _coordinates() {
  final random = js_math.Random(20261019);
  return [
    null,
    0,
    -0,
    double.nan,
    double.infinity,
    double.negativeInfinity,
    double.minPositive,
    -double.minPositive,
    1.4e154,
    -1.4e154,
    1,
    -3.5,
    for (var i = 0; i < 4; i++)
      (random.nextDouble() - 0.5) * js_math.pow(10.0, random.nextInt(40) - 20),
  ];
}

void main() {
  group('helpers.math constants', () {
    test('have the upstream values', () {
      expect(math.pi, 3.141592653589793);
      expect(math.tau, 6.283185307179586);
      expect(math.piTau, 9.42477796076938);
      expect(math.infinity, double.infinity);
      expect(math.radPerDeg, 0.017453292519943295);
      expect(math.halfPi, 1.5707963267948966);
      expect(math.quarterPi, 0.7853981633974483);
      expect(math.twoThirdsPi, 2.0943951023931953);
    });
  });

  group('niceNum', () {
    const cases = <(double, double)>[
      (0, 0),
      (1, 1),
      (1.5, 2),
      (2, 2),
      (3, 5),
      (7, 10),
      (12, 20),
      (0.15, 0.2),
      (0.3, 0.5),
      (999.9999, 1000),
      (1000.4, 1000),
      (25, 50),
      (49.99, 50),
      (0.007, 0.01),
      (1e-7, 1e-7),
      (123456789, 200000000),
      (5e20, 5e20),
      (0.5, 0.5),
      (4.99999, 5),
    ];
    for (final (range, expected) in cases) {
      test('niceNum($range) is $expected', () {
        expect(math.niceNum(range), _isSameNumber(expected));
      });
    }
  });

  group('factorize', () {
    test('handles squares, 1, 0 and primes', () {
      expect(math.factorize(36), <double>[1, 2, 3, 4, 6, 9, 12, 18]);
      expect(math.factorize(1), <double>[]);
      expect(math.factorize(0), <double>[]);
      expect(math.factorize(49), <double>[1, 7]);
      expect(math.factorize(2), <double>[1]);
    });
  });

  group('isNumber', () {
    test('coerces like isFinite and parseFloat', () {
      expect(math.isNumber([5]), isTrue);
      expect(math.isNumber([1, 2]), isFalse);
      expect(math.isNumber(' 12 '), isTrue);
      expect(math.isNumber('0x10'), isTrue);
      expect(math.isNumber(true), isFalse);
      expect(math.isNumber('Infinity'), isFalse);
      expect(math.isNumber('1e3'), isTrue);
      expect(math.isNumber('12px'), isFalse);
      expect(math.isNumber(''), isFalse);
      expect(math.isNumber(<Object?>[]), isFalse);
      expect(math.isNumber(5), isTrue);
    });
  });

  group('sign', () {
    test('keeps -0 and NaN', () {
      expect(math.sign(-0), _isSameNumber(-0));
      expect(math.sign(double.nan), isNaN);
      expect(math.sign(-3), -1);
      expect(math.sign(0.5), 1);
    });
  });

  group('decimalPlaces', () {
    test('counts the places of small and inexact numbers', () {
      expect(math.decimalPlaces(1e-7), 7);
      expect(math.decimalPlaces(0.1 + 0.2), 17);
      expect(math.decimalPlaces(1.5e-10), 11);
      expect(math.decimalPlaces(-12.25), 2);
      expect(math.decimalPlaces(123.456), 3);
      expect(math.decimalPlaces(double.infinity), isNull);
      expect(math.decimalPlaces(double.nan), isNull);
      expect(math.decimalPlaces(5), 0);
    });
  });

  group('setMinAndMaxByKey', () {
    test('coerces values, counts null as 0 and skips absent keys and NaN', () {
      final target = _Target(double.infinity, double.negativeInfinity);
      math.setMinAndMaxByKey(
        [
          {'value': 3},
          {'value': null},
          {},
          {'value': double.nan},
          {'value': '7'},
          {'value': -2},
        ],
        target,
        'value',
      );
      expect((target.min, target.max), (-2, 7));
    });

    test('counts a lone null as 0', () {
      final target = _Target(double.infinity, double.negativeInfinity);
      math.setMinAndMaxByKey(
        [
          {'value': null},
        ],
        target,
        'value',
      );
      expect((target.min, target.max), (0, 0));
    });

    test('leaves the target alone when no value is a number', () {
      final target = _Target(double.infinity, double.negativeInfinity);
      math.setMinAndMaxByKey(
        [
          {},
          {'value': 'x'},
        ],
        target,
        'value',
      );
      expect((target.min, target.max), (double.infinity, -double.infinity));
    });

    test('coerces arrays through their join', () {
      final target = _Target(1, 2);
      math.setMinAndMaxByKey(
        [
          {'v': 5},
          {
            'v': [0],
          },
        ],
        target,
        'v',
      );
      expect((target.min, target.max), (0, 5));
    });

    // The scales pass their ticks (scale.linearbase.js:274,
    // scale.logarithmic.js:172). A tick gives its value for the key 'value'
    // (Chart.js ADR 0025, section 7).
    test('reads the value of a tick and skips NaN', () {
      final target = _Target(double.infinity, double.negativeInfinity);
      math.setMinAndMaxByKey(
        [_Tick(3), _Tick(double.nan), _Tick(-2), _Tick(7)],
        target,
        'value',
      );
      expect((target.min, target.max), (-2, 7));
    });

    test('keeps a NaN target, as Math.min(NaN, x) does', () {
      final target = _Target(double.nan, double.nan);
      math.setMinAndMaxByKey([_Tick(1), _Tick(2)], target, 'value');
      expect(target.min, isNaN);
      expect(target.max, isNaN);
    });

    test('reads a mixed list of ticks and objects', () {
      final target = _Target(double.infinity, double.negativeInfinity);
      math.setMinAndMaxByKey(
        [
          _Tick(4),
          {'value': -1},
          {},
        ],
        target,
        'value',
      );
      expect((target.min, target.max), (-1, 4));
    });

    test('gives undefined for another key of a tick, without a throw', () {
      final target = _Target(1, 2);
      math.setMinAndMaxByKey([_Tick(5), _Tick(-5)], target, 'label');
      expect((target.min, target.max), (1, 2));
    });
  });

  group('distanceBetweenPoints', () {
    test('measures the distance, with null coordinates as 0', () {
      expect(
        math.distanceBetweenPoints(const _Point(0, 0), const _Point(3, 4)),
        5,
      );
      expect(
        math.distanceBetweenPoints(
          const _Point(null, 0),
          const _Point(3, null),
        ),
        3,
      );
    });

    test('gives the bits of the jsToNumber and Math.pow form', () {
      // The form before Chart.js ADR 0010: ToNumber through jsToNumber, and
      // Math.pow(x, 2) through dart:math pow.
      double before(Point pt1, Point pt2) => js_math.sqrt(
        // js-ok: the earlier form, the reference of the test.
        js_math.pow(jsToNumber(pt2.x) - jsToNumber(pt1.x), 2.0) +
            // js-ok: the earlier form, the reference of the test.
            js_math.pow(jsToNumber(pt2.y) - jsToNumber(pt1.y), 2.0),
      );
      final coordinates = _coordinates();
      for (final x1 in coordinates) {
        for (final y1 in coordinates) {
          final pt1 = _Point(x1, y1);
          for (final x2 in coordinates) {
            for (final y2 in coordinates) {
              final pt2 = _Point(x2, y2);
              expect(
                _bits(math.distanceBetweenPoints(pt1, pt2)),
                _bits(before(pt1, pt2)),
                reason: '($x1, $y1) to ($x2, $y2)',
              );
            }
          }
        }
      }
    });
  });

  group('getAngleFromPoint', () {
    test('reads a null coordinate as jsToNumber(null), 0', () {
      final coordinates = _coordinates();
      for (final x1 in coordinates) {
        for (final y1 in coordinates) {
          for (final x2 in coordinates) {
            for (final y2 in coordinates) {
              final actual = math.getAngleFromPoint(
                _Point(x1, y1),
                _Point(x2, y2),
              );
              final expected = math.getAngleFromPoint(
                _Point(jsToNumber(x1), jsToNumber(y1)),
                _Point(jsToNumber(x2), jsToNumber(y2)),
              );
              final reason = '($x1, $y1) about ($x2, $y2)';
              expect(
                _bits(actual.angle),
                _bits(expected.angle),
                reason: reason,
              );
              expect(
                _bits(actual.distance),
                _bits(expected.distance),
                reason: reason,
              );
            }
          }
        }
      }
    });

    test('keeps the angle in (-PI/2, 3PI/2]', () {
      expect(
        math.getAngleFromPoint(const _Point(null, null), const _Point(0, -1)),
        (angle: -1.5707963267948966, distance: 1.0),
      );
      expect(
        math.getAngleFromPoint(const _Point(0, 0), const _Point(-1, 0)),
        (angle: js_math.pi, distance: 1.0),
      );
      expect(
        math.getAngleFromPoint(const _Point(0, 0), const _Point(-1, -1e-9)),
        (angle: 3.141592654589793, distance: 1.0),
      );
    });

    test('takes the V8 side of the -PI/2 test where atan2 results differ', () {
      // Math.atan2(-1e17, -1) is -1.5707963267948968 in V8, below -PI/2, so
      // the angle is 3PI/2. dart:math atan2 on the VM returns -PI/2.
      expect(
        math.getAngleFromPoint(
          const _Point(0, 0),
          const _Point(-1, -100_000_000_000_000_000),
        ),
        (angle: 4.71238898038469, distance: 100_000_000_000_000_000.0),
      );
      // Here |y/x| > 2**60 with x < 0: V8 returns -PI/2, so the angle stays
      // -PI/2. Netlib fdlibm 5.3 returns 1 ulp below -PI/2.
      expect(
        math.getAngleFromPoint(
          const _Point(0.1 + 0.2, 0),
          const _Point(0.3, -1000),
        ),
        (angle: -1.5707963267948966, distance: 1000.0),
      );
    });
  });

  group('limitValue and int16Range', () {
    test('clamp like Math.max(min, Math.min(max, value))', () {
      expect(math.limitValue(5, 0, 3), 3);
      expect(math.limitValue(-1, 0, 3), 0);
      expect(math.limitValue(double.nan, 0, 3), isNaN);
      expect(math.limitValue(-0, 0, 3), _isSameNumber(0));
      // min > max: unlike num.clamp, no error, and min wins.
      expect(math.limitValue(2, 3, 0), 3);
      expect(math.int16Range(1000000), 32767);
      expect(math.int16Range(-1000000), -32768);
      expect(math.int16Range(12.5), 12.5);
      expect(math.int16Range(double.nan), isNaN);
    });
  });

  group('isBetween', () {
    test('includes the epsilon and accepts reversed bounds', () {
      expect(math.isBetween(1, 0, 2), isTrue);
      expect(math.isBetween(2.0000001, 0, 2), isTrue);
      expect(math.isBetween(2.1, 0, 2), isFalse);
      expect(math.isBetween(1, 2, 0), isTrue);
      expect(math.isBetween(-0.0000009, 0, 1), isTrue);
      expect(math.isBetween(2.05, 0, 2, 0.1), isTrue);
      expect(math.isBetween(double.nan, 0, 1), isFalse);
    });
  });

  group('angleBetween', () {
    test('treats equal bounds as a full circle only on request', () {
      expect(math.angleBetween(1, 2, 2, true), isTrue);
      expect(math.angleBetween(1, 2, 2, false), isFalse);
      expect(math.angleBetween(2, 2, 2, false), isTrue);
      expect(math.angleBetween(1, 0, 2 * js_math.pi), isFalse);
      expect(math.angleBetween(7, 0, 1), isTrue);
    });
  });

  group('angleDiff and normalizeAngle', () {
    test('return +0 for zero angles', () {
      expect(math.normalizeAngle(-0), _isSameNumber(0));
      expect(math.angleDiff(0, 0), _isSameNumber(0));
    });
  });
}
