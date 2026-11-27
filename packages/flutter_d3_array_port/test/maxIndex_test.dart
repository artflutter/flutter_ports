// Ported from d3-array v3.2.4 test/maxIndex-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test('maxIndex(array) returns the index of the greatest '
      'numeric value for numbers', () {
    expect(maxIndex([1]), 0);
    expect(maxIndex([5, 1, 2, 3, 4]), 0);
    expect(maxIndex([20, 3]), 0);
    expect(maxIndex([3, 20]), 1);
  });

  test(
    'maxIndex(array) returns the greatest lexicographic value for strings',
    () {
      expect(maxIndex(['c', 'a', 'b']), 0);
      expect(maxIndex(['20', '3']), 1);
      expect(maxIndex(['3', '20']), 0);
    },
  );

  test('maxIndex(array) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(maxIndex<num>([double.nan, 1, 2, 3, 4, 5]), 5);
    expect(maxIndex<num>([1, 2, 3, 4, 5, double.nan]), 4);
    expect(maxIndex<num>([10, null, 3, null, 5, double.nan]), 0);
    expect(maxIndex<num>([-1, null, -3, null, -5, double.nan]), 0);
  });

  test(
    'maxIndex(array) compares heterogenous types as numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('maxIndex(array) returns -1 if the array contains no numbers', () {
    expect(maxIndex<num>([]), -1);
    expect(maxIndex<num>([null]), -1);
    expect(maxIndex<num>([double.nan]), -1);
    expect(maxIndex<num>([double.nan, double.nan]), -1);
  });

  test('maxIndex(array, f) returns the greatest numeric value for numbers', () {
    expect(maxIndexBy([1].map(_box), _unbox<int>), 0);
    expect(maxIndexBy([5, 1, 2, 3, 4].map(_box), _unbox<int>), 0);
    expect(maxIndexBy([20, 3].map(_box), _unbox<int>), 0);
    expect(maxIndexBy([3, 20].map(_box), _unbox<int>), 1);
  });

  test(
    'maxIndex(array, f) returns the greatest lexicographic value for strings',
    () {
      expect(maxIndexBy(['c', 'a', 'b'].map(_box), _unbox<String>), 0);
      expect(maxIndexBy(['20', '3'].map(_box), _unbox<String>), 1);
      expect(maxIndexBy(['3', '20'].map(_box), _unbox<String>), 0);
    },
  );

  test('maxIndex(array, f) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(
      maxIndexBy<({num? value}), num>(
        [double.nan, 1, 2, 3, 4, 5].map(_box),
        _unbox,
      ),
      5,
    );
    expect(
      maxIndexBy<({num? value}), num>(
        [1, 2, 3, 4, 5, double.nan].map(_box),
        _unbox,
      ),
      4,
    );
    expect(
      maxIndexBy<({num? value}), num>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      0,
    );
    expect(
      maxIndexBy<({num? value}), num>(
        [-1, null, -3, null, -5, double.nan].map(_box),
        _unbox,
      ),
      0,
    );
  });

  test(
    'maxIndex(array, f) compares heterogenous types as numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'maxIndex(array, f) returns -1 if the array contains no observed values',
    () {
      expect(maxIndexBy<({num? value}), num>(<num?>[].map(_box), _unbox), -1);
      expect(
        maxIndexBy<({num? value}), num>(<num?>[null].map(_box), _unbox),
        -1,
      );
      expect(
        maxIndexBy<({num? value}), num>(<num?>[double.nan].map(_box), _unbox),
        -1,
      );
      expect(
        maxIndexBy<({num? value}), num>(
          <num?>[double.nan, double.nan].map(_box),
          _unbox,
        ),
        -1,
      );
    },
  );

  test('maxIndex(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    maxIndexByIndexed<String, num>(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'maxIndex(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
