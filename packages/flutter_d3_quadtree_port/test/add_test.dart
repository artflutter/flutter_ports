// Ported from d3-quadtree v3.0.1 test/add-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

import 'port/node_matchers.dart';

void main() {
  test(
    'quadtree.add(datum) creates a new point and adds it to the quadtree',
    () {
      final q = quadtree();
      expectNodeEquals(q.add((0.0, 0.0)).root, leaf((0, 0)));
      expectNodeEquals(
        q.add((0.9, 0.9)).root,
        branch(nw: leaf((0, 0)), se: leaf((0.9, 0.9))),
      );
      expectNodeEquals(
        q.add((0.9, 0.0)).root,
        branch(nw: leaf((0, 0)), ne: leaf((0.9, 0)), se: leaf((0.9, 0.9))),
      );
      expectNodeEquals(
        q.add((0.0, 0.9)).root,
        branch(
          nw: leaf((0, 0)),
          ne: leaf((0.9, 0)),
          sw: leaf((0, 0.9)),
          se: leaf((0.9, 0.9)),
        ),
      );
      expectNodeEquals(
        q.add((0.4, 0.4)).root,
        branch(
          nw: branch(nw: leaf((0, 0)), se: leaf((0.4, 0.4))),
          ne: leaf((0.9, 0)),
          sw: leaf((0, 0.9)),
          se: leaf((0.9, 0.9)),
        ),
      );
    },
  );

  test('quadtree.add(datum) handles points being on the perimeter '
      'of the quadtree bounds', () {
    final q = quadtree().setExtent(((0, 0), (1, 1)));
    expectNodeEquals(q.add((0, 0)).root, leaf((0, 0)));
    expectNodeEquals(
      q.add((1, 1)).root,
      branch(nw: leaf((0, 0)), se: leaf((1, 1))),
    );
    expectNodeEquals(
      q.add((1, 0)).root,
      branch(nw: leaf((0, 0)), ne: leaf((1, 0)), se: leaf((1, 1))),
    );
    expectNodeEquals(
      q.add((0, 1)).root,
      branch(
        nw: leaf((0, 0)),
        ne: leaf((1, 0)),
        sw: leaf((0, 1)),
        se: leaf((1, 1)),
      ),
    );
  });

  test('quadtree.add(datum) handles points being to the top '
      'of the quadtree bounds', () {
    final q = quadtree().setExtent(((0, 0), (2, 2)));
    expect(q.add((1, -1)).extent, ((0.0, -4.0), (8.0, 4.0)));
  });

  test('quadtree.add(datum) handles points being to the right '
      'of the quadtree bounds', () {
    final q = quadtree().setExtent(((0, 0), (2, 2)));
    expect(q.add((3, 1)).extent, ((0.0, 0.0), (4.0, 4.0)));
  });

  test('quadtree.add(datum) handles points being to the bottom '
      'of the quadtree bounds', () {
    final q = quadtree().setExtent(((0, 0), (2, 2)));
    expect(q.add((1, 3)).extent, ((0.0, 0.0), (4.0, 4.0)));
  });

  test('quadtree.add(datum) handles points being to the left '
      'of the quadtree bounds', () {
    final q = quadtree().setExtent(((0, 0), (2, 2)));
    expect(q.add((-1, 1)).extent, ((-4.0, 0.0), (4.0, 8.0)));
  });

  test(
    'quadtree.add(datum) handles coincident points by creating a linked list',
    () {
      final q = quadtree().setExtent(((0, 0), (1, 1)));
      expectNodeEquals(q.add((0, 0)).root, leaf((0, 0)));
      expectNodeEquals(
        q.add((1, 0)).root,
        branch(nw: leaf((0, 0)), ne: leaf((1, 0))),
      );
      expectNodeEquals(
        q.add((0, 1)).root,
        branch(nw: leaf((0, 0)), ne: leaf((1, 0)), sw: leaf((0, 1))),
      );
      expectNodeEquals(
        q.add((0, 1)).root,
        branch(
          nw: leaf((0, 0)),
          ne: leaf((1, 0)),
          sw: leaf((0, 1), leaf((0, 1))),
        ),
      );
    },
  );

  test(
    'quadtree.add(datum) implicitly defines trivial bounds for the first point',
    () {
      final q = quadtree().add((1, 2));
      expect(q.extent, ((1.0, 2.0), (2.0, 3.0)));
      expectNodeEquals(q.root, leaf((1, 2)));
    },
  );
}
