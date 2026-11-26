// Ported from d3-shape v3.2.0 test/curve/bundle-test.js (ISC, Mike Bostock).
// Expected SVG path literals stay on single lines for readability.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('line.curve(curveBundle) uses a default beta of 0.85', () {
    final l = line<List<double>>()..curve = curveBundle.beta(0.85).call;
    const data = <List<double>>[
      [0, 1],
      [1, 3],
      [2, 1],
      [3, 3],
    ];
    expect((line<List<double>>()..curve = curveBundle.call)(data), l(data));
  });

  test('line.curve(curveBundle.beta(beta)) uses the specified beta', () {
    assertPathEqual(
      (line<List<double>>()..curve = curveBundle.beta(0.5).call)([
        [0, 1],
        [1, 3],
        [2, 1],
        [3, 3],
      ]),
      'M0,1L0.166667,1.222222C0.333333,1.444444,0.666667,1.888889,1,2C1.333333,2.111111,1.666667,1.888889,2,2C2.333333,2.111111,2.666667,2.555556,2.833333,2.777778L3,3',
    );
  });

  test(
    'line.curve(curveBundle.beta(beta)) coerces the specified beta to a number',
    () {},
    skip: 'diverges: adapt-shape-typed-api',
  );
}
