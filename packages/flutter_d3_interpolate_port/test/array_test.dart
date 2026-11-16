// Ported from d3-interpolate v3.0.1 test/array-test.js (ISC, Mike Bostock).
import 'dart:typed_data';

import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

void main() {
  test('interpolateArray(a, b) interpolates defined elements in a and b', () {
    expect(interpolateArray<double>([2, 12], [4, 24])(0.5), [3.0, 18.0]);
  });

  test('interpolateArray(a, b) interpolates nested objects and arrays', () {
    expect(
      interpolateArray<List<double>>(
        [
          [2, 12],
        ],
        [
          [4, 24],
        ],
      )(0.5),
      [
        [3.0, 18.0],
      ],
    );
    // assert.deepStrictEqual(
    //   interpolateArray([{foo: [2, 12]}], [{foo: [4, 24]}])(0.5),
    //   [{foo: [3, 18]}]);
    //
    // An object has no interpolator: interpolateObject has no Dart form
    // (adapt-interpolate-typed-values).
  });

  test('interpolateArray(a, b) ignores elements in a that are not in b', () {
    expect(interpolateArray<double>([2, 12, 12], [4, 24])(0.5), [3.0, 18.0]);
  });

  test(
    'interpolateArray(a, b) uses constant elements in b that are not in a',
    () {
      expect(interpolateArray<double>([2, 12], [4, 24, 12])(0.5), [
        3.0,
        18.0,
        12.0,
      ]);
    },
  );

  test('interpolateArray(a, b) treats undefined as an empty array', () {
    // assert.deepStrictEqual(interpolateArray(undefined, [2, 12])(0.5),
    //   [2, 12]);
    // assert.deepStrictEqual(interpolateArray([2, 12], undefined)(0.5), []);
    // assert.deepStrictEqual(interpolateArray(undefined, undefined)(0.5),
    //   []);
    //
    // Dart has no undefined, and a list parameter is not nullable.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolateArray(a, b) interpolates array-like objects', () {
    final array = Float64List(2);
    array[0] = 2;
    array[1] = 12;
    expect(interpolateArray<double>(array, [4, 24])(0.5), [3.0, 18.0]);
    // const args = (function() { return arguments; })(2, 12);
    // assert.deepStrictEqual(interpolateArray(args, [4, 24])(0.5), [3, 18]);
    //
    // A JavaScript arguments object has no Dart form; a typed-data list is
    // the array-like value of Dart (adapt-interpolate-typed-values).
  });

  test('interpolateArray(a, b) gives exact ends for t=0 and t=1', () {
    final a = [2e+42];
    final b = [335.0];
    expect(interpolateArray(a, b)(1), b);
    expect(interpolateArray(a, b)(0), a);
  });
}
