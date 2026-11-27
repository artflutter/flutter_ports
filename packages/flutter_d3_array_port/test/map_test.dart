// Ported from d3-array v3.2.4 test/map-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('map(values, mapper) returns the mapped values', () {
    expect(map([1, 2, 3, 2, 1], (x, _, _) => x * 2), [2, 4, 6, 4, 2]);
  });

  test('map(values, mapper) accepts an iterable', () {
    expect(map({1, 2, 3}, (x, _, _) => x * 2), [2, 4, 6]);
    expect(
      map(() sync* {
        yield* [1, 2, 3, 2, 1];
      }(), (x, _, _) => x * 2),
      [2, 4, 6, 4, 2],
    );
  });

  test('map(values, mapper) accepts a typed array', () {
    expect(map(Uint8List.fromList([1, 2, 3, 2, 1]), (x, _, _) => x * 2), [
      2,
      4,
      6,
      4,
      2,
    ]);
  });

  test(
    'map(values, mapper) enforces that test is a function',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'map(values, mapper) enforces that values is iterable',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('map(values, mapper) passes test (value, index, values)', () {
    final calls = <(int, int, Iterable<int>)>[];
    final values = {5, 4, 3, 2, 1};
    map(values, (v, i, vals) {
      calls.add((v, i, vals));
      return v;
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
    'map(values, mapper) does not skip sparse elements',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
