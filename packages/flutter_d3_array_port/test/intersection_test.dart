// Ported from d3-array v3.2.4 test/intersection-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('intersection(values) returns a set of values', () {
    assertSetEqual(intersection([1, 2, 3, 2, 1], []), [1, 2, 3]);
  });

  test('intersection(values, other) returns a set of values', () {
    assertSetEqual(intersection2([1, 2], [2, 3, 1]), [1, 2]);
    assertSetEqual(intersection2([2, 1, 3], [4, 3, 1]), [1, 3]);
  });

  test('intersection(...values) returns a set of values', () {
    assertSetEqual(
      intersection(
        [1, 2],
        [
          [2, 1],
          [2, 3],
        ],
      ),
      [2],
    );
  });

  test('intersection(...values) accepts iterables', () {
    assertSetEqual(intersection({1, 2, 3}, []), [1, 2, 3]);
  });

  test('intersection(...values) performs interning', () {
    assertSetEqual(
      intersection2(
        [
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-03T00:00:00Z'),
        ],
        [
          DateTime.parse('2021-01-01T00:00:00Z'),
          DateTime.parse('2021-01-02T00:00:00Z'),
        ],
      ),
      [DateTime.parse('2021-01-01T00:00:00Z')],
    );
  });
}
