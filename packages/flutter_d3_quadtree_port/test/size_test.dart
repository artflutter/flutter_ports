// Ported from d3-quadtree v3.0.1 test/size-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

void main() {
  test('quadtree.size() returns the number of points in the quadtree', () {
    final q = quadtree();
    expect(q.size(), 0);
    q
      ..add((0, 0))
      ..add((1, 2));
    expect(q.size(), 2);
  });

  test('quadtree.size() correctly counts coincident nodes', () {
    final q = quadtree()
      ..add((0, 0))
      ..add((0, 0));
    expect(q.size(), 2);
  });
}
