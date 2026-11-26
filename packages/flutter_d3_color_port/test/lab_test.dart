// Ported from d3-color v3.1.0 test/lab-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

import 'asserts.dart';

/// lab-test.js:118 `TestColor`: a color of another space, with `rgb()` and
/// a `toString()` that throws.
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
  test('lab(…) returns an instance of lab and color', () {
    const c = Lab(120, 40, 50);
    expect(c, isA<Lab>());
    expect(c, isA<Color>());
  });

  test('lab(…) exposes l, a and b channel values and opacity', () {
    assertLabEqual(
      Lab.parse('rgba(170, 187, 204, 0.4)'),
      74.96879980931759,
      -3.398998724348956,
      -10.696507207853333,
      0.4,
    );
  });

  test('lab.toString() converts to RGB and formats as rgb(…) or rgba(…)', () {
    expect(Lab.parse('#abcdef').toString(), 'rgb(171, 205, 239)');
    expect(Lab.parse('moccasin').toString(), 'rgb(255, 228, 181)');
    expect(Lab.parse('hsl(60, 100%, 20%)').toString(), 'rgb(102, 102, 0)');
    expect(
      Lab.parse('hsla(60, 100%, 20%, 0.4)').toString(),
      'rgba(102, 102, 0, 0.4)',
    );
    expect(Lab.parse('rgb(12, 34, 56)').toString(), 'rgb(12, 34, 56)');
    expect(Lab.from(const Rgb(12, 34, 56)).toString(), 'rgb(12, 34, 56)');
    expect(Lab.from(const Hsl(60, 1, 0.2)).toString(), 'rgb(102, 102, 0)');
    expect(
      Lab.from(const Hsl(60, 1, 0.2, 0.4)).toString(),
      'rgba(102, 102, 0, 0.4)',
    );
  });

  test('lab.toString() reflects l, a and b channel values and opacity', () {
    final c = Lab.parse('#abc');
    final modified = c.copy(
      l: c.l + 10,
      a: c.a - 10,
      b: c.b + 10,
      opacity: 0.4,
    );
    expect(modified.toString(), 'rgba(184, 220, 213, 0.4)');
  });

  test('lab.toString() treats undefined channel values as 0', () {
    expect(Lab.parse('invalid').toString(), 'rgb(0, 0, 0)');
    expect(const Lab(double.nan, 0, 0).toString(), 'rgb(0, 0, 0)');
    expect(const Lab(50, double.nan, 0).toString(), 'rgb(119, 119, 119)');
    expect(const Lab(50, 0, double.nan).toString(), 'rgb(119, 119, 119)');
    expect(
      const Lab(50, double.nan, double.nan).toString(),
      'rgb(119, 119, 119)',
    );
  });

  test('lab.toString() treats undefined opacity as 1', () {
    final c = Lab.parse('#abc').copy(opacity: double.nan);
    expect(c.toString(), 'rgb(170, 187, 204)');
  });

  test('lab(l, a, b) does not clamp l channel value', () {
    assertLabEqual(const Lab(-10, 1, 2), -10, 1, 2, 1);
    assertLabEqual(const Lab(0, 1, 2), 0, 1, 2, 1);
    assertLabEqual(const Lab(100, 1, 2), 100, 1, 2, 1);
    assertLabEqual(const Lab(110, 1, 2), 110, 1, 2, 1);
  });

  test('lab(l, a, b, opacity) does not clamp opacity to [0,1]', () {
    assertLabEqual(const Lab(50, 10, 20, -0.2), 50, 10, 20, -0.2);
    assertLabEqual(const Lab(50, 10, 20, 1.2), 50, 10, 20, 1.2);
  });

  test('lab(l, a, b) coerces channel values to numbers', () {
    // `lab("50", "4", "-5")`: the Dart constructor takes doubles only.
  }, skip: 'diverges: adapt-color-factories');

  test('lab(l, a, b, opacity) coerces opacity to number', () {
    // `lab(50, 4, -5, "0.2")`: the Dart constructor takes doubles only.
  }, skip: 'diverges: adapt-color-factories');

  test('lab(l, a, b) allows undefined channel values', () {
    // `lab(undefined, NaN, "foo")`: undefined and "foo" are NaN channels.
    assertLabEqual(
      const Lab(double.nan, double.nan, double.nan),
      double.nan,
      double.nan,
      double.nan,
      1,
    );
    // An undefined channel is NaN.
    assertLabEqual(const Lab(double.nan, 4, -5), double.nan, 4, -5, 1);
    assertLabEqual(const Lab(42, double.nan, -5), 42, double.nan, -5, 1);
    assertLabEqual(const Lab(42, 4, double.nan), 42, 4, double.nan, 1);
  });

  test('lab(l, a, b, opacity) converts undefined opacity to 1', () {
    // `lab(10, 20, 30, null)` and `lab(10, 20, 30, undefined)`: an omitted
    // opacity is 1.
    assertLabEqual(const Lab(10, 20, 30), 10, 20, 30, 1);
    assertLabEqual(const Lab(10, 20, 30), 10, 20, 30, 1);
  });

  test('lab(format) parses the specified format and converts to Lab', () {
    assertLabEqual(
      Lab.parse('#abcdef'),
      80.77135418262527,
      -5.957098328496224,
      -20.785782794739237,
      1,
    );
    assertLabEqual(
      Lab.parse('#abc'),
      74.96879980931759,
      -3.398998724348956,
      -10.696507207853333,
      1,
    );
    assertLabEqual(
      Lab.parse('rgb(12, 34, 56)'),
      12.404844123471648,
      -2.159950219712034,
      -17.168132391132946,
      1,
    );
    assertLabEqual(
      Lab.parse('rgb(12%, 34%, 56%)'),
      35.48300043476593,
      -2.507637675606522,
      -36.95112983195855,
      1,
    );
    assertLabEqual(
      Lab.parse('rgba(12%, 34%, 56%, 0.4)'),
      35.48300043476593,
      -2.507637675606522,
      -36.95112983195855,
      0.4,
    );
    assertLabEqual(
      Lab.parse('hsl(60,100%,20%)'),
      41.97125732118659,
      -8.03835128380484,
      47.65411917854332,
      1,
    );
    assertLabEqual(
      Lab.parse('hsla(60,100%,20%,0.4)'),
      41.97125732118659,
      -8.03835128380484,
      47.65411917854332,
      0.4,
    );
    assertLabEqual(
      Lab.parse('aliceblue'),
      97.12294991108756,
      -1.773836604137824,
      -4.332680308569969,
      1,
    );
  });

  test('lab(format) returns undefined channel values for unknown formats', () {
    assertLabEqual(
      Lab.parse('invalid'),
      double.nan,
      double.nan,
      double.nan,
      double.nan,
    );
  });

  test('lab(lab) copies a Lab color', () {
    // DIVERGES(d3-color): adapt-color-immutable, immutable Lab reused directly.
    const c1 = Lab(50, 4, -5, 0.4);
    final c2 = Lab.from(c1);
    expect(identical(c1, c2), isTrue);
    assertLabEqual(c1, 50, 4, -5, 0.4);
    assertLabEqual(c2, 50, 4, -5, 0.4);
  });

  test('lab(hcl(lab)) doesn’t lose a and b channels if luminance is zero', () {
    assertLabEqual(Lab.from(Hcl.from(const Lab(0, 10, 0))), 0, 10, 0, 1);
  });

  test('lab(rgb) converts from RGB', () {
    assertLabEqual(
      Lab.from(const Rgb(255, 0, 0, 0.4)),
      54.29173376861782,
      80.8124553179771,
      69.88504032350531,
      0.4,
    );
  });

  test('lab(color) converts from another colorspace via rgb()', () {
    assertLabEqual(
      Lab.from(_TestColor()),
      12.404844123471648,
      -2.159950219712034,
      -17.168132391132946,
      0.4,
    );
  });

  test('lab.brighter(k) returns a brighter color if k > 0', () {
    final c = Lab.parse('rgba(165, 42, 42, 0.4)');
    assertLabEqual(
      c.brighter(0.5),
      47.149667346714935,
      50.388769337115,
      31.834059255569358,
      0.4,
    );
    assertLabEqual(
      c.brighter(1),
      56.149667346714935,
      50.388769337115,
      31.834059255569358,
      0.4,
    );
    assertLabEqual(
      c.brighter(2),
      74.14966734671493,
      50.388769337115,
      31.834059255569358,
      0.4,
    );
  });

  test('lab.brighter(k) returns a copy', () {
    final c1 = Lab.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter(1);
    assertLabEqual(
      c1,
      51.98624890550498,
      -8.362792037014344,
      -32.832699449697685,
      0.4,
    );
    assertLabEqual(
      c2,
      69.98624890550498,
      -8.362792037014344,
      -32.832699449697685,
      0.4,
    );
  });

  test('lab.brighter() is equivalent to lab.brighter(1)', () {
    final c1 = Lab.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter();
    final c3 = c1.brighter(1);
    assertLabEqual(c2, c3.l, c3.a, c3.b, 0.4);
  });

  test('lab.brighter(k) is equivalent to lab.darker(-k)', () {
    final c1 = Lab.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.brighter(1.5);
    final c3 = c1.darker(-1.5);
    assertLabEqual(c2, c3.l, c3.a, c3.b, 0.4);
  });

  test('lab.darker(k) returns a darker color if k > 0', () {
    final c = Lab.parse('rgba(165, 42, 42, 0.4)');
    assertLabEqual(
      c.darker(0.5),
      29.149667346714935,
      50.388769337115,
      31.834059255569358,
      0.4,
    );
    assertLabEqual(
      c.darker(1),
      20.149667346714935,
      50.388769337115,
      31.834059255569358,
      0.4,
    );
    assertLabEqual(
      c.darker(2),
      2.149667346714935,
      50.388769337115,
      31.834059255569358,
      0.4,
    );
  });

  test('lab.darker(k) returns a copy', () {
    final c1 = Lab.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker(1);
    assertLabEqual(
      c1,
      51.98624890550498,
      -8.362792037014344,
      -32.832699449697685,
      0.4,
    );
    assertLabEqual(
      c2,
      33.98624890550498,
      -8.362792037014344,
      -32.832699449697685,
      0.4,
    );
  });

  test('lab.darker() is equivalent to lab.darker(1)', () {
    final c1 = Lab.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker();
    final c3 = c1.darker(1);
    assertLabEqual(c2, c3.l, c3.a, c3.b, 0.4);
  });

  test('lab.darker(k) is equivalent to lab.brighter(-k)', () {
    final c1 = Lab.parse('rgba(70, 130, 180, 0.4)');
    final c2 = c1.darker(1.5);
    final c3 = c1.brighter(-1.5);
    assertLabEqual(c2, c3.l, c3.a, c3.b, 0.4);
  });

  test('lab.rgb() converts to RGB', () {
    const c = Lab(50, 4, -5, 0.4);
    assertRgbApproxEqual(c.rgb(), 123, 117, 128, 0.4);
  });
}
