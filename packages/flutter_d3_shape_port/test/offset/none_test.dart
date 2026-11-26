// Ported from d3-shape v3.2.0 test/offset/none-test.js (ISC, Mike Bostock).

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
  test('stackOffsetNone(series, order) stacks upon the first layer’s existing '
      'positions', () {
    final series = _make([
      [(1, 2), (2, 4), (3, 4)],
      [(0, 3), (0, 4), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetNone(series, stackOrderNone(series));
    expect(_vals(series), [
      [
        [1, 2],
        [2, 4],
        [3, 4],
      ],
      [
        [2, 5],
        [4, 8],
        [4, 6],
      ],
      [
        [5, 10],
        [8, 10],
        [6, 10],
      ],
    ]);
  });

  test('stackOffsetNone(series, order) treats NaN as zero', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, double.nan), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetNone(series, stackOrderNone(series));
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
        [2, -999],
        [1, 3],
      ],
      [
        [4, 9],
        [2, 4],
        [3, 7],
      ],
    ]);
  });

  test('stackOffsetNone(series, order) observes the specified order', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, 4), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetNone(series, stackOrderReverse(series));
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
}
