// Ported from d3-array v3.2.4 test/rank-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void _expectFloat64(Float64List actual, List<double> expected) {
  expect(actual, isA<Float64List>());
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    if (expected[i].isNaN) {
      expect(actual[i].isNaN, isTrue, reason: 'index $i expected NaN');
    } else {
      expect(actual[i], expected[i], reason: 'index $i');
    }
  }
}

void main() {
  test('rank(numbers) returns the rank of numbers', () {
    _expectFloat64(rank([1000, 10, 0]), [2, 1, 0]);
    _expectFloat64(rank([1.2, 1.1, 1.2, 1.0, 1.5, 1.2]), [2, 1, 2, 0, 5, 2]);
  });

  test('rank(strings) returns the rank of letters', () {
    _expectFloat64(rank('EDGFCBA'.split('')), [4, 3, 6, 5, 2, 1, 0]);
  });

  test('rank(dates) returns the rank of Dates', () {
    _expectFloat64(
      rank([
        DateTime.parse('2000-01-01'),
        DateTime.parse('2000-01-01'),
        DateTime.parse('1999-01-01'),
        DateTime.parse('2001-01-01'),
      ]),
      [1, 1, 0, 3],
    );
  });

  test('rank(iterator) accepts an iterator', () {
    _expectFloat64(rank(<String>{'B', 'C', 'A'}), [1, 2, 0]);
  });

  test('rank(undefineds) ranks undefined as NaN', () {
    _expectFloat64(rankNullable<double>([1.2, 1.1, null, 1.0, null, 1.5]), [
      2,
      1,
      double.nan,
      0,
      double.nan,
      3,
    ]);
    _expectFloat64(
      rankNullable<double>([
        null,
        null,
        null,
        1.2,
        1.1,
        null,
        1.0,
        double.nan,
        1.5,
      ]),
      [double.nan, double.nan, double.nan, 2, 1, double.nan, 0, double.nan, 3],
    );
  });

  test('rank(values, valueof) accepts an accessor', () {
    _expectFloat64(
      rankBy<({int? x}), int>([
        (x: 3),
        (x: 1),
        (x: 2),
        (x: 4),
        (x: null),
      ], (d) => d.x),
      [2, 0, 1, 3, double.nan],
    );
  });

  test('rank(values, compare) accepts a comparator', () {
    _expectFloat64(
      rankWith<({int? x})>([
        (x: 3),
        (x: 1),
        (x: 2),
        (x: 4),
        (x: null),
      ], (a, b) => a.x == null || b.x == null ? double.nan : a.x! - b.x!),
      [2, 0, 1, 3, double.nan],
    );
    _expectFloat64(
      rankWith<({int? x})>([
        (x: 3),
        (x: 1),
        (x: 2),
        (x: 4),
        (x: null),
      ], (a, b) => a.x == null || b.x == null ? double.nan : b.x! - a.x!),
      [1, 3, 2, 0, double.nan],
    );
    _expectFloat64(
      rank(['aa', 'ba', 'bc', 'bb', 'ca'], (a, b) {
        final c = ascending(a[0], b[0]);
        return c != 0 ? c : ascending(a[1], b[1]);
      }),
      [0, 1, 3, 2, 4],
    );
    _expectFloat64(
      rankNullable<String>(['A', null, 'B', 'C', 'D'], descending),
      [3, double.nan, 2, 1, 0],
    );
  });

  test('rank(values) computes the ties as expected', () {
    _expectFloat64(rank(['a', 'b', 'b', 'b', 'c']), [0, 1, 1, 1, 4]);
    _expectFloat64(rank(['a', 'b', 'b', 'b', 'b', 'c']), [0, 1, 1, 1, 1, 5]);
  });

  test('rank(values) handles NaNs as expected', () {
    _expectFloat64(rankNullable<String>(['a', 'b', 'b', 'b', 'c', null]), [
      0,
      1,
      1,
      1,
      4,
      double.nan,
    ]);
    _expectFloat64(rankNullable<String>(['a', 'b', 'b', 'b', 'b', 'c', null]), [
      0,
      1,
      1,
      1,
      1,
      5,
      double.nan,
    ]);
  });
}
