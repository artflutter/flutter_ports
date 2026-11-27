// Ported from d3-array v3.2.4 test/cumsum-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test('cumsum(array) returns the cumulative sum of the specified numbers', () {
    final single = cumsum([1]);
    expect(single, isA<Float64List>());
    expect(single, [1]);
    expect(cumsum([5, 1, 2, 3, 4]), [5, 6, 8, 11, 15]);
    expect(cumsum([20, 3]), [20, 23]);
    expect(cumsum([3, 20]), [3, 23]);
  });

  test(
    'cumsum(array) observes values that can be coerced to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'cumsum(array) ignores non-numeric values',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('cumsum(array) ignores null, undefined and NaN', () {
    expect(cumsum([double.nan, 1, 2, 3, 4, 5]), [0, 1, 3, 6, 10, 15]);
    expect(cumsum([1, 2, 3, 4, 5, double.nan]), [1, 3, 6, 10, 15, 15]);
    expect(cumsum([10, null, 3, null, 5, double.nan]), [
      10,
      10,
      13,
      13,
      18,
      18,
    ]);
  });

  test('cumsum(array) returns zeros if there are no numbers', () {
    expect(cumsum([]), isEmpty);
    expect(cumsum([double.nan]), [0]);
    expect(cumsum([null]), [0]);
    expect(cumsum([null, double.nan]), [0, 0]);
    // Non-numeric {} omitted: adapt-array-typed-api.
  });

  test('cumsum(array, f) returns the cumsum of the specified numbers', () {
    expect(cumsumBy([1].map(_box), _unbox), [1]);
    expect(cumsumBy([5, 1, 2, 3, 4].map(_box), _unbox), [5, 6, 8, 11, 15]);
    expect(cumsumBy([20, 3].map(_box), _unbox), [20, 23]);
    expect(cumsumBy([3, 20].map(_box), _unbox), [3, 23]);
  });

  test(
    'cumsum(array, f) observes values that can be coerced to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'cumsum(array, f) ignores non-numeric values',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('cumsum(array, f) ignores null, undefined and NaN', () {
    expect(
      cumsumBy<({num? value})>([double.nan, 1, 2, 3, 4, 5].map(_box), _unbox),
      [0, 1, 3, 6, 10, 15],
    );
    expect(
      cumsumBy<({num? value})>([1, 2, 3, 4, 5, double.nan].map(_box), _unbox),
      [1, 3, 6, 10, 15, 15],
    );
    expect(
      cumsumBy<({num? value})>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      [10, 10, 13, 13, 18, 18],
    );
  });

  test('cumsum(array, f) returns zeros if there are no numbers', () {
    expect(cumsumBy<({num? value})>(<num?>[].map(_box), _unbox), isEmpty);
    expect(cumsumBy<({num? value})>(<num?>[double.nan].map(_box), _unbox), [0]);
    expect(cumsumBy<({num? value})>(<num?>[null].map(_box), _unbox), [0]);
    expect(
      cumsumBy<({num? value})>(<num?>[null, double.nan].map(_box), _unbox),
      [0, 0],
    );
    // Non-numeric {} omitted: adapt-array-typed-api.
  });

  test('cumsum(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    cumsumByIndexed(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'cumsum(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
