// Ported from d3-array v3.2.4 test/quickselect-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart';

void main() {
  test(
    'quickselect(array, k) does nothing if k is not a number',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('quickselect(array, k) does nothing if k is less than left', () {
    final array = [3, 1, 2];
    expect(identical(quickselect(array, -1), array), isTrue);
    expect(array, [3, 1, 2]);

    final nullable = <int?>[3, null, 1, 2];
    expect(identical(quickselectNullable(nullable, -1), nullable), isTrue);
    expect(nullable, [3, null, 1, 2]);
  });

  test('quickselect(array, k) does nothing if k is greater than right', () {
    final array = [3, 1, 2];
    expect(identical(quickselect(array, 3), array), isTrue);
    expect(array, [3, 1, 2]);

    final custom = [(v: 3), (v: 1), (v: 2)];
    expect(
      identical(quickselectWith(custom, 3, (a, b) => a.v - b.v), custom),
      isTrue,
    );
    expect(custom, [(v: 3), (v: 1), (v: 2)]);
  });

  test(
    'quickselect(array, k) implicitly floors k, left, and right',
    () {},
    skip: 'diverges: adapt-array-typed-api',
  );

  test('quickselect partitions typed, nullable, and comparator lists', () {
    expect(quickselect([3, 1, 2], 0), [1, 2, 3]);
    expect(quickselect([3, 1, 2, 5, 4], 4), [3, 1, 2, 4, 5]);
    expect(quickselect([3, 1, 2], 0, 0, 2), [1, 2, 3]);

    final nullable = <int?>[3, null, 1, 2];
    quickselectNullable(nullable, 0);
    expect(nullable[0], 1);

    final boxes = [(v: 3), (v: 1), (v: 2)];
    quickselectWith(boxes, 1, (a, b) => a.v - b.v);
    expect(boxes[1], (v: 2));
  });
}
