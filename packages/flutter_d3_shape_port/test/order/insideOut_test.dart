// Ported from d3-shape v3.2.0 test/order/insideOut-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

List<StackSeries<Null, Null>> _make(List<List<(double, double)>> rows) => [
  for (final r in rows) StackSeries.fromPairs(r),
];

void main() {
  test('stackOrderInsideOut(series) returns an order by appearance', () {
    expect(
      stackOrderInsideOut(
        _make([
          [(0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 1)],
          [(0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 2), (0, 0)],
          [(0, 0), (0, 0), (0, 0), (0, 0), (0, 3), (0, 0), (0, 0)],
          [(0, 0), (0, 0), (0, 0), (0, 4), (0, 0), (0, 0), (0, 0)],
          [(0, 0), (0, 0), (0, 5), (0, 0), (0, 0), (0, 0), (0, 0)],
          [(0, 0), (0, 6), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)],
          [(0, 7), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)],
        ]),
      ),
      [2, 3, 6, 5, 4, 1, 0],
    );
  });

  test('stackOrderInsideOut(series) treats NaN values as zero', () {
    expect(
      stackOrderInsideOut(
        _make([
          [(0, 0), (0, double.nan), (0, 0), (0, 0), (0, 0), (0, 0), (0, 1)],
          [(0, 0), (0, 0), (0, double.nan), (0, 0), (0, 0), (0, 2), (0, 0)],
          [(0, 0), (0, 0), (0, 0), (0, 0), (0, 3), (0, 0), (0, 0)],
          [(0, 0), (0, 0), (0, 0), (0, 4), (0, double.nan), (0, 0), (0, 0)],
          [(0, 0), (0, 0), (0, 5), (0, 0), (0, 0), (0, double.nan), (0, 0)],
          [
            (0, double.nan),
            (0, 6),
            (0, 0),
            (0, double.nan),
            (0, 0),
            (0, 0),
            (0, 0),
          ],
          [(0, 7), (0, double.nan), (0, 0), (0, 0), (0, 0), (0, 0), (0, 0)],
        ]),
      ),
      [2, 3, 6, 5, 4, 1, 0],
    );
  });
}
