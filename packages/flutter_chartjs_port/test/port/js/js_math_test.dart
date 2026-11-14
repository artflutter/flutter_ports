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

/// The operands of the max and min grid: the signed zeros, NaN, the
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

/// `Math.max(a, b)` by the steps of ECMAScript 21.3.2.24: NaN if an operand
/// is NaN, +0 for +0 and -0 in either order, else the larger value.
double _jsMathMax(double a, double b) {
  if (a.isNaN || b.isNaN) return double.nan;
  if (a == 0 && b == 0) return a.isNegative && b.isNegative ? -0 : 0;
  return a > b ? a : b;
}

/// `Math.min(a, b)` by the steps of ECMAScript 21.3.2.25: NaN if an operand
/// is NaN, -0 for +0 and -0 in either order, else the smaller value.
double _jsMathMin(double a, double b) {
  if (a.isNaN || b.isNaN) return double.nan;
  if (a == 0 && b == 0) return a.isNegative || b.isNegative ? -0 : 0;
  return a < b ? a : b;
}

void main() {
  group('numberEpsilon', () {
    test('is 2^-52', () {
      expect(numberEpsilon, 1 / 4503599627370496);
      expect(1 + numberEpsilon, isNot(1));
      expect(1 + numberEpsilon / 2, 1);
    });
  });

  group('jsToInt32', () {
    final negativeZero = -double.parse('0');
    final cases = <(double, double)>[
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
      (negativeZero, 0),
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

  // Chart.js ADR 0146 §4: ported code calls dart:math max and min with double
  // operands for Math.max and Math.min. They give the JS results on the VM,
  // dart2js and dart2wasm.
  group('dart:math max and min', () {
    test('give the JS results for the special values', () {
      expect(math.max<double>(1, 2), 2);
      expect(math.max<double>(-1, -2), -1);
      expect(math.min<double>(1, 2), 1);
      expect(math.min<double>(-1, -2), -2);
      expect(math.max<double>(double.negativeInfinity, 3), 3);
      expect(math.min<double>(double.infinity, 3), 3);
      // Math.max(0, -0) is 0 and Math.min(0, -0) is -0, in either order.
      expect(math.max<double>(0, -0), _isSameNumber(0));
      expect(math.max<double>(-0, 0), _isSameNumber(0));
      expect(math.max<double>(-0, -0), _isSameNumber(-0));
      expect(math.max<double>(0, 0), _isSameNumber(0));
      expect(math.min<double>(0, -0), _isSameNumber(-0));
      expect(math.min<double>(-0, 0), _isSameNumber(-0));
      expect(math.min<double>(-0, -0), _isSameNumber(-0));
      expect(math.min<double>(0, 0), _isSameNumber(0));
      // NaN in either position gives NaN, also against an infinity.
      expect(math.max<double>(1, double.nan), isNaN);
      expect(math.max<double>(double.nan, 1), isNaN);
      expect(math.max(double.nan, double.infinity), isNaN);
      expect(math.min<double>(1, double.nan), isNaN);
      expect(math.min<double>(double.nan, 1), isNaN);
      expect(math.min(double.negativeInfinity, double.nan), isNaN);
      expect(math.max<double>(double.minPositive, -0), double.minPositive);
      expect(math.min<double>(-double.minPositive, 0), -double.minPositive);
    });

    test('give the bits of Math.max and Math.min for every operand pair', () {
      final operands = _gridOperands();
      final mismatches = <String>[];
      for (final a in operands) {
        for (final b in operands) {
          if (_bits(math.max(a, b)) != _bits(_jsMathMax(a, b))) {
            mismatches.add('max($a, $b)');
          }
          if (_bits(math.min(a, b)) != _bits(_jsMathMin(a, b))) {
            mismatches.add('min($a, $b)');
          }
        }
      }
      expect(operands, hasLength(40));
      expect(mismatches, isEmpty);
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
      expect(
        <double>[3, -0, 0].fold(double.infinity, math.min),
        _isSameNumber(-0),
      );
    });
  });

  // Math.pow(x, 2) is dart:math pow (Chart.js ADR 0146 §4). V8 gives the bits
  // of x * x for it (Chart.js ADR 0146, section 4).
  group('dart:math pow(x, 2.0)', () {
    // js-ok: the form of Math.pow(x, 2) under test.
    double square(double x) => math.pow(x, 2.0).toDouble();

    test('gives the JS results of Math.pow(x, 2) for the special values', () {
      expect(square(3), 9);
      expect(square(-0.1), _isSameNumber(0.010000000000000002));
      expect(square(-0), _isSameNumber(0));
      expect(square(double.nan), _isSameNumber(double.nan));
      expect(square(double.negativeInfinity), double.infinity);
      expect(square(double.minPositive), _isSameNumber(0));
      expect(square(-double.minPositive), _isSameNumber(0));
      // Overflow: 1.4e154 squared is above the largest finite double.
      expect(square(1.4e154), double.infinity);
      expect(square(-1.4e154), double.infinity);
      expect(square(1.3e154), 1.6899999999999998e308);
    });

    test('gives the bits of x * x', () {
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
        expect(_bits(square(x)), _bits(x * x), reason: 'pow($x, 2.0)');
      }
    });
  });
}
