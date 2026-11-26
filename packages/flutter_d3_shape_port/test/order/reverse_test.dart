// Ported from d3-shape v3.2.0 test/order/reverse-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

void main() {
  test('stackOrderReverse(series) returns [series.length - 1, '
      'series.length - 2, … 0]', () {
    final series = List<StackSeries<Null, Null>>.generate(
      4,
      (_) => StackSeries.fromPairs(const []),
    );
    expect(stackOrderReverse(series), [3, 2, 1, 0]);
  });
}
