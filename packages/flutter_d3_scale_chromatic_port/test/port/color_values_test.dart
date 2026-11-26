// Original code, not ported from d3-scale-chromatic: native value tests.

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_scale_chromatic_port/d3_scale_chromatic.dart';
import 'package:test/test.dart';

void main() {
  group('colors()', () {
    test('parses 6-digit hex slices into an unmodifiable Rgb list', () {
      final list = colors('ff000000ff000000ff');
      expect(list.length, 3);
      expect(list[0].formatHex(), '#ff0000');
      expect(list[1].formatHex(), '#00ff00');
      expect(list[2].formatHex(), '#0000ff');
      expect(() => list.add(const Rgb(0, 0, 0)), throwsUnsupportedError);
    });

    test('truncates trailing partial characters as upstream', () {
      final list = colors('1f77b4ff');
      expect(list.length, 1);
      expect(list[0].formatHex(), '#1f77b4');
    });
  });

  group('immutable color objects per call', () {
    final interpolators = <String, Color Function(double)>{
      'interpolateBrBG': interpolateBrBG,
      'interpolateBlues': interpolateBlues,
      'interpolateBuGn': interpolateBuGn,
      'interpolateCividis': interpolateCividis,
      'interpolateCubehelixDefault': interpolateCubehelixDefault,
      'interpolateInferno': interpolateInferno,
      'interpolateMagma': interpolateMagma,
      'interpolatePlasma': interpolatePlasma,
      'interpolateRainbow': interpolateRainbow,
      'interpolateSinebow': interpolateSinebow,
      'interpolateTurbo': interpolateTurbo,
      'interpolateViridis': interpolateViridis,
      'interpolateWarm': interpolateWarm,
      'interpolateCool': interpolateCool,
    };

    for (final entry in interpolators.entries) {
      test('${entry.key} returns consistent immutable Color values', () {
        final a = entry.value(0.5);
        final b = entry.value(0.5);
        expect(a.runtimeType, b.runtimeType);
        expect(a.toString(), b.toString());
      });
    }

    test('viridis family returns shared const Rgb instances directly', () {
      for (final fn in [
        interpolateViridis,
        interpolateMagma,
        interpolateInferno,
        interpolatePlasma,
      ]) {
        expect(identical(fn(0.5), fn(0.5)), isTrue);
      }
    });
  });

  group('edge inputs (clamping, wrapping, NaN, infinities)', () {
    test('cividis and turbo clamp out-of-range and propagate NaN', () {
      for (final fn in [interpolateCividis, interpolateTurbo]) {
        expect(fn(-1).toString(), fn(0).toString());
        expect(fn(double.negativeInfinity).toString(), fn(0).toString());
        expect(fn(2).toString(), fn(1).toString());
        expect(fn(double.infinity).toString(), fn(1).toString());
        final nan = fn(double.nan);
        expect(nan.r.isNaN, isTrue);
        expect(nan.g.isNaN, isTrue);
        expect(nan.b.isNaN, isTrue);
      }
    });

    test('viridis family clamps out-of-range and throws on NaN', () {
      for (final fn in [
        interpolateViridis,
        interpolateMagma,
        interpolateInferno,
        interpolatePlasma,
      ]) {
        expect(fn(-1).formatHex(), fn(0).formatHex());
        expect(fn(double.negativeInfinity).formatHex(), fn(0).formatHex());
        expect(fn(2).formatHex(), fn(1).formatHex());
        expect(fn(double.infinity).formatHex(), fn(1).formatHex());
        expect(() => fn(double.nan), throwsUnsupportedError);
      }
    });

    test('rainbow wraps cyclic t and propagates NaN / infinity', () {
      expect(
        interpolateRainbow(-0.25).toString(),
        interpolateRainbow(0.75).toString(),
      );
      expect(
        interpolateRainbow(1.25).toString(),
        interpolateRainbow(0.25).toString(),
      );
      expect(interpolateRainbow(double.nan).h.isNaN, isTrue);
      expect(interpolateRainbow(double.infinity).h.isNaN, isTrue);
      expect(interpolateRainbow(double.negativeInfinity).h.isNaN, isTrue);
    });

    test('sinebow is cyclic with period 1', () {
      final a = interpolateSinebow(0.25);
      final b = interpolateSinebow(1.25);
      expect(a.r, closeTo(b.r, 1e-12));
      expect(a.g, closeTo(b.g, 1e-12));
      expect(a.b, closeTo(b.b, 1e-12));
    });
  });

  group('scheme list invariants', () {
    test(
      'ColorBrewer schemes have null for 0..2 and exact lengths for k >= 3',
      () {
        for (final s in [schemeBrBG, schemeSpectral, schemeRdBu]) {
          expect(s.length, 12);
          expect(s[0], isNull);
          expect(s[1], isNull);
          expect(s[2], isNull);
          for (var k = 3; k <= 11; k++) {
            expect(s[k]!.length, k);
          }
          expect(() => s[3] = null, throwsUnsupportedError);
        }
        for (final s in [schemeBlues, schemeGreens, schemeYlGnBu, schemeOrRd]) {
          expect(s.length, 10);
          expect(s[0], isNull);
          expect(s[1], isNull);
          expect(s[2], isNull);
          for (var k = 3; k <= 9; k++) {
            expect(s[k]!.length, k);
          }
        }
      },
    );
  });
}
