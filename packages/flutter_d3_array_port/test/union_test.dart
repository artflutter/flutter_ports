// Ported from d3-array v3.2.4 test/union-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('union(values) returns a set of values', () {
    assertSetEqual(
      union([
        [1, 2, 3, 2, 1],
      ]),
      [1, 2, 3],
    );
  });

  test('union(values, other) returns a set of values', () {
    assertSetEqual(union2([1, 2], [2, 3, 1]), [1, 2, 3]);
    assertSetEqual(
      union([
        [1, 2],
        [2, 3, 1],
      ]),
      [1, 2, 3],
    );
  });

  test('union(...values) returns a set of values', () {
    assertSetEqual(
      union([
        [1],
        [2],
        [2, 3],
        [1],
      ]),
      [1, 2, 3],
    );
  });

  test('union(...values) accepts iterables', () {
    assertSetEqual(
      union([
        {1, 2, 3},
      ]),
      [1, 2, 3],
    );
    assertSetEqual(
      union([
        Uint8List.fromList([1, 2, 3]),
      ]),
      [1, 2, 3],
    );
  });

  test('union(...values) performs interning', () {
    assertSetEqual(
      union([
        [
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-02T00:00:00Z'),
        ],
      ]),
      [
        DateTime.parse('2021-01-01T00:00:00Z'),
        DateTime.parse('2021-01-02T00:00:00Z'),
      ],
    );
    assertSetEqual(
      union2(
        [
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-03T00:00:00Z'),
        ],
        [
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-02T00:00:00Z'),
        ],
      ),
      [
        DateTime.parse('2021-01-01T00:00:00Z'),
        DateTime.parse('2021-01-02T00:00:00Z'),
        DateTime.parse('2021-01-03T00:00:00Z'),
      ],
    );
  });
}
