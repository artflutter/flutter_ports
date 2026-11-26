// Ported from d3-shape v3.2.0 test/offset/diverging-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

List<StackSeries<Null, Null>> _make(List<List<(double, double)>> rows) => [
  for (final r in rows) StackSeries.fromPairs(r),
];

List<List<List<double>>> _vals(List<StackSeries<Null, Null>> s) => [
  for (final row in s)
    [
      for (final p in row.points) [p.y0, p.y1],
    ],
];

void main() {
  test('stackOffsetDiverging(series, order) applies a zero baseline, ignoring '
      'existing offsets', () {
    final series = _make([
      [(1, 2), (2, 4), (3, 4)],
      [(0, 3), (0, 4), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetDiverging(series, stackOrderNone(series));
    expect(_vals(series), [
      [
        [0, 1],
        [0, 2],
        [0, 1],
      ],
      [
        [1, 4],
        [2, 6],
        [1, 3],
      ],
      [
        [4, 9],
        [6, 8],
        [3, 7],
      ],
    ]);
  });

  test('stackOffsetDiverging(series, order) handles a single series', () {
    final series = _make([
      [(1, 2), (2, 4), (3, 4)],
    ]);
    stackOffsetDiverging(series, stackOrderNone(series));
    expect(_vals(series), [
      [
        [0, 1],
        [0, 2],
        [0, 1],
      ],
    ]);
  });

  test('stackOffsetDiverging(series, order) treats NaN as zero', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, double.nan), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetDiverging(series, stackOrderNone(series));
    expect(series[1][1].y1.isNaN, isTrue);
    series[1][1].y1 = -999;
    expect(_vals(series), [
      [
        [0, 1],
        [0, 2],
        [0, 1],
      ],
      [
        [1, 4],
        [0, -999],
        [1, 3],
      ],
      [
        [4, 9],
        [2, 4],
        [3, 7],
      ],
    ]);
  });

  test('stackOffsetDiverging(series, order) observes the specified order', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, 4), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetDiverging(series, stackOrderReverse(series));
    expect(_vals(series), [
      [
        [8, 9],
        [6, 8],
        [6, 7],
      ],
      [
        [5, 8],
        [2, 6],
        [4, 6],
      ],
      [
        [0, 5],
        [0, 2],
        [0, 4],
      ],
    ]);
  });

  test('stackOffsetDiverging(series, order) puts negative values below zero, '
      'in order', () {
    final series = _make([
      [(0, 1), (0, -2), (0, -1)],
      [(0, -3), (0, -4), (0, -2)],
      [(0, -5), (0, -2), (0, 4)],
    ]);
    stackOffsetDiverging(series, stackOrderNone(series));
    expect(_vals(series), [
      [
        [0, 1],
        [-2, 0],
        [-1, 0],
      ],
      [
        [-3, 0],
        [-6, -2],
        [-3, -1],
      ],
      [
        [-8, -3],
        [-8, -6],
        [0, 4],
      ],
    ]);
  });

  test(
    'stackOffsetDiverging(series, order) puts zero values at zero, in order',
    () {
      final series = _make([
        [(0, 1), (0, 2), (0, -1)],
        [(0, 3), (0, 0), (0, 0)],
        [(0, 5), (0, 2), (0, 4)],
      ]);
      stackOffsetDiverging(series, stackOrderNone(series));
      expect(_vals(series), [
        [
          [0, 1],
          [0, 2],
          [-1, 0],
        ],
        [
          [1, 4],
          [0, 0],
          [0, 0],
        ],
        [
          [4, 9],
          [2, 4],
          [0, 4],
        ],
      ]);
    },
  );
}
