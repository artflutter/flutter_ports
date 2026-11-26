// Ported from d3-shape v3.2.0 test/curve/bumpY-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('line.curve(curveBumpY)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveBumpY;
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
      'M0,1C0,2,1,2,1,3',
    );
    assertPathEqual(
      l([
        [0, 1],
        [1, 3],
        [2, 1],
      ]),
      'M0,1C0,2,1,2,1,3C1,2,2,2,2,1',
    );
  });

  test('area.curve(curveBumpY)(data) generates the expected path', () {
    final a = area<List<double>>()..curve = curveBumpY;
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
      'M0,1C0,2,1,2,1,3L1,0C1,0,0,0,0,0Z',
    );
    assertPathEqual(
      a([
        [0, 1],
        [1, 3],
        [2, 1],
      ]),
      'M0,1C0,2,1,2,1,3C1,2,2,2,2,1L2,0C2,0,1,0,1,0C1,0,0,0,0,0Z',
    );
  });
}
