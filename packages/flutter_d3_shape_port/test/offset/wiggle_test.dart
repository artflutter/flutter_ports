// Ported from d3-shape v3.2.0 test/offset/wiggle-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

double _round6(double x) => x.isNaN ? x : (x * 1e6).roundToDouble() / 1e6;

List<StackSeries<Null, Null>> _make(List<List<(double, double)>> rows) => [
  for (final r in rows) StackSeries.fromPairs(r),
];

List<List<List<double>>> _roundVals(List<StackSeries<Null, Null>> s) => [
  for (final row in s)
    [
      for (final p in row.points) [_round6(p.y0), _round6(p.y1)],
    ],
];

List<List<List<double>>> _roundExpected(List<List<List<double>>> s) => [
  for (final row in s)
    [
      for (final p in row) [_round6(p[0]), _round6(p[1])],
    ],
];

void main() {
  test('stackOffsetWiggle(series, order) minimizes weighted wiggle', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, 4), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetWiggle(series, stackOrderNone(series));
    expect(
      _roundVals(series),
      _roundExpected([
        [
          [0, 1],
          [-1, 1],
          [0.7857143, 1.7857143],
        ],
        [
          [1, 4],
          [1, 5],
          [1.7857143, 3.7857143],
        ],
        [
          [4, 9],
          [5, 7],
          [3.7857143, 7.7857143],
        ],
      ]),
    );
  });

  test('stackOffsetWiggle(series, order) treats NaN as zero', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, double.nan), (0, double.nan), (0, double.nan)],
      [(0, 3), (0, 4), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetWiggle(series, stackOrderNone(series));
    expect(series[1][0].y1.isNaN, isTrue);
    expect(series[1][1].y1.isNaN, isTrue);
    expect(series[1][2].y1.isNaN, isTrue);
    series[1][0].y1 = series[1][1].y1 = series[1][2].y1 = -999;
    expect(
      _roundVals(series),
      _roundExpected([
        [
          [0, 1],
          [-1, 1],
          [0.7857143, 1.7857143],
        ],
        [
          [1, -999],
          [1, -999],
          [1.7857143, -999],
        ],
        [
          [1, 4],
          [1, 5],
          [1.7857143, 3.7857143],
        ],
        [
          [4, 9],
          [5, 7],
          [3.7857143, 7.7857143],
        ],
      ]),
    );
  });

  test('stackOffsetWiggle(series, order) observes the specified order', () {
    final series = _make([
      [(0, 1), (0, 2), (0, 1)],
      [(0, 3), (0, 4), (0, 2)],
      [(0, 5), (0, 2), (0, 4)],
    ]);
    stackOffsetWiggle(series, stackOrderReverse(series));
    expect(
      _roundVals(series),
      _roundExpected([
        [
          [8, 9],
          [8, 10],
          [7.21428571, 8.21428571],
        ],
        [
          [5, 8],
          [4, 8],
          [5.21428571, 7.21428571],
        ],
        [
          [0, 5],
          [2, 4],
          [1.21428571, 5.21428571],
        ],
      ]),
    );
  });
}
