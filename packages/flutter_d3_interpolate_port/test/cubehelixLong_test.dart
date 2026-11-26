// Ported from d3-interpolate v3.0.1 test/cubehelixLong-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

// A CSS text of the spec is `color(text)!` at the call site, and an
// interpolator returns a Cubehelix whose `toString()` is the upstream RGB
// text (adapt-interpolate-color-values). The `null` color of the spec is
// `cubehelix(null)` upstream: a Cubehelix with NaN channels and a NaN
// opacity.

void main() {
  const nan = double.nan;

  test(
    'interpolateCubehelixLong(a, b) converts a and b to Cubehelix colors',
    () {
      expect(
        interpolateCubehelixLong(color('steelblue')!, color('brown')!)(0)
            .toString(),
        Rgb.parse('steelblue').toString(),
      );
      expect(
        interpolateCubehelixLong(color('steelblue')!, Hcl.parse('brown'))(1)
            .toString(),
        Rgb.parse('brown').toString(),
      );
      expect(
        interpolateCubehelixLong(color('steelblue')!, Rgb.parse('brown'))(1)
            .toString(),
        Rgb.parse('brown').toString(),
      );
    },
  );

  test('interpolateCubehelixLong(a, b) interpolates in Cubehelix and returns '
      'an RGB string', () {
    expect(
      interpolateCubehelixLong(color('steelblue')!, color('#f00')!)(0.2)
          .toString(),
      'rgb(88, 100, 218)',
    );
    expect(
      interpolateCubehelixLong(
        color('rgba(70, 130, 180, 1)')!,
        color('rgba(255, 0, 0, 0.2)')!,
      )(0.2).toString(),
      'rgba(88, 100, 218, 0.84)',
    );
  });

  test(
    'interpolateCubehelixLong.gamma(3)(a, b) returns the expected values',
    () {
      expect(
        interpolateCubehelixLong
            .gamma(3)(color('steelblue')!, color('#f00')!)(0.2)
            .toString(),
        'rgb(96, 107, 228)',
      );
    },
  );

  test(
    'interpolateCubehelixLong.gamma(g) coerces the specified gamma to a number',
    () {
      // assert.strictEqual(interpolateCubehelixLong.gamma({valueOf:
      //   function() { return 3; }})("steelblue", "#f00")(0.2),
      //   "rgb(96, 107, 228)");
      //
      // The Dart gamma is a double, with no valueOf coercion.
    },
    skip: 'diverges: adapt-interpolate-typed-values',
  );

  test('interpolateCubehelixLong(a, b) is equivalent to '
      'interpolateCubehelixLong.gamma(1)(a, b)', () {
    final i0 = interpolateCubehelixLong.gamma(1)(
      color('purple')!,
      color('orange')!,
    );
    final i1 = interpolateCubehelixLong(color('purple')!, color('orange')!);
    expect(i1(0).toString(), i0(0).toString());
    expect(i1(0.2).toString(), i0(0.2).toString());
    expect(i1(0.4).toString(), i0(0.4).toString());
    expect(i1(0.6).toString(), i0(0.6).toString());
    expect(i1(0.8).toString(), i0(0.8).toString());
    expect(i1(1).toString(), i0(1).toString());
  });

  test('interpolateCubehelixLong(a, b) uses the longest path when '
      'interpolating hue difference greater than 180°', () {
    final i = interpolateCubehelixLong(color('purple')!, color('orange')!);
    expect(i(0).toString(), 'rgb(128, 0, 128)');
    expect(i(0.2).toString(), 'rgb(63, 54, 234)');
    expect(i(0.4).toString(), 'rgb(0, 151, 217)');
    expect(i(0.6).toString(), 'rgb(0, 223, 83)');
    expect(i(0.8).toString(), 'rgb(79, 219, 0)');
    expect(i(1).toString(), 'rgb(255, 165, 0)');
  });

  test(
    'interpolateCubehelixLong(a, b) uses a’s hue when b’s hue is undefined',
    () {
      expect(
        interpolateCubehelixLong(color('#f60')!, const Hcl(nan, nan, 0))(0.5)
            .toString(),
        'rgb(162, 41, 0)',
      );
      expect(
        interpolateCubehelixLong(color('#6f0')!, const Hcl(nan, nan, 0))(0.5)
            .toString(),
        'rgb(3, 173, 0)',
      );
    },
  );

  test(
    'interpolateCubehelixLong(a, b) uses b’s hue when a’s hue is undefined',
    () {
      expect(
        interpolateCubehelixLong(const Hcl(nan, nan, 0), color('#f60')!)(0.5)
            .toString(),
        'rgb(162, 41, 0)',
      );
      expect(
        interpolateCubehelixLong(const Hcl(nan, nan, 0), color('#6f0')!)(0.5)
            .toString(),
        'rgb(3, 173, 0)',
      );
    },
  );

  test('interpolateCubehelixLong(a, b) uses a’s chroma when b’s chroma is '
      'undefined', () {
    expect(
      interpolateCubehelixLong(color('#ccc')!, const Hcl(nan, nan, 0))(0.5)
          .toString(),
      'rgb(102, 102, 102)',
    );
    expect(
      interpolateCubehelixLong(color('#f00')!, const Hcl(nan, nan, 0))(0.5)
          .toString(),
      'rgb(147, 0, 0)',
    );
  });

  test('interpolateCubehelixLong(a, b) uses b’s chroma when a’s chroma is '
      'undefined', () {
    expect(
      interpolateCubehelixLong(const Hcl(nan, nan, 0), color('#ccc')!)(0.5)
          .toString(),
      'rgb(102, 102, 102)',
    );
    expect(
      interpolateCubehelixLong(const Hcl(nan, nan, 0), color('#f00')!)(0.5)
          .toString(),
      'rgb(147, 0, 0)',
    );
  });

  test('interpolateCubehelixLong(a, b) uses b’s luminance when a’s luminance '
      'is undefined', () {
    expect(
      interpolateCubehelixLong(
        const Cubehelix(nan, nan, nan, nan),
        const Cubehelix(20, 1.5, 0.5),
      )(0.5).toString(),
      'rgb(248, 93, 0)',
    );
  });

  test('interpolateCubehelixLong(a, b) uses a’s luminance when b’s luminance '
      'is undefined', () {
    expect(
      interpolateCubehelixLong(
        const Cubehelix(20, 1.5, 0.5),
        const Cubehelix(nan, nan, nan, nan),
      )(0.5).toString(),
      'rgb(248, 93, 0)',
    );
  });
}
