// Ported from d3-array v3.2.4 test/greatestIndex-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('greatestIndex(array) compares using natural order', () {
    expect(greatestIndex([0, 1]), 1);
    expect(greatestIndex([1, 0]), 0);
    expect(greatestIndex(['10', '2']), 1);
    expect(greatestIndex(['2', '10']), 0);
    expect(greatestIndex([2, double.nan, 10]), 2);
    expect(greatestIndex([10, 2, double.nan]), 0);
    expect(greatestIndex([double.nan, 10, 2]), 1);
  });

  test('greatestIndex(array, compare) compares using the specified compare '
      'function', () {
    const a = (name: 'a');
    const b = (name: 'b');
    expect(greatestIndexWith([a, b], (a, b) => a.name.compareTo(b.name)), 1);
    expect(greatestIndex([1, 0], ascending), 0);
    expect(greatestIndex(['2', '10'], ascending), 0);
    expect(greatestIndex([2, double.nan, 10], ascending), 2);
  });

  test(
    'greatestIndex(array, accessor) uses the specified accessor function',
    () {
      const a = (name: 'a', v: 42.0);
      const b = (name: 'b', v: 0.42);
      expect(greatestIndexBy([a, b], (d) => d.name), 1);
      expect(greatestIndexBy([a, b], (d) => d.v), 0);
    },
  );

  test('greatestIndex(array) returns -1 if the array is empty', () {
    expect(greatestIndex<num>(const []), -1);
  });

  test(
    'greatestIndex(array) returns -1 if the array contains only incomparable '
    'values',
    () {
      expect(greatestIndex<double>([double.nan, null]), -1);
      expect(
        greatestIndexWith<double>([double.nan, double.nan], (a, b) => a - b),
        -1,
      );
    },
  );

  test('greatestIndex(array) returns the first of equal values', () {
    expect(greatestIndex([-2, -2, -1, -1, 0, 0, 0, -3, 0]), 4);
    expect(greatestIndex([-3, -2, -2, -1, -1, 0, 0, 0, -3, 0], descending), 0);
  });

  test('greatestIndex(array) ignores null and undefined', () {
    expect(greatestIndex<num>([null, -2, null]), 1);
  });

  test('greatestIndex(array, accessor) ignores null and undefined', () {
    expect(greatestIndexBy<num?, num>([null, -2, null], (d) => d), 1);
  });
}
