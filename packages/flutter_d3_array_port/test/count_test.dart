// Ported from d3-array v3.2.4 test/count-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

Iterable<T> _generate<T>(Iterable<T> values) sync* {
  yield* values;
}

void main() {
  test('count() accepts an iterable', () {
    expect(count([1, 2]), 2);
    expect(count({1, 2}), 2);
    expect(count(_generate([1, 2])), 2);
  });

  test('count() ignores NaN, null', () {
    expect(count([double.nan, null, 0, 1]), 2);
  });

  test(
    'count() coerces to a number',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('count() accepts an accessor', () {
    expect(
      countBy<({num? v})>([
        (v: double.nan),
        (v: null),
        (v: 0),
        (v: 1),
      ], (d) => d.v),
      2,
    );
    expect(
      countBy<({String n, num? age})>([
        (n: 'Alice', age: double.nan),
        (n: 'Bob', age: 18),
        (n: 'Other', age: null),
      ], (d) => d.age),
      1,
    );
  });
}
