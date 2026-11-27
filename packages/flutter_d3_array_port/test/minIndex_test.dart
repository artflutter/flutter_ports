// Ported from d3-array v3.2.4 test/minIndex-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test(
    'minIndex(array) returns the index of the least numeric value for numbers',
    () {
      expect(minIndex([1]), 0);
      expect(minIndex([5, 1, 2, 3, 4]), 1);
      expect(minIndex([20, 3]), 1);
      expect(minIndex([3, 20]), 0);
    },
  );

  test('minIndex(array) returns the index of the least '
      'lexicographic value for strings', () {
    expect(minIndex(['c', 'a', 'b']), 1);
    expect(minIndex(['20', '3']), 0);
    expect(minIndex(['3', '20']), 1);
  });

  test('minIndex(array) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(minIndex<num>([double.nan, 1, 2, 3, 4, 5]), 1);
    expect(minIndex<num>([1, 2, 3, 4, 5, double.nan]), 0);
    expect(minIndex<num>([10, null, 3, null, 5, double.nan]), 2);
    expect(minIndex<num>([-1, null, -3, null, -5, double.nan]), 4);
  });

  test(
    'minIndex(array) compares heterogenous types as numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('minIndex(array) returns -1 if the array contains no numbers', () {
    expect(minIndex<num>([]), -1);
    expect(minIndex<num>([null]), -1);
    expect(minIndex<num>([double.nan]), -1);
    expect(minIndex<num>([double.nan, double.nan]), -1);
  });

  test('minIndex(array, f) returns the index of the least '
      'numeric value for numbers', () {
    expect(minIndexBy([1].map(_box), _unbox<int>), 0);
    expect(minIndexBy([5, 1, 2, 3, 4].map(_box), _unbox<int>), 1);
    expect(minIndexBy([20, 3].map(_box), _unbox<int>), 1);
    expect(minIndexBy([3, 20].map(_box), _unbox<int>), 0);
  });

  test('minIndex(array, f) returns the index of the least '
      'lexicographic value for strings', () {
    expect(minIndexBy(['c', 'a', 'b'].map(_box), _unbox<String>), 1);
    expect(minIndexBy(['20', '3'].map(_box), _unbox<String>), 0);
    expect(minIndexBy(['3', '20'].map(_box), _unbox<String>), 1);
  });

  test('minIndex(array, f) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(
      minIndexBy<({num? value}), num>(
        [double.nan, 1, 2, 3, 4, 5].map(_box),
        _unbox,
      ),
      1,
    );
    expect(
      minIndexBy<({num? value}), num>(
        [1, 2, 3, 4, 5, double.nan].map(_box),
        _unbox,
      ),
      0,
    );
    expect(
      minIndexBy<({num? value}), num>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      2,
    );
    expect(
      minIndexBy<({num? value}), num>(
        [-1, null, -3, null, -5, double.nan].map(_box),
        _unbox,
      ),
      4,
    );
  });

  test(
    'minIndex(array, f) compares heterogenous types as numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'minIndex(array, f) returns -1 if the array contains no observed values',
    () {
      expect(minIndexBy<({num? value}), num>(<num?>[].map(_box), _unbox), -1);
      expect(
        minIndexBy<({num? value}), num>(<num?>[null].map(_box), _unbox),
        -1,
      );
      expect(
        minIndexBy<({num? value}), num>(<num?>[double.nan].map(_box), _unbox),
        -1,
      );
      expect(
        minIndexBy<({num? value}), num>(
          <num?>[double.nan, double.nan].map(_box),
          _unbox,
        ),
        -1,
      );
    },
  );

  test('minIndex(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    minIndexByIndexed<String, num>(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'minIndex(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
