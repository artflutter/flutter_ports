// Ported from d3-array v3.2.4 test/cross-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart' hide group;

Iterable<T> _generate<T>(List<T> values) sync* {
  yield* values;
}

void main() {
  test('cross() returns an empty array', () {
    expect(crossAll<int>(<Iterable<int>>[]), <List<int>>[]);
  });

  test('cross([]) returns an empty array', () {
    expect(crossAll<int>(<Iterable<int>>[<int>[]]), <List<int>>[]);
  });

  test('cross([1, 2], []) returns an empty array', () {
    expect(cross<int, int>(<int>[1, 2], <int>[]), <(int, int)>[]);
    expect(
      crossAll<int>(<Iterable<int>>[
        <int>[1, 2],
        <int>[],
      ]),
      <List<int>>[],
    );
  });

  test(
    'cross({length: weird}) returns an empty array',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('cross(...strings) returns the expected result', () {
    expect(
      crossWith('foo'.split(''), 'bar'.split(''), (a, b) => '$a$b'),
      <String>['fb', 'fa', 'fr', 'ob', 'oa', 'or', 'ob', 'oa', 'or'],
    );
  });

  test('cross(a) returns the expected result', () {
    expect(
      crossAll<int>(<Iterable<int>>[
        <int>[1, 2],
      ]),
      <List<int>>[
        <int>[1],
        <int>[2],
      ],
    );
  });

  test('cross(a, b) returns Cartesian product a×b', () {
    expect(cross(<int>[1, 2], <String>['x', 'y']), <(int, String)>[
      (1, 'x'),
      (1, 'y'),
      (2, 'x'),
      (2, 'y'),
    ]);
  });

  test('cross(a, b, c) returns Cartesian product a×b×c', () {
    expect(cross3(<int>[1, 2], <int>[3, 4], <int>[5, 6, 7]), <(int, int, int)>[
      (1, 3, 5),
      (1, 3, 6),
      (1, 3, 7),
      (1, 4, 5),
      (1, 4, 6),
      (1, 4, 7),
      (2, 3, 5),
      (2, 3, 6),
      (2, 3, 7),
      (2, 4, 5),
      (2, 4, 6),
      (2, 4, 7),
    ]);
    expect(
      crossAll<int>(<Iterable<int>>[
        <int>[1, 2],
        <int>[3, 4],
        <int>[5, 6, 7],
      ]),
      <List<int>>[
        <int>[1, 3, 5],
        <int>[1, 3, 6],
        <int>[1, 3, 7],
        <int>[1, 4, 5],
        <int>[1, 4, 6],
        <int>[1, 4, 7],
        <int>[2, 3, 5],
        <int>[2, 3, 6],
        <int>[2, 3, 7],
        <int>[2, 4, 5],
        <int>[2, 4, 6],
        <int>[2, 4, 7],
      ],
    );
  });

  test('cross(a, b, f) invokes the specified function for each pair', () {
    expect(
      crossWith(<int>[1, 2], <String>['x', 'y'], (a, b) => '$a$b'),
      <String>['1x', '1y', '2x', '2y'],
    );
  });

  test('cross(a, b, c, f) invokes the specified function for each triple', () {
    expect(
      cross3With(<int>[1, 2], <int>[3, 4], <int>[
        5,
        6,
        7,
      ], (a, b, c) => a + b + c),
      <int>[9, 10, 11, 10, 11, 12, 10, 11, 12, 11, 12, 13],
    );
    expect(
      crossAllWith<int, int>(<Iterable<int>>[
        <int>[1, 2],
        <int>[3, 4],
        <int>[5, 6, 7],
      ], (t) => t[0] + t[1] + t[2]),
      <int>[9, 10, 11, 10, 11, 12, 10, 11, 12, 11, 12, 13],
    );
  });

  test('cross(a, b) returns Cartesian product a×b of generators', () {
    expect(
      cross(_generate(<int>[1, 2]), _generate(<String>['x', 'y'])),
      <(int, String)>[(1, 'x'), (1, 'y'), (2, 'x'), (2, 'y')],
    );
  });
}
