// Original code, not ported from d3-quadtree: visitAfter and API tests.

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

import 'node_matchers.dart';

Iterable<(double, double)> _lazyPoints() sync* {
  yield (10, 10);
  yield (90, 10);
  yield (10, 90);
  yield (90, 90);
}

void main() {
  test('quadtree.visitAfter(callback) applies post-order traversal', () {
    final results = <(double, double, double, double)>[];
    final q = quadtree().addAll(const [(0, 0), (1, 0), (0, 1), (1, 1)]);
    expect(
      q.visitAfter((_, x0, y0, x1, y1) {
        results.add((x0, y0, x1, y1));
      }),
      same(q),
    );
    expect(results, const [
      (0.0, 0.0, 1.0, 1.0),
      (1.0, 0.0, 2.0, 1.0),
      (0.0, 1.0, 1.0, 2.0),
      (1.0, 1.0, 2.0, 2.0),
      (0.0, 0.0, 2.0, 2.0),
    ]);
  });

  test('quadtree.visitAfter(callback) visits deeper trees post-order', () {
    final results = <(double, double, double, double)>[];
    final q = quadtree()
      ..setExtent(((0, 0), (960, 960)))
      ..addAll(const [(100, 100), (200, 200), (300, 300)])
      ..visitAfter((_, x0, y0, x1, y1) {
        results.add((x0, y0, x1, y1));
      });
    expect(q.size(), 3);
    expect(results, const [
      (0.0, 0.0, 128.0, 128.0),
      (128.0, 128.0, 256.0, 256.0),
      (0.0, 0.0, 256.0, 256.0),
      (256.0, 256.0, 512.0, 512.0),
      (0.0, 0.0, 512.0, 512.0),
      (0.0, 0.0, 1024.0, 1024.0),
    ]);
  });

  test('quadtree.visitAfter on empty tree does nothing', () {
    var called = 0;
    final q = quadtree()..extent = ((0, 0), (100, 100));
    expect(q.visitAfter((_, _, _, _, _) => ++called), same(q));
    expect(called, 0);
  });

  test('quadtree.removeAll removes multiple points including missing ones', () {
    final q = quadtree(const [(0, 0), (10, 0), (0, 10), (10, 10)]);
    expect(
      q.removeAll(const [(0, 0), (99, 99), (double.nan, 0), (10, 10)]),
      same(q),
    );
    expect(q.size(), 2);
    expect(q.data(), unorderedEquals(const [(10.0, 0.0), (0.0, 10.0)]));
  });

  test('quadtree constructors and extent setter work with lazy iterables', () {
    final q1 = Quadtree.points(_lazyPoints());
    expect(q1.size(), 4);
    final q2 = Quadtree<(double, double)>(
      x: defaultQuadtreeX,
      y: defaultQuadtreeY,
      data: _lazyPoints(),
    );
    expectTreeEquals(q1, q2);

    final q3 = quadtree()
      ..extent = null
      ..extent = ((0, 0), (10, 10));
    expect(q3.extent, ((0.0, 0.0), (16.0, 16.0)));
  });

  test('sealed QuadtreeNode pattern matching and indexer', () {
    final node = QuadtreeInternalNode<int>(nw: leaf(1), se: leaf(4));
    expect(node[0], isA<QuadtreeLeafNode<int>>());
    expect(node[1], isNull);
    expect(node[2], isNull);
    expect(node[3], isA<QuadtreeLeafNode<int>>());
    node[1] = leaf(2);
    node[2] = leaf(3);
    expect((node.ne! as QuadtreeLeafNode<int>).data, 2);
    expect((node.sw! as QuadtreeLeafNode<int>).data, 3);
    expect(() => node[-1], throwsRangeError);
    expect(() => node[4], throwsRangeError);
    expect(() => node[4] = null, throwsRangeError);
  });

  test('re-entrant visit and find calls do not corrupt traversal stacks', () {
    final q = quadtree(const [
      (10, 10),
      (80, 15),
      (20, 75),
      (85, 85),
      (45, 50),
    ]);
    final found = <(double, double)>[];
    q.visit((node, _, _, _, _) {
      if (node is QuadtreeLeafNode<(double, double)>) {
        final (px, py) = node.data;
        final nearest = q.find(px, py);
        if (nearest != null) found.add(nearest);
        var nestedCount = 0;
        q.visit((_, _, _, _, _) {
          ++nestedCount;
          return false;
        });
        expect(nestedCount, greaterThan(0));
      }
      return false;
    });
    expect(found, hasLength(5));
  });

  test('copy deep-copies coincident leaf chains', () {
    final q0 = quadtree()
      ..add((1, 1))
      ..add((1, 1))
      ..add((1, 1));
    final q1 = q0.copy();
    expect(q1.size(), 3);
    q0.remove((1, 1));
    expect(q0.size(), 2);
    expect(q1.size(), 3);
  });
}
