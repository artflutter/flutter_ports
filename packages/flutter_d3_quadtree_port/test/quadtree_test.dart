// Ported from d3-quadtree v3.0.1 test/quadtree-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

import 'port/node_matchers.dart';

typedef _Point = ({double x, double y});

void main() {
  test('quadtree() creates an empty quadtree', () {
    final q = quadtree();
    expect(q, isA<Quadtree<(double, double)>>());
    expect(
      q.visit((_, _, _, _, _) => throw StateError('should not visit')),
      same(q),
    );
    expect(q.size(), 0);
    expect(q.extent, isNull);
    expect(q.root, isNull);
    expect(q.data(), isEmpty);
  });

  test('quadtree(nodes) is equivalent to quadtree().addAll(nodes)', () {
    final q = quadtree(const <(double, double)>[(0, 0), (1, 1)]);
    expect(q, isA<Quadtree<(double, double)>>());
    expectNodeEquals(q.root, branch(nw: leaf((0, 0)), se: leaf((1, 1))));
  });

  test(
    'quadtree(nodes, x, y) is equivalent to quadtree().x(x).y(y).addAll(nodes)',
    () {
      final q = quadtreeBy<_Point>(
        data: const <_Point>[(x: 0, y: 0), (x: 1, y: 1)],
        x: (d) => d.x,
        y: (d) => d.y,
      );
      expect(q, isA<Quadtree<_Point>>());
      expectNodeEquals(
        q.root,
        branch(nw: leaf((x: 0, y: 0)), se: leaf((x: 1, y: 1))),
      );
    },
  );
}
