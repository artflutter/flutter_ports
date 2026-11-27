// Ported from d3-array v3.2.4 test/filter-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('filter(values, test) returns the values that pass the test', () {
    expect(filter([1, 2, 3, 2, 1], (x, _, _) => (x & 1) != 0), [1, 3, 1]);
  });

  test('filter(values, test) accepts an iterable', () {
    expect(filter({1, 2, 3}, (x, _, _) => (x & 1) != 0), [1, 3]);
    expect(
      filter(() sync* {
        yield* [1, 2, 3, 2, 1];
      }(), (x, _, _) => (x & 1) != 0),
      [1, 3, 1],
    );
  });

  test('filter(values, test) accepts a typed array', () {
    expect(
      filter(Uint8List.fromList([1, 2, 3, 2, 1]), (x, _, _) => (x & 1) != 0),
      [1, 3, 1],
    );
  });

  test(
    'filter(values, test) enforces that test is a function',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'filter(values, test) enforces that values is iterable',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('filter(values, test) passes test (value, index, values)', () {
    final calls = <(int, int, Iterable<int>)>[];
    final values = {5, 4, 3, 2, 1};
    filter(values, (v, i, vals) {
      calls.add((v, i, vals));
      return false;
    });
    expect(calls, [
      (5, 0, values),
      (4, 1, values),
      (3, 2, values),
      (2, 3, values),
      (1, 4, values),
    ]);
  });

  test(
    'filter(values, test) does not skip sparse elements',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
