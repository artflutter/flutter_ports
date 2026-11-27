// Ported from d3-array v3.2.4 test/leastIndex-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('leastIndex(array) compares using natural order', () {
    expect(leastIndex([0, 1]), 0);
    expect(leastIndex([1, 0]), 1);
    expect(leastIndex(['10', '2']), 0);
    expect(leastIndex(['2', '10']), 1);
    expect(leastIndex([2, double.nan, 10]), 0);
    expect(leastIndex([10, 2, double.nan]), 1);
    expect(leastIndex([double.nan, 10, 2]), 2);
  });

  test(
    'leastIndex(array, compare) compares using the specified compare function',
    () {
      const a = (name: 'a');
      const b = (name: 'b');
      expect(leastIndexWith([a, b], (a, b) => a.name.compareTo(b.name)), 0);
      expect(leastIndex([1, 0], descending), 0);
      expect(leastIndex(['2', '10'], descending), 0);
      expect(leastIndex([2, double.nan, 10], descending), 2);
    },
  );

  test('leastIndex(array, accessor) uses the specified accessor function', () {
    const a = (name: 'a', v: 42.0);
    const b = (name: 'b', v: 0.42);
    expect(leastIndexBy([a, b], (d) => d.name), 0);
    expect(leastIndexBy([a, b], (d) => d.v), 1);
  });

  test('leastIndex(array) returns -1 if the array is empty', () {
    expect(leastIndex<num>(const []), -1);
  });

  test('leastIndex(array) returns -1 if the array contains only incomparable '
      'values', () {
    expect(leastIndex<double>([double.nan, null]), -1);
    expect(
      leastIndexWith<double>([double.nan, double.nan], (a, b) => a - b),
      -1,
    );
  });

  test('leastIndex(array) returns the first of equal values', () {
    expect(leastIndex([2, 2, 1, 1, 0, 0, 0, 3, 0]), 4);
    expect(leastIndex([3, 2, 2, 1, 1, 0, 0, 0, 3, 0], descending), 0);
  });

  test('leastIndex(array) ignores null and undefined', () {
    expect(leastIndex<num>([null, 2, null]), 1);
  });

  test('leastIndex(array, accessor) ignores null and undefined', () {
    expect(leastIndexBy<num?, num>([null, 2, null], (d) => d), 1);
  });
}
