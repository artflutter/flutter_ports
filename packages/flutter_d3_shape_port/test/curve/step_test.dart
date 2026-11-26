// Ported from d3-shape v3.2.0 test/curve/step-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('line.curve(curveStep)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveStep;
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
        [2, 3],
      ]),
      'M0,1L1,1L1,3L2,3',
    );
    assertPathEqual(
      l([
        [0, 1],
        [2, 3],
        [4, 5],
      ]),
      'M0,1L1,1L1,3L3,3L3,5L4,5',
    );
  });

  test('area.curve(curveStep)(data) generates the expected path', () {
    final a = area<List<double>>()..curve = curveStep;
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
        [2, 3],
      ]),
      'M0,1L1,1L1,3L2,3L2,0L1,0L1,0L0,0Z',
    );
    assertPathEqual(
      a([
        [0, 1],
        [2, 3],
        [4, 5],
      ]),
      'M0,1L1,1L1,3L3,3L3,5L4,5L4,0L3,0L3,0L1,0L1,0L0,0Z',
    );
  });
}
