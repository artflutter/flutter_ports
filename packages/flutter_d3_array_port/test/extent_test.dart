// Ported from d3-array v3.2.4 test/extent-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test(
    'extent(array) returns the least and greatest numeric values for numbers',
    () {
      expect(extent([1]), (1, 1));
      expect(extent([5, 1, 2, 3, 4]), (1, 5));
      expect(extent([20, 3]), (3, 20));
      expect(extent([3, 20]), (3, 20));
    },
  );

  test('extent(array) returns the least and greatest '
      'lexicographic value for strings', () {
    expect(extent(['c', 'a', 'b']), ('a', 'c'));
    expect(extent(['20', '3']), ('20', '3'));
    expect(extent(['3', '20']), ('20', '3'));
  });

  test('extent(array) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(extent<num>([double.nan, 1, 2, 3, 4, 5]), (1, 5));
    expect(extent<num>([1, 2, 3, 4, 5, double.nan]), (1, 5));
    expect(extent<num>([10, null, 3, null, 5, double.nan]), (3, 10));
    expect(extent<num>([-1, null, -3, null, -5, double.nan]), (-5, -1));
  });

  test(
    'extent(array) compares heterogenous types as numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('extent(array) returns undefined if the array contains no numbers', () {
    expect(extent<num>([]), isNull);
    expect(extent<num>([null]), isNull);
    expect(extent<num>([double.nan]), isNull);
    expect(extent<num>([double.nan, double.nan]), isNull);
  });

  test(
    'extent(array, f) returns the least and greatest numeric value for numbers',
    () {
      expect(extentBy([1].map(_box), _unbox<int>), (1, 1));
      expect(extentBy([5, 1, 2, 3, 4].map(_box), _unbox<int>), (1, 5));
      expect(extentBy([20, 3].map(_box), _unbox<int>), (3, 20));
      expect(extentBy([3, 20].map(_box), _unbox<int>), (3, 20));
    },
  );

  test('extent(array, f) returns the least and greatest '
      'lexicographic value for strings', () {
    expect(extentBy(['c', 'a', 'b'].map(_box), _unbox<String>), ('a', 'c'));
    expect(extentBy(['20', '3'].map(_box), _unbox<String>), ('20', '3'));
    expect(extentBy(['3', '20'].map(_box), _unbox<String>), ('20', '3'));
  });

  test('extent(array, f) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(
      extentBy<({num? value}), num>(
        [double.nan, 1, 2, 3, 4, 5].map(_box),
        _unbox,
      ),
      (1, 5),
    );
    expect(
      extentBy<({num? value}), num>(
        [1, 2, 3, 4, 5, double.nan].map(_box),
        _unbox,
      ),
      (1, 5),
    );
    expect(
      extentBy<({num? value}), num>(
        [10, null, 3, null, 5, double.nan].map(_box),
        _unbox,
      ),
      (3, 10),
    );
    expect(
      extentBy<({num? value}), num>(
        [-1, null, -3, null, -5, double.nan].map(_box),
        _unbox,
      ),
      (-5, -1),
    );
  });

  test(
    'extent(array, f) compares heterogenous types as numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('extent(array, f) returns undefined if the array '
      'contains no observed values', () {
    expect(extentBy<({num? value}), num>(<num?>[].map(_box), _unbox), isNull);
    expect(
      extentBy<({num? value}), num>(<num?>[null].map(_box), _unbox),
      isNull,
    );
    expect(
      extentBy<({num? value}), num>(<num?>[double.nan].map(_box), _unbox),
      isNull,
    );
    expect(
      extentBy<({num? value}), num>(
        <num?>[double.nan, double.nan].map(_box),
        _unbox,
      ),
      isNull,
    );
  });

  test('extent(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    extentByIndexed<String, num>(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'extent(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
