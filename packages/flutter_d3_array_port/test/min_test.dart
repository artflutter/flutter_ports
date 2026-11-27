// Ported from d3-array v3.2.4 test/min-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test('min(array) returns the least numeric value for numbers', () {
    expect(min([1]), 1);
    expect(min([5, 1, 2, 3, 4]), 1);
    expect(min([20, 3]), 3);
    expect(min([3, 20]), 3);
  });

  test('min(array) returns the least lexicographic value for strings', () {
    expect(min(['c', 'a', 'b']), 'a');
    expect(min(['20', '3']), '20');
    expect(min(['3', '20']), '20');
  });

  test('min(array) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(min<num>([double.nan, 1, 2, 3, 4, 5]), 1);
    expect(min<num>([1, 2, 3, 4, 5, double.nan]), 1);
    expect(min<num>([10, null, 3, null, 5, double.nan]), 3);
    expect(min<num>([-1, null, -3, null, -5, double.nan]), -5);
  });

  test(
    'min(array) compares heterogenous types as numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('min(array) returns undefined if the array contains no numbers', () {
    expect(min<num>([]), isNull);
    expect(min<num>([null]), isNull);
    expect(min<num>([double.nan]), isNull);
    expect(min<num>([double.nan, double.nan]), isNull);
  });

  test('min(array, f) returns the least numeric value for numbers', () {
    expect(minBy([1].map(_box), _unbox<int>), 1);
    expect(minBy([5, 1, 2, 3, 4].map(_box), _unbox<int>), 1);
    expect(minBy([20, 3].map(_box), _unbox<int>), 3);
    expect(minBy([3, 20].map(_box), _unbox<int>), 3);
  });

  test('min(array, f) returns the least lexicographic value for strings', () {
    expect(minBy(['c', 'a', 'b'].map(_box), _unbox<String>), 'a');
    expect(minBy(['20', '3'].map(_box), _unbox<String>), '20');
    expect(minBy(['3', '20'].map(_box), _unbox<String>), '20');
  });

  test('min(array, f) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(
      minBy<({num? value}), num>([double.nan, 1, 2, 3, 4, 5].map(_box), _unbox),
      1,
    );
    expect(
      minBy<({num? value}), num>([1, 2, 3, 4, 5, double.nan].map(_box), _unbox),
      1,
    );
    expect(
      minBy<({num? value}), num>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      3,
    );
    expect(
      minBy<({num? value}), num>(
        [-1, null, -3, null, -5, double.nan].map(_box),
        _unbox,
      ),
      -5,
    );
  });

  test(
    'min(array, f) compares heterogenous types as numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'min(array, f) returns undefined if the array contains no observed values',
    () {
      expect(minBy<({num? value}), num>(<num?>[].map(_box), _unbox), isNull);
      expect(
        minBy<({num? value}), num>(<num?>[null].map(_box), _unbox),
        isNull,
      );
      expect(
        minBy<({num? value}), num>(<num?>[double.nan].map(_box), _unbox),
        isNull,
      );
      expect(
        minBy<({num? value}), num>(
          <num?>[double.nan, double.nan].map(_box),
          _unbox,
        ),
        isNull,
      );
    },
  );

  test('min(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    minByIndexed<String, num>(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'min(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
