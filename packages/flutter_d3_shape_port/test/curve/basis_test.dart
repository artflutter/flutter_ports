// Ported from d3-shape v3.2.0 test/curve/basis-test.js (ISC, Mike Bostock).
// Expected SVG path literals stay on single lines for readability.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('line.curve(curveBasis)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveBasis;
    expect(l([]), isNull);
    assertPathEqual(
      l([
        [0, 1],
      ]),
      'M0,1Z',
    );
    assertPathEqual(
      l([
        [0, 1],
        [1, 3],
      ]),
      'M0,1L1,3',
    );
    assertPathEqual(
      l([
        [0, 1],
        [1, 3],
        [2, 1],
      ]),
      'M0,1L0.166667,1.333333C0.333333,1.666667,0.666667,2.333333,1,2.333333C1.333333,2.333333,1.666667,1.666667,1.833333,1.333333L2,1',
    );
  });

  test('area.curve(curveBasis)(data) generates the expected path', () {
    final a = area<List<double>>()..curve = curveBasis;
    expect(a([]), isNull);
    assertPathEqual(
      a([
        [0, 1],
      ]),
      'M0,1L0,0Z',
    );
    assertPathEqual(
      a([
        [0, 1],
        [1, 3],
      ]),
      'M0,1L1,3L1,0L0,0Z',
    );
    assertPathEqual(
      a([
        [0, 1],
        [1, 3],
        [2, 1],
      ]),
      'M0,1L0.166667,1.333333C0.333333,1.666667,0.666667,2.333333,1,2.333333C1.333333,2.333333,1.666667,1.666667,1.833333,1.333333L2,1L2,0L1.833333,0C1.666667,0,1.333333,0,1,0C0.666667,0,0.333333,0,0.166667,0L0,0Z',
    );
  });
}
