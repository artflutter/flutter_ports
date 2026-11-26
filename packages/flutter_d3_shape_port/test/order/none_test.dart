// Ported from d3-shape v3.2.0 test/order/none-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

void main() {
  test('stackOrderNone(series) returns [0, 1, … series.length - 1]', () {
    final series = List<StackSeries<Null, Null>>.generate(
      4,
      (_) => StackSeries.fromPairs(const []),
    );
    expect(stackOrderNone(series), [0, 1, 2, 3]);
  });
}
