// Ported from d3-interpolate v3.0.1 test/hsl-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

// A CSS text of the spec is `color(text)!` at the call site, and an
// interpolator returns an Hsl whose `toString()` is the upstream RGB text
// (adapt-interpolate-color-values). The `null` color of the spec is
// `hsl(null)` upstream: an Hsl with NaN channels and a NaN opacity.

void main() {
  const nan = double.nan;

  test('interpolateHsl(a, b) converts a and b to HSL colors', () {
    expect(
      interpolateHsl(color('steelblue')!, color('brown')!)(0).toString(),
      Rgb.parse('steelblue').toString(),
    );
    expect(
      interpolateHsl(color('steelblue')!, Hsl.parse('brown'))(1).toString(),
      Rgb.parse('brown').toString(),
    );
    expect(
      interpolateHsl(color('steelblue')!, Rgb.parse('brown'))(1).toString(),
      Rgb.parse('brown').toString(),
    );
  });

  test(
    'interpolateHsl(a, b) interpolates in HSL and returns an RGB string',
    () {
      expect(
        interpolateHsl(color('steelblue')!, color('#f00')!)(0.2).toString(),
        'rgb(56, 61, 195)',
      );
      expect(
        interpolateHsl(
          color('rgba(70, 130, 180, 1)')!,
          color('rgba(255, 0, 0, 0.2)')!,
        )(0.2).toString(),
        'rgba(56, 61, 195, 0.84)',
      );
    },
  );

  test(
    'interpolateHsl(a, b) uses the shortest path when interpolating hue',
    () {
      final i = interpolateHsl(
        color('hsl(10,50%,50%)')!,
        color('hsl(350,50%,50%)')!,
      );
      expect(i(0).toString(), 'rgb(191, 85, 64)');
      expect(i(0.2).toString(), 'rgb(191, 77, 64)');
      expect(i(0.4).toString(), 'rgb(191, 68, 64)');
      expect(i(0.6).toString(), 'rgb(191, 64, 68)');
      expect(i(0.8).toString(), 'rgb(191, 64, 77)');
      expect(i(1).toString(), 'rgb(191, 64, 85)');
    },
  );

  test('interpolateHsl(a, b) uses a’s hue when b’s hue is undefined', () {
    expect(
      interpolateHsl(color('#f60')!, color('#000')!)(0.5).toString(),
      'rgb(128, 51, 0)',
    );
    expect(
      interpolateHsl(color('#6f0')!, color('#fff')!)(0.5).toString(),
      'rgb(179, 255, 128)',
    );
  });

  test('interpolateHsl(a, b) uses b’s hue when a’s hue is undefined', () {
    expect(
      interpolateHsl(color('#000')!, color('#f60')!)(0.5).toString(),
      'rgb(128, 51, 0)',
    );
    expect(
      interpolateHsl(color('#fff')!, color('#6f0')!)(0.5).toString(),
      'rgb(179, 255, 128)',
    );
  });

  test(
    'interpolateHsl(a, b) uses a’s saturation when b’s saturation is undefined',
    () {
      expect(
        interpolateHsl(color('#ccc')!, color('#000')!)(0.5).toString(),
        'rgb(102, 102, 102)',
      );
      expect(
        interpolateHsl(color('#f00')!, color('#000')!)(0.5).toString(),
        'rgb(128, 0, 0)',
      );
    },
  );

  test(
    'interpolateHsl(a, b) uses b’s saturation when a’s saturation is undefined',
    () {
      expect(
        interpolateHsl(color('#000')!, color('#ccc')!)(0.5).toString(),
        'rgb(102, 102, 102)',
      );
      expect(
        interpolateHsl(color('#000')!, color('#f00')!)(0.5).toString(),
        'rgb(128, 0, 0)',
      );
    },
  );

  test(
    'interpolateHsl(a, b) uses b’s lightness when a’s lightness is undefined',
    () {
      expect(
        interpolateHsl(const Hsl(nan, nan, nan, nan), const Hsl(20, 1, 0.5))(
          0.5,
        ).toString(),
        'rgb(255, 85, 0)',
      );
    },
  );

  test(
    'interpolateHsl(a, b) uses a’s lightness when b’s lightness is undefined',
    () {
      expect(
        interpolateHsl(const Hsl(20, 1, 0.5), const Hsl(nan, nan, nan, nan))(
          0.5,
        ).toString(),
        'rgb(255, 85, 0)',
      );
    },
  );
}
