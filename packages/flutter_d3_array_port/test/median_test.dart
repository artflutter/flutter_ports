// Ported from d3-array v3.2.4 test/median-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

typedef _Box = ({num? value});

_Box _box(num? value) => (value: value);
num? _unbox(_Box box) => box.value;

void main() {
  test('median(array) returns the median value for numbers', () {
    expect(median([1]), 1);
    expect(median([5, 1, 2, 3]), 2.5);
    expect(median([5, 1, 2, 3, 4]), 3);
    expect(median([20, 3]), 11.5);
    expect(median([3, 20]), 11.5);
  });

  test('median(array) ignores null, undefined and NaN', () {
    expect(median([double.nan, 1, 2, 3, 4, 5]), 3);
    expect(median([1, 2, 3, 4, 5, double.nan]), 3);
    expect(median([10, null, 3, null, 5, double.nan]), 5);
  });

  test('median(array) can handle large numbers without overflowing', () {
    expect(median([double.maxFinite, double.maxFinite]), double.maxFinite);
    expect(median([-double.maxFinite, -double.maxFinite]), -double.maxFinite);
  });

  test(
    'median(array) returns undefined if the array contains no observed values',
    () {
      expect(median(const <num>[]), isNull);
      expect(median([null]), isNull);
      expect(median([double.nan]), isNull);
      expect(median([double.nan, double.nan]), isNull);
    },
  );

  test(
    'median(array) coerces strings to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'median(array) coerces values exactly once',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('median(array, f) returns the median value for numbers', () {
    expect(medianBy([1].map(_box), _unbox), 1);
    expect(medianBy([5, 1, 2, 3, 4].map(_box), _unbox), 3);
    expect(medianBy([20, 3].map(_box), _unbox), 11.5);
    expect(medianBy([3, 20].map(_box), _unbox), 11.5);
  });

  test('median(array, f) ignores null, undefined and NaN', () {
    expect(medianBy([double.nan, 1, 2, 3, 4, 5].map(_box), _unbox), 3);
    expect(medianBy([1, 2, 3, 4, 5, double.nan].map(_box), _unbox), 3);
    expect(medianBy([10, null, 3, null, 5, double.nan].map(_box), _unbox), 5);
  });

  test('median(array, f) can handle large numbers without overflowing', () {
    expect(
      medianBy([double.maxFinite, double.maxFinite].map(_box), _unbox),
      double.maxFinite,
    );
    expect(
      medianBy([-double.maxFinite, -double.maxFinite].map(_box), _unbox),
      -double.maxFinite,
    );
  });

  test('median(array, f) returns undefined if the array contains no observed '
      'values', () {
    expect(medianBy(const <num>[].map(_box), _unbox), isNull);
    expect(medianBy([null].map(_box), _unbox), isNull);
    expect(medianBy([double.nan].map(_box), _unbox), isNull);
    expect(medianBy([double.nan, double.nan].map(_box), _unbox), isNull);
  });

  test(
    'median(array, f) coerces strings to numbers',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'median(array, f) coerces values exactly once',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('median(array, f) passes the accessor d, i, and array', () {
    final results = <(String, int, Iterable<String>)>[];
    final array = ['a', 'b', 'c'];
    medianByIndexed(array, (d, i, a) {
      results.add((d, i, a));
      return results.length;
    });
    expect(results, [('a', 0, array), ('b', 1, array), ('c', 2, array)]);
  });

  test(
    'median(array, f) uses the undefined context',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('medianIndex(array) returns the index', () {
    expect(medianIndex([1, 2]), 0);
    expect(medianIndex([1, 2, 3]), 1);
    expect(medianIndex([1, 3, 2]), 2);
    expect(medianIndex([2, 3, 1]), 0);
    expect(medianIndex([1]), 0);
    expect(medianIndex(const <num>[]), -1);
  });
}
