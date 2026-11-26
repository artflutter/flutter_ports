// Ported from d3-shape v3.2.0 test/offset/expand-test.js (ISC, Mike Bostock).

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
  test('stackOffsetExpand(series, order) expands to fill [0, 1]', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, 4), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetExpand(series, stackOrderNone(series));
    expect(_vals(series), [
      [
        [0 / 9, 1 / 9],
        [0 / 8, 2 / 8],
        [0 / 7, 1 / 7],
      ],
      [
        [1 / 9, 4 / 9],
        [2 / 8, 6 / 8],
        [1 / 7, 3 / 7],
      ],
      [
        [4 / 9, 9 / 9],
        [6 / 8, 8 / 8],
        [3 / 7, 7 / 7],
      ],
    ]);
  });

  test('stackOffsetExpand(series, order) treats NaN as zero', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, double.nan), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetExpand(series, stackOrderNone(series));
    expect(series[1][1].y1.isNaN, isTrue);
    series[1][1].y1 = -999;
    expect(_vals(series), [
      [
        [0 / 9, 1 / 9],
        [0 / 4, 2 / 4],
        [0 / 7, 1 / 7],
      ],
      [
        [1 / 9, 4 / 9],
        [2 / 4, -999],
        [1 / 7, 3 / 7],
      ],
      [
        [4 / 9, 9 / 9],
        [2 / 4, 4 / 4],
        [3 / 7, 7 / 7],
      ],
    ]);
  });

  test('stackOffsetExpand(series, order) observes the specified order', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, 4), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetExpand(series, stackOrderReverse(series));
    expect(_vals(series), [
      [
        [8 / 9, 9 / 9],
        [6 / 8, 8 / 8],
        [6 / 7, 7 / 7],
      ],
      [
        [5 / 9, 8 / 9],
        [2 / 8, 6 / 8],
        [4 / 7, 6 / 7],
      ],
      [
        [0 / 9, 5 / 9],
        [0 / 8, 2 / 8],
        [0 / 7, 4 / 7],
      ],
    ]);
  });
}
