// Original code, not ported from d3-interpolate: the color values of the port.

/// Pins the rows `adapt-interpolate-color-values` and
/// `adapt-interpolate-function-properties` for the color interpolators: an
/// interpolator takes d3-color colors and returns a new color of the class of
/// its space at each call, whose text is the upstream string; a factory with
/// a gamma is a callable object.
library;

import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

void main() {
  final a = color('steelblue')!;
  final b = color('brown')!;

  /// The interpolators of [a] and [b], with the class of their results.
  List<(String, Color Function(double t), Type)> interpolators() => [
    ('interpolateRgb', interpolateRgb(a, b), Rgb),
    ('interpolateRgb.gamma(2.2)', interpolateRgb.gamma(2.2)(a, b), Rgb),
    ('interpolateRgbBasis', interpolateRgbBasis([a, b, a]), Rgb),
    ('interpolateRgbBasisClosed', interpolateRgbBasisClosed([a, b]), Rgb),
    ('interpolateHsl', interpolateHsl(a, b), Hsl),
    ('interpolateHslLong', interpolateHslLong(a, b), Hsl),
    ('interpolateLab', interpolateLab(a, b), Lab),
    ('interpolateHcl', interpolateHcl(a, b), Hcl),
    ('interpolateHclLong', interpolateHclLong(a, b), Hcl),
    ('interpolateCubehelix', interpolateCubehelix(a, b), Cubehelix),
    ('interpolateCubehelixLong', interpolateCubehelixLong(a, b), Cubehelix),
    (
      'interpolateCubehelix.gamma(3)',
      interpolateCubehelix.gamma(3)(a, b),
      Cubehelix,
    ),
  ];

  test('repeated calls return equal immutable colors of the space', () {
    for (final (name, i, type) in interpolators()) {
      final x = i(0.3);
      final y = i(0.3);
      expect(x.runtimeType, type, reason: name);
      expect(x.toString(), y.toString(), reason: name);
    }
  });

  test(
    'an interpolator captures its endpoints and returns consistent results',
    () {
      const start = Rgb(70, 130, 180);
      const end = Hsl(0, 0.59, 0.41);
      final i = interpolateRgb(start, end);
      final text = i(0.5).toString();
      expect(start.toString(), 'rgb(70, 130, 180)');
      expect(i(0.5).toString(), text);
    },
  );

  test('the RGB splines have the opacity 1 and need a color', () {
    final i = interpolateRgbBasis([
      const Rgb(10, 20, 30, 0.2),
      const Rgb(40, 50, 60, 0.4),
    ]);
    expect(i(0.5).opacity, 1);
    expect(i(0.5).toString(), 'rgb(25, 35, 45)');
    expect(() => interpolateRgbBasis(const []), throwsArgumentError);
    expect(() => interpolateRgbBasisClosed(const []), throwsArgumentError);
  });

  test('gamma(y) gives a new factory and keeps the constant', () {
    final i3 = interpolateRgb.gamma(3);
    expect(i3, isA<InterpolateRgb>());
    expect(
      i3(color('steelblue')!, color('#f00')!)(0.2).toString(),
      'rgb(153, 121, 167)',
    );
    expect(
      interpolateRgb(color('steelblue')!, color('#f00')!)(0.2).toString(),
      'rgb(107, 104, 144)',
    );
    // cubehelixLong.gamma(y) keeps the long hue path of its factory.
    final long = interpolateCubehelixLong.gamma(1)(
      color('purple')!,
      color('orange')!,
    );
    expect(long(0.2).toString(), 'rgb(63, 54, 234)');
  });

  test('a factory tears off as a function of two colors', () {
    // piecewise and interpolate take a function of two colors: the
    // tear-off of `call` (the lint implicit_call_tearoffs asks for `.call`).
    final Color Function(double t) Function(Color a, Color b) f =
        interpolateCubehelix.call;
    final Color Function(double t) Function(Color a, Color b) g = interpolateRgb
        .gamma(2.2)
        .call;
    expect(f(a, b)(0).toString(), a.toString());
    expect(g(a, b)(1).toString(), b.toString());
  });
}
