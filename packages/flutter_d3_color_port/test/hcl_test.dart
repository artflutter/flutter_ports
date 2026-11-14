// Ported from d3-color v3.1.0 test/hcl-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

import 'asserts.dart';

/// `TestColor` of the spec: a color whose `rgb()` gives
/// `rgb(12, 34, 56, 0.4)` and whose `toString()` throws.
final class _TestColor() extends Color {
  @override
  double opacity = double.nan;

  @override
  Rgb rgb() => Rgb(12, 34, 56, 0.4);

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
  test('hcl(…) returns an instance of hcl and color', () {
    final c = Hcl(120, 40, 50);
    expect(c, isA<Hcl>());
    expect(c, isA<Color>());
  });

  test('hcl(…) exposes h, c, and l channel values', () {
    assertHclEqual(
      Hcl.parse('#abc'),
      252.37145234745182,
      11.223567114593477,
      74.96879980931759,
      1,
    );
  });

  test(
    'hcl(…) returns defined hue and undefined chroma for black and white',
    () {
      assertHclEqual(Hcl.parse('black'), double.nan, double.nan, 0, 1);
      assertHclEqual(Hcl.parse('#000'), double.nan, double.nan, 0, 1);
      assertHclEqual(Hcl.from(Lab.parse('#000')), double.nan, double.nan, 0, 1);
      assertHclEqual(Hcl.parse('white'), double.nan, double.nan, 100, 1);
      assertHclEqual(Hcl.parse('#fff'), double.nan, double.nan, 100, 1);
      assertHclEqual(
        Hcl.from(Lab.parse('#fff')),
        double.nan,
        double.nan,
        100,
        1,
      );
    },
  );

  test('hcl(…) returns undefined hue and zero chroma for gray', () {
    assertHclEqual(Hcl.parse('gray'), double.nan, 0, 53.585013, 1);
    assertHclEqual(Hcl.from(Lab.parse('gray')), double.nan, 0, 53.585013, 1);
  });

  test('hcl.toString() converts to RGB and formats as hexadecimal', () {
    expect(Hcl.parse('#abcdef').toString(), 'rgb(171, 205, 239)');
    expect(Hcl.parse('moccasin').toString(), 'rgb(255, 228, 181)');
    expect(Hcl.parse('hsl(60, 100%, 20%)').toString(), 'rgb(102, 102, 0)');
    expect(Hcl.parse('rgb(12, 34, 56)').toString(), 'rgb(12, 34, 56)');
    expect(Hcl.from(Rgb(12, 34, 56)).toString(), 'rgb(12, 34, 56)');
    expect(Hcl.from(Hsl(60, 1, 0.2)).toString(), 'rgb(102, 102, 0)');
  });

  test('hcl.toString() reflects h, c and l channel values', () {
    final c = Hcl.parse('#abc')
      ..h += 10
      ..c += 1
      ..l -= 1;
    expect(c.toString(), 'rgb(170, 183, 204)');
  });

  test('hcl.toString() treats undefined opacity as 1', () {
    final c = Hcl.parse('#abc')..opacity = double.nan;
    expect(c.toString(), 'rgb(170, 187, 204)');
  });

  test('hcl.toString() treats undefined channel values as 0', () {
    expect(Hcl.parse('invalid').toString(), 'rgb(0, 0, 0)');
    expect(Hcl.parse('#000').toString(), 'rgb(0, 0, 0)');
    expect(Hcl.parse('#ccc').toString(), 'rgb(204, 204, 204)');
    expect(Hcl.parse('#fff').toString(), 'rgb(255, 255, 255)');
    // equivalent to hcl(*, *, 40)
    expect(Hcl(double.nan, 20, 40).toString(), 'rgb(94, 94, 94)');
    expect(Hcl(120, double.nan, 40).toString(), 'rgb(94, 94, 94)');
    expect(Hcl(0, double.nan, 40).toString(), 'rgb(94, 94, 94)');
    // equivalent to hcl(*, *, 0)
    expect(Hcl(120, 50, double.nan).toString(), 'rgb(0, 0, 0)');
    expect(Hcl(0, 50, double.nan).toString(), 'rgb(0, 0, 0)');
    expect(Hcl(120, 0, double.nan).toString(), 'rgb(0, 0, 0)');
  });

  test('hcl(yellow) is displayable', () {
    expect(Hcl.parse('yellow').displayable(), true);
    expect(Hcl.parse('yellow').toString(), 'rgb(255, 255, 0)');
  });

  test('hcl(h, c, l) does not wrap hue to [0,360)', () {
    assertHclEqual(Hcl(-10, 40, 50), -10, 40, 50, 1);
    assertHclEqual(Hcl(0, 40, 50), 0, 40, 50, 1);
    assertHclEqual(Hcl(360, 40, 50), 360, 40, 50, 1);
    assertHclEqual(Hcl(370, 40, 50), 370, 40, 50, 1);
  });

  test('hcl(h, c, l) does not clamp l channel value', () {
    assertHclEqual(Hcl(120, 20, -10), 120, 20, -10, 1);
    assertHclEqual(Hcl(120, 20, 0), 120, 20, 0, 1);
    assertHclEqual(Hcl(120, 20, 100), 120, 20, 100, 1);
    assertHclEqual(Hcl(120, 20, 110), 120, 20, 110, 1);
  });

  test('hcl(h, c, l, opacity) does not clamp opacity to [0,1]', () {
    assertHclEqual(Hcl(120, 20, 100, -0.2), 120, 20, 100, -0.2);
    assertHclEqual(Hcl(120, 20, 110, 1.2), 120, 20, 110, 1.2);
  });

  test('hcl(h, c, l) coerces channel values to numbers', () {
    // `hcl("120", "40", "50")`: a channel is a double, never a string.
  }, skip: 'diverges: adapt-color-factories');

  test('hcl(h, c, l, opacity) coerces opacity to number', () {
    // `hcl(120, 40, 50, "0.2")`: the opacity is a double, never a string.
  }, skip: 'diverges: adapt-color-factories');

  test('hcl(h, c, l) allows undefined channel values', () {
    // `hcl(undefined, NaN, "foo")`: an undefined channel and the string
    // "foo" are NaN as numbers.
    assertHclEqual(
      Hcl(double.nan, double.nan, double.nan),
      double.nan,
      double.nan,
      double.nan,
      1,
    );
    // `hcl(undefined, 40, 50)`: an undefined channel is NaN.
    assertHclEqual(Hcl(double.nan, 40, 50), double.nan, 40, 50, 1);
    // `hcl(42, undefined, 50)`: an undefined channel is NaN.
    assertHclEqual(Hcl(42, double.nan, 50), 42, double.nan, 50, 1);
    // `hcl(42, 40, undefined)`: an undefined channel is NaN.
    assertHclEqual(Hcl(42, 40, double.nan), 42, 40, double.nan, 1);
  });

  test('hcl(h, c, l, opacity) converts undefined opacity to 1', () {
    // `hcl(10, 20, 30, null)`: an omitted opacity is 1.
    assertHclEqual(Hcl(10, 20, 30), 10, 20, 30, 1);
    // `hcl(10, 20, 30, undefined)`: an omitted opacity is 1.
    assertHclEqual(Hcl(10, 20, 30), 10, 20, 30, 1);
  });

  test('hcl(format) parses the specified format and converts to HCL', () {
    assertHclEqual(
      Hcl.parse('#abcdef'),
      254.0079700170605,
      21.62257586147983,
      80.77135418262527,
      1,
    );
    assertHclEqual(
      Hcl.parse('#abc'),
      252.37145234745182,
      11.223567114593477,
      74.96879980931759,
      1,
    );
    assertHclEqual(
      Hcl.parse('rgb(12, 34, 56)'),
      262.8292023352897,
      17.30347233219686,
      12.404844123471648,
      1,
    );
    assertHclEqual(
      Hcl.parse('rgb(12%, 34%, 56%)'),
      266.117653326772,
      37.03612078188506,
      35.48300043476593,
      1,
    );
    assertHclEqual(
      Hcl.parse('rgba(12%, 34%, 56%, 0.4)'),
      266.117653326772,
      37.03612078188506,
      35.48300043476593,
      0.4,
    );
    assertHclEqual(
      Hcl.parse('hsl(60,100%,20%)'),
      99.57458688693686,
      48.327323183108916,
      41.97125732118659,
      1,
    );
    assertHclEqual(
      Hcl.parse('hsla(60,100%,20%,0.4)'),
      99.57458688693686,
      48.327323183108916,
      41.97125732118659,
      0.4,
    );
    assertHclEqual(
      Hcl.parse('aliceblue'),
      247.7353849904697,
      4.681732046417135,
      97.12294991108756,
      1,
    );
  });

  test('hcl(format) returns undefined channel values for unknown formats', () {
    assertHclEqual(
      Hcl.parse('invalid'),
      double.nan,
      double.nan,
      double.nan,
      double.nan,
    );
  });

  test('hcl(hcl) copies an HCL color', () {
    final c1 = Hcl(120, 30, 50, 0.4);
    final c2 = Hcl.from(c1);
    assertHclEqual(c1, 120, 30, 50, 0.4);
    c1.h = c1.c = c1.l = c1.opacity = 0;
    assertHclEqual(c1, 0, 0, 0, 0);
    assertHclEqual(c2, 120, 30, 50, 0.4);
  });

  test('hcl(lab) returns h = NaN if a and b are zero', () {
    assertHclEqual(Hcl.from(Lab(0, 0, 0)), double.nan, double.nan, 0, 1);
    assertHclEqual(Hcl.from(Lab(50, 0, 0)), double.nan, 0, 50, 1);
    assertHclEqual(Hcl.from(Lab(100, 0, 0)), double.nan, double.nan, 100, 1);
    assertHclEqual(Hcl.from(Lab(0, 10, 0)), 0, 10, 0, 1);
    assertHclEqual(Hcl.from(Lab(50, 10, 0)), 0, 10, 50, 1);
    assertHclEqual(Hcl.from(Lab(100, 10, 0)), 0, 10, 100, 1);
    assertHclEqual(Hcl.from(Lab(0, 0, 10)), 90, 10, 0, 1);
    assertHclEqual(Hcl.from(Lab(50, 0, 10)), 90, 10, 50, 1);
    assertHclEqual(Hcl.from(Lab(100, 0, 10)), 90, 10, 100, 1);
  });

  test('hcl(rgb) converts from RGB', () {
    assertHclEqual(
      Hcl.from(Rgb(255, 0, 0, 0.4)),
      40.85261277607024,
      106.83899941284552,
      54.29173376861782,
      0.4,
    );
  });

  test('hcl(color) converts from another colorspace via rgb()', () {
    assertHclEqual(
      Hcl.from(_TestColor()),
      262.8292023352897,
      17.30347233219686,
      12.404844123471648,
      0.4,
    );
  });

  test('hcl.brighter(k) returns a brighter color if k > 0', () {
    final c = Hcl.parse('rgba(165, 42, 42, 0.4)');
    assertHclEqual(
      c.brighter(0.5),
      32.28342524928155,
      59.60231039142763,
      47.149667346714935,
      0.4,
    );
    assertHclEqual(
      c.brighter(1),
      32.28342524928155,
      59.60231039142763,
      56.149667346714935,
      0.4,
    );
    assertHclEqual(
      c.brighter(2),
      32.28342524928155,
      59.60231039142763,
      74.14966734671493,
      0.4,
    );
  });

  test('hcl.brighter(k) returns a copy', () {
    final c1 = Hcl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter(1);
    assertHclEqual(
      c1,
      255.71009124439382,
      33.88100417355615,
      51.98624890550498,
      0.4,
    );
    assertHclEqual(
      c2,
      255.71009124439382,
      33.88100417355615,
      69.98624890550498,
      0.4,
    );
  });

  test('hcl.brighter() is equivalent to hcl.brighter(1)', () {
    final c1 = Hcl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter();
    final c3 = c1.brighter(1);
    assertHclEqual(c2, c3.h, c3.c, c3.l, 0.4);
  });

  test('hcl.brighter(k) is equivalent to hcl.darker(-k)', () {
    final c1 = Hcl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter(1.5);
    final c3 = c1.darker(-1.5);
    assertHclEqual(c2, c3.h, c3.c, c3.l, 0.4);
  });

  test('hcl.darker(k) returns a darker color if k > 0', () {
    final c = Hcl.parse('rgba(165, 42, 42, 0.4)');
    assertHclEqual(
      c.darker(0.5),
      32.28342524928155,
      59.60231039142763,
      29.149667346714935,
      0.4,
    );
    assertHclEqual(
      c.darker(1),
      32.28342524928155,
      59.60231039142763,
      20.149667346714935,
      0.4,
    );
    assertHclEqual(
      c.darker(2),
      32.28342524928155,
      59.60231039142763,
      2.149667346714935,
      0.4,
    );
  });

  test('hcl.darker(k) returns a copy', () {
    final c1 = Hcl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker(1);
    assertHclEqual(
      c1,
      255.71009124439382,
      33.88100417355615,
      51.98624890550498,
      0.4,
    );
    assertHclEqual(
      c2,
      255.71009124439382,
      33.88100417355615,
      33.98624890550498,
      0.4,
    );
  });

  test('hcl.darker() is equivalent to hcl.darker(1)', () {
    final c1 = Hcl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker();
    final c3 = c1.darker(1);
    assertHclEqual(c2, c3.h, c3.c, c3.l, 0.4);
  });

  test('hcl.darker(k) is equivalent to hcl.brighter(-k)', () {
    final c1 = Hcl.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker(1.5);
    final c3 = c1.brighter(-1.5);
    assertHclEqual(c2, c3.h, c3.c, c3.l, 0.4);
  });

  test('hcl.rgb() converts to RGB', () {
    final c = Hcl(120, 30, 50, 0.4);
    assertRgbApproxEqual(c.rgb(), 105, 126, 73, 0.4);
  });
}
