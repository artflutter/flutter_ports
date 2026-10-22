// Ported from Chart.js v4.5.1+7169e651 test/specs/helpers.collection.tests.js (MIT, Chart.js Contributors).
import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart';
import 'package:test/test.dart';

void main() {
  setUpSpecs();
  group('helpers.collection', () {
    test('Should do binary search', () {
      const data = <double>[0, 2, 6, 9];
      expect(lookup(data, 0), (lo: 0, hi: 1));
      expect(lookup(data, 1), (lo: 0, hi: 1));
      expect(lookup(data, 3), (lo: 1, hi: 2));
      expect(lookup(data, 6), (lo: 1, hi: 2));
      expect(lookup(data, 9), (lo: 2, hi: 3));
    });

    test('Should do binary search by key', () {
      const data = <Map<String, Object?>>[
        {'x': 0.0},
        {'x': 2.0},
        {'x': 6.0},
        {'x': 9.0},
      ];
      expect(lookupByKey(data, 'x', 0), (lo: 0, hi: 1));
      expect(lookupByKey(data, 'x', 1), (lo: 0, hi: 1));
      expect(lookupByKey(data, 'x', 3), (lo: 1, hi: 2));
      expect(lookupByKey(data, 'x', 6), (lo: 1, hi: 2));
      expect(lookupByKey(data, 'x', 9), (lo: 2, hi: 3));
    });

    test('Should do binary search by key with last', () {
      expect(lookupByKey(_table([0, 2, 6, 9]), 'x', 25, true), (lo: 2, hi: 3));
      expect(lookupByKey(_table([0, 2, 9, 9]), 'x', 25, true), (lo: 2, hi: 3));
      expect(
        lookupByKey(_table([0, 2, 9, 9, 22]), 'x', 25, true),
        (lo: 3, hi: 4),
      );
      expect(
        lookupByKey(_table([0, 2, 25, 28]), 'x', 25, true),
        (lo: 1, hi: 2),
      );
      expect(
        lookupByKey(_table([0, 2, 25, 25]), 'x', 25, true),
        (lo: 2, hi: 3),
      );
      expect(
        lookupByKey(_table([0, 2, 25, 25, 28]), 'x', 25, true),
        (lo: 2, hi: 3),
      );
      expect(
        lookupByKey(_table([0, 2, 25, 25, 25, 28, 29]), 'x', 25, true),
        (lo: 3, hi: 4),
      );
    });

    test('Should do reverse binary search by key', () {
      const data = <Map<String, Object?>>[
        {'x': 10.0},
        {'x': 7.0},
        {'x': 3.0},
        {'x': 0.0},
      ];
      expect(rlookupByKey(data, 'x', 0), (lo: 2, hi: 3));
      expect(rlookupByKey(data, 'x', 3), (lo: 2, hi: 3));
      expect(rlookupByKey(data, 'x', 5), (lo: 1, hi: 2));
      expect(rlookupByKey(data, 'x', 8), (lo: 0, hi: 1));
      expect(rlookupByKey(data, 'x', 10), (lo: 0, hi: 1));
    });

    test('Should filter a sorted array', () {
      expect(filterBetween([1, 2, 3, 4, 5, 6, 7, 8, 9], 5, 8), <double>[
        5,
        6,
        7,
        8,
      ]);
      expect(filterBetween([1], 1, 1), <double>[1]);
      expect(
        filterBetween([1583049600000], 1584816327553, 1585680327553),
        <double>[],
      );
    });
  });
}

/// The JavaScript array literal `[{x: x0}, {x: x1}, ...]` of the spec.
List<Map<String, Object?>> _table(List<double> xs) => [
  for (final x in xs) {'x': x},
];
