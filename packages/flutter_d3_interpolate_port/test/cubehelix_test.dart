// Ported from d3-interpolate v3.0.1 test/cubehelix-test.js (ISC, Mike Bostock).
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

  test('interpolateCubehelix(a, b) converts a and b to Cubehelix colors', () {
    expect(
      interpolateCubehelix(color('steelblue')!, color('brown')!)(0).toString(),
      Rgb.parse('steelblue').toString(),
    );
    expect(
      interpolateCubehelix(color('steelblue')!, Hcl.parse('brown'))(1)
          .toString(),
      Rgb.parse('brown').toString(),
    );
    expect(
      interpolateCubehelix(color('steelblue')!, Rgb.parse('brown'))(1)
          .toString(),
      Rgb.parse('brown').toString(),
    );
  });

  test('interpolateCubehelix(a, b) interpolates in Cubehelix and returns an '
      'RGB string', () {
    expect(
      interpolateCubehelix(color('steelblue')!, color('#f00')!)(0.2).toString(),
      'rgb(88, 100, 218)',
    );
    expect(
      interpolateCubehelix(
        color('rgba(70, 130, 180, 1)')!,
        color('rgba(255, 0, 0, 0.2)')!,
      )(0.2).toString(),
      'rgba(88, 100, 218, 0.84)',
    );
  });

  test('interpolateCubehelix.gamma(3)(a, b) returns the expected values', () {
    expect(
      interpolateCubehelix
          .gamma(3)(color('steelblue')!, color('#f00')!)(0.2)
          .toString(),
      'rgb(96, 107, 228)',
    );
  });

  test(
    'interpolateCubehelix.gamma(g) coerces the specified gamma to a number',
    () {
      // assert.strictEqual(interpolateCubehelix.gamma({valueOf: function() {
      //   return 3; }})("steelblue", "#f00")(0.2), "rgb(96, 107, 228)");
      //
      // The Dart gamma is a double, with no valueOf coercion.
    },
    skip: 'diverges: adapt-interpolate-typed-values',
  );

  test('interpolateCubehelix(a, b) is equivalent to '
      'interpolateCubehelix.gamma(1)(a, b)', () {
    final i0 = interpolateCubehelix.gamma(1)(
      color('purple')!,
      color('orange')!,
    );
    final i1 = interpolateCubehelix(color('purple')!, color('orange')!);
    expect(i1(0).toString(), i0(0).toString());
    expect(i1(0.2).toString(), i0(0.2).toString());
    expect(i1(0.4).toString(), i0(0.4).toString());
    expect(i1(0.6).toString(), i0(0.6).toString());
    expect(i1(0.8).toString(), i0(0.8).toString());
    expect(i1(1).toString(), i0(1).toString());
  });

  test('interpolateCubehelix(a, b) uses the shortest path when interpolating '
      'hue difference greater than 180°', () {
    final i = interpolateCubehelix(color('purple')!, color('orange')!);
    expect(i(0).toString(), 'rgb(128, 0, 128)');
    expect(i(0.2).toString(), 'rgb(208, 1, 127)');
    expect(i(0.4).toString(), 'rgb(255, 17, 93)');
    expect(i(0.6).toString(), 'rgb(255, 52, 43)');
    expect(i(0.8).toString(), 'rgb(255, 105, 5)');
    expect(i(1).toString(), 'rgb(255, 165, 0)');
  });

  test('interpolateCubehelix(a, b) uses a’s hue when b’s hue is undefined', () {
    expect(
      interpolateCubehelix(color('#f60')!, Cubehelix(nan, nan, 0))(0.5)
          .toString(),
      'rgb(162, 41, 0)',
    );
    expect(
      interpolateCubehelix(color('#6f0')!, Cubehelix(nan, nan, 0))(0.5)
          .toString(),
      'rgb(3, 173, 0)',
    );
  });

  test('interpolateCubehelix(a, b) uses b’s hue when a’s hue is undefined', () {
    expect(
      interpolateCubehelix(Cubehelix(nan, nan, 0), color('#f60')!)(0.5)
          .toString(),
      'rgb(162, 41, 0)',
    );
    expect(
      interpolateCubehelix(Cubehelix(nan, nan, 0), color('#6f0')!)(0.5)
          .toString(),
      'rgb(3, 173, 0)',
    );
  });

  test(
    'interpolateCubehelix(a, b) uses a’s chroma when b’s chroma is undefined',
    () {
      expect(
        interpolateCubehelix(color('#ccc')!, Cubehelix(nan, nan, 0))(0.5)
            .toString(),
        'rgb(102, 102, 102)',
      );
      expect(
        interpolateCubehelix(color('#f00')!, Cubehelix(nan, nan, 0))(0.5)
            .toString(),
        'rgb(147, 0, 0)',
      );
    },
  );

  test(
    'interpolateCubehelix(a, b) uses b’s chroma when a’s chroma is undefined',
    () {
      expect(
        interpolateCubehelix(Cubehelix(nan, nan, 0), color('#ccc')!)(0.5)
            .toString(),
        'rgb(102, 102, 102)',
      );
      expect(
        interpolateCubehelix(Cubehelix(nan, nan, 0), color('#f00')!)(0.5)
            .toString(),
        'rgb(147, 0, 0)',
      );
    },
  );

  test('interpolateCubehelix(a, b) uses b’s luminance when a’s luminance is '
      'undefined', () {
    expect(
      interpolateCubehelix(
        Cubehelix(nan, nan, nan, nan),
        Cubehelix(20, 1.5, 0.5),
      )(0.5).toString(),
      'rgb(248, 93, 0)',
    );
  });

  test('interpolateCubehelix(a, b) uses a’s luminance when b’s luminance is '
      'undefined', () {
    expect(
      interpolateCubehelix(
        Cubehelix(20, 1.5, 0.5),
        Cubehelix(nan, nan, nan, nan),
      )(0.5).toString(),
      'rgb(248, 93, 0)',
    );
  });
}
