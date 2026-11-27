// Ported from d3-array v3.2.4 test/sort-test.js (ISC, Mike Bostock).

import 'dart:typed_data';

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void _expectNullableDoubles(List<double?> actual, List<double?> expected) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; ++i) {
    final e = expected[i];
    final a = actual[i];
    if (e != null && e.isNaN) {
      expect(a != null && a.isNaN, isTrue, reason: 'index $i expected NaN');
    } else {
      expect(a, e, reason: 'index $i');
    }
  }
}

void main() {
  test('sort(values) returns a sorted copy', () {
    final input = [1, 3, 2, 5, 4];
    expect(sort(input), [1, 2, 3, 4, 5]);
    expect(input, [1, 3, 2, 5, 4]);
  });

  test(
    'sort(values) defaults to ascending, not lexicographic',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'sort(values) puts non-orderable values last, followed by undefined',
    () {
      final input = <double?>[null, 1, 0, double.nan, 10, 2];
      _expectNullableDoubles(sortNullable<double>(input), [
        0,
        1,
        2,
        10,
        null,
        double.nan,
      ]);
    },
  );

  test('sort(values, comparator) puts non-orderable values last, followed by '
      'undefined', () {
    final input = <double?>[null, 1, 0, double.nan, 10, 2];
    _expectNullableDoubles(sortNullable<double>(input, ascending), [
      0,
      1,
      2,
      10,
      null,
      double.nan,
    ]);
    _expectNullableDoubles(sortNullable<double>(input, descending), [
      10,
      2,
      1,
      0,
      null,
      double.nan,
    ]);
  });

  test('sort(values, accessor) puts non-orderable values last', () {
    final input = <double?>[null, 1, 0, double.nan, 10, 2];
    _expectNullableDoubles(sortBy<double?, double>(input, (d) => d), [
      0,
      1,
      2,
      10,
      null,
      double.nan,
    ]);
    _expectNullableDoubles(
      sortBy<double?, double>(input, (d) => d == null ? null : -d),
      [10, 2, 1, 0, null, double.nan],
    );
  });

  test(
    'sort(values, accessor) uses the specified accessor in natural order',
    () {
      expect(sortBy([1, 3, 2, 5, 4], (d) => d), [1, 2, 3, 4, 5]);
      expect(sortBy([1, 3, 2, 5, 4], (d) => -d), [5, 4, 3, 2, 1]);
    },
  );

  test('sort(values, ...accessors) accepts multiple accessors', () {
    expect(
      sortBy2(
        [(1, 0), (2, 1), (2, 0), (1, 1), (3, 0)],
        (p) => p.$1,
        (p) => p.$2,
      ),
      [(1, 0), (1, 1), (2, 0), (2, 1), (3, 0)],
    );
    expect(
      sortBy2(
        [(x: 1, y: 0), (x: 2, y: 1), (x: 2, y: 0), (x: 1, y: 1), (x: 3, y: 0)],
        (p) => p.x,
        (p) => p.y,
      ),
      [(x: 1, y: 0), (x: 1, y: 1), (x: 2, y: 0), (x: 2, y: 1), (x: 3, y: 0)],
    );
  });

  test('sort(values, comparator) uses the specified comparator', () {
    expect(sort([1, 3, 2, 5, 4], descending), [5, 4, 3, 2, 1]);
    expect(sortWith([1, 3, 2, 5, 4], descending), [5, 4, 3, 2, 1]);
  });

  test('sort(values) returns an array', () {
    final result = sort(Uint8List.fromList([1, 2]));
    expect(result, isA<List<int>>());
    expect(result, isNot(isA<Uint8List>()));
  });

  test('sort(values) accepts an iterable', () {
    expect(sort(const <int>{1, 3, 2}), [1, 2, 3]);
    Iterable<int> gen() sync* {
      yield* const [1, 3, 2, 5, 4];
    }

    expect(sort(gen()), [1, 2, 3, 4, 5]);
    expect(sort(Uint8List.fromList([1, 3, 2, 5, 4])), [1, 2, 3, 4, 5]);
  });

  test(
    'sort(values) enforces that values is iterable',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'sort(values, comparator) enforces that comparator is a function',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test(
    'sort(values) does not skip sparse elements',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );
}
