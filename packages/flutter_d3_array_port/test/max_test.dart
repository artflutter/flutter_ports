// Ported from d3-array v3.2.4 test/max-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test('max(array) returns the greatest numeric value for numbers', () {
    expect(max([1]), 1);
    expect(max([5, 1, 2, 3, 4]), 5);
    expect(max([20, 3]), 20);
    expect(max([3, 20]), 20);
  });

  test('max(array) returns the greatest lexicographic value for strings', () {
    expect(max(['c', 'a', 'b']), 'c');
    expect(max(['20', '3']), '3');
    expect(max(['3', '20']), '3');
  });

  test('max(array) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(max<num>([double.nan, 1, 2, 3, 4, 5]), 5);
    expect(max<num>([1, 2, 3, 4, 5, double.nan]), 5);
    expect(max<num>([10, null, 3, null, 5, double.nan]), 10);
    expect(max<num>([-1, null, -3, null, -5, double.nan]), -1);
  });

  test(
    'max(array) compares heterogenous types as numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('max(array) returns undefined if the array contains no numbers', () {
    expect(max<num>([]), isNull);
    expect(max<num>([null]), isNull);
    expect(max<num>([double.nan]), isNull);
    expect(max<num>([double.nan, double.nan]), isNull);
  });

  test('max(array, f) returns the greatest numeric value for numbers', () {
    expect(maxBy([1].map(_box), _unbox<int>), 1);
    expect(maxBy([5, 1, 2, 3, 4].map(_box), _unbox<int>), 5);
    expect(maxBy([20, 3].map(_box), _unbox<int>), 20);
    expect(maxBy([3, 20].map(_box), _unbox<int>), 20);
  });

  test(
    'max(array, f) returns the greatest lexicographic value for strings',
    () {
      expect(maxBy(['c', 'a', 'b'].map(_box), _unbox<String>), 'c');
      expect(maxBy(['20', '3'].map(_box), _unbox<String>), '3');
      expect(maxBy(['3', '20'].map(_box), _unbox<String>), '3');
    },
  );

  test('max(array, f) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(
      maxBy<({num? value}), num>([double.nan, 1, 2, 3, 4, 5].map(_box), _unbox),
      5,
    );
    expect(
      maxBy<({num? value}), num>([1, 2, 3, 4, 5, double.nan].map(_box), _unbox),
      5,
    );
    expect(
      maxBy<({num? value}), num>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      10,
    );
    expect(
      maxBy<({num? value}), num>(
        [-1, null, -3, null, -5, double.nan].map(_box),
        _unbox,
      ),
      -1,
    );
  });

  test(
    'max(array, f) compares heterogenous types as numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'max(array, f) returns undefined if the array contains no observed values',
    () {
      expect(maxBy<({num? value}), num>(<num?>[].map(_box), _unbox), isNull);
      expect(
        maxBy<({num? value}), num>(<num?>[null].map(_box), _unbox),
        isNull,
      );
      expect(
        maxBy<({num? value}), num>(<num?>[double.nan].map(_box), _unbox),
        isNull,
      );
      expect(
        maxBy<({num? value}), num>(
          <num?>[double.nan, double.nan].map(_box),
          _unbox,
        ),
        isNull,
      );
    },
  );

  test('max(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    maxByIndexed<String, num>(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'max(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
