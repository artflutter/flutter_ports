// Ported from d3-shape v3.2.0 test/order/appearance-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

List<StackSeries<Null, Null>> _make(List<List<(double, double)>> rows) => [
  for (final r in rows) StackSeries.fromPairs(r),
];

void main() {
  test('stackOrderAppearance(series) returns an order by appearance', () {
    expect(
      stackOrderAppearance(
        _make([
          [(0, 0), (0, 0), (0, 1)],
          [(0, 3), (0, 2), (0, 0)],
          [(0, 0), (0, 4), (0, 0)],
        ]),
      ),
      [1, 2, 0],
    );
  });

  test('stackOrderAppearance(series) treats NaN values as zero', () {
    expect(
      stackOrderAppearance(
        _make([
          [(0, double.nan), (0, double.nan), (0, 1)],
          [(0, 3), (0, 2), (0, double.nan)],
          [(0, double.nan), (0, 4), (0, double.nan)],
        ]),
      ),
      [1, 2, 0],
    );
  });
}
