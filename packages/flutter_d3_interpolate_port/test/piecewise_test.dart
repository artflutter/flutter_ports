// Ported from d3-interpolate v3.0.1 test/piecewise-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

void main() {
  test('piecewise(interpolate, values)(t) returns the expected values', () {
    final i = piecewise<double>([0, 2, 10], interpolate: interpolate);
    expect(i(-1), -4);
    expect(i(0), 0);
    expect(i(0.19), 0.76);
    expect(i(0.21), 0.84);
    expect(i(0.5), 2);
    expect(i(0.75), 6);
    expect(i(1), 10);
  });

  test('piecewise(values) uses the default interpolator', () {
    final i = piecewise<double>([0, 2, 10]);
    expect(i(-1), -4);
    expect(i(0), 0);
    expect(i(0.19), 0.76);
    expect(i(0.21), 0.84);
    expect(i(0.5), 2);
    expect(i(0.75), 6);
    expect(i(1), 10);
  });

  test('piecewise(values) uses the default interpolator/2', () {
    // const i = piecewise(["a0", "a2", "a10"]);
    // assert.strictEqual(i(-1), "a-4");
    // assert.strictEqual(i(0), "a0");
    // assert.strictEqual(i(0.19), "a0.76");
    // assert.strictEqual(i(0.21), "a0.84");
    // assert.strictEqual(i(0.5), "a2");
    // assert.strictEqual(i(0.75), "a6");
    // assert.strictEqual(i(1), "a10");
    //
    // A String has no interpolator: interpolateString has no Dart form.
  }, skip: 'diverges: adapt-interpolate-typed-values');
}
