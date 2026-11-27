// Ported from d3-array v3.2.4 test/mode-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

({T value}) _box<T>(T value) => (value: value);

T _unbox<T>(({T value}) box) => box.value;

void main() {
  test('mode(array) returns the most frequent value for numbers', () {
    expect(mode([1]), 1);
    expect(mode([5, 1, 1, 3, 4]), 1);
  });

  test('mode(array) returns the most frequent value for strings', () {
    expect(mode(['1']), '1');
    expect(mode(['5', '1', '1', '3', '4']), '1');
  });

  test(
    'mode(array) returns the most frequent value for heterogenous types',
    () {
      expect(mode<Object>(['1']), '1');
      expect(mode<Object>(['5', '1', '1', 2, 2, '2', 1, 1, 1, '3', '4']), 1);
      expect(mode<Object>(['5', 2, 2, '2', '2', 1, 1, 1, '3', '4']), 1);
    },
  );

  test('mode(array) returns the first of the most frequent values', () {
    expect(mode(['5', '1', '1', '2', '2', '3', '4']), '1');
  });

  test('mode(array) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(mode<num>([double.nan, 1, 1, 3, 4, 5]), 1);
    expect(mode<num>([1, double.nan, double.nan, 1, 5, double.nan]), 1);
    expect(mode<num>([1, null, null, 1, 5, null]), 1);
  });

  test(
    'mode(array) returns undefined if the array contains no comparable values',
    () {
      expect(mode<num>([]), isNull);
      expect(mode<num>([null]), isNull);
      expect(mode<num>([double.nan]), isNull);
      expect(mode<num>([double.nan, double.nan]), isNull);
    },
  );

  test('mode(array, f) returns the most frequent value for numbers', () {
    expect(modeBy([1].map(_box), _unbox<int>), 1);
    expect(modeBy([5, 1, 1, 3, 4].map(_box), _unbox<int>), 1);
  });

  test('mode(array, f) returns the most frequent value for strings', () {
    expect(modeBy(['1'].map(_box), _unbox<String>), '1');
    expect(modeBy(['5', '1', '1', '3', '4'].map(_box), _unbox<String>), '1');
  });

  test(
    'mode(array, f) returns the most frequent value for heterogenous types',
    () {
      expect(modeBy<({Object value}), Object>(['1'].map(_box), _unbox), '1');
      expect(
        modeBy<({Object value}), Object>(
          <Object>['5', '1', '1', 2, 2, '2', 1, 1, 1, '3', '4'].map(_box),
          _unbox,
        ),
        1,
      );
    },
  );

  test('mode(array, f) returns the first of the most frequent values', () {
    expect(
      modeBy(['5', '1', '1', '2', '2', '3', '4'].map(_box), _unbox<String>),
      '1',
    );
  });

  test('mode(array, f) ignores null, undefined and NaN', () {
    // {valueOf: () => NaN} object coercion omitted: adapt-array-typed-api.
    expect(
      modeBy<({num? value}), num>(
        [double.nan, 1, 1, 3, 4, 5].map(_box),
        _unbox,
      ),
      1,
    );
    expect(
      modeBy<({num? value}), num>(
        [1, double.nan, double.nan, 1, 5, double.nan].map(_box),
        _unbox,
      ),
      1,
    );
    expect(
      modeBy<({num? value}), num>(
        [1, null, null, 1, 5, null].map(_box),
        _unbox,
      ),
      1,
    );
  });

  test('mode(array, f) returns undefined if the array '
      'contains no comparable values', () {
    expect(modeBy<({num? value}), num>(<num?>[].map(_box), _unbox), isNull);
    expect(modeBy<({num? value}), num>(<num?>[null].map(_box), _unbox), isNull);
    expect(
      modeBy<({num? value}), num>(<num?>[double.nan].map(_box), _unbox),
      isNull,
    );
    expect(
      modeBy<({num? value}), num>(
        <num?>[double.nan, double.nan].map(_box),
        _unbox,
      ),
      isNull,
    );
  });

  test('mode(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    const array = ['a', 'b', 'c'];
    modeByIndexed<String, Object>(array, (d, i, a) {
      results.add((d, i, a));
      return null;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'mode(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
