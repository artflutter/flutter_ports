// Ported from d3-array v3.2.4 test/reduce-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('reduce(values, reducer) returns the reduced value', () {
    expect(reduceFirst([1, 2, 3, 2, 1], (p, v, _, _) => p + v), 9);
    expect(reduceFirst([1, 2], (p, v, _, _) => p + v), 3);
    expect(reduceFirst([1], (p, v, _, _) => p + v), 1);
    expect(reduceFirst(<int>[], (p, v, _, _) => p + v), isNull);
  });

  test('reduce(values, reducer, initial) returns the reduced value', () {
    expect(reduce([1, 2, 3, 2, 1], (p, v, _, _) => p + v, 0), 9);
    expect(reduce([1], (p, v, _, _) => p + v, 0), 1);
    expect(reduce(<int>[], (p, v, _, _) => p + v, 0), 0);
    expect(reduce([1, 2, 3, 2, 1], (p, v, _, _) => [...p, v], <int>[]), [
      1,
      2,
      3,
      2,
      1,
    ]);
  });

  test('reduce(values, reducer) accepts an iterable', () {
    expect(reduceFirst({1, 2, 3}, (p, v, _, _) => p + v), 6);
    expect(
      reduceFirst(() sync* {
        yield* [1, 2, 3, 2, 1];
      }(), (p, v, _, _) => p + v),
      9,
    );
    expect(
      reduceFirst(Uint8List.fromList([1, 2, 3, 2, 1]), (p, v, _, _) => p + v),
      9,
    );
  });

  test(
    'reduce(values, reducer) enforces that test is a function',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'reduce(values, reducer) enforces that values is iterable',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'reduce(values, reducer) passes reducer (reduced, value, index, values)',
    () {
      final calls = <(int, int, int, Iterable<int>)>[];
      final values = {5, 4, 3, 2, 1};
      reduceFirst(values, (p, v, i, vals) {
        calls.add((p, v, i, vals));
        return p + v;
      });
      expect(calls, [
        (5, 4, 1, values),
        (9, 3, 2, values),
        (12, 2, 3, values),
        (14, 1, 4, values),
      ]);
    },
  );

  test('reduce(values, reducer, initial) passes reducer '
      '(reduced, value, index, values)', () {
    final calls = <(int, int, int, Iterable<int>)>[];
    final values = {5, 4, 3, 2, 1};
    reduce(values, (p, v, i, vals) {
      calls.add((p, v, i, vals));
      return p + v;
    }, 0);
    expect(calls, [
      (0, 5, 0, values),
      (5, 4, 1, values),
      (9, 3, 2, values),
      (12, 2, 3, values),
      (14, 1, 4, values),
    ]);
  });

  test(
    'reduce(values, reducer, initial) does not skip sparse elements',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
