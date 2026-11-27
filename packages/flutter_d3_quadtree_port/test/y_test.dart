// Ported from d3-quadtree v3.0.1 test/y-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

import 'port/node_matchers.dart';

typedef _YDatum = ({double x, double y});

double _getY(_YDatum d) => d.y;

void main() {
  test('quadtree.y(y) sets the y-accessor used by quadtree.add', () {
    final q = quadtreeBy<_YDatum>(x: (d) => d.x, y: (_) => double.nan)
      ..y = _getY
      ..add((x: 1, y: 2));
    expect(q.y, same(_getY));
    expect(q.extent, ((1.0, 2.0), (2.0, 3.0)));
    expectNodeEquals(q.root, leaf((x: 1, y: 2)));
  });

  test('quadtree.y(y) sets the y-accessor used by quadtree.addAll', () {
    final q = quadtreeBy<_YDatum>(x: (d) => d.x, y: (_) => double.nan)
      ..y = _getY
      ..addAll(const [(x: 1, y: 2)]);
    expect(q.extent, ((1.0, 2.0), (2.0, 3.0)));
    expectNodeEquals(q.root, leaf((x: 1, y: 2)));
  });

  test('quadtree.y(y) sets the y-accessor used by quadtree.remove', () {
    const p0 = (x: 0.0, y: 1.0);
    const p1 = (x: 1.0, y: 2.0);
    final q = quadtreeBy<_YDatum>(x: (d) => d.x, y: (_) => double.nan)
      ..y = _getY;
    expectNodeEquals(q.add(p0).root, leaf(p0));
    expectNodeEquals(q.add(p1).root, branch(nw: leaf(p0), se: leaf(p1)));
    expectNodeEquals(q.remove(p1).root, leaf(p0));
    expect(q.remove(p0).root, isNull);
  });
}
