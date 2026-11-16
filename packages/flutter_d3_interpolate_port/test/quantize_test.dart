// Ported from d3-interpolate v3.0.1 test/quantize-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

void main() {
  test('quantize(interpolate, n) returns n uniformly-spaced samples from the '
      'specified interpolator', () {
    expect(quantize(interpolateNumber(0, 1), 5), [
      0 / 4,
      1 / 4,
      2 / 4,
      3 / 4,
      4 / 4,
    ]);
    // The CSS texts convert at the call site, and each sample is an Rgb,
    // whose text is the upstream sample (adapt-interpolate-color-values).
    expect(
      quantize(
        interpolateRgb(Rgb.parse('steelblue'), Rgb.parse('brown')),
        5,
      ).map((c) => c.toString()),
      [
        'rgb(70, 130, 180)',
        'rgb(94, 108, 146)',
        'rgb(118, 86, 111)',
        'rgb(141, 64, 77)',
        'rgb(165, 42, 42)',
      ],
    );
  });
}
