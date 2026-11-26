// Ported from d3-color v3.1.0 test/hsl-test.js (ISC, Mike Bostock).
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
  Color copyWith({double? opacity}) => throw UnimplementedError();

  @override
  Color brighter([double? k]) => throw UnimplementedError();

  @override
  Color darker([double? k]) => throw UnimplementedError();
}

void main() {
  test('hsl(…) returns an instance of hsl and color', () {
    const c = Hsl(120, 0.4, 0.5);
    expect(c, isA<Hsl>());
    expect(c, isA<Color>());
  });

  test('hsl(…) exposes h, s, and l channel values and opacity', () {
    assertHslEqual(Hsl.parse('#abc'), 210, 0.25, 0.7333333, 1);
    assertHslEqual(Hsl.parse('hsla(60, 100%, 20%, 0.4)'), 60, 1, 0.2, 0.4);
  });

  test('hsl.toString() converts to RGB and formats as rgb(…) or rgba(…)', () {
    expect(Hsl.parse('#abcdef').toString(), 'rgb(171, 205, 239)');
    expect(Hsl.parse('moccasin').toString(), 'rgb(255, 228, 181)');
    expect(Hsl.parse('hsl(60, 100%, 20%)').toString(), 'rgb(102, 102, 0)');
    expect(
      Hsl.parse('hsla(60, 100%, 20%, 0.4)').toString(),
      'rgba(102, 102, 0, 0.4)',
    );
    expect(Hsl.parse('rgb(12, 34, 56)').toString(), 'rgb(12, 34, 56)');
    expect(Hsl.from(const Rgb(12, 34, 56)).toString(), 'rgb(12, 34, 56)');
    expect(Hsl.from(const Hsl(60, 1, 0.2)).toString(), 'rgb(102, 102, 0)');
    expect(
      Hsl.from(const Hsl(60, 1, 0.2, 0.4)).toString(),
      'rgba(102, 102, 0, 0.4)',
    );
  });

  test('hsl.formatRgb() formats as rgb(…) or rgba(…)', () {
    expect(Hsl.parse('#abcdef').formatRgb(), 'rgb(171, 205, 239)');
    expect(Hsl.parse('hsl(60, 100%, 20%)').formatRgb(), 'rgb(102, 102, 0)');
    expect(
      Hsl.parse('rgba(12%, 34%, 56%, 0.4)').formatRgb(),
      'rgba(31, 87, 143, 0.4)',
    );
    expect(
      Hsl.parse('hsla(60, 100%, 20%, 0.4)').formatRgb(),
      'rgba(102, 102, 0, 0.4)',
    );
  });

  test('hsl.formatHsl() formats as hsl(…) or hsla(…)', () {
    expect(
      Hsl.parse('#abcdef').formatHsl(),
      'hsl(210, 68%, 80.3921568627451%)',
    );
    expect(Hsl.parse('hsl(60, 100%, 20%)').formatHsl(), 'hsl(60, 100%, 20%)');
    expect(
      Hsl.parse('rgba(12%, 34%, 56%, 0.4)').formatHsl(),
      'hsla(210, 64.70588235294117%, 34%, 0.4)',
    );
    expect(
      Hsl.parse('hsla(60, 100%, 20%, 0.4)').formatHsl(),
      'hsla(60, 100%, 20%, 0.4)',
    );
  });

  test('hsl.formatHsl() clamps to the expected range', () {
    expect(const Hsl(180, -100, -50).formatHsl(), 'hsl(180, 0%, 0%)');
    expect(const Hsl(180, 150, 200).formatHsl(), 'hsl(180, 100%, 100%)');
    expect(const Hsl(-90, 50, 50).formatHsl(), 'hsl(270, 100%, 100%)');
    expect(const Hsl(420, 50, 50).formatHsl(), 'hsl(60, 100%, 100%)');
  });

  test('hsl.formatHex() formats as #rrggbb', () {
    expect(Hsl.parse('#abcdef').formatHex(), '#abcdef');
    expect(Hsl.parse('hsl(60, 100%, 20%)').formatHex(), '#666600');
    expect(Hsl.parse('rgba(12%, 34%, 56%, 0.4)').formatHex(), '#1f578f');
    expect(Hsl.parse('hsla(60, 100%, 20%, 0.4)').formatHex(), '#666600');
  });

  test('hsl.toString() reflects h, s and l channel values and opacity', () {
    final c = Hsl.parse('#abc');
    final modified = c.copyWith(
      h: c.h + 10,
      s: c.s + 0.01,
      l: c.l - 0.01,
      opacity: 0.4,
    );
    expect(modified.toString(), 'rgba(166, 178, 203, 0.4)');
  });

  test('hsl.toString() treats undefined channel values as 0', () {
    expect(Hsl.parse('invalid').toString(), 'rgb(0, 0, 0)');
    expect(Hsl.parse('#000').toString(), 'rgb(0, 0, 0)');
    expect(Hsl.parse('#ccc').toString(), 'rgb(204, 204, 204)');
    expect(Hsl.parse('#fff').toString(), 'rgb(255, 255, 255)');
    // equivalent to hsl(*, 0, 0.4)
    expect(const Hsl(double.nan, 0.5, 0.4).toString(), 'rgb(102, 102, 102)');
    expect(const Hsl(120, double.nan, 0.4).toString(), 'rgb(102, 102, 102)');
    expect(
      const Hsl(double.nan, double.nan, 0.4).toString(),
      'rgb(102, 102, 102)',
    );
    // equivalent to hsl(120, 0.5, 0)
    expect(const Hsl(120, 0.5, double.nan).toString(), 'rgb(0, 0, 0)');
  });

  test('hsl.toString() treats undefined opacity as 1', () {
    final c = Hsl.parse('#abc').copyWith(opacity: double.nan);
    expect(c.toString(), 'rgb(170, 187, 204)');
  });

  test('hsl(h, s, l) does not wrap hue to [0,360)', () {
    assertHslEqual(const Hsl(-10, 0.4, 0.5), -10, 0.4, 0.5, 1);
    assertHslEqual(const Hsl(0, 0.4, 0.5), 0, 0.4, 0.5, 1);
    assertHslEqual(const Hsl(360, 0.4, 0.5), 360, 0.4, 0.5, 1);
    assertHslEqual(const Hsl(370, 0.4, 0.5), 370, 0.4, 0.5, 1);
  });

  test('hsl(h, s, l) does not clamp s and l channel values to [0,1]', () {
    assertHslEqual(const Hsl(120, -0.1, 0.5), 120, -0.1, 0.5, 1);
    assertHslEqual(const Hsl(120, 1.1, 0.5), 120, 1.1, 0.5, 1);
    assertHslEqual(const Hsl(120, 0.2, -0.1), 120, 0.2, -0.1, 1);
    assertHslEqual(const Hsl(120, 0.2, 1.1), 120, 0.2, 1.1, 1);
  });

  test('hsl(h, s, l).clamp() clamps channel values', () {
    assertHslEqual(const Hsl(120, -0.1, -0.2).clamp(), 120, 0, 0, 1);
    assertHslEqual(const Hsl(120, 1.1, 1.2).clamp(), 120, 1, 1, 1);
    assertHslEqual(const Hsl(120, 2.1, 2.2).clamp(), 120, 1, 1, 1);
    assertHslEqual(const Hsl(420, -0.1, -0.2).clamp(), 60, 0, 0, 1);
    assertHslEqual(const Hsl(-420, -0.1, -0.2).clamp(), 300, 0, 0, 1);
    expect(const Hsl(-420, -0.1, -0.2, double.nan).clamp().opacity, 1);
    expect(const Hsl(-420, -0.1, -0.2, 0.5).clamp().opacity, 0.5);
    expect(const Hsl(-420, -0.1, -0.2, -1).clamp().opacity, 0);
    expect(const Hsl(-420, -0.1, -0.2, 2).clamp().opacity, 1);
  });

  test('hsl(h, s, l, opacity) does not clamp opacity to [0,1]', () {
    assertHslEqual(const Hsl(120, 0.1, 0.5, -0.2), 120, 0.1, 0.5, -0.2);
    assertHslEqual(const Hsl(120, 0.9, 0.5, 1.2), 120, 0.9, 0.5, 1.2);
  });

  test('hsl(h, s, l) coerces channel values to numbers', () {
    // The channels are doubles: Dart has no string channel to coerce.
  }, skip: 'diverges: adapt-color-factories');

  test('hsl(h, s, l, opacity) coerces opacity to number', () {
    // The opacity is a double: Dart has no string opacity to coerce.
  }, skip: 'diverges: adapt-color-factories');

  test('hsl(h, s, l) allows undefined channel values', () {
    // `hsl(undefined, NaN, "foo")`: undefined and the string "foo" give NaN
    // channels, and a Dart channel is a double, so each is NaN here.
    assertHslEqual(
      const Hsl(double.nan, double.nan, double.nan),
      double.nan,
      double.nan,
      double.nan,
      1,
    );
    // An undefined channel is NaN.
    assertHslEqual(const Hsl(double.nan, 0.4, 0.5), double.nan, 0.4, 0.5, 1);
    // An undefined channel is NaN.
    assertHslEqual(const Hsl(42, double.nan, 0.5), 42, double.nan, 0.5, 1);
    // An undefined channel is NaN.
    assertHslEqual(const Hsl(42, 0.4, double.nan), 42, 0.4, double.nan, 1);
  });

  test('hsl(h, s, l, opacity) converts undefined opacity to 1', () {
    // `hsl(10, 0.2, 0.3, null)`: an omitted opacity is 1.
    assertHslEqual(const Hsl(10, 0.2, 0.3), 10, 0.2, 0.3, 1);
    // `hsl(10, 0.2, 0.3, undefined)`: an omitted opacity is 1.
    assertHslEqual(const Hsl(10, 0.2, 0.3), 10, 0.2, 0.3, 1);
  });

  test('hsl(h, s, l) preserves explicit hue, even for grays', () {
    assertHslEqual(const Hsl(0, 0, 0), 0, 0, 0, 1);
    assertHslEqual(const Hsl(42, 0, 0.5), 42, 0, 0.5, 1);
    assertHslEqual(const Hsl(118, 0, 1), 118, 0, 1, 1);
  });

  test(
    'hsl(h, s, l) preserves explicit saturation, even for white or black',
    () {
      assertHslEqual(const Hsl(0, 0, 0), 0, 0, 0, 1);
      assertHslEqual(const Hsl(0, 0.18, 0), 0, 0.18, 0, 1);
      assertHslEqual(const Hsl(0, 0.42, 1), 0, 0.42, 1, 1);
      assertHslEqual(const Hsl(0, 1, 1), 0, 1, 1, 1);
    },
  );

  test('hsl(format) parses the specified format and converts to HSL', () {
    assertHslEqual(Hsl.parse('#abcdef'), 210, 0.68, 0.8039215, 1);
    assertHslEqual(Hsl.parse('#abc'), 210, 0.25, 0.733333333, 1);
    assertHslEqual(Hsl.parse('rgb(12, 34, 56)'), 210, 0.647058, 0.1333333, 1);
    assertHslEqual(Hsl.parse('rgb(12%, 34%, 56%)'), 210, 0.647058, 0.34, 1);
    assertHslEqual(Hsl.parse('hsl(60,100%,20%)'), 60, 1, 0.2, 1);
    assertHslEqual(Hsl.parse('hsla(60,100%,20%,0.4)'), 60, 1, 0.2, 0.4);
    assertHslEqual(Hsl.parse('aliceblue'), 208, 1, 0.9705882, 1);
    assertHslEqual(
      Hsl.parse('transparent'),
      double.nan,
      double.nan,
      double.nan,
      0,
    );
  });

  test('hsl(format) ignores the hue if the saturation is <= 0', () {
    assertHslEqual(Hsl.parse('hsl(120,0%,20%)'), double.nan, 0, 0.2, 1);
    assertHslEqual(Hsl.parse('hsl(120,-10%,20%)'), double.nan, -0.1, 0.2, 1);
  });

  test('hsl(format) ignores the hue and saturation if the lightness is <= 0 or '
      '>= 1', () {
    assertHslEqual(
      Hsl.parse('hsl(120,20%,-10%)'),
      double.nan,
      double.nan,
      -0.1,
      1,
    );
    assertHslEqual(Hsl.parse('hsl(120,20%,0%)'), double.nan, double.nan, 0, 1);
    assertHslEqual(
      Hsl.parse('hsl(120,20%,100%)'),
      double.nan,
      double.nan,
      1,
      1,
    );
    assertHslEqual(
      Hsl.parse('hsl(120,20%,120%)'),
      double.nan,
      double.nan,
      1.2,
      1,
    );
  });

  test('hsl(format) ignores all channels if the alpha is <= 0', () {
    assertHslEqual(
      Hsl.parse('hsla(120,20%,10%,0)'),
      double.nan,
      double.nan,
      double.nan,
      0,
    );
    assertHslEqual(
      Hsl.parse('hsla(120,20%,10%,-0.1)'),
      double.nan,
      double.nan,
      double.nan,
      -0.1,
    );
  });

  test('hsl(format) does not lose precision when parsing HSL formats', () {
    assertHslEqual(Hsl.parse('hsl(325,50%,40%)'), 325, 0.5, 0.4, 1);
  });

  test('hsl(format) returns undefined channel values for unknown formats', () {
    assertHslEqual(
      Hsl.parse('invalid'),
      double.nan,
      double.nan,
      double.nan,
      double.nan,
    );
  });

  test('hsl(hsl) copies an HSL color', () {
    // DIVERGES(d3-color): adapt-color-immutable, immutable Hsl reused directly.
    final c1 = Hsl.parse('hsla(120,30%,50%,0.4)');
    final c2 = Hsl.from(c1);
    expect(identical(c1, c2), isTrue);
    assertHslEqual(c1, 120, 0.3, 0.5, 0.4);
    assertHslEqual(c2, 120, 0.3, 0.5, 0.4);
  });

  test('hsl(rgb) converts from RGB', () {
    assertHslEqual(Hsl.from(const Rgb(255, 0, 0, 0.4)), 0, 1, 0.5, 0.4);
  });

  test(
    'hsl(color) returns undefined hue and zero saturation for grays (but not '
    'white and black)',
    () {
      assertHslEqual(Hsl.parse('gray'), double.nan, 0, 0.5019608, 1);
      assertHslEqual(Hsl.parse('#ccc'), double.nan, 0, 0.8, 1);
      assertHslEqual(Hsl.from(Rgb.parse('gray')), double.nan, 0, 0.5019608, 1);
    },
  );

  test(
    'hsl(color) returns undefined hue and saturation for black and white',
    () {
      assertHslEqual(Hsl.parse('black'), double.nan, double.nan, 0, 1);
      assertHslEqual(Hsl.parse('#000'), double.nan, double.nan, 0, 1);
      assertHslEqual(Hsl.parse('white'), double.nan, double.nan, 1, 1);
      assertHslEqual(Hsl.parse('#fff'), double.nan, double.nan, 1, 1);
      assertHslEqual(Hsl.from(Rgb.parse('#fff')), double.nan, double.nan, 1, 1);
    },
  );

  test('hsl(color) converts from another colorspace via rgb()', () {
    assertHslEqual(Hsl.from(_TestColor()), 210, 0.6470588, 0.1333334, 0.4);
  });

  test(
    'hsl.displayable() returns true if the color is within the RGB gamut and '
    'the opacity is in [0,1]',
    () {
      expect(Hsl.parse('white').displayable(), true);
      expect(Hsl.parse('red').displayable(), true);
      expect(Hsl.parse('black').displayable(), true);
      expect(Hsl.parse('invalid').displayable(), false);
      expect(const Hsl(double.nan, double.nan, 1).displayable(), true);
      expect(const Hsl(double.nan, double.nan, 1.5).displayable(), false);
      expect(const Hsl(120, -0.5, 0).displayable(), false);
      expect(const Hsl(120, 1.5, 0).displayable(), false);
      expect(const Hsl(0, 1, 1, 0).displayable(), true);
      expect(const Hsl(0, 1, 1, 1).displayable(), true);
      expect(const Hsl(0, 1, 1, -0.2).displayable(), false);
      expect(const Hsl(0, 1, 1, 1.2).displayable(), false);
    },
  );

  test('hsl.brighter(k) returns a brighter color if k > 0', () {
    final c = Hsl.parse('rgba(165, 42, 42, 0.4)');
    assertHslEqual(c.brighter(0.5), 0, 0.5942028, 0.4851222, 0.4);
    assertHslEqual(c.brighter(1), 0, 0.5942028, 0.5798319, 0.4);
    assertHslEqual(c.brighter(2), 0, 0.5942028, 0.8283313, 0.4);
  });

  test('hsl.brighter(k) returns a copy', () {
    final c1 = Hsl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter(1);
    assertHslEqual(c1, 207.272727, 0.44, 0.4901961, 0.4);
    assertHslEqual(c2, 207.272727, 0.44, 0.7002801, 0.4);
  });

  test('hsl.brighter() is equivalent to hsl.brighter(1)', () {
    final c1 = Hsl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter();
    final c3 = c1.brighter(1);
    assertHslEqual(c2, c3.h, c3.s, c3.l, 0.4);
  });

  test('hsl.brighter(k) is equivalent to hsl.darker(-k)', () {
    final c1 = Hsl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter(1.5);
    final c3 = c1.darker(-1.5);
    assertHslEqual(c2, c3.h, c3.s, c3.l, 0.4);
  });

  test('hsl("black").brighter() still returns black', () {
    final c1 = Hsl.parse('black');
    final c2 = c1.brighter(1);
    assertHslEqual(c1, double.nan, double.nan, 0, 1);
    assertHslEqual(c2, double.nan, double.nan, 0, 1);
  });

  test('hsl.darker(k) returns a darker color if k > 0', () {
    final c = Hsl.parse('rgba(165, 42, 42, 0.4)');
    assertHslEqual(c.darker(0.5), 0, 0.5942029, 0.3395855, 0.4);
    assertHslEqual(c.darker(1), 0, 0.5942029, 0.2841176, 0.4);
    assertHslEqual(c.darker(2), 0, 0.5942029, 0.1988823, 0.4);
  });

  test('hsl.darker(k) returns a copy', () {
    final c1 = Hsl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker(1);
    assertHslEqual(c1, 207.272727, 0.44, 0.4901961, 0.4);
    assertHslEqual(c2, 207.272727, 0.44, 0.3431373, 0.4);
  });

  test('hsl.darker() is equivalent to hsl.darker(1)', () {
    final c1 = Hsl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker();
    final c3 = c1.darker(1);
    assertHslEqual(c2, c3.h, c3.s, c3.l, 0.4);
  });

  test('hsl.darker(k) is equivalent to hsl.brighter(-k)', () {
    final c1 = Hsl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker(1.5);
    final c3 = c1.brighter(-1.5);
    assertHslEqual(c2, c3.h, c3.s, c3.l, 0.4);
  });

  test('hsl.rgb() converts to RGB', () {
    const c = Hsl(120, 0.3, 0.5, 0.4);
    assertRgbApproxEqual(c.rgb(), 89, 166, 89, 0.4);
  });

  test('hsl.copy(…) returns a new hsl with the specified channel values', () {
    const c = Hsl(120, 0.3, 0.5, 0.4);
    expect(c.copyWith(), isA<Hsl>());
    expect(c.copyWith().formatHsl(), 'hsla(120, 30%, 50%, 0.4)');
    expect(c.copyWith(opacity: 1).formatHsl(), 'hsl(120, 30%, 50%)');
    expect(c.copyWith(h: 20).formatHsl(), 'hsla(20, 30%, 50%, 0.4)');
    expect(c.copyWith(h: 20, s: 0.4).formatHsl(), 'hsla(20, 40%, 50%, 0.4)');
  });
}
