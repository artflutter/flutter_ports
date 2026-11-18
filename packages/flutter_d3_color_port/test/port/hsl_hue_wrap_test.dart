// Original code, not ported from d3-color: the twin test of a faster form.

/// The twin test of the row `adapt-color-hsl-hue-wrap`: `Hsl.rgb()` skips
/// the `remainder` of a hue in (-360, 360). The test keeps the plain
/// translation of color.js:354-365 and compares each channel with the port,
/// bit for bit, on hues of each kind.
library;

import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

/// color.js:354-365 `Hsl.rgb()`, the plain translation of the upstream lines:
/// the channels `[r, g, b, opacity]`.
List<double> _referenceRgb(double hue, double sat, double l, double opacity) {
  final h = hue.remainder(360) + (hue < 0 ? 360 : 0);
  final s = h.isNaN || sat.isNaN ? 0 : sat;
  final m2 = l + (l < 0.5 ? l : 1 - l) * s;
  final m1 = 2 * l - m2;
  return [
    _referenceHsl2rgb(h >= 240 ? h - 240 : h + 120, m1, m2),
    _referenceHsl2rgb(h, m1, m2),
    _referenceHsl2rgb(h < 120 ? h + 240 : h - 120, m1, m2),
    opacity,
  ];
}

/// color.js:391 `hsl2rgb(h, m1, m2)`, the plain translation.
double _referenceHsl2rgb(double h, double m1, double m2) =>
    (h < 60
        ? m1 + (m2 - m1) * h / 60
        : h < 180
        ? m2
        : h < 240
        ? m1 + (m2 - m1) * (240 - h) / 60
        : m1) *
    255;

/// Whether [a] and [b] are the same double: NaN equals NaN, and -0 differs
/// from +0.
bool _same(double a, double b) =>
    a.isNaN ? b.isNaN : a == b && a.isNegative == b.isNegative;

/// A double of random bits: each sign, exponent and fraction.
double _randomBits(Random r, ByteData bytes) {
  bytes
    ..setUint32(0, r.nextInt(1 << 16) << 16 | r.nextInt(1 << 16))
    ..setUint32(4, r.nextInt(1 << 16) << 16 | r.nextInt(1 << 16));
  return bytes.getFloat64(0);
}

/// The hues of the test: the edges of the fast form, a dense sweep, random
/// hues and random bits.
List<double> _hues() {
  final r = Random(20261115);
  final bytes = ByteData(8);
  const edges = [
    0.0, -0.0, 360.0, -360.0, 359.99999999999994, -359.99999999999994, //
    720.0, -720.0, 120.0, 240.0, 60.0, 180.0, 1e-300, -1e-300, 5e-324,
    -5e-324, 1e300, -1e300, double.maxFinite, -double.maxFinite,
    double.infinity, double.negativeInfinity, double.nan, 1e16, -1e16,
    360.00000000000006, -360.00000000000006, 0.5, -0.5,
  ];
  return [
    ...edges,
    for (var k = -4000; k <= 4000; k++) k * 0.37,
    for (var k = -800; k <= 800; k++) k * 1.0,
    for (var i = 0; i < 3000; i++) (r.nextDouble() - 0.5) * 2000,
    for (var i = 0; i < 1000; i++) _randomBits(r, bytes),
  ];
}

void main() {
  test('Hsl.rgb() gives the channels of the plain translation', () {
    final r = Random(7);
    const levels = [
      0.0, -0.0, 0.25, 0.5, 0.75, 1.0, -0.2, 1.3, double.nan, //
      double.infinity, 1e-300,
    ];
    final mismatches = <String>[];
    var count = 0;
    for (final h in _hues()) {
      for (var j = 0; j < 4; j++) {
        final s = j == 0 ? levels[r.nextInt(levels.length)] : r.nextDouble();
        final l = j == 1 ? levels[r.nextInt(levels.length)] : r.nextDouble();
        final opacity = r.nextDouble();
        final actual = Hsl(h, s, l, opacity).rgb();
        final expected = _referenceRgb(h, s, l, opacity);
        final channels = [actual.r, actual.g, actual.b, actual.opacity];
        count++;
        for (var k = 0; k < 4; k++) {
          if (!_same(channels[k], expected[k])) {
            mismatches.add(
              'Hsl($h, $s, $l).rgb()[$k]: ${channels[k]} != '
              '${expected[k]}',
            );
          }
        }
      }
    }
    expect(count, greaterThan(40000));
    expect(mismatches.take(20), isEmpty);
  });
}
