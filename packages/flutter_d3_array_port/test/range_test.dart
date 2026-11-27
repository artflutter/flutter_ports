// Ported from d3-array v3.2.4 test/range-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('range(stop) returns [0, 1, 2, … stop - 1]', () {
    expect(range(5), <double>[0, 1, 2, 3, 4]);
    expect(range(2.01), <double>[0, 1, 2]);
    expect(range(1), <double>[0]);
    expect(range(0.5), <double>[0]);
  });

  test('range(stop) returns an empty array if stop <= 0', () {
    expect(range(0), <double>[]);
    expect(range(-0.5), <double>[]);
    expect(range(-1), <double>[]);
  });

  test('range(stop) returns an empty array if stop is NaN', () {
    expect(range(double.nan), <double>[]);
  });

  test('range(start, stop) returns [start, start + 1, … stop - 1]', () {
    expect(range(0, 5), <double>[0, 1, 2, 3, 4]);
    expect(range(2, 5), <double>[2, 3, 4]);
    expect(range(2.5, 5), <double>[2.5, 3.5, 4.5]);
    expect(range(-1, 3), <double>[-1, 0, 1, 2]);
  });

  test('range(start, stop) returns an empty array if start or stop is NaN', () {
    expect(range(0, double.nan), <double>[]);
    expect(range(1, double.nan), <double>[]);
    expect(range(-1, double.nan), <double>[]);
    expect(range(double.nan, 0), <double>[]);
    expect(range(double.nan, 1), <double>[]);
    expect(range(double.nan, -1), <double>[]);
    expect(range(double.nan, double.nan), <double>[]);
  });

  test('range(start, stop) returns an empty array if start >= stop', () {
    expect(range(0, 0), <double>[]);
    expect(range(5, 5), <double>[]);
    expect(range(6, 5), <double>[]);
    expect(range(10, 10), <double>[]);
    expect(range(20, 10), <double>[]);
  });

  test(
    'range(start, stop, step) returns [start, start + step, start + 2 * step, '
    '… stop - step]',
    () {
      expect(range(0, 5, 1), <double>[0, 1, 2, 3, 4]);
      expect(range(0, 5, 2), <double>[0, 2, 4]);
      expect(range(2, 5, 2), <double>[2, 4]);
      expect(range(-1, 3, 2), <double>[-1, 1]);
    },
  );

  test('range(start, stop, step) allows a negative step', () {
    expect(range(5, 0, -1), <double>[5, 4, 3, 2, 1]);
    expect(range(5, 0, -2), <double>[5, 3, 1]);
    expect(range(5, 2, -2), <double>[5, 3]);
    expect(range(3, -1, -2), <double>[3, 1]);
  });

  test('range(start, stop, step) returns an empty array if start >= stop and '
      'step > 0', () {
    expect(range(5, 5, 2), <double>[]);
    expect(range(6, 5, 2), <double>[]);
    expect(range(10, 10, 1), <double>[]);
    expect(range(10, 10, 0.5), <double>[]);
    expect(range(0, 0, 1), <double>[]);
    expect(range(0, 0, 0.5), <double>[]);
    expect(range(20, 10, 2), <double>[]);
    expect(range(20, 10, 1), <double>[]);
    expect(range(20, 10, 0.5), <double>[]);
  });

  test('range(start, stop, step) returns an empty array if start >= stop and '
      'step < 0', () {
    expect(range(5, 5, -2), <double>[]);
    expect(range(5, 6, -2), <double>[]);
    expect(range(10, 10, -1), <double>[]);
    expect(range(10, 10, -0.5), <double>[]);
    expect(range(0, 0, -1), <double>[]);
    expect(range(0, 0, -0.5), <double>[]);
    expect(range(10, 20, -2), <double>[]);
    expect(range(10, 20, -1), <double>[]);
    expect(range(10, 20, -0.5), <double>[]);
  });

  test('range(start, stop, step) returns an empty array if start, stop or step '
      'is NaN', () {
    expect(range(double.nan, 3, 2), <double>[]);
    expect(range(3, double.nan, 2), <double>[]);
    expect(range(0, 5, double.nan), <double>[]);
    expect(range(double.nan, double.nan, double.nan), <double>[]);
    expect(range(0, 10, double.nan), <double>[]);
    expect(range(10, 0, double.nan), <double>[]);
  });

  test('range(start, stop, step) returns an empty array if step is zero', () {
    expect(range(0, 5, 0), <double>[]);
  });

  test('range(start, stop, step) returns exactly [start + step * i, …] for '
      'fractional steps', () {
    expect(range(0, 0.5, 0.1), <double>[
      0 + 0.1 * 0,
      0 + 0.1 * 1,
      0 + 0.1 * 2,
      0 + 0.1 * 3,
      0 + 0.1 * 4,
    ]);
    expect(range(0.5, 0, -0.1), <double>[
      0.5 - 0.1 * 0,
      0.5 - 0.1 * 1,
      0.5 - 0.1 * 2,
      0.5 - 0.1 * 3,
      0.5 - 0.1 * 4,
    ]);
    expect(range(-2, -1.2, 0.1), <double>[
      -2 + 0.1 * 0,
      -2 + 0.1 * 1,
      -2 + 0.1 * 2,
      -2 + 0.1 * 3,
      -2 + 0.1 * 4,
      -2 + 0.1 * 5,
      -2 + 0.1 * 6,
      -2 + 0.1 * 7,
    ]);
    expect(range(-1.2, -2, -0.1), <double>[
      -1.2 - 0.1 * 0,
      -1.2 - 0.1 * 1,
      -1.2 - 0.1 * 2,
      -1.2 - 0.1 * 3,
      -1.2 - 0.1 * 4,
      -1.2 - 0.1 * 5,
      -1.2 - 0.1 * 6,
      -1.2 - 0.1 * 7,
    ]);
  });

  test(
    'range(start, stop, step) returns exactly [start + step * i, …] for very '
    'small fractional steps',
    () {
      expect(range(2.1e-31, 5e-31, 1.1e-31), <double>[
        2.1e-31 + 1.1e-31 * 0,
        2.1e-31 + 1.1e-31 * 1,
        2.1e-31 + 1.1e-31 * 2,
      ]);
      expect(range(5e-31, 2.1e-31, -1.1e-31), <double>[
        5e-31 - 1.1e-31 * 0,
        5e-31 - 1.1e-31 * 1,
        5e-31 - 1.1e-31 * 2,
      ]);
    },
  );

  test(
    'range(start, stop, step) returns exactly [start + step * i, …] for very '
    'large fractional steps',
    () {
      expect(range(1e300, 2e300, 0.3e300), <double>[
        1e300 + 0.3e300 * 0,
        1e300 + 0.3e300 * 1,
        1e300 + 0.3e300 * 2,
        1e300 + 0.3e300 * 3,
      ]);
      expect(range(2e300, 1e300, -0.3e300), <double>[
        2e300 - 0.3e300 * 0,
        2e300 - 0.3e300 * 1,
        2e300 - 0.3e300 * 2,
        2e300 - 0.3e300 * 3,
      ]);
    },
  );
}
