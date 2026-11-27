// Ported from d3-quadtree v3.0.1 test/copy-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

import 'port/node_matchers.dart';

void main() {
  test('quadtree.copy() returns a copy of this quadtree', () {
    final q0 = quadtree().addAll(const [(0, 0), (1, 0), (0, 1), (1, 1)]);
    expectTreeEquals(q0.copy(), q0);
  });

  test('quadtree.copy() isolates changes to the extent', () {
    final q0 = quadtree().setExtent(((0, 0), (1, 1)));
    final q1 = q0.copy();
    q0.add((2, 2));
    expect(q1.extent, ((0.0, 0.0), (2.0, 2.0)));
    q1.add((-1, -1));
    expect(q0.extent, ((0.0, 0.0), (4.0, 4.0)));
  });

  test('quadtree.copy() isolates changes to the root when a leaf', () {
    final q0 = quadtree().setExtent(((0, 0), (1, 1)));
    final q1 = q0.copy();
    const p0 = (2.0, 2.0);
    q0.add(p0);
    expect(q1.root, isNull);
    final q2 = q0.copy();
    expectNodeEquals(q0.root, leaf((2, 2)));
    expectNodeEquals(q2.root, leaf((2, 2)));
    expect(q0.remove(p0), same(q0));
    expect(q0.root, isNull);
    expectNodeEquals(q2.root, leaf((2, 2)));
  });

  test('quadtree.copy() isolates changes to the root when not a leaf', () {
    const p0 = (1.0, 1.0);
    const p1 = (2.0, 2.0);
    const p2 = (3.0, 3.0);
    final q0 = quadtree().setExtent(((0, 0), (4, 4))).addAll(const [p0, p1]);
    final q1 = q0.copy();
    q0.add(p2);
    expect(q0.extent, ((0.0, 0.0), (8.0, 8.0)));
    expectNodeEquals(
      q0.root,
      branch(
        nw: branch(
          nw: leaf((1, 1)),
          se: branch(nw: leaf((2, 2)), se: leaf((3, 3))),
        ),
      ),
    );
    expect(q1.extent, ((0.0, 0.0), (8.0, 8.0)));
    expectNodeEquals(
      q1.root,
      branch(
        nw: branch(nw: leaf((1, 1)), se: leaf((2, 2))),
      ),
    );
    final q3 = q0.copy();
    q0.remove(p2);
    expect(q3.extent, ((0.0, 0.0), (8.0, 8.0)));
    expectNodeEquals(
      q3.root,
      branch(
        nw: branch(
          nw: leaf((1, 1)),
          se: branch(nw: leaf((2, 2)), se: leaf((3, 3))),
        ),
      ),
    );
  });
}
