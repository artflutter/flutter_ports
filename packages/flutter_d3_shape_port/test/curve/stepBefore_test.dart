// Ported from d3-shape v3.2.0 test/curve/stepBefore-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('line.curve(curveStepBefore)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveStepBefore;
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
      'M0,1L0,3L2,3',
    );
    assertPathEqual(
      l([
        [0, 1],
        [2, 3],
        [4, 5],
      ]),
      'M0,1L0,3L2,3L2,5L4,5',
    );
  });

  test('area.curve(curveStepBefore)(data) generates the expected path', () {
    final a = area<List<double>>()..curve = curveStepBefore;
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
      'M0,1L0,3L2,3L2,0L0,0L0,0Z',
    );
    assertPathEqual(
      a([
        [0, 1],
        [2, 3],
        [4, 5],
      ]),
      'M0,1L0,3L2,3L2,5L4,5L4,0L2,0L2,0L0,0L0,0Z',
    );
  });
}
