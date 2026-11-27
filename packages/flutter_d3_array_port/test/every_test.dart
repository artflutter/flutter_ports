// Ported from d3-array v3.2.4 test/every-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('every(values, test) returns true if all tests pass', () {
    expect(every([1, 2, 3, 2, 1], (x, _, _) => (x & 1) != 0), isFalse);
    expect(every([1, 2, 3, 2, 1], (x, _, _) => x >= 1), isTrue);
  });

  test('every(values, test) returns true if values is empty', () {
    expect(every(<int>[], (_, _, _) => false), isTrue);
  });

  test('every(values, test) accepts an iterable', () {
    expect(every({1, 2, 3}, (x, _, _) => x >= 1), isTrue);
    expect(
      every(() sync* {
        yield* [1, 2, 3, 2, 1];
      }(), (x, _, _) => x >= 1),
      isTrue,
    );
    expect(
      every(Uint8List.fromList([1, 2, 3, 2, 1]), (x, _, _) => x >= 1),
      isTrue,
    );
  });

  test(
    'every(values, test) enforces that test is a function',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'every(values, test) enforces that values is iterable',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('every(values, test) passes test (value, index, values)', () {
    final calls = <(int, int, Iterable<int>)>[];
    final values = {5, 4, 3, 2, 1};
    every(values, (v, i, vals) {
      calls.add((v, i, vals));
      return true;
    });
    expect(calls, [
      (5, 0, values),
      (4, 1, values),
      (3, 2, values),
      (2, 3, values),
      (1, 4, values),
    ]);
  });

  test('every(values, test) short-circuts when test returns falsey', () {
    var calls = 0;
    expect(
      every([1, 2, 3], (x, _, _) {
        ++calls;
        return x < 2;
      }),
      isFalse,
    );
    expect(calls, 2);
    expect(
      every([1, 2, 3], (x, _, _) {
        ++calls;
        return (x - 2) != 0;
      }),
      isFalse,
    );
    expect(calls, 4);
  });

  test(
    'every(values, test) does not skip sparse elements',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
