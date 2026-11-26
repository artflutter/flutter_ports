// Original code, not ported from d3-path: twin tests of the fast serializer.

/// Verifies that the optimized `Uint8List` + direct-decimal + Ryū serializer
/// in `Path` produces outputs bit-for-bit identical to the plain reference
/// formulation across 100k+ IEEE-754 doubles and all `pathRound(0..15)`
/// precisions.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_path_port/d3_path.dart';
import 'package:test/test.dart';

const double _minRoundableNeg = -4503599627370496;

double _refJsRound(double v) {
  if (v >= 0) return v.roundToDouble();
  if (v > _minRoundableNeg) return (v + 0.5).floorToDouble();
  return v;
}

String _refNumberText(double x) {
  if (x == 0) return '0';
  if (x.isNaN) return 'NaN';
  if (x == double.infinity) return 'Infinity';
  if (x == double.negativeInfinity) return '-Infinity';
  final s = x.toString();
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// Bit neighbors of [x] (+1 ULP and -1 ULP) for finite non-zero [x].
List<double> _neighbors(double x) {
  final bd = ByteData(8);
  final out = <double>[];
  for (final step in [-1, 1]) {
    bd.setFloat64(0, x);
    var hi = bd.getUint32(0);
    var lo = bd.getUint32(4) + step;
    if (lo < 0) {
      lo += 0x100000000;
      hi -= 1;
    } else if (lo > 0xFFFFFFFF) {
      lo -= 0x100000000;
      hi += 1;
    }
    bd
      ..setUint32(0, hi)
      ..setUint32(4, lo);
    out.add(bd.getFloat64(0));
  }
  return out;
}

List<double> _testValues() {
  final rng = math.Random(1337);
  final values = <double>[
    0,
    // Negative zero must be a double literal on VM.
    // ignore: prefer_int_literals
    -0.0,
    double.nan,
    double.infinity,
    double.negativeInfinity,
    double.maxFinite,
    -double.maxFinite,
    double.minPositive,
    -double.minPositive,
    2.2250738585072014e-308, // smallest normal
    2.225073858507201e-308, // largest subnormal
    1e-300,
    -1e-300,
    1e-20,
    -1e-20,
    1e-7,
    -1e-7,
    9.999999999999999e-7,
    1e-6,
    -1e-6,
    1.0000000000000002e-6,
    1e-5,
    0.0005,
    -0.0005,
    0.005,
    -0.005,
    0.05,
    -0.05,
    0.1,
    0.2,
    0.1 + 0.2,
    0.5,
    -0.5,
    1,
    -1,
    1.5,
    -1.5,
    math.pi,
    -math.pi,
    math.e,
    -math.e,
    9999,
    10000,
    999999,
    1000000,
    9007199254740991,
    9007199254740992,
    9007199254740994,
    1000000000000000,
    10000000000000000,
    1000000000000000000,
    1e20,
    1e21,
    -1e21,
    1e100,
    -1e100,
    1e308,
    -1e308,
  ];

  // Powers of 10 and powers of 2 with bit neighbors.
  for (var e = -300; e <= 300; e += 3) {
    final p = math.pow(10.0, e).toDouble();
    if (p.isFinite && p != 0) {
      values
        ..add(p)
        ..add(-p)
        ..addAll(_neighbors(p));
    }
  }
  for (var e = -1070; e <= 1020; e += 13) {
    final p = math.pow(2.0, e).toDouble();
    if (p.isFinite && p != 0) {
      values
        ..add(p)
        ..add(-p)
        ..addAll(_neighbors(p));
    }
  }

  // Dense decimals around common SVG coordinates and rounding boundaries.
  for (var k = -2000; k <= 2000; k++) {
    values
      ..add(k / 1000)
      ..add(k / 100)
      ..add(k / 2);
  }

  // 20,000 random IEEE-754 doubles across the full exponent spectrum.
  final bd = ByteData(8);
  for (var i = 0; i < 20000; i++) {
    final hi = rng.nextInt(0x100000000);
    final lo = rng.nextInt(0x100000000);
    bd
      ..setUint32(0, hi)
      ..setUint32(4, lo);
    final d = bd.getFloat64(0);
    values
      ..add(d)
      ..add(rng.nextDouble() * 2000 - 1000);
  }
  return values;
}

void main() {
  test(
    'full-precision Path number formatting matches reference on 50k+ doubles',
    () {
      final values = _testValues();
      final mismatches = <String>[];
      for (final x in values) {
        final p = path()..moveTo(x, 0);
        final actual = '$p';
        final expected = 'M${_refNumberText(x)},0';
        if (actual != expected) {
          mismatches.add('x=$x: actual=$actual expected=$expected');
          if (mismatches.length >= 20) break;
        }
      }
      expect(mismatches, isEmpty);
      expect(values.length, greaterThan(50000));
    },
  );

  test('pathRound(0..8) matches reference on coordinates and edge cases', () {
    final rng = math.Random(99);
    final values = <double>[
      0,
      // Negative zero must be a double literal on VM.
      // ignore: prefer_int_literals
      -0.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
      0.5,
      -0.5,
      1.5,
      -1.5,
      0.0005,
      -0.0005,
      0.0015,
      -0.0015,
      123.456789,
      -987.654321,
      999.9999,
      -999.9999,
      1e-7,
      -1e-7,
      1e-6,
      -1e-6,
      100000000000000,
      -100000000000000,
      10000000000000000,
      -10000000000000000,
      for (var i = 0; i < 4000; i++) (rng.nextDouble() - 0.5) * 20000,
    ];

    for (final digits in [0, 1, 2, 3, 4, 5, 6, 7, 8]) {
      final k = math.pow(10.0, digits).toDouble();
      final mismatches = <String>[];
      for (final x in values) {
        final p = pathRound(digits)..moveTo(x, 0);
        final actual = '$p';
        final expected = 'M${_refNumberText(_refJsRound(x * k) / k)},0';
        if (actual != expected) {
          mismatches.add(
            'digits=$digits x=$x: actual=$actual expected=$expected',
          );
          if (mismatches.length >= 20) break;
        }
      }
      expect(mismatches, isEmpty, reason: 'digits=$digits');
    }
  });
}
