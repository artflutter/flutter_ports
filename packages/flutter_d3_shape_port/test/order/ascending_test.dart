// Ported from d3-shape v3.2.0 test/order/ascending-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

List<StackSeries<Null, Null>> _make(List<List<(double, double)>> rows) => [
  for (final r in rows) StackSeries.fromPairs(r),
];

void main() {
  test('stackOrderAscending(series) returns an order by sum', () {
    expect(
      stackOrderAscending(
        _make([
          [(0, 1), (0, 2), (0, 3)],
          [(0, 2), (0, 3), (0, 4)],
          [(0, 0), (0, 1), (0, 2)],
        ]),
      ),
      [2, 0, 1],
    );
  });

  test('stackOrderAscending(series) treats NaN values as zero', () {
    expect(
      stackOrderAscending(
        _make([
          [(0, 1), (0, 2), (0, double.nan), (0, 3)],
          [(0, 2), (0, 3), (0, double.nan), (0, 4)],
          [(0, 0), (0, 1), (0, double.nan), (0, 2)],
        ]),
      ),
      [2, 0, 1],
    );
  });
}
