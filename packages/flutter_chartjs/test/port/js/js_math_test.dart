// Original code, not ported from Chart.js: tests of lib/src/js/js_math.dart and of dart:math max and min.
import 'dart:math' as math;

import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:test/test.dart';

// The expected values come from Node.js v24.12.0 (V8 13.6).

/// Matches a double with the same value as [expected], where -0 differs from
/// +0 and NaN matches NaN, as `Object.is` does.
Matcher _isSameNumber(double expected) => predicate<double>(
  (actual) => expected.isNaN
      ? actual.isNaN
      : actual == expected && actual.isNegative == expected.isNegative,
  'Object.is($expected)',
);

void main() {
  group('numberEpsilon', () {
    test('is 2^-52', () {
      expect(numberEpsilon, 1 / 4503599627370496);
      expect(1 + numberEpsilon, isNot(1));
      expect(1 + numberEpsilon / 2, 1);
    });
  });

  group('jsRound', () {
    const cases = <(double, double)>[
      (0.5, 1),
      (1.5, 2),
      (2.5, 3),
      (-0.5, -0),
      (-1.5, -1),
      (-2.5, -2),
      (0.49999999999999994, 0),
      (-0.49999999999999994, -0),
      (4503599627370495.5, 4503599627370496),
      (-4503599627370495.5, -4503599627370495),
      (4503599627370497, 4503599627370497),
      (1e300, 1e300),
      (0.4, 0),
      (-0.4, -0),
      (0, 0),
      (-0, -0),
      (double.nan, double.nan),
      (double.infinity, double.infinity),
      (double.negativeInfinity, double.negativeInfinity),
    ];
    for (final (x, expected) in cases) {
      test('Math.round($x) is $expected', () {
        expect(jsRound(x), _isSameNumber(expected));
      });
    }
  });

  group('jsToInt32', () {
    const cases = <(double, double)>[
      (2147483647, 2147483647),
      (2147483648, -2147483648),
      (-2147483648, -2147483648),
      (-2147483649, 2147483647),
      (4294967295, -1),
      (4294967296, 0),
      (4294967301, 5),
      (-1.5, -1),
      (1.9, 1),
      (-1.9, -1),
      (1e20, 1661992960),
      (-1e20, -1661992960),
      (9007199254740992, 0),
      (9007199254740994, 2),
      (-9007199254740992, 0),
      (1.7976931348623157e308, 0),
      (5e-324, 0),
      (-0.5, 0),
      (-0, 0),
      (double.nan, 0),
      (double.infinity, 0),
      (double.negativeInfinity, 0),
    ];
    for (final (x, expected) in cases) {
      test('$x | 0 is $expected', () {
        expect(jsToInt32(x), _isSameNumber(expected));
      });
    }
  });

  // Chart.js ADR 0002: ported code calls dart:math max and min for Math.max
  // and Math.min, with double operands. These tests pin that the results are
  // the JS results on the VM, dart2js and dart2wasm.
  group('dart:math max and min', () {
    test('return the larger and the smaller value', () {
      expect(math.max<double>(1, 2), 2);
      expect(math.max<double>(-1, -2), -1);
      expect(math.min<double>(1, 2), 1);
      expect(math.min<double>(-1, -2), -2);
      expect(math.max<double>(double.negativeInfinity, 3), 3);
      expect(math.min<double>(double.infinity, 3), 3);
    });

    test('order -0 below +0', () {
      expect(math.max<double>(0, -0), _isSameNumber(0));
      expect(math.max<double>(-0, 0), _isSameNumber(0));
      expect(math.min<double>(0, -0), _isSameNumber(-0));
      expect(math.min<double>(-0, 0), _isSameNumber(-0));
    });

    test('return NaN when either argument is NaN', () {
      expect(math.max<double>(1, double.nan), isNaN);
      expect(math.max<double>(double.nan, 1), isNaN);
      expect(math.min<double>(1, double.nan), isNaN);
      expect(math.min<double>(double.nan, 1), isNaN);
    });

    test('fold over a list as the spread form does', () {
      // Math.max(...[]) is -Infinity. Math.max(...[-0]) is -0.
      expect(<double>[].fold(double.negativeInfinity, math.max), -1 / 0);
      expect(
        <double>[-0].fold(double.negativeInfinity, math.max),
        _isSameNumber(-0),
      );
      expect(
        <double>[1, double.nan, 3].fold(double.negativeInfinity, math.max),
        isNaN,
      );
      expect(<double>[].fold(double.infinity, math.min), 1 / 0);
    });
  });

  group('jsLog10', () {
    test('handles the special values', () {
      expect(jsLog10(0), double.negativeInfinity);
      expect(jsLog10(-0), double.negativeInfinity);
      expect(jsLog10(-1), isNaN);
      expect(jsLog10(double.negativeInfinity), isNaN);
      expect(jsLog10(double.infinity), double.infinity);
      expect(jsLog10(double.nan), isNaN);
      expect(jsLog10(1), _isSameNumber(0));
      expect(jsLog10(1000), 3);
    });
  });

  group('jsAtan2', () {
    test('handles the special values', () {
      const pi = 3.141592653589793;
      expect(jsAtan2(0, 0), _isSameNumber(0));
      expect(jsAtan2(-0, 0), _isSameNumber(-0));
      expect(jsAtan2(0, -0), pi);
      expect(jsAtan2(-0, -0), -pi);
      expect(jsAtan2(1, 0), pi / 2);
      expect(jsAtan2(-1, -0), -pi / 2);
      expect(jsAtan2(double.infinity, double.infinity), pi / 4);
      expect(jsAtan2(double.infinity, double.negativeInfinity), 3 * pi / 4);
      expect(jsAtan2(-1, double.infinity), _isSameNumber(-0));
      expect(jsAtan2(1, double.negativeInfinity), pi);
      expect(jsAtan2(double.nan, 1), isNaN);
      expect(jsAtan2(1, double.nan), isNaN);
      expect(jsAtan2(1, 1), pi / 4);
    });
  });
}
