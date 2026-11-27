// Ported from d3-array v3.2.4 test/pairs-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_array_port/d3_array.dart';
import 'package:test/test.dart' hide group;

void main() {
  test('pairs(array) returns the empty array if input array has fewer than two '
      'elements', () {
    expect(pairs(<int>[]), <(int, int)>[]);
    expect(pairs(<int>[1]), <(int, int)>[]);
  });

  test(
    'pairs(array) returns pairs of adjacent elements in the given array',
    () {
      final a = Object();
      final b = Object();
      final c = Object();
      final d = Object();
      expect(pairs(<int>[1, 2]), <(int, int)>[(1, 2)]);
      expect(pairs(<int>[1, 2, 3]), <(int, int)>[(1, 2), (2, 3)]);
      expect(pairs(<Object>[a, b, c, d]), <(Object, Object)>[
        (a, b),
        (b, c),
        (c, d),
      ]);
      expect(pair(1, 2), (1, 2));
    },
  );

  test(
    'pairs(array, f) invokes the function f for each pair of adjacent elements',
    () {
      expect(pairsWith(<int>[1, 3, 7], (a, b) => b - a), <int>[2, 4]);
    },
  );

  test('pairs(array) includes null or undefined elements in pairs', () {
    expect(pairs(<int?>[1, null, 2]), <(int?, int?)>[(1, null), (null, 2)]);
    expect(pairs(<int?>[1, 2, null]), <(int?, int?)>[(1, 2), (2, null)]);
  });
}
