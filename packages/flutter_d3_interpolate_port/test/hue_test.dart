// Ported from d3-interpolate v3.0.1 test/hue-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

void main() {
  test('interpolateHue(a, b) interpolate numbers', () {
    // Upstream gives the texts "10" and "20", which `+a` converts. The
    // angles are doubles here (adapt-interpolate-typed-values).
    final i = interpolateHue(10, 20);
    expect(i(0), 10);
    expect(i(0.2), 12);
    expect(i(0.4), 14);
    expect(i(0.6), 16);
    expect(i(0.8), 18);
    expect(i(1), 20);
  });

  test('interpolateHue(a, b) returns a if b is NaN', () {
    final i = interpolateHue(10, double.nan);
    expect(i(0), 10);
    expect(i(0.5), 10);
    expect(i(1), 10);
  });

  test('interpolateHue(a, b) returns b if a is NaN', () {
    final i = interpolateHue(double.nan, 20);
    expect(i(0), 20);
    expect(i(0.5), 20);
    expect(i(1), 20);
  });

  test('interpolateHue(a, b) returns NaN if both a and b are NaN', () {
    final i = interpolateHue(double.nan, double.nan);
    expect(i(0), isNaN);
    expect(i(0.5), isNaN);
    expect(i(1), isNaN);
  });

  test('interpolateHue(a, b) uses the shortest path', () {
    final i = interpolateHue(10, 350);
    expect(i(0), 10);
    expect(i(0.2), 6);
    expect(i(0.4), 2);
    expect(i(0.6), 358);
    expect(i(0.8), 354);
    expect(i(1), 350);
  });
}
