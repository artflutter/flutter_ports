// Ported from d3-array v3.2.4 test/reverse-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('reverse(values) returns a reversed copy', () {
    final input = [1, 3, 2, 5, 4];
    expect(reverse(input), [4, 5, 2, 3, 1]);
    expect(input, [1, 3, 2, 5, 4]);
  });

  test('reverse(values) returns an array', () {
    final result = reverse(Uint8List.fromList([1, 2]));
    expect(result, isA<List<int>>());
    expect(result, isNot(isA<Uint8List>()));
  });

  test('reverse(values) accepts an iterable', () {
    expect(reverse({1, 2, 3}), [3, 2, 1]);
    expect(
      reverse(() sync* {
        yield* [1, 3, 2, 5, 4];
      }()),
      [4, 5, 2, 3, 1],
    );
    expect(reverse(Uint8List.fromList([1, 3, 2, 5, 4])), [4, 5, 2, 3, 1]);
  });

  test(
    'reverse(values) enforces that values is iterable',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'reverse(values) does not skip sparse elements',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
