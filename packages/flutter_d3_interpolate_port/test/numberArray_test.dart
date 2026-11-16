// Ported from d3-interpolate v3.0.1 test/numberArray-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names
import 'dart:typed_data';

import 'package:flutter_d3_interpolate_port/d3_interpolate.dart';
import 'package:test/test.dart';

/// `assert.deepStrictEqual` of two typed arrays: the same class and the same
/// items.
Matcher _typedEquals<T extends List<num>>(T expected) =>
    allOf(isA<T>(), equals(expected));

void main() {
  test(
    'interpolateNumberArray(a, b) interpolates defined elements in a and b',
    () {
      expect(
        interpolateNumberArray(
          Float64List.fromList([2, 12]),
          Float64List.fromList([4, 24]),
        )(0.5),
        _typedEquals(Float64List.fromList([3, 18])),
      );
    },
  );

  test(
    'interpolateNumberArray(a, b) ignores elements in a that are not in b',
    () {
      expect(
        interpolateNumberArray(
          Float64List.fromList([2, 12, 12]),
          Float64List.fromList([4, 24]),
        )(0.5),
        _typedEquals(Float64List.fromList([3, 18])),
      );
    },
  );

  test('interpolateNumberArray(a, b) uses constant elements in b that are not '
      'in a', () {
    expect(
      interpolateNumberArray(
        Float64List.fromList([2, 12]),
        Float64List.fromList([4, 24, 12]),
      )(0.5),
      _typedEquals(Float64List.fromList([3, 18, 12])),
    );
  });

  test('interpolateNumberArray(a, b) treats undefined as an empty array', () {
    // assert.deepStrictEqual(interpolateNumberArray(undefined, [2, 12])(0.5),
    //   [2, 12]);
    // assert.deepStrictEqual(interpolateNumberArray([2, 12], undefined)(0.5),
    //   []);
    // assert.deepStrictEqual(
    //   interpolateNumberArray(undefined, undefined)(0.5), []);
    //
    // Dart has no undefined, and a list parameter is not nullable.
  }, skip: 'diverges: adapt-interpolate-typed-values');

  test('interpolateNumberArray(a, b) uses b’s array type', () {
    expect(
      interpolateNumberArray(
        Float64List.fromList([2, 12]),
        Float64List.fromList([4, 24, 12]),
      )(0.5),
      isA<Float64List>(),
    );
    expect(
      interpolateNumberArray(
        Float64List.fromList([2, 12]),
        Float32List.fromList([4, 24, 12]),
      )(0.5),
      isA<Float32List>(),
    );
    expect(
      interpolateNumberArray(
        Float64List.fromList([2, 12]),
        Uint8List.fromList([4, 24, 12]),
      )(0.5),
      isA<Uint8List>(),
    );
    expect(
      interpolateNumberArray(
        Float64List.fromList([2, 12]),
        Uint16List.fromList([4, 24, 12]),
      )(0.5),
      isA<Uint16List>(),
    );
  });

  test('interpolateNumberArray(a, b) works with unsigned data', () {
    expect(
      interpolateNumberArray(
        Uint8List.fromList([1, 12]),
        Uint8List.fromList([255, 0]),
      )(0.5),
      _typedEquals(Uint8List.fromList([128, 6])),
    );
  });

  test('interpolateNumberArray(a, b) gives exact ends', () {
    final i = interpolateNumberArray(
      Float64List.fromList([2e42]),
      Float64List.fromList([355]),
    );
    expect(i(0), _typedEquals(Float64List.fromList([2e42])));
    expect(i(1), _typedEquals(Float64List.fromList([355])));
  });
}
