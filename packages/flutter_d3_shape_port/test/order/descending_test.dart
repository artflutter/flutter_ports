// Ported from d3-shape v3.2.0 test/order/descending-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

List<StackSeries<Null, Null>> _make(List<List<(double, double)>> rows) => [
  for (final r in rows) StackSeries.fromPairs(r),
];

void main() {
  test('stackOrderDescending(series) returns an order by sum', () {
    expect(
      stackOrderDescending(
        _make([
          [(0, 1), (0, 2), (0, 3)],
          [(0, 2), (0, 3), (0, 4)],
          [(0, 0), (0, 1), (0, 2)],
        ]),
      ),
      [1, 0, 2],
    );
  });

  test('stackOrderDescending(series) treats NaN values as zero', () {
    expect(
      stackOrderDescending(
        _make([
          [(0, 1), (0, 2), (0, 3), (0, double.nan)],
          [(0, 2), (0, 3), (0, 4), (0, double.nan)],
          [(0, 0), (0, 1), (0, 2), (0, double.nan)],
        ]),
      ),
      [1, 0, 2],
    );
  });
}
