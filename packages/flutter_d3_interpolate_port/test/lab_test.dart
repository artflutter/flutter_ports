// Ported from d3-interpolate v3.0.1 test/lab-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

// A CSS text of the spec is `color(text)!` at the call site, and an
// interpolator returns a Lab whose `toString()` is the upstream RGB text
// (adapt-interpolate-color-values). The `null` color of the spec is
// `lab(null)` upstream: a Lab with NaN channels and a NaN opacity.

void main() {
  const nan = double.nan;

  test('interpolateLab(a, b) converts a and b to Lab colors', () {
    expect(
      interpolateLab(color('steelblue')!, color('brown')!)(0).toString(),
      Rgb.parse('steelblue').toString(),
    );
    expect(
      interpolateLab(color('steelblue')!, Hsl.parse('brown'))(1).toString(),
      Rgb.parse('brown').toString(),
    );
    expect(
      interpolateLab(color('steelblue')!, Rgb.parse('brown'))(1).toString(),
      Rgb.parse('brown').toString(),
    );
  });

  test(
    'interpolateLab(a, b) interpolates in Lab and returns an RGB string',
    () {
      expect(
        interpolateLab(color('steelblue')!, color('#f00')!)(0.2).toString(),
        'rgb(134, 120, 146)',
      );
      expect(
        interpolateLab(
          color('rgba(70, 130, 180, 1)')!,
          color('rgba(255, 0, 0, 0.2)')!,
        )(0.2).toString(),
        'rgba(134, 120, 146, 0.84)',
      );
    },
  );

  test('interpolateLab(a, b) uses b’s channel value when a’s channel value is '
      'undefined', () {
    expect(
      interpolateLab(Lab(nan, nan, nan, nan), Lab(20, 40, 60))(0.5).toString(),
      Lab(20, 40, 60).toString(),
    );
    expect(
      interpolateLab(Lab(nan, 20, 40), Lab(60, 80, 100))(0.5).toString(),
      Lab(60, 50, 70).toString(),
    );
    expect(
      interpolateLab(Lab(20, nan, 40), Lab(60, 80, 100))(0.5).toString(),
      Lab(40, 80, 70).toString(),
    );
    expect(
      interpolateLab(Lab(20, 40, nan), Lab(60, 80, 100))(0.5).toString(),
      Lab(40, 60, 100).toString(),
    );
  });

  test('interpolateLab(a, b) uses a’s channel value when b’s channel value is '
      'undefined', () {
    expect(
      interpolateLab(Lab(20, 40, 60), Lab(nan, nan, nan, nan))(0.5).toString(),
      Lab(20, 40, 60).toString(),
    );
    expect(
      interpolateLab(Lab(60, 80, 100), Lab(nan, 20, 40))(0.5).toString(),
      Lab(60, 50, 70).toString(),
    );
    expect(
      interpolateLab(Lab(60, 80, 100), Lab(20, nan, 40))(0.5).toString(),
      Lab(40, 80, 70).toString(),
    );
    expect(
      interpolateLab(Lab(60, 80, 100), Lab(20, 40, nan))(0.5).toString(),
      Lab(40, 60, 100).toString(),
    );
  });
}
