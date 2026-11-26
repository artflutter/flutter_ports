// Ported from d3-shape v3.2.0 test/curve/basisClosed-test.js (ISC, Mike Bostock).
// Expected SVG path literals exceed 80 chars and filename mirrors upstream.
// ignore_for_file: file_names, lines_longer_than_80_chars

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('line.curve(curveBasisClosed)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveBasisClosed;
    expect(l([]), isNull);
    assertPathEqual(
      l([
        [0, 0],
      ]),
      'M0,0Z',
    );
    assertPathEqual(
      l([
        [0, 0],
        [0, 10],
      ]),
      'M0,6.666667L0,3.333333Z',
    );
    assertPathEqual(
      l([
        [0, 0],
        [0, 10],
        [10, 10],
      ]),
      'M1.666667,8.333333C3.333333,10,6.666667,10,6.666667,8.333333C6.666667,6.666667,3.333333,3.333333,1.666667,3.333333C0,3.333333,0,6.666667,1.666667,8.333333',
    );
    assertPathEqual(
      l([
        [0, 0],
        [0, 10],
        [10, 10],
        [10, 0],
      ]),
      'M1.666667,8.333333C3.333333,10,6.666667,10,8.333333,8.333333C10,6.666667,10,3.333333,8.333333,1.666667C6.666667,0,3.333333,0,1.666667,1.666667C0,3.333333,0,6.666667,1.666667,8.333333',
    );
    assertPathEqual(
      l([
        [0, 0],
        [0, 10],
        [10, 10],
        [10, 0],
        [0, 0],
      ]),
      'M1.666667,8.333333C3.333333,10,6.666667,10,8.333333,8.333333C10,6.666667,10,3.333333,8.333333,1.666667C6.666667,0,3.333333,0,1.666667,0C0,0,0,0,0,1.666667C0,3.333333,0,6.666667,1.666667,8.333333',
    );
  });
}
