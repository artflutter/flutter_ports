// Original code, not ported from d3-color: tests of the Flutter colors.
import 'dart:ui' as ui;

import 'package:flutter_d3_color_port/flutter_d3_color_port.dart';
import 'package:test/test.dart';

void main() {
  group('toUiColor', () {
    test('maps the channels to [0, 1] with no rounding', () {
      final c = Rgb(70.5, 130, 180, 0.4).toUiColor();
      expect(c.colorSpace, ui.ColorSpace.sRGB);
      expect(c.r, 70.5 / 255);
      expect(c.g, 130 / 255);
      expect(c.b, 180 / 255);
      expect(c.a, 0.4);
    });

    test('clamps the channels and the opacity', () {
      final c = Rgb(-10, 300, 128, 1.5).toUiColor();
      expect([c.r, c.g, c.b, c.a], [0, 1, 128 / 255, 1]);
      expect(Rgb(0, 0, 0, -0.2).toUiColor().a, 0);
    });

    test('reads an undefined channel as 0 and an undefined opacity as 1', () {
      final c = Rgb.parse('invalid').toUiColor();
      expect([c.r, c.g, c.b, c.a], [0, 0, 0, 1]);
      final t = color('transparent')!.toUiColor();
      expect([t.r, t.g, t.b, t.a], [0, 0, 0, 0]);
    });

    test('converts each color space through rgb()', () {
      for (final source in <Color>[
        Hsl(210, 0.68, 0.8),
        Lab(50, 4, -5, 0.4),
        Hcl(120, 30, 50),
        Cubehelix(300, 0.5, 0.5),
      ]) {
        final rgb = source.rgb();
        final c = source.toUiColor();
        expect(c.r, closeTo((rgb.r / 255).clamp(0, 1), 1e-15));
        expect(c.g, closeTo((rgb.g / 255).clamp(0, 1), 1e-15));
        expect(c.b, closeTo((rgb.b / 255).clamp(0, 1), 1e-15));
        expect(c.a, source.opacity);
      }
    });

    test('gives the 8-bit Flutter color of formatHex', () {
      for (final text in ['steelblue', '#abcdef', 'rgb(12, 34, 56)']) {
        final c = Rgb.parse(text);
        final argb = c.toUiColor().toARGB32();
        expect(
          '#${(argb & 0xffffff).toRadixString(16).padLeft(6, '0')}',
          c.formatHex(),
        );
      }
    });
  });

  group('toD3Rgb', () {
    test('maps an sRGB color to [0, 255] channels', () {
      final c = const ui.Color(0x664682b4).toD3Rgb();
      expect(c.r, closeTo(0x46, 1e-12));
      expect(c.g, closeTo(0x82, 1e-12));
      expect(c.b, closeTo(0xb4, 1e-12));
      expect(c.opacity, closeTo(0x66 / 255, 1e-12));
      expect(c.formatHex8(), '#4682b466');
    });

    test('converts a Display P3 color to extended sRGB', () {
      const p3 = ui.Color.from(
        alpha: 1,
        red: 1,
        green: 0,
        blue: 0,
        colorSpace: ui.ColorSpace.displayP3,
      );
      final c = p3.toD3Rgb();
      final srgb = p3.withValues(colorSpace: ui.ColorSpace.extendedSRGB);
      expect(c.r, srgb.r * 255);
      expect(c.r, greaterThan(255));
      expect(c.displayable(), isFalse);
    });

    test('round-trips with toUiColor', () {
      final c = Rgb(12.25, 34.5, 56.75, 0.5);
      final back = c.toUiColor().toD3Rgb();
      expect(back.r, closeTo(c.r, 1e-12));
      expect(back.g, closeTo(c.g, 1e-12));
      expect(back.b, closeTo(c.b, 1e-12));
      expect(back.opacity, c.opacity);
    });
  });
}
