// Original code, not ported from Chart.js: tests of lib/src/js/js_math.dart and of dart:math max and min.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/js/js_math.dart';
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

/// The IEEE 754 bit pattern of [x] in hex, from two 32-bit halves (dart2js
/// has no 64-bit int). All NaN values give `NaN`: JS has one NaN value.
String _bits(double x) {
  if (x.isNaN) return 'NaN';
  final data = ByteData(8)..setFloat64(0, x);
  String half(int offset) =>
      data.getUint32(offset).toRadixString(16).padLeft(8, '0');
  return '${half(0)}${half(4)}';
}

/// The operands of the jsMax and jsMin grid: the signed zeros, NaN, the
/// infinities, the subnormal and normal limits, and seeded random finites.
List<double> _gridOperands() {
  final random = math.Random(20261018);
  return [
    0,
    -0,
    double.nan,
    double.infinity,
    double.negativeInfinity,
    double.minPositive,
    -double.minPositive,
    2.2250738585072014e-308,
    -2.2250738585072014e-308,
    double.maxFinite,
    -double.maxFinite,
    1,
    -1,
    0.1,
    -0.1,
    1e15,
    for (var i = 0; i < 24; i++)
      (random.nextDouble() - 0.5) * math.pow(10.0, random.nextInt(40) - 20),
  ];
}

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
      // The edges of the range that needs no wrap, and the values next to
      // them. A result is never -0.
      (2147483647.9, 2147483647),
      (2147483648.5, -2147483648),
      (-2147483648.9, -2147483648),
      (-2147483649.5, 2147483647),
      (-0.9, 0),
      (-1e-300, 0),
      (0.5, 0),
      (-7.5, -7),
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

  // Chart.js ADR 0032: ported code calls jsMax and jsMin for Math.max and
  // Math.min with double operands. The dart2wasm leg runs their comparisons,
  // the VM and dart2js legs run dart:math max and min.
  group('jsMax and jsMin', () {
    test('compare their operands in their own code on dart2wasm only', () {
      // dart2js numbers are JS numbers: 1.0 is an int there. On the VM and
      // dart2wasm it is not. Only the web legs have dart:js_interop.
      const web = bool.fromEnvironment('dart.library.js_interop');
      final Object one = double.parse('1');
      expect(jsMaxMinCompare, web && one is! int);
    });

    test('give the JS results for the special values', () {
      expect(jsMax(1, 2), 2);
      expect(jsMax(-1, -2), -1);
      expect(jsMin(1, 2), 1);
      expect(jsMin(-1, -2), -2);
      expect(jsMax(double.negativeInfinity, 3), 3);
      expect(jsMin(double.infinity, 3), 3);
      // Math.max(0, -0) is 0 and Math.min(0, -0) is -0, in either order.
      expect(jsMax(0, -0), _isSameNumber(0));
      expect(jsMax(-0, 0), _isSameNumber(0));
      expect(jsMax(-0, -0), _isSameNumber(-0));
      expect(jsMax(0, 0), _isSameNumber(0));
      expect(jsMin(0, -0), _isSameNumber(-0));
      expect(jsMin(-0, 0), _isSameNumber(-0));
      expect(jsMin(-0, -0), _isSameNumber(-0));
      expect(jsMin(0, 0), _isSameNumber(0));
      // NaN in either position gives NaN, also against an infinity.
      expect(jsMax(1, double.nan), isNaN);
      expect(jsMax(double.nan, 1), isNaN);
      expect(jsMax(double.nan, double.infinity), isNaN);
      expect(jsMin(1, double.nan), isNaN);
      expect(jsMin(double.nan, 1), isNaN);
      expect(jsMin(double.negativeInfinity, double.nan), isNaN);
      expect(jsMax(double.minPositive, -0), double.minPositive);
      expect(jsMin(-double.minPositive, 0), -double.minPositive);
    });

    test('give the dart:math max and min bits for every operand pair', () {
      final operands = _gridOperands();
      final mismatches = <String>[];
      for (final a in operands) {
        for (final b in operands) {
          if (_bits(jsMax(a, b)) != _bits(math.max(a, b))) {
            mismatches.add('jsMax($a, $b)');
          }
          if (_bits(jsMin(a, b)) != _bits(math.min(a, b))) {
            mismatches.add('jsMin($a, $b)');
          }
        }
      }
      expect(operands, hasLength(40));
      expect(mismatches, isEmpty);
    });

    test('fold over a list as the spread form does', () {
      // Math.max(...[]) is -Infinity. Math.max(...[-0]) is -0.
      expect(<double>[].fold(double.negativeInfinity, jsMax), -1 / 0);
      expect(
        <double>[-0].fold(double.negativeInfinity, jsMax),
        _isSameNumber(-0),
      );
      expect(
        <double>[1, double.nan, 3].fold(double.negativeInfinity, jsMax),
        isNaN,
      );
      expect(<double>[].fold(double.infinity, jsMin), 1 / 0);
      expect(
        <double>[3, -0, 0].fold(double.infinity, jsMin),
        _isSameNumber(-0),
      );
    });
  });

  // The reference of the jsMax and jsMin grid: dart:math max and min give
  // the JS results on the VM, dart2js and dart2wasm (Chart.js ADR 0032).
  // Ported code calls them for int operands only.
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

  group('jsSquare', () {
    test('gives the JS results of Math.pow(x, 2) for the special values', () {
      expect(jsSquare(3), 9);
      expect(jsSquare(-0.1), _isSameNumber(0.010000000000000002));
      expect(jsSquare(-0), _isSameNumber(0));
      expect(jsSquare(double.nan), _isSameNumber(double.nan));
      expect(jsSquare(double.negativeInfinity), double.infinity);
      expect(jsSquare(double.minPositive), _isSameNumber(0));
      expect(jsSquare(-double.minPositive), _isSameNumber(0));
      // Overflow: 1.4e154 squared is above the largest finite double.
      expect(jsSquare(1.4e154), double.infinity);
      expect(jsSquare(-1.4e154), double.infinity);
      expect(jsSquare(1.3e154), 1.6899999999999998e308);
    });

    test('gives the bits of dart:math pow(x, 2.0)', () {
      final random = math.Random(20261019);
      final data = ByteData(8);
      // 2^32. On dart2js, `1 << 32` is 0.
      const words = 0x100000000;
      final operands = [
        ..._gridOperands(),
        1.4e154,
        -1.4e154,
        1.3407807929942596e154,
        // Seeded random bit patterns: every exponent, NaN payloads included.
        for (var i = 0; i < 20000; i++)
          (data
                ..setUint32(0, random.nextInt(words))
                ..setUint32(4, random.nextInt(words)))
              .getFloat64(0),
      ];
      for (final x in operands) {
        // js-ok: the old form of Math.pow(x, 2), the reference of the test.
        final expected = math.pow(x, 2.0).toDouble();
        expect(_bits(jsSquare(x)), _bits(expected), reason: 'jsSquare($x)');
      }
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
