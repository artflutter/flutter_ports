// Ported from d3-quadtree v3.0.1 test/find-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

void main() {
  test('quadtree.find(x, y) returns the closest point to the given [x, y]', () {
    const dx = 17;
    const dy = 17;
    final q = quadtree();
    for (var i = 0, n = dx * dy; i < n; ++i) {
      q.add(((i % dx).toDouble(), (i ~/ dx).toDouble()));
    }
    expect(q.find(0.1, 0.1), (0.0, 0.0));
    expect(q.find(7.1, 7.1), (7.0, 7.0));
    expect(q.find(0.1, 15.9), (0.0, 16.0));
    expect(q.find(15.9, 15.9), (16.0, 16.0));
  });

  test(
    'quadtree.find(x, y, radius) returns the closest point within the search '
    'radius to the given [x, y]',
    () {
      final q = quadtree(const [(0, 0), (100, 0), (0, 100), (100, 100)]);
      expect(q.find(20, 20, double.infinity), (0.0, 0.0));
      expect(q.find(20, 20, 20 * math.sqrt2 + 1e-6), (0.0, 0.0));
      expect(q.find(20, 20, 20 * math.sqrt2 - 1e-6), isNull);
      expect(q.find(0, 20, 20 + 1e-6), (0.0, 0.0));
      expect(q.find(0, 20, 20 - 1e-6), isNull);
      expect(q.find(20, 0, 20 + 1e-6), (0.0, 0.0));
      expect(q.find(20, 0, 20 - 1e-6), isNull);
    },
  );

  test('quadtree.find(x, y, null) treats the given radius as Infinity', () {
    final q = quadtree(const [(0, 0), (100, 0), (0, 100), (100, 100)]);
    expect(q.find(20, 20), (0.0, 0.0));
    // Upstream find-test.js explicitly passes null for radius.
    // ignore: avoid_redundant_argument_values
    expect(q.find(20, 20, null), (0.0, 0.0));
  });
}
