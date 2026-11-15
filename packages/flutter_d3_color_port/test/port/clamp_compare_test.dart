// Original code, not ported from d3-color: the twin of the clamp compares.

/// The twin test of the row `adapt-color-clamp-compare`: `clampi` without
/// `Math.round` and `clamph` without `%` for a hue in (0, 360) give the
/// results of the plain translations of color.js:292 and color.js:381, on a
/// large set of generated values. `clampt`, with its test of NaN before the
/// clamp, gives the bits of color.js:386 too.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_d3_color_port/src/color.dart';
import 'package:test/test.dart';

/// color.js:292 `Math.max(0, Math.min(255, Math.round(value) || 0))`.
/// `roundToDouble` rounds a half away from 0, `Math.round` rounds it up:
/// the two differ only below 0, where the clamp gives 0.
int _clampiReference(double value) {
  final v = value.roundToDouble();
  return v > 0 ? (v < 255 ? v.toInt() : 255) : 0;
}

/// color.js:381 `value = (value || 0) % 360; value < 0 ? value + 360 :
/// value`.
double _clamphReference(double value) {
  final v = (value.isNaN || value == 0 ? 0.0 : value).remainder(360);
  return v < 0 ? v + 360 : v;
}

/// color.js:386 `Math.max(0, Math.min(1, value || 0))`: `value || 0` is 0
/// for NaN and -0.
double _clamptReference(double value) =>
    math.max(0, math.min(1, value.isNaN || value == 0 ? 0.0 : value));

/// The double next to [x] away from 0 ([step] 1) or toward 0 ([step] -1),
/// through the two 32-bit halves of its bits, as on each platform.
double _next(double x, int step) {
  final data = ByteData(8)..setFloat64(0, x);
  var high = data.getUint32(0);
  var low = data.getUint32(4) + step;
  if (low < 0) {
    low += 0x100000000;
    high -= 1;
  } else if (low > 0xffffffff) {
    low -= 0x100000000;
    high += 1;
  }
  data
    ..setUint32(0, high)
    ..setUint32(4, low);
  return data.getFloat64(0);
}

/// [x] and its two neighbors, for a finite [x] that is not 0.
Iterable<double> _withNeighbors(double x) => [_next(x, -1), x, _next(x, 1)];

/// Whether [a] and [b] have the same bits, with NaN equal to NaN.
bool _same(double a, double b) =>
    a.isNaN ? b.isNaN : a == b && a.isNegative == b.isNegative;

/// The special values of a double.
const List<double> _specials = [
  double.nan,
  0,
  -0.0,
  double.infinity,
  double.negativeInfinity,
  double.maxFinite,
  -double.maxFinite,
  double.minPositive,
  -double.minPositive,
  1e-300,
  -1e-300,
  4503599627370496, // 2^52
  4503599627370497,
  9007199254740992, // 2^53
  9007199254740994,
  9223372036854775808, // 2^63
  1e21,
  1e300,
  -1e300,
];

/// The values of the twin: the specials, each half from -400 to 400 with
/// its neighbors, random values in some ranges, and random doubles of any
/// exponent.
List<double> _values() {
  final random = math.Random(42);
  final values = <double>[..._specials];
  for (var k = 1; k <= 800; k++) {
    values
      ..addAll(_withNeighbors(k / 2))
      ..addAll(_withNeighbors(-k / 2));
  }
  for (final x in [0.25, 0.49999999999999994, 254.49999999999997, 360.0]) {
    values.addAll(_withNeighbors(x));
  }
  for (var i = 0; i < 4000; i++) {
    values
      ..add(random.nextDouble() * 300 - 20)
      ..add(random.nextDouble())
      ..add(random.nextDouble() * 2000 - 1000)
      ..add(random.nextInt(25600) / 100)
      ..add(random.nextInt(36000) / 100);
  }
  final data = ByteData(8);
  for (var i = 0; i < 4000; i++) {
    data
      ..setUint32(0, random.nextInt(0x10000) << 16 | random.nextInt(0x10000))
      ..setUint32(4, random.nextInt(0x10000) << 16 | random.nextInt(0x10000));
    values.add(data.getFloat64(0));
  }
  return values;
}

void main() {
  final values = _values();

  test('clampi gives the integer of the plain translation', () {
    final mismatches = <String>[];
    for (final x in values) {
      final actual = clampi(x);
      final expected = _clampiReference(x);
      if (actual != expected) mismatches.add('clampi($x): $actual, $expected');
    }
    expect(mismatches, isEmpty);
    expect(values.length, greaterThan(25000));
  });

  test('clampt gives the bits of the plain translation', () {
    final mismatches = <String>[];
    for (final x in [...values, for (final x in values) x / 256]) {
      final actual = clampt(x);
      final expected = _clamptReference(x);
      if (!_same(actual, expected)) {
        mismatches.add('clampt($x): $actual, $expected');
      }
    }
    expect(mismatches, isEmpty);
  });

  test('clamph gives the bits of the plain translation', () {
    final mismatches = <String>[];
    for (final x in values) {
      final actual = clamph(x);
      final expected = _clamphReference(x);
      if (!_same(actual, expected)) {
        mismatches.add('clamph($x): $actual, $expected');
      }
    }
    expect(mismatches, isEmpty);
  });
}
