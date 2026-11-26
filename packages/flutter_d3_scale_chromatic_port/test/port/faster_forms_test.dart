// Original code, not ported from d3-scale-chromatic: twin tests for fast forms.

import 'dart:math' as math;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';
import 'package:test/test.dart';

/// Direct upstream translation of `src/colors.js`.
List<Rgb> _upstreamColors(String specifier) {
  final n = specifier.length ~/ 6;
  return [
    for (var i = 0; i < n; i++)
      Rgb.parse('#${specifier.substring(i * 6, (i + 1) * 6)}'),
  ];
}

/// Direct upstream translation of `src/sequential-multi/sinebow.js`.
Rgb _upstreamSinebow(double t) {
  const pi13 = math.pi / 3;
  const pi23 = math.pi * 2 / 3;
  final a = (0.5 - t) * math.pi;
  final xr = math.sin(a);
  final xg = math.sin(a + pi13);
  final xb = math.sin(a + pi23);
  return Rgb(255 * xr * xr, 255 * xg * xg, 255 * xb * xb);
}

void main() {
  final sampleTs = <double>[
    double.negativeInfinity,
    -2.5,
    -1,
    -0.001,
    -0,
    0,
    1e-12,
    for (var k = 1; k < 256; k++) k / 256,
    0.9999999999999999,
    1,
    1.001,
    2.5,
    double.infinity,
  ];

  test('fast colors() matches upstream hex decode across cases', () {
    const spec = '000000ffffff1f77b4ABCDEFabcdef0123456789ab';
    final fast = colors(spec);
    final ref = _upstreamColors(spec);
    expect(fast.length, ref.length);
    for (var i = 0; i < ref.length; i++) {
      expect(fast[i].r, ref[i].r);
      expect(fast[i].g, ref[i].g);
      expect(fast[i].b, ref[i].b);
    }
    expect(() => colors('zzzzzz'), throwsFormatException);
  });

  test('fast ramp() is bit-identical to interpolateRgbBasis(scheme.last!)', () {
    for (final scheme in [
      schemeBrBG,
      schemeBlues,
      schemeSpectral,
      schemeYlGnBu,
    ]) {
      final fast = ramp(scheme);
      final ref = interpolateRgbBasis(scheme.last!);
      for (final t in [...sampleTs, double.nan]) {
        final a = fast(t);
        final b = ref(t);
        if (b.r.isNaN) {
          expect(a.r.isNaN, isTrue, reason: 't=$t');
          expect(a.g.isNaN, isTrue, reason: 't=$t');
          expect(a.b.isNaN, isTrue, reason: 't=$t');
        } else {
          expect(a.r, b.r, reason: 'r at t=$t');
          expect(a.g, b.g, reason: 'g at t=$t');
          expect(a.b, b.b, reason: 'b at t=$t');
        }
      }
    }
  });

  test('fast interpolateSinebow matches 3-sin upstream within 1e-12', () {
    for (final t in sampleTs) {
      if (!t.isFinite) continue;
      final a = interpolateSinebow(t);
      final b = _upstreamSinebow(t);
      expect(a.r, closeTo(b.r, 1e-12), reason: 'r at t=$t');
      expect(a.g, closeTo(b.g, 1e-12), reason: 'g at t=$t');
      expect(a.b, closeTo(b.b, 1e-12), reason: 'b at t=$t');
    }
    final nan = interpolateSinebow(double.nan);
    expect(nan.r.isNaN, isTrue);
  });

  test('fast viridis ramp handles 1 - ulp, -0.0, infinities, and NaN', () {
    expect(
      interpolateViridis(-0).formatHex(),
      interpolateViridis(0).formatHex(),
    );
    expect(
      interpolateViridis(0.9999999999999999).formatHex(),
      interpolateViridis(1).formatHex(),
    );
    expect(
      interpolateViridis(double.negativeInfinity).formatHex(),
      interpolateViridis(0).formatHex(),
    );
    expect(
      interpolateViridis(double.infinity).formatHex(),
      interpolateViridis(1).formatHex(),
    );
    expect(() => interpolateViridis(double.nan), throwsUnsupportedError);
  });
}
