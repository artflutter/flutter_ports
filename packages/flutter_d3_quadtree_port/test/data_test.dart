// Ported from d3-quadtree v3.0.1 test/data-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

void main() {
  test('quadtree.data() returns an array of data in the quadtree', () {
    final q = quadtree();
    expect(q.data(), isEmpty);
    q
      ..add((0, 0))
      ..add((1, 2));
    expect(q.data(), const [(0.0, 0.0), (1.0, 2.0)]);
  });

  test('quadtree.data() correctly handles coincident nodes', () {
    final q = quadtree()
      ..add((0, 0))
      ..add((0, 0));
    expect(q.data(), const [(0.0, 0.0), (0.0, 0.0)]);
  });
}
