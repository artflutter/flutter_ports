// Ported from d3-shape v3.2.0 test/curve/monotoneY-test.js (ISC, Mike Bostock).
// Expected SVG path literals exceed 80 chars and filename mirrors upstream.
// ignore_for_file: file_names, lines_longer_than_80_chars

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

import '../asserts.dart';

List<List<double>> _reflect(List<List<double>> pts) => [
  for (final p in pts) [p[1], p[0]],
];

void main() {
  test('line.curve(curveMonotoneY)(data) generates the expected path', () {
    final l = line<List<double>>()..curve = curveMonotoneY;
    expect(l(_reflect([])), isNull);
    assertPathEqual(
      l(
        _reflect([
          [0, 1],
        ]),
      ),
      'M1,0Z',
    );
    assertPathEqual(
      l(
        _reflect([
          [0, 1],
          [1, 3],
        ]),
      ),
      'M1,0L3,1',
    );
    assertPathEqual(
      l(
        _reflect([
          [0, 1],
          [1, 3],
          [2, 1],
        ]),
      ),
      'M1,0C2,0.333333,3,0.666667,3,1C3,1.333333,2,1.666667,1,2',
    );
    assertPathEqual(
      l(
        _reflect([
          [0, 1],
          [1, 3],
          [2, 1],
          [3, 3],
        ]),
      ),
      'M1,0C2,0.333333,3,0.666667,3,1C3,1.333333,1,1.666667,1,2C1,2.333333,2,2.666667,3,3',
    );
  });

  test('line.curve(curveMonotoneY)(data) preserves monotonicity in y', () {
    final l = line<List<double>>()..curve = curveMonotoneY;
    assertPathEqual(
      l(
        _reflect([
          [0, 200],
          [100, 100],
          [200, 100],
          [300, 300],
          [400, 300],
        ]),
      ),
      'M200,0C150,33.333333,100,66.666667,100,100C100,133.333333,100,166.666667,100,200C100,233.333333,300,266.666667,300,300C300,333.333333,300,366.666667,300,400',
    );
  });

  test('line.curve(curveMonotoneY)(data) handles duplicate x-values', () {
    final l = line<List<double>>()..curve = curveMonotoneY;
    assertPathEqual(
      l(
        _reflect([
          [0, 200],
          [0, 100],
          [100, 100],
          [200, 0],
        ]),
      ),
      'M200,0C200,0,100,0,100,0C100,33.333333,100,66.666667,100,100C100,133.333333,50,166.666667,0,200',
    );
    assertPathEqual(
      l(
        _reflect([
          [0, 200],
          [100, 100],
          [100, 0],
          [200, 0],
        ]),
      ),
      'M200,0C183.333333,33.333333,166.666667,66.666667,100,100C100,100,0,100,0,100C0,133.333333,0,166.666667,0,200',
    );
    assertPathEqual(
      l(
        _reflect([
          [0, 200],
          [100, 100],
          [200, 100],
          [200, 0],
        ]),
      ),
      'M200,0C150,33.333333,100,66.666667,100,100C100,133.333333,100,166.666667,100,200C100,200,0,200,0,200',
    );
  });

  test(
    'line.curve(curveMonotoneY)(data) handles segments of infinite slope',
    () {
      final l = line<List<double>>()..curve = curveMonotoneY;
      assertPathEqual(
        l(
          _reflect([
            [0, 200],
            [100, 150],
            [100, 50],
            [200, 0],
          ]),
        ),
        'M200,0C191.666667,33.333333,183.333333,66.666667,150,100C150,100,50,100,50,100C16.666667,133.333333,8.333333,166.666667,0,200',
      );
      assertPathEqual(
        l(
          _reflect([
            [200, 0],
            [100, 50],
            [100, 150],
            [0, 200],
          ]),
        ),
        'M0,200C8.333333,166.666667,16.666667,133.333333,50,100C50,100,150,100,150,100C183.333333,66.666667,191.666667,33.333333,200,0',
      );
    },
  );

  test('line.curve(curveMonotoneY)(data) ignores coincident points', () {
    final l = line<List<double>>()..curve = curveMonotoneY;
    final p = l(
      _reflect([
        [0, 200],
        [50, 200],
        [100, 100],
        [150, 0],
        [200, 0],
      ]),
    );
    expect(
      l(
        _reflect([
          [0, 200],
          [0, 200],
          [50, 200],
          [100, 100],
          [150, 0],
          [200, 0],
        ]),
      ),
      p,
    );
    expect(
      l(
        _reflect([
          [0, 200],
          [50, 200],
          [50, 200],
          [100, 100],
          [150, 0],
          [200, 0],
        ]),
      ),
      p,
    );
    expect(
      l(
        _reflect([
          [0, 200],
          [50, 200],
          [100, 100],
          [100, 100],
          [150, 0],
          [200, 0],
        ]),
      ),
      p,
    );
    expect(
      l(
        _reflect([
          [0, 200],
          [50, 200],
          [100, 100],
          [150, 0],
          [150, 0],
          [200, 0],
        ]),
      ),
      p,
    );
    expect(
      l(
        _reflect([
          [0, 200],
          [50, 200],
          [100, 100],
          [150, 0],
          [200, 0],
          [200, 0],
        ]),
      ),
      p,
    );
  });

  test('area.curve(curveMonotoneY)(data) generates the expected path', () {
    final a = area<List<double>>()..curve = curveMonotoneY;
    expect(a(_reflect([])), isNull);
    assertPathEqual(
      a(
        _reflect([
          [0, 1],
        ]),
      ),
      'M1,0L1,0Z',
    );
    assertPathEqual(
      a(
        _reflect([
          [0, 1],
          [1, 3],
        ]),
      ),
      'M1,0L3,1L3,0L1,0Z',
    );
    assertPathEqual(
      a(
        _reflect([
          [0, 1],
          [1, 3],
          [2, 1],
        ]),
      ),
      'M1,0C2,0.333333,3,0.666667,3,1C3,1.333333,2,1.666667,1,2L1,0C1,0,3,0,3,0C3,0,1,0,1,0Z',
    );
    assertPathEqual(
      a(
        _reflect([
          [0, 1],
          [1, 3],
          [2, 1],
          [3, 3],
        ]),
      ),
      'M1,0C2,0.333333,3,0.666667,3,1C3,1.333333,1,1.666667,1,2C1,2.333333,2,2.666667,3,3L3,0C3,0,1,0,1,0C1,0,3,0,3,0C3,0,1,0,1,0Z',
    );
  });
}
