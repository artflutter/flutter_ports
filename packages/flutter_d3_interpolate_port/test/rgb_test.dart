// Ported from d3-interpolate v3.0.1 test/rgb-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

// A CSS text of the spec is `color(text)!` at the call site, and an
// interpolator returns an Rgb whose `toString()` is the upstream text
// (adapt-interpolate-color-values). The `null` color of the spec is
// `rgb(null)` upstream: an Rgb with NaN channels and a NaN opacity.

void main() {
  const nan = double.nan;

  test('interpolateRgb(a, b) converts a and b to RGB colors', () {
    expect(
      interpolateRgb(color('steelblue')!, color('brown')!)(0).toString(),
      Rgb.parse('steelblue').toString(),
    );
    expect(
      interpolateRgb(color('steelblue')!, Hsl.parse('brown'))(1).toString(),
      Rgb.parse('brown').toString(),
    );
    expect(
      interpolateRgb(color('steelblue')!, Rgb.parse('brown'))(1).toString(),
      Rgb.parse('brown').toString(),
    );
  });

  test(
    'interpolateRgb(a, b) interpolates in RGB and returns an RGB string',
    () {
      expect(
        interpolateRgb(color('steelblue')!, color('#f00')!)(0.2).toString(),
        'rgb(107, 104, 144)',
      );
      expect(
        interpolateRgb(
          color('rgba(70, 130, 180, 1)')!,
          color('rgba(255, 0, 0, 0.2)')!,
        )(0.2).toString(),
        'rgba(107, 104, 144, 0.84)',
      );
    },
  );

  test('interpolateRgb(a, b) uses b’s channel value when a’s channel value is '
      'undefined', () {
    expect(
      interpolateRgb(Rgb(nan, nan, nan, nan), Rgb(20, 40, 60))(0.5).toString(),
      Rgb(20, 40, 60).toString(),
    );
    expect(
      interpolateRgb(Rgb(nan, 20, 40), Rgb(60, 80, 100))(0.5).toString(),
      Rgb(60, 50, 70).toString(),
    );
    expect(
      interpolateRgb(Rgb(20, nan, 40), Rgb(60, 80, 100))(0.5).toString(),
      Rgb(40, 80, 70).toString(),
    );
    expect(
      interpolateRgb(Rgb(20, 40, nan), Rgb(60, 80, 100))(0.5).toString(),
      Rgb(40, 60, 100).toString(),
    );
  });

  test('interpolateRgb(a, b) uses a’s channel value when b’s channel value is '
      'undefined', () {
    expect(
      interpolateRgb(Rgb(20, 40, 60), Rgb(nan, nan, nan, nan))(0.5).toString(),
      Rgb(20, 40, 60).toString(),
    );
    expect(
      interpolateRgb(Rgb(60, 80, 100), Rgb(nan, 20, 40))(0.5).toString(),
      Rgb(60, 50, 70).toString(),
    );
    expect(
      interpolateRgb(Rgb(60, 80, 100), Rgb(20, nan, 40))(0.5).toString(),
      Rgb(40, 80, 70).toString(),
    );
    expect(
      interpolateRgb(Rgb(60, 80, 100), Rgb(20, 40, nan))(0.5).toString(),
      Rgb(40, 60, 100).toString(),
    );
  });

  test('interpolateRgb.gamma(3)(a, b) returns the expected values', () {
    expect(
      interpolateRgb
          .gamma(3)(color('steelblue')!, color('#f00')!)(0.2)
          .toString(),
      'rgb(153, 121, 167)',
    );
  });

  test(
    'interpolateRgb.gamma(3)(a, b) uses linear interpolation for opacity',
    () {
      expect(
        interpolateRgb
            .gamma(3)(color('transparent')!, color('#f00')!)(0.2)
            .toString(),
        'rgba(255, 0, 0, 0.2)',
      );
    },
  );

  test('interpolateRgb.gamma(g) coerces the specified gamma to a number', () {
    // assert.strictEqual(interpolateRgb.gamma({valueOf: function() {
    //   return 3; }})("steelblue", "#f00")(0.2), "rgb(153, 121, 167)");
    //
    // The Dart gamma is a double, with no valueOf coercion.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test(
    'interpolateRgb(a, b) is equivalent to interpolateRgb.gamma(1)(a, b)',
    () {
      final i0 = interpolateRgb.gamma(1)(color('purple')!, color('orange')!);
      final i1 = interpolateRgb(color('purple')!, color('orange')!);
      expect(i1(0).toString(), i0(0).toString());
      expect(i1(0.2).toString(), i0(0.2).toString());
      expect(i1(0.4).toString(), i0(0.4).toString());
      expect(i1(0.6).toString(), i0(0.6).toString());
      expect(i1(0.8).toString(), i0(0.8).toString());
      expect(i1(1).toString(), i0(1).toString());
    },
  );
}
