// Ported from d3-interpolate v3.0.1 test/hclLong-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

// A CSS text of the spec is `color(text)!` at the call site, and an
// interpolator returns an Hcl whose `toString()` is the upstream RGB text
// (adapt-interpolate-color-values). The `null` color of the spec is
// `hcl(null)` upstream: an Hcl with NaN channels and a NaN opacity.

void main() {
  const nan = double.nan;

  test('interpolateHclLong(a, b) converts a and b to HCL colors', () {
    expect(
      interpolateHclLong(color('steelblue')!, color('brown')!)(0).toString(),
      Rgb.parse('steelblue').toString(),
    );
    expect(
      interpolateHclLong(color('steelblue')!, Hcl.parse('brown'))(1).toString(),
      Rgb.parse('brown').toString(),
    );
    expect(
      interpolateHclLong(color('steelblue')!, Rgb.parse('brown'))(1).toString(),
      Rgb.parse('brown').toString(),
    );
  });

  test(
    'interpolateHclLong(a, b) interpolates in HCL and returns an RGB string',
    () {
      expect(
        interpolateHclLong(color('steelblue')!, color('#f00')!)(0.2).toString(),
        'rgb(0, 144, 169)',
      );
      expect(
        interpolateHclLong(
          color('rgba(70, 130, 180, 1)')!,
          color('rgba(255, 0, 0, 0.2)')!,
        )(0.2).toString(),
        'rgba(0, 144, 169, 0.84)',
      );
    },
  );

  test('interpolateHclLong(a, b) does not use the shortest path when '
      'interpolating hue', () {
    final i = interpolateHclLong(const Hcl(10, 50, 50), const Hcl(350, 50, 50));
    expect(i(0).toString(), 'rgb(194, 78, 107)');
    expect(i(0.2).toString(), 'rgb(151, 111, 28)');
    expect(i(0.4).toString(), 'rgb(35, 136, 68)');
    expect(i(0.6).toString(), 'rgb(0, 138, 165)');
    expect(i(0.8).toString(), 'rgb(91, 116, 203)');
    expect(i(1).toString(), 'rgb(189, 79, 136)');
  });

  test('interpolateHclLong(a, b) uses a’s hue when b’s hue is undefined', () {
    expect(
      interpolateHclLong(color('#f60')!, const Hcl(nan, nan, 0))(0.5)
          .toString(),
      'rgb(155, 0, 0)',
    );
    expect(
      interpolateHclLong(color('#6f0')!, const Hcl(nan, nan, 0))(0.5)
          .toString(),
      'rgb(0, 129, 0)',
    );
  });

  test('interpolateHclLong(a, b) uses b’s hue when a’s hue is undefined', () {
    expect(
      interpolateHclLong(const Hcl(nan, nan, 0), color('#f60')!)(0.5)
          .toString(),
      'rgb(155, 0, 0)',
    );
    expect(
      interpolateHclLong(const Hcl(nan, nan, 0), color('#6f0')!)(0.5)
          .toString(),
      'rgb(0, 129, 0)',
    );
  });

  test(
    'interpolateHclLong(a, b) uses a’s chroma when b’s chroma is undefined',
    () {
      expect(
        interpolateHclLong(color('#ccc')!, const Hcl(nan, nan, 0))(0.5)
            .toString(),
        'rgb(97, 97, 97)',
      );
      expect(
        interpolateHclLong(color('#f00')!, const Hcl(nan, nan, 0))(0.5)
            .toString(),
        'rgb(166, 0, 0)',
      );
    },
  );

  test(
    'interpolateHclLong(a, b) uses b’s chroma when a’s chroma is undefined',
    () {
      expect(
        interpolateHclLong(const Hcl(nan, nan, 0), color('#ccc')!)(0.5)
            .toString(),
        'rgb(97, 97, 97)',
      );
      expect(
        interpolateHclLong(const Hcl(nan, nan, 0), color('#f00')!)(0.5)
            .toString(),
        'rgb(166, 0, 0)',
      );
    },
  );

  test('interpolateHclLong(a, b) uses b’s luminance when a’s luminance is '
      'undefined', () {
    expect(
      interpolateHclLong(const Hcl(nan, nan, nan, nan), const Hcl(20, 80, 50))(
        0.5,
      ).toString(),
      'rgb(230, 13, 79)',
    );
  });

  test('interpolateHclLong(a, b) uses a’s luminance when b’s luminance is '
      'undefined', () {
    expect(
      interpolateHclLong(const Hcl(20, 80, 50), const Hcl(nan, nan, nan, nan))(
        0.5,
      ).toString(),
      'rgb(230, 13, 79)',
    );
  });
}
