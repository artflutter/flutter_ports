// Ported from d3-shape v3.2.0 test/offset/silhouette-test.js (ISC, Mike Bostock).

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
  test(
    'stackOffsetSilhouette(series, order) centers the stack around zero',
    () {
      final series = _make([
        [(0, 1), (0, 2), (0, 1)],
        [(0, 3), (0, 4), (0, 2)],
        [(0, 5), (0, 2), (0, 4)],
      ]);
      stackOffsetSilhouette(series, stackOrderNone(series));
      expect(_vals(series), [
        [
          [0 - 9 / 2, 1 - 9 / 2],
          [0 - 8 / 2, 2 - 8 / 2],
          [0 - 7 / 2, 1 - 7 / 2],
        ],
        [
          [1 - 9 / 2, 4 - 9 / 2],
          [2 - 8 / 2, 6 - 8 / 2],
          [1 - 7 / 2, 3 - 7 / 2],
        ],
        [
          [4 - 9 / 2, 9 - 9 / 2],
          [6 - 8 / 2, 8 - 8 / 2],
          [3 - 7 / 2, 7 - 7 / 2],
        ],
      ]);
    },
  );

  test('stackOffsetSilhouette(series, order) treats NaN as zero', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, double.nan), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetSilhouette(series, stackOrderNone(series));
    expect(series[1][1].y1.isNaN, isTrue);
    series[1][1].y1 = -999;
    expect(_vals(series), [
      [
        [0 - 9 / 2, 1 - 9 / 2],
        [0 - 4 / 2, 2 - 4 / 2],
        [0 - 7 / 2, 1 - 7 / 2],
      ],
      [
        [1 - 9 / 2, 4 - 9 / 2],
        [2 - 4 / 2, -999],
        [1 - 7 / 2, 3 - 7 / 2],
      ],
      [
        [4 - 9 / 2, 9 - 9 / 2],
        [2 - 4 / 2, 4 - 4 / 2],
        [3 - 7 / 2, 7 - 7 / 2],
      ],
    ]);
  });

  test('stackOffsetSilhouette(series, order) observes the specified order', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, 4), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetSilhouette(series, stackOrderReverse(series));
    expect(_vals(series), [
      [
        [8 - 9 / 2, 9 - 9 / 2],
        [6 - 8 / 2, 8 - 8 / 2],
        [6 - 7 / 2, 7 - 7 / 2],
      ],
      [
        [5 - 9 / 2, 8 - 9 / 2],
        [2 - 8 / 2, 6 - 8 / 2],
        [4 - 7 / 2, 6 - 7 / 2],
      ],
      [
        [0 - 9 / 2, 5 - 9 / 2],
        [0 - 8 / 2, 2 - 8 / 2],
        [0 - 7 / 2, 4 - 7 / 2],
      ],
    ]);
  });
}
