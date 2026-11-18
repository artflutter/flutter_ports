// Original code, not ported from d3-color: the twin test of a faster form.

/// The twin test of the row `adapt-color-lrgb-table`: `rgb2lrgb` reads a
/// whole channel from 11 to 255 from a table. The test keeps the plain
/// translation of lab.js:80-82 and compares it with the port, bit for bit,
/// on each whole channel, a dense sweep and random channels.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

/// lab.js:80 `rgb2lrgb(x)`, the plain translation.
double _rgb2lrgb(double x) {
  final v = x / 255;
  return v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
}

/// Whether [a] and [b] are the same double: NaN equals NaN, and -0 differs
/// from +0.
bool _same(double a, double b) =>
    a.isNaN ? b.isNaN : a == b && a.isNegative == b.isNegative;

/// The channels of the test.
List<double> _channels() {
  final r = Random(20261115);
  final bytes = ByteData(8);
  double bits() {
    bytes
      ..setUint32(0, r.nextInt(1 << 16) << 16 | r.nextInt(1 << 16))
      ..setUint32(4, r.nextInt(1 << 16) << 16 | r.nextInt(1 << 16));
    return bytes.getFloat64(0);
  }

  const edges = [
    0.0, -0.0, 10.0, 10.31, 10.3275, 10.32750001, 11.0, 254.99999999999997, //
    255.0, 255.00000000000003, 256.0, -1.0, -11.0, -255.0, 1e-300, 5e-324,
    -5e-324, 1e300, -1e300, double.maxFinite, -double.maxFinite,
    double.infinity, double.negativeInfinity, double.nan, 4294967296.0,
    9007199254740992.0, -9007199254740992.0,
  ];
  return [
    ...edges,
    for (var i = -300; i <= 600; i++) i.toDouble(),
    for (var i = 0; i <= 256; i++) ...[
      max(0, i - 1e-13),
      i + 1e-13,
      i + 0.5,
      -i.toDouble(),
    ],
    for (var k = -2000; k <= 70000; k++) k / 256,
    for (var k = 0; k <= 30000; k++) k / 100,
    for (var i = 0; i < 20000; i++) r.nextDouble() * 300 - 20,
    for (var i = 0; i < 5000; i++) bits(),
  ];
}

void main() {
  test('rgb2lrgb gives the double of the formula', () {
    final mismatches = <String>[];
    final channels = _channels();
    for (final x in channels) {
      final actual = rgb2lrgb(x);
      final expected = _rgb2lrgb(x);
      if (!_same(actual, expected)) {
        mismatches.add('rgb2lrgb($x): $actual != $expected');
      }
    }
    expect(channels.length, greaterThan(100000));
    expect(mismatches.take(20), isEmpty);
  });
}
