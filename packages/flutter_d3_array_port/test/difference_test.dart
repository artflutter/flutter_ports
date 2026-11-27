// Ported from d3-array v3.2.4 test/difference-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('difference(values, other) returns a set of values', () {
    assertSetEqual(difference2([1, 2, 3], [2, 1]), [3]);
    assertSetEqual(difference2([1, 2], [2, 3, 1]), <int>[]);
    assertSetEqual(difference2([2, 1, 3], [4, 3, 1]), [2]);
  });

  test('difference(...values) accepts iterables', () {
    assertSetEqual(
      difference(
        {1, 2, 3},
        [
          {1},
        ],
      ),
      [2, 3],
    );
  });

  test('difference(values, other) performs interning', () {
    assertSetEqual(
      difference2(
        [
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-02T00:00:00Z'),
          DateTime.parse('2021-01-03T00:00:00Z'),
        ],
        [
          DateTime.parse('2021-01-02T00:00:00Z'),
          DateTime.parse('2021-01-01T00:00:00Z'),
        ],
      ),
      [DateTime.parse('2021-01-03T00:00:00Z')],
    );
    assertSetEqual(
      difference2(
        [
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-02T00:00:00Z'),
        ],
        [
          DateTime.parse('2021-01-02T00:00:00Z'),
          DateTime.parse('2021-01-03T00:00:00Z'),
          DateTime.parse('2021-01-01T00:00:00Z'),
        ],
      ),
      <DateTime>[],
    );
    assertSetEqual(
      difference2(
        [
          DateTime.parse('2021-01-02T00:00:00Z'),
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-03T00:00:00Z'),
        ],
        [
          DateTime.parse('2021-01-04T00:00:00Z'),
          DateTime.parse('2021-01-03T00:00:00Z'),
          DateTime.parse('2021-01-01T00:00:00Z'),
        ],
      ),
      [DateTime.parse('2021-01-02T00:00:00Z')],
    );
  });
}
