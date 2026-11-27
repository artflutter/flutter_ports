// Ported from d3-array v3.2.4 test/permute-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('permute(…) permutes according to the specified index', () {
    expect(permute([3, 4, 5], [2, 1, 0]), [5, 4, 3]);
    expect(permute([3, 4, 5], [2, 0, 1]), [5, 3, 4]);
    expect(permute([3, 4, 5], [0, 1, 2]), [3, 4, 5]);
  });

  test('permute(…) does not modify the input array', () {
    final input = [3, 4, 5];
    permute(input, [2, 1, 0]);
    expect(input, [3, 4, 5]);
  });

  test('permute(…) can duplicate input values', () {
    expect(permute([3, 4, 5], [0, 1, 0]), [3, 4, 3]);
    expect(permute([3, 4, 5], [2, 2, 2]), [5, 5, 5]);
    expect(permute([3, 4, 5], [0, 1, 1]), [3, 4, 4]);
  });

  test('permute(…) can return more elements', () {
    expect(permute([3, 4, 5], [0, 0, 1, 2]), [3, 3, 4, 5]);
    expect(permute([3, 4, 5], [0, 1, 1, 1]), [3, 4, 4, 4]);
  });

  test('permute(…) can return fewer elements', () {
    expect(permute([3, 4, 5], [0]), [3]);
    expect(permute([3, 4, 5], [1, 2]), [4, 5]);
    expect(permute([3, 4, 5], []), <int>[]);
  });

  test('permute(…) can return undefined elements', () {
    expect(permuteNullable([3, 4, 5], [10]), [null]);
    expect(permuteNullable([3, 4, 5], [-1]), [null]);
    expect(permuteNullable([3, 4, 5], [0, -1]), [3, null]);
  });

  test('permute(…) can take an object as the source', () {
    expect(permuteMap({'foo': 1, 'bar': 2}, ['bar', 'foo']), [2, 1]);
  });

  test('permute(…) can take a typed array as the source', () {
    expect(permute(Float32List.fromList([1, 2]), [0, 0, 1, 0]), [
      1.0,
      1.0,
      2.0,
      1.0,
    ]);
    final result = permute(Float32List.fromList([1, 2]), [0]);
    expect(result, isA<List<double>>());
    expect(result, isNot(isA<Float32List>()));
  });

  test('permute(…) can take an iterable as the keys', () {
    expect(permuteMap({'foo': 1, 'bar': 2}, {'bar', 'foo'}), [2, 1]);
    expect(permute([3, 4, 5], {2, 1, 0}), [5, 4, 3]);
  });
}
