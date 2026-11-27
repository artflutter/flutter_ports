// Ported from d3-array v3.2.4 test/zip-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test('zip() and zip([]) return an empty array', () {
    expect(zip<int>([]), <List<int>>[]);
    expect(zip<int>([[]]), <List<int>>[]);
  });

  test('zip([a, b, …]) returns [[a], [b], …]', () {
    expect(
      zip([
        [1, 2, 3, 4, 5],
      ]),
      [
        [1],
        [2],
        [3],
        [4],
        [5],
      ],
    );
  });

  test('zip([a1, b1, …], [a2, b2, …]) returns [[a1, a2], [b1, b2], …]', () {
    expect(
      zip([
        [1, 2],
        [3, 4],
      ]),
      [
        [1, 3],
        [2, 4],
      ],
    );
    expect(
      zip([
        [1, 2, 3, 4, 5],
        [2, 4, 6, 8, 10],
      ]),
      [
        [1, 2],
        [2, 4],
        [3, 6],
        [4, 8],
        [5, 10],
      ],
    );
    expect(zip2([1, 2], [3, 4]), [(1, 3), (2, 4)]);
  });

  test('zip([a1, b1, …], [a2, b2, …], [a3, b3, …]) returns '
      '[[a1, a2, a3], [b1, b2, b3], …]', () {
    expect(
      zip([
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
      ]),
      [
        [1, 4, 7],
        [2, 5, 8],
        [3, 6, 9],
      ],
    );
    expect(zip3([1, 2, 3], [4, 5, 6], [7, 8, 9]), [
      (1, 4, 7),
      (2, 5, 8),
      (3, 6, 9),
    ]);
  });

  test('zip(…) ignores extra elements given an irregular matrix', () {
    expect(
      zip([
        [1, 2],
        [3, 4],
        [5, 6, 7],
      ]),
      [
        [1, 3, 5],
        [2, 4, 6],
      ],
    );
    expect(zip3([1, 2], [3, 4], [5, 6, 7]), [(1, 3, 5), (2, 4, 6)]);
  });
}
