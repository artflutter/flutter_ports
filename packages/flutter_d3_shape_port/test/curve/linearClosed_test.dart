// Ported from d3-shape v3.2.0 test/curve/linearClosed-test.js (ISC, Mike Bostock).
// ignore_for_file: file_names

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

void main() {
  test('line.curve(curveLinearClosed)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveLinearClosed;
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
      'M0,1L2,3Z',
    );
    assertPathEqual(
      l([
        [0, 1],
        [2, 3],
        [4, 5],
      ]),
      'M0,1L2,3L4,5Z',
    );
  });
}
