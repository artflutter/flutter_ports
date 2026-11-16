// Ported from d3-interpolate v3.0.1 test/discrete-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

void main() {
  test('interpolateDiscrete(values)(t) returns the expected values', () {
    final i = interpolateDiscrete('abcde'.split(''));
    expect(i(-1), 'a');
    expect(i(0), 'a');
    expect(i(0.19), 'a');
    expect(i(0.21), 'b');
    expect(i(1), 'e');
  });

  test(
    'interpolateDiscrete([0, 1]) is equivalent to similar to Math.round',
    () {
      final i = interpolateDiscrete([0, 1]);
      expect(i(-1), 0);
      expect(i(0), 0);
      expect(i(0.49), 0);
      expect(i(0.51), 1);
      expect(i(1), 1);
      expect(i(2), 1);
    },
  );

  test('interpolateDiscrete(…)(NaN) returned undefined', () {
    // const i = interpolateDiscrete([0, 1]);
    // assert.strictEqual(i(NaN), undefined);
    //
    // Dart has no undefined: the result type of the interpolator has no
    // value for a NaN t, and the call throws.
  }, skip: 'diverges: adapt-interpolate-typed-values');
}
