// Ported from d3-array v3.2.4 test/scan-test.js (ISC, Mike Bostock).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('scan(array) compares using natural order', () {
    expect(scan([0, 1]), 0);
    expect(scan([1, 0]), 1);
    expect(scan(['10', '2']), 0);
    expect(scan(['2', '10']), 1);
    expect(scan([2, double.nan, 10]), 0);
    expect(scan([10, 2, double.nan]), 1);
    expect(scan([double.nan, 10, 2]), 2);
  });

  test(
    'scan(array, compare) compares using the specified compare function',
    () {
      const a = (name: 'a');
      const b = (name: 'b');
      expect(scanWith([a, b], (a, b) => a.name.compareTo(b.name)), 0);
      expect(scan([1, 0], descending), 0);
      expect(scan(['2', '10'], descending), 0);
      expect(scan([2, double.nan, 10], descending), 2);
    },
  );

  test('scan(array) returns undefined if the array is empty', () {
    expect(scan<num>(const []), isNull);
  });

  test('scan(array) returns undefined if the array contains only incomparable '
      'values', () {
    expect(scan<double>([double.nan, null]), isNull);
    expect(scanWith<double>([double.nan, double.nan], (a, b) => a - b), isNull);
  });

  test('scan(array) returns the first of equal values', () {
    expect(scan([2, 2, 1, 1, 0, 0, 0, 3, 0]), 4);
    expect(scan([3, 2, 2, 1, 1, 0, 0, 0, 3, 0], descending), 0);
  });
}
