// Ported from d3-array v3.2.4 test/bisect-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('bisect is an alias for bisectRight', () {
    const numbers = [1, 2, 2, 3];
    for (final x in const [0, 1, 2, 3, 4]) {
      expect(bisect(numbers, x), bisectRight(numbers, x));
    }
  });

  test('bisectLeft(array, value) returns the index of an exact match', () {
    const numbers = [1, 2, 3];
    expect(bisectLeft(numbers, 1), 0);
    expect(bisectLeft(numbers, 2), 1);
    expect(bisectLeft(numbers, 3), 2);
  });

  test('bisectLeft(array, value) returns the index of the first match', () {
    const numbers = [1, 2, 2, 3];
    expect(bisectLeft(numbers, 1), 0);
    expect(bisectLeft(numbers, 2), 1);
    expect(bisectLeft(numbers, 3), 3);
  });

  test('bisectLeft(empty, value) returns zero', () {
    expect(bisectLeft(const <int>[], 1), 0);
  });

  test(
    'bisectLeft(array, value) returns the insertion point of a non-exact match',
    () {
      const numbers = <num>[1, 2, 3];
      expect(bisectLeft(numbers, 0.5), 0);
      expect(bisectLeft(numbers, 1.5), 1);
      expect(bisectLeft(numbers, 2.5), 2);
      expect(bisectLeft(numbers, 3.5), 3);
    },
  );

  test('bisectLeft(array, value) has undefined behavior if the search value is '
      'unorderable', () {
    const numbers = <num>[1, 2, 3];
    expect(bisectLeft(numbers, null), isA<int>());
    expect(bisectLeft(numbers, double.nan), isA<int>());
  });

  test('bisectLeft(array, value, lo) observes the specified lower bound', () {
    const numbers = [1, 2, 3, 4, 5];
    expect(bisectLeft(numbers, 0, 2), 2);
    expect(bisectLeft(numbers, 1, 2), 2);
    expect(bisectLeft(numbers, 2, 2), 2);
    expect(bisectLeft(numbers, 3, 2), 2);
    expect(bisectLeft(numbers, 4, 2), 3);
    expect(bisectLeft(numbers, 5, 2), 4);
    expect(bisectLeft(numbers, 6, 2), 5);
  });

  test('bisectLeft(array, value, lo, hi) observes the specified bounds', () {
    const numbers = [1, 2, 3, 4, 5];
    expect(bisectLeft(numbers, 0, 2, 3), 2);
    expect(bisectLeft(numbers, 1, 2, 3), 2);
    expect(bisectLeft(numbers, 2, 2, 3), 2);
    expect(bisectLeft(numbers, 3, 2, 3), 2);
    expect(bisectLeft(numbers, 4, 2, 3), 3);
    expect(bisectLeft(numbers, 5, 2, 3), 3);
    expect(bisectLeft(numbers, 6, 2, 3), 3);
  });

  test(
    'bisectLeft(array, value) handles large sparse d3',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('bisectRight(array, value) returns the index after an exact match', () {
    const numbers = [1, 2, 3];
    expect(bisectRight(numbers, 1), 1);
    expect(bisectRight(numbers, 2), 2);
    expect(bisectRight(numbers, 3), 3);
  });

  test('bisectRight(array, value) returns the index after the last match', () {
    const numbers = [1, 2, 2, 3];
    expect(bisectRight(numbers, 1), 1);
    expect(bisectRight(numbers, 2), 3);
    expect(bisectRight(numbers, 3), 4);
  });

  test('bisectRight(empty, value) returns zero', () {
    expect(bisectRight(const <int>[], 1), 0);
  });

  test('bisectRight(array, value) returns the insertion point of a non-exact '
      'match', () {
    const numbers = <num>[1, 2, 3];
    expect(bisectRight(numbers, 0.5), 0);
    expect(bisectRight(numbers, 1.5), 1);
    expect(bisectRight(numbers, 2.5), 2);
    expect(bisectRight(numbers, 3.5), 3);
  });

  test('bisectRight(array, value, lo) observes the specified lower bound', () {
    const numbers = [1, 2, 3, 4, 5];
    expect(bisectRight(numbers, 0, 2), 2);
    expect(bisectRight(numbers, 1, 2), 2);
    expect(bisectRight(numbers, 2, 2), 2);
    expect(bisectRight(numbers, 3, 2), 3);
    expect(bisectRight(numbers, 4, 2), 4);
    expect(bisectRight(numbers, 5, 2), 5);
    expect(bisectRight(numbers, 6, 2), 5);
  });

  test('bisectRight(array, value, lo, hi) observes the specified bounds', () {
    const numbers = [1, 2, 3, 4, 5];
    expect(bisectRight(numbers, 0, 2, 3), 2);
    expect(bisectRight(numbers, 1, 2, 3), 2);
    expect(bisectRight(numbers, 2, 2, 3), 2);
    expect(bisectRight(numbers, 3, 2, 3), 3);
    expect(bisectRight(numbers, 4, 2, 3), 3);
    expect(bisectRight(numbers, 5, 2, 3), 3);
    expect(bisectRight(numbers, 6, 2, 3), 3);
  });

  test(
    'bisectRight(array, value) handles large sparse d3',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'bisectLeft(array, value, lo, hi) keeps non-comparable values to the right',
    () {
      const values = <num?>[1, 2, null, null, double.nan];
      expect(bisectLeft(values, 1), 0);
      expect(bisectLeft(values, 2), 1);
      expect(bisectLeft(values, null), 5);
      expect(bisectLeft(values, double.nan), 5);
    },
  );

  test(
    'bisectLeft(array, value, lo, hi) keeps comparable values to the left',
    () {
      const values = <num?>[null, null, double.nan];
      expect(bisectLeft(values, 1), 0);
      expect(bisectLeft(values, 2), 0);
    },
  );

  test('bisectRight(array, value, lo, hi) keeps non-comparable values to the '
      'right', () {
    const values = <num?>[1, 2, null, null];
    expect(bisectRight(values, 1), 1);
    expect(bisectRight(values, 2), 2);
    expect(bisectRight(values, null), 4);
    expect(bisectRight(values, double.nan), 4);
  });

  test('bisectCenter and bisectCenterDate return the closest index', () {
    const data = <num>[0, 1, 2, 3, 4];
    expect(bisectCenter(data, 2), 2);
    expect(bisectCenter(data, 2.2), 2);
    expect(bisectCenter(data, 2.6), 3);
    expect(bisectCenter(data, 3), 3);
    expect(bisectCenter(data, 4.5), 4);

    final dates = [
      DateTime.utc(2020),
      DateTime.utc(2020, 1, 11),
      DateTime.utc(2020, 1, 21),
    ];
    expect(bisectCenterDate(dates, DateTime.utc(2020, 1, 3)), 0);
    expect(bisectCenterDate(dates, DateTime.utc(2020, 1, 9)), 1);
    expect(bisectCenterDate(dates, DateTime.utc(2020, 1, 11)), 1);
    expect(bisectCenterDate(dates, DateTime.utc(2020, 1, 18)), 2);
  });
}
