// Ported from d3-quadtree v3.0.1 test/cover-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

import 'port/node_matchers.dart';

void main() {
  test(
    'quadtree.cover(x, y) sets a trivial extent if the extent was undefined',
    () {
      expect(quadtree().cover(1, 2).extent, ((1.0, 2.0), (2.0, 3.0)));
    },
  );

  test('quadtree.cover(x, y) sets a non-trivial squarified and centered extent '
      'if the extent was trivial', () {
    expect(quadtree().cover(0, 0).cover(1, 2).extent, ((0.0, 0.0), (4.0, 4.0)));
  });

  test('quadtree.cover(x, y) ignores invalid points', () {
    expect(quadtree().cover(0, 0).cover(double.nan, 2).extent, (
      (0.0, 0.0),
      (1.0, 1.0),
    ));
  });

  test('quadtree.cover(x, y) repeatedly doubles the existing extent '
      'if the extent was non-trivial', () {
    expect(quadtree().cover(0, 0).cover(2, 2).cover(-1, -1).extent, (
      (-4.0, -4.0),
      (4.0, 4.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(1, -1).extent, (
      (0.0, -4.0),
      (8.0, 4.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(3, -1).extent, (
      (0.0, -4.0),
      (8.0, 4.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(3, 1).extent, (
      (0.0, 0.0),
      (4.0, 4.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(3, 3).extent, (
      (0.0, 0.0),
      (4.0, 4.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(1, 3).extent, (
      (0.0, 0.0),
      (4.0, 4.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(-1, 3).extent, (
      (-4.0, 0.0),
      (4.0, 8.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(-1, 1).extent, (
      (-4.0, 0.0),
      (4.0, 8.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(-3, -3).extent, (
      (-4.0, -4.0),
      (4.0, 4.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(3, -3).extent, (
      (0.0, -4.0),
      (8.0, 4.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(5, -3).extent, (
      (0.0, -4.0),
      (8.0, 4.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(5, 3).extent, (
      (0.0, 0.0),
      (8.0, 8.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(5, 5).extent, (
      (0.0, 0.0),
      (8.0, 8.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(3, 5).extent, (
      (0.0, 0.0),
      (8.0, 8.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(-3, 5).extent, (
      (-4.0, 0.0),
      (4.0, 8.0),
    ));
    expect(quadtree().cover(0, 0).cover(2, 2).cover(-3, 3).extent, (
      (-4.0, 0.0),
      (4.0, 8.0),
    ));
  });

  test(
    'quadtree.cover(x, y) repeatedly wraps the root node if it has children',
    () {
      final q = quadtree().add((0, 0)).add((2, 2));
      final base = branch(nw: leaf((0.0, 0.0)), se: leaf((2.0, 2.0)));
      expectNodeEquals(q.root, base);
      expectNodeEquals(q.copy().cover(3, 3).root, base);
      expectNodeEquals(q.copy().cover(-1, 3).root, branch(ne: base));
      expectNodeEquals(q.copy().cover(3, -1).root, branch(sw: base));
      expectNodeEquals(q.copy().cover(-1, -1).root, branch(se: base));
      expectNodeEquals(q.copy().cover(5, 5).root, branch(nw: base));
      expectNodeEquals(q.copy().cover(-3, 5).root, branch(ne: base));
      expectNodeEquals(q.copy().cover(5, -3).root, branch(sw: base));
      expectNodeEquals(q.copy().cover(-3, -3).root, branch(se: base));
    },
  );

  test('quadtree.cover(x, y) does not wrap the root node if it is a leaf', () {
    final q = quadtree().cover(0, 0).add((2, 2));
    final expected = leaf((2.0, 2.0));
    expectNodeEquals(q.root, expected);
    expectNodeEquals(q.copy().cover(3, 3).root, expected);
    expectNodeEquals(q.copy().cover(-1, 3).root, expected);
    expectNodeEquals(q.copy().cover(3, -1).root, expected);
    expectNodeEquals(q.copy().cover(-1, -1).root, expected);
    expectNodeEquals(q.copy().cover(5, 5).root, expected);
    expectNodeEquals(q.copy().cover(-3, 5).root, expected);
    expectNodeEquals(q.copy().cover(5, -3).root, expected);
    expectNodeEquals(q.copy().cover(-3, -3).root, expected);
  });

  test(
    'quadtree.cover(x, y) does not wrap the root node if it is undefined',
    () {
      final q = quadtree().cover(0, 0).cover(2, 2);
      expect(q.root, isNull);
      expect(q.copy().cover(3, 3).root, isNull);
      expect(q.copy().cover(-1, 3).root, isNull);
      expect(q.copy().cover(3, -1).root, isNull);
      expect(q.copy().cover(-1, -1).root, isNull);
      expect(q.copy().cover(5, 5).root, isNull);
      expect(q.copy().cover(-3, 5).root, isNull);
      expect(q.copy().cover(5, -3).root, isNull);
      expect(q.copy().cover(-3, -3).root, isNull);
    },
  );

  test('quadtree.cover() does not crash on huge values', () {
    final q = quadtree(const [(1e23, 0)]);
    expect(q.size(), 1);
  });
}
