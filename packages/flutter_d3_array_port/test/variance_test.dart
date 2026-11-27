// Ported from d3-array v3.2.4 test/variance-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test('variance(array) returns the variance of the specified numbers', () {
    expect(variance([5, 1, 2, 3, 4]), 2.5);
    expect(variance([20, 3]), 144.5);
    expect(variance([3, 20]), 144.5);
  });

  test('variance(array) ignores null, undefined and NaN', () {
    expect(variance([double.nan, 1, 2, 3, 4, 5]), 2.5);
    expect(variance([1, 2, 3, 4, 5, double.nan]), 2.5);
    expect(variance([10, null, 3, null, 5, double.nan]), 13);
  });

  test('variance(array) can handle large numbers without overflowing', () {
    expect(variance([double.maxFinite, double.maxFinite]), 0);
    expect(variance([-double.maxFinite, -double.maxFinite]), 0);
  });

  test(
    'variance(array) returns undefined if the array has fewer than two numbers',
    () {
      expect(variance([1]), isNull);
      expect(variance([]), isNull);
      expect(variance([null]), isNull);
      expect(variance([double.nan]), isNull);
      expect(variance([double.nan, double.nan]), isNull);
    },
  );

  test('variance(array, f) returns the variance of the specified numbers', () {
    expect(varianceBy([5, 1, 2, 3, 4].map(_box), _unbox), 2.5);
    expect(varianceBy([20, 3].map(_box), _unbox), 144.5);
    expect(varianceBy([3, 20].map(_box), _unbox), 144.5);
  });

  test('variance(array, f) ignores null, undefined and NaN', () {
    expect(
      varianceBy<({num? value})>([double.nan, 1, 2, 3, 4, 5].map(_box), _unbox),
      2.5,
    );
    expect(
      varianceBy<({num? value})>([1, 2, 3, 4, 5, double.nan].map(_box), _unbox),
      2.5,
    );
    expect(
      varianceBy<({num? value})>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      13,
    );
  });

  test('variance(array, f) can handle large numbers without overflowing', () {
    expect(
      varianceBy([double.maxFinite, double.maxFinite].map(_box), _unbox),
      0,
    );
    expect(
      varianceBy([-double.maxFinite, -double.maxFinite].map(_box), _unbox),
      0,
    );
  });

  test('variance(array, f) returns undefined if the array '
      'has fewer than two numbers', () {
    expect(varianceBy([1].map(_box), _unbox), isNull);
    expect(varianceBy<({num? value})>(<num?>[].map(_box), _unbox), isNull);
    expect(varianceBy<({num? value})>(<num?>[null].map(_box), _unbox), isNull);
    expect(
      varianceBy<({num? value})>(<num?>[double.nan].map(_box), _unbox),
      isNull,
    );
    expect(
      varianceBy<({num? value})>(
        <num?>[double.nan, double.nan].map(_box),
        _unbox,
      ),
      isNull,
    );
  });

  test('variance(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    varianceByIndexed(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'variance(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
