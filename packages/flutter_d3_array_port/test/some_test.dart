// Ported from d3-array v3.2.4 test/some-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('some(values, test) returns true if any test passes', () {
    expect(some([1, 2, 3, 2, 1], (x, _, _) => (x & 1) != 0), isTrue);
    expect(some([1, 2, 3, 2, 1], (x, _, _) => x > 3), isFalse);
  });

  test('some(values, test) returns false if values is empty', () {
    expect(some(<int>[], (_, _, _) => true), isFalse);
  });

  test('some(values, test) accepts an iterable', () {
    expect(some({1, 2, 3}, (x, _, _) => x >= 3), isTrue);
    expect(
      some(() sync* {
        yield* [1, 2, 3, 2, 1];
      }(), (x, _, _) => x >= 3),
      isTrue,
    );
    expect(
      some(Uint8List.fromList([1, 2, 3, 2, 1]), (x, _, _) => x >= 3),
      isTrue,
    );
  });

  test(
    'some(values, test) enforces that test is a function',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'some(values, test) enforces that values is iterable',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('some(values, test) passes test (value, index, values)', () {
    final calls = <(int, int, Iterable<int>)>[];
    final values = {5, 4, 3, 2, 1};
    some(values, (v, i, vals) {
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

  test('some(values, test) short-circuts when test returns truthy', () {
    var calls = 0;
    expect(
      some([1, 2, 3], (x, _, _) {
        ++calls;
        return x >= 2;
      }),
      isTrue,
    );
    expect(calls, 2);
    expect(
      some([1, 2, 3], (x, _, _) {
        ++calls;
        return (x - 1) != 0;
      }),
      isTrue,
    );
    expect(calls, 4);
  });

  test(
    'some(values, test) does not skip sparse elements',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
