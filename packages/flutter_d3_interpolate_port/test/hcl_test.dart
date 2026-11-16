// Ported from d3-interpolate v3.0.1 test/hcl-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

// A CSS text of the spec is `color(text)!` at the call site, and an
// interpolator returns an Hcl whose `toString()` is the upstream RGB text
// (adapt-interpolate-color-values). The `null` color of the spec is
// `hcl(null)` upstream: an Hcl with NaN channels and a NaN opacity.

void main() {
  const nan = double.nan;

  test('interpolateHcl(a, b) converts a and b to HCL colors', () {
    expect(
      interpolateHcl(color('steelblue')!, color('brown')!)(0).toString(),
      Rgb.parse('steelblue').toString(),
    );
    expect(
      interpolateHcl(color('steelblue')!, Hcl.parse('brown'))(1).toString(),
      Rgb.parse('brown').toString(),
    );
    expect(
      interpolateHcl(color('steelblue')!, Rgb.parse('brown'))(1).toString(),
      Rgb.parse('brown').toString(),
    );
  });

  test(
    'interpolateHcl(a, b) interpolates in HCL and returns an RGB string',
    () {
      expect(
        interpolateHcl(color('steelblue')!, color('#f00')!)(0.2).toString(),
        'rgb(106, 121, 206)',
      );
      expect(
        interpolateHcl(
          color('rgba(70, 130, 180, 1)')!,
          color('rgba(255, 0, 0, 0.2)')!,
        )(0.2).toString(),
        'rgba(106, 121, 206, 0.84)',
      );
    },
  );

  test('interpolateHcl(a, b) uses the shortest path when interpolating hue '
      'difference greater than 180°', () {
    final i = interpolateHcl(Hcl(10, 50, 50), Hcl(350, 50, 50));
    expect(i(0).toString(), 'rgb(194, 78, 107)');
    expect(i(0.2).toString(), 'rgb(194, 78, 113)');
    expect(i(0.4).toString(), 'rgb(193, 78, 118)');
    expect(i(0.6).toString(), 'rgb(192, 78, 124)');
    expect(i(0.8).toString(), 'rgb(191, 78, 130)');
    expect(i(1).toString(), 'rgb(189, 79, 136)');
  });

  test('interpolateHcl(a, b) uses the shortest path when interpolating hue '
      'difference greater than 360°', () {
    final i = interpolateHcl(Hcl(10, 50, 50), Hcl(380, 50, 50));
    expect(i(0).toString(), 'rgb(194, 78, 107)');
    expect(i(0.2).toString(), 'rgb(194, 78, 104)');
    expect(i(0.4).toString(), 'rgb(194, 79, 101)');
    expect(i(0.6).toString(), 'rgb(194, 79, 98)');
    expect(i(0.8).toString(), 'rgb(194, 80, 96)');
    expect(i(1).toString(), 'rgb(194, 80, 93)');
  });

  test('interpolateHcl(a, b) uses the shortest path when interpolating hue '
      'difference greater than 540°', () {
    final i = interpolateHcl(Hcl(10, 50, 50), Hcl(710, 50, 50));
    expect(i(0).toString(), 'rgb(194, 78, 107)');
    expect(i(0.2).toString(), 'rgb(194, 78, 113)');
    expect(i(0.4).toString(), 'rgb(193, 78, 118)');
    expect(i(0.6).toString(), 'rgb(192, 78, 124)');
    expect(i(0.8).toString(), 'rgb(191, 78, 130)');
    expect(i(1).toString(), 'rgb(189, 79, 136)');
  });

  test('interpolateHcl(a, b) uses the shortest path when interpolating hue '
      'difference greater than 720°', () {
    final i = interpolateHcl(Hcl(10, 50, 50), Hcl(740, 50, 50));
    expect(i(0).toString(), 'rgb(194, 78, 107)');
    expect(i(0.2).toString(), 'rgb(194, 78, 104)');
    expect(i(0.4).toString(), 'rgb(194, 79, 101)');
    expect(i(0.6).toString(), 'rgb(194, 79, 98)');
    expect(i(0.8).toString(), 'rgb(194, 80, 96)');
    expect(i(1).toString(), 'rgb(194, 80, 93)');
  });

  test('interpolateHcl(a, b) uses a’s hue when b’s hue is undefined', () {
    expect(
      interpolateHcl(color('#f60')!, Hcl(nan, nan, 0))(0.5).toString(),
      'rgb(155, 0, 0)',
    );
    expect(
      interpolateHcl(color('#6f0')!, Hcl(nan, nan, 0))(0.5).toString(),
      'rgb(0, 129, 0)',
    );
  });

  test('interpolateHcl(a, b) uses b’s hue when a’s hue is undefined', () {
    expect(
      interpolateHcl(Hcl(nan, nan, 0), color('#f60')!)(0.5).toString(),
      'rgb(155, 0, 0)',
    );
    expect(
      interpolateHcl(Hcl(nan, nan, 0), color('#6f0')!)(0.5).toString(),
      'rgb(0, 129, 0)',
    );
  });

  test('interpolateHcl(a, b) uses a’s chroma when b’s chroma is undefined', () {
    expect(
      interpolateHcl(color('#ccc')!, Hcl(nan, nan, 0))(0.5).toString(),
      'rgb(97, 97, 97)',
    );
    expect(
      interpolateHcl(color('#f00')!, Hcl(nan, nan, 0))(0.5).toString(),
      'rgb(166, 0, 0)',
    );
  });

  test('interpolateHcl(a, b) uses b’s chroma when a’s chroma is undefined', () {
    expect(
      interpolateHcl(Hcl(nan, nan, 0), color('#ccc')!)(0.5).toString(),
      'rgb(97, 97, 97)',
    );
    expect(
      interpolateHcl(Hcl(nan, nan, 0), color('#f00')!)(0.5).toString(),
      'rgb(166, 0, 0)',
    );
  });

  test(
    'interpolateHcl(a, b) uses b’s luminance when a’s luminance is undefined',
    () {
      expect(
        interpolateHcl(Hcl(nan, nan, nan, nan), Hcl(20, 80, 50))(0.5)
            .toString(),
        'rgb(230, 13, 79)',
      );
    },
  );

  test(
    'interpolateHcl(a, b) uses a’s luminance when b’s luminance is undefined',
    () {
      expect(
        interpolateHcl(Hcl(20, 80, 50), Hcl(nan, nan, nan, nan))(0.5)
            .toString(),
        'rgb(230, 13, 79)',
      );
    },
  );
}
