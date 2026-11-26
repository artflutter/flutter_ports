// Ported from d3-color v3.1.0 test/rgb-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

import 'asserts.dart';

/// The `TestColor` of the spec: a color whose `rgb()` gives
/// `rgb(12, 34, 56, 0.4)` and whose `toString()` throws.
final class _TestColor() extends Color {
  @override
  double opacity = double.nan;

  @override
  Rgb rgb() => const Rgb(12, 34, 56, 0.4);

  @override
  String toString() => throw StateError('should use rgb, not toString');

  @override
  Color copy({double? opacity}) => throw UnimplementedError();

  @override
  Color brighter([double? k]) => throw UnimplementedError();

  @override
  Color darker([double? k]) => throw UnimplementedError();
}

void main() {
  test('rgb(…) returns an instance of rgb and color', () {
    const c = Rgb(70, 130, 180);
    expect(c, isA<Rgb>());
    expect(c, isA<Color>());
  });

  test('rgb(…) exposes r, g and b channel values and opacity', () {
    assertRgbApproxEqual(Rgb.parse('#abc'), 170, 187, 204, 1);
    assertRgbApproxEqual(
      Rgb.parse('rgba(170, 187, 204, 0.4)'),
      170,
      187,
      204,
      0.4,
    );
  });

  test('rgb.toString() formats as rgb(…) or rgba(…)', () {
    expect(Rgb.parse('#abcdef').toString(), 'rgb(171, 205, 239)');
    expect(Rgb.parse('moccasin').toString(), 'rgb(255, 228, 181)');
    expect(Rgb.parse('hsl(60, 100%, 20%)').toString(), 'rgb(102, 102, 0)');
    expect(Rgb.parse('rgb(12, 34, 56)').toString(), 'rgb(12, 34, 56)');
    expect(Rgb.from(const Rgb(12, 34, 56)).toString(), 'rgb(12, 34, 56)');
    expect(Rgb.from(const Hsl(60, 1, 0.2)).toString(), 'rgb(102, 102, 0)');
    expect(
      Rgb.parse('rgba(12, 34, 56, 0.4)').toString(),
      'rgba(12, 34, 56, 0.4)',
    );
    expect(
      Rgb.parse('rgba(12%, 34%, 56%, 0.4)').toString(),
      'rgba(31, 87, 143, 0.4)',
    );
    expect(
      Rgb.parse('hsla(60, 100%, 20%, 0.4)').toString(),
      'rgba(102, 102, 0, 0.4)',
    );
  });

  test('rgb.formatRgb() formats as rgb(…) or rgba(…)', () {
    expect(Rgb.parse('#abcdef').formatRgb(), 'rgb(171, 205, 239)');
    expect(Rgb.parse('hsl(60, 100%, 20%)').formatRgb(), 'rgb(102, 102, 0)');
    expect(
      Rgb.parse('rgba(12%, 34%, 56%, 0.4)').formatRgb(),
      'rgba(31, 87, 143, 0.4)',
    );
    expect(
      Rgb.parse('hsla(60, 100%, 20%, 0.4)').formatRgb(),
      'rgba(102, 102, 0, 0.4)',
    );
  });

  test('rgb.formatHsl() formats as hsl(…) or hsla(…)', () {
    expect(
      Rgb.parse('#abcdef').formatHsl(),
      'hsl(210, 68%, 80.3921568627451%)',
    );
    expect(Rgb.parse('hsl(60, 100%, 20%)').formatHsl(), 'hsl(60, 100%, 20%)');
    expect(
      Rgb.parse('rgba(12%, 34%, 56%, 0.4)').formatHsl(),
      'hsla(210, 64.70588235294117%, 34%, 0.4)',
    );
    expect(
      Rgb.parse('hsla(60, 100%, 20%, 0.4)').formatHsl(),
      'hsla(60, 100%, 20%, 0.4)',
    );
  });

  test('rgb.formatHex() formats as #rrggbb', () {
    expect(Rgb.parse('#abcdef').formatHex(), '#abcdef');
    expect(Rgb.parse('hsl(60, 100%, 20%)').formatHex(), '#666600');
    expect(Rgb.parse('rgba(12%, 34%, 56%, 0.4)').formatHex(), '#1f578f');
    expect(Rgb.parse('hsla(60, 100%, 20%, 0.4)').formatHex(), '#666600');
  });

  test('rgb.formatHex8() formats as #rrggbbaa', () {
    expect(Rgb.parse('#abcdef').formatHex8(), '#abcdefff');
    expect(Rgb.parse('hsl(60, 100%, 20%)').formatHex8(), '#666600ff');
    expect(Rgb.parse('rgba(12%, 34%, 56%, 0.4)').formatHex8(), '#1f578f66');
    expect(Rgb.parse('hsla(60, 100%, 20%, 0.4)').formatHex8(), '#66660066');
  });

  test('rgb.hex() is an alias for rgb.formatHex()', () {
    // `color.prototype.hex === color.prototype.formatHex`: a Dart method has
    // no identity across names, so the alias compares the results, on a
    // color of the base type and on an rgb color.
    final c = color('hsl(60, 100%, 20%)')!;
    // The spec reads the deprecated alias.
    // ignore: deprecated_member_use_from_same_package
    expect(c.hex(), c.formatHex());
    final r = Rgb.parse('#abcdef');
    // The spec reads the deprecated alias.
    // ignore: deprecated_member_use_from_same_package
    expect(r.hex(), r.formatHex());
  });

  test('rgb.toString() reflects r, g and b channel values and opacity', () {
    final c = Rgb.parse('#abc');
    final modified = c.copy(r: c.r + 1, g: c.g + 1, b: c.b + 1, opacity: 0.5);
    expect(modified.toString(), 'rgba(171, 188, 205, 0.5)');
  });

  test('rgb.toString() treats undefined channel values as 0', () {
    expect(Rgb.parse('invalid').toString(), 'rgb(0, 0, 0)');
    expect(const Rgb(double.nan, 12, 34).toString(), 'rgb(0, 12, 34)');
  });

  test('rgb.toString() treats undefined opacity as 1', () {
    final c = Rgb.parse('#abc');
    final modified = c.copy(
      r: c.r + 1,
      g: c.g + 1,
      b: c.b + 1,
      opacity: double.nan,
    );
    expect(modified.toString(), 'rgb(171, 188, 205)');
  });

  test('rgb.toString() clamps r, g, b and opacity channel values', () {
    expect(const Rgb(-1, 2, 3).toString(), 'rgb(0, 2, 3)');
    expect(const Rgb(2, -1, 3).toString(), 'rgb(2, 0, 3)');
    expect(const Rgb(2, 3, -1).toString(), 'rgb(2, 3, 0)');
    expect(const Rgb(2, 3, -1, -0.2).toString(), 'rgba(2, 3, 0, 0)');
    expect(const Rgb(2, 3, -1, 1.2).toString(), 'rgb(2, 3, 0)');
  });

  test('rgb.toString() rounds r, g and b channel values', () {
    expect(const Rgb(0.5, 2, 3).toString(), 'rgb(1, 2, 3)');
    expect(const Rgb(2, 0.5, 3).toString(), 'rgb(2, 1, 3)');
    expect(const Rgb(2, 3, 0.5).toString(), 'rgb(2, 3, 1)');
  });

  test('rgb(r, g, b) does not round channel values', () {
    assertRgbEqual(const Rgb(1.2, 2.6, 42.9), 1.2, 2.6, 42.9, 1);
  });

  test('rgb(r, g, b) does not clamp channel values', () {
    assertRgbApproxEqual(const Rgb(-10, -20, -30), -10, -20, -30, 1);
    assertRgbApproxEqual(const Rgb(300, 400, 500), 300, 400, 500, 1);
  });

  test('rgb(r, g, b).clamp() rounds and clamps channel values', () {
    assertRgbApproxEqual(const Rgb(-10, -20, -30).clamp(), 0, 0, 0, 1);
    assertRgbApproxEqual(const Rgb(10.5, 20.5, 30.5).clamp(), 11, 21, 31, 1);
    assertRgbApproxEqual(const Rgb(300, 400, 500).clamp(), 255, 255, 255, 1);
    expect(const Rgb(10.5, 20.5, 30.5, -1).clamp().opacity, 0);
    expect(const Rgb(10.5, 20.5, 30.5, 0.5).clamp().opacity, 0.5);
    expect(const Rgb(10.5, 20.5, 30.5, 2).clamp().opacity, 1);
    expect(const Rgb(10.5, 20.5, 30.5, double.nan).clamp().opacity, 1);
  });

  test('rgb(r, g, b, opacity) does not clamp opacity', () {
    assertRgbApproxEqual(const Rgb(-10, -20, -30, -0.2), -10, -20, -30, -0.2);
    assertRgbApproxEqual(const Rgb(300, 400, 500, 1.2), 300, 400, 500, 1.2);
  });

  test('rgb(r, g, b) coerces channel values to numbers', () {
    // A string or null channel: a Dart channel is a double.
  }, skip: 'diverges: adapt-color-factories');

  test('rgb(r, g, b, opacity) coerces opacity to number', () {
    // A string opacity: a Dart opacity is a double.
  }, skip: 'diverges: adapt-color-factories');

  test('rgb(r, g, b) allows undefined channel values', () {
    // `rgb(undefined, NaN, "foo")`: undefined and the text "foo" give a NaN
    // channel upstream; a channel is a double in Dart, so each is NaN.
    assertRgbApproxEqual(
      const Rgb(double.nan, double.nan, double.nan),
      double.nan,
      double.nan,
      double.nan,
      1,
    );
    // An undefined channel is NaN.
    assertRgbApproxEqual(const Rgb(double.nan, 42, 56), double.nan, 42, 56, 1);
    assertRgbApproxEqual(const Rgb(42, double.nan, 56), 42, double.nan, 56, 1);
    assertRgbApproxEqual(const Rgb(42, 56, double.nan), 42, 56, double.nan, 1);
  });

  test('rgb(r, g, b, opacity) converts undefined opacity to 1', () {
    // `rgb(10, 20, 30, null)` and `rgb(10, 20, 30, undefined)`: an omitted
    // opacity is 1.
    assertRgbApproxEqual(const Rgb(10, 20, 30), 10, 20, 30, 1);
    assertRgbApproxEqual(const Rgb(10, 20, 30), 10, 20, 30, 1);
  });

  test('rgb(format) parses the specified format and converts to RGB', () {
    assertRgbApproxEqual(Rgb.parse('#abcdef'), 171, 205, 239, 1);
    assertRgbApproxEqual(Rgb.parse('#abc'), 170, 187, 204, 1);
    assertRgbApproxEqual(Rgb.parse('rgb(12, 34, 56)'), 12, 34, 56, 1);
    assertRgbApproxEqual(Rgb.parse('rgb(12%, 34%, 56%)'), 31, 87, 143, 1);
    assertRgbApproxEqual(Rgb.parse('hsl(60,100%,20%)'), 102, 102, 0, 1);
    assertRgbApproxEqual(Rgb.parse('aliceblue'), 240, 248, 255, 1);
    assertRgbApproxEqual(Rgb.parse('hsla(60,100%,20%,0.4)'), 102, 102, 0, 0.4);
  });

  test('rgb(format) ignores all channels if the alpha is <= 0', () {
    assertRgbApproxEqual(
      Rgb.parse('rgba(12,34,45,0)'),
      double.nan,
      double.nan,
      double.nan,
      0,
    );
    assertRgbApproxEqual(
      Rgb.parse('rgba(12,34,45,-0.1)'),
      double.nan,
      double.nan,
      double.nan,
      -0.1,
    );
  });

  test('rgb(format) returns undefined channel values for unknown formats', () {
    assertRgbApproxEqual(
      Rgb.parse('invalid'),
      double.nan,
      double.nan,
      double.nan,
      double.nan,
    );
  });

  test('rgb(rgb) copies an RGB color', () {
    // DIVERGES(d3-color): adapt-color-immutable, immutable Rgb reused directly.
    final c1 = Rgb.parse('rgba(70, 130, 180, 0.4)');
    final c2 = Rgb.from(c1);
    expect(identical(c1, c2), isTrue);
    assertRgbApproxEqual(c1, 70, 130, 180, 0.4);
    assertRgbApproxEqual(c2, 70, 130, 180, 0.4);
  });

  test('rgb(hsl) converts from HSL', () {
    assertRgbApproxEqual(Rgb.from(const Hsl(0, 1, 0.5)), 255, 0, 0, 1);
    assertRgbApproxEqual(Rgb.from(const Hsl(0, 1, 0.5, 0.4)), 255, 0, 0, 0.4);
  });

  test('rgb(color) converts from another colorspace via rgb()', () {
    assertRgbApproxEqual(Rgb.from(_TestColor()), 12, 34, 56, 0.4);
  });

  test('rgb.displayable() returns true if the color is within the RGB gamut '
      'and opacity is in [0,1]', () {
    expect(Rgb.parse('white').displayable(), true);
    expect(Rgb.parse('red').displayable(), true);
    expect(Rgb.parse('black').displayable(), true);
    expect(Rgb.parse('invalid').displayable(), false);
    expect(const Rgb(-1, 0, 0).displayable(), false);
    expect(const Rgb(0, -1, 0).displayable(), false);
    expect(const Rgb(0, 0, -1).displayable(), false);
    expect(const Rgb(256, 0, 0).displayable(), false);
    expect(const Rgb(0, 256, 0).displayable(), false);
    expect(const Rgb(0, 0, 256).displayable(), false);
    expect(const Rgb(0, 0, 255, 0).displayable(), true);
    expect(const Rgb(0, 0, 255, 1.2).displayable(), false);
    expect(const Rgb(0, 0, 255, -0.2).displayable(), false);
  });

  test('rgb.brighter(k) returns a brighter color if k > 0', () {
    final c = Rgb.parse('rgba(165, 42, 42, 0.4)');
    assertRgbApproxEqual(c.brighter(0.5), 197, 50, 50, 0.4);
    assertRgbApproxEqual(c.brighter(1), 236, 60, 60, 0.4);
    assertRgbApproxEqual(c.brighter(2), 337, 86, 86, 0.4);
  });

  test('rgb.brighter(k) returns a copy', () {
    final c1 = Rgb.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter(1);
    assertRgbApproxEqual(c1, 70, 130, 180, 0.4);
    assertRgbApproxEqual(c2, 100, 186, 257, 0.4);
  });

  test('rgb.brighter() is equivalent to rgb.brighter(1)', () {
    final c1 = Rgb.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter();
    final c3 = c1.brighter(1);
    assertRgbApproxEqual(c2, c3.r, c3.g, c3.b, 0.4);
  });

  test('rgb.brighter(k) is equivalent to rgb.darker(-k)', () {
    final c1 = Rgb.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter(1.5);
    final c3 = c1.darker(-1.5);
    assertRgbApproxEqual(c2, c3.r, c3.g, c3.b, 0.4);
  });

  test('rgb("black").brighter() still returns black', () {
    final c1 = Rgb.parse('black');
    final c2 = c1.brighter(1);
    assertRgbApproxEqual(c1, 0, 0, 0, 1);
    assertRgbApproxEqual(c2, 0, 0, 0, 1);
  });

  test('rgb.darker(k) returns a darker color if k > 0', () {
    final c = Rgb.parse('rgba(165, 42, 42, 0.4)');
    assertRgbApproxEqual(c.darker(0.5), 138, 35, 35, 0.4);
    assertRgbApproxEqual(c.darker(1), 115, 29, 29, 0.4);
    assertRgbApproxEqual(c.darker(2), 81, 21, 21, 0.4);
  });

  test('rgb.darker(k) returns a copy', () {
    final c1 = Rgb.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker(1);
    assertRgbApproxEqual(c1, 70, 130, 180, 0.4);
    assertRgbApproxEqual(c2, 49, 91, 126, 0.4);
  });

  test('rgb.darker() is equivalent to rgb.darker(1)', () {
    final c1 = Rgb.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker();
    final c3 = c1.darker(1);
    assertRgbApproxEqual(c2, c3.r, c3.g, c3.b, 0.4);
  });

  test('rgb.darker(k) is equivalent to rgb.brighter(-k)', () {
    final c1 = Rgb.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker(1.5);
    final c3 = c1.brighter(-1.5);
    assertRgbApproxEqual(c2, c3.r, c3.g, c3.b, 0.4);
  });

  test('rgb.rgb() returns this', () {
    const c = Rgb(70, 130, 180);
    expect(c.rgb(), same(c));
  });

  test('rgb.copy(…) returns a new rgb with the specified channel values', () {
    const c = Rgb(70, 130, 180);
    expect(c.copy(), isA<Rgb>());
    expect(c.copy().toString(), 'rgb(70, 130, 180)');
    expect(c.copy(opacity: 0.2).toString(), 'rgba(70, 130, 180, 0.2)');
    expect(c.copy(r: 20).toString(), 'rgb(20, 130, 180)');
    expect(c.copy(r: 20, g: 40).toString(), 'rgb(20, 40, 180)');
  });
}
