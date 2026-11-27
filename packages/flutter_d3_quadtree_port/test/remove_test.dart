// Ported from d3-quadtree v3.0.1 test/remove-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

import 'port/node_matchers.dart';

Quadtree<List<double>> _listTree() =>
    quadtreeBy<List<double>>(x: (d) => d[0], y: (d) => d[1]);

void main() {
  test('quadtree.remove(datum) removes a point and returns the quadtree', () {
    final p0 = <double>[1, 1];
    final q = _listTree().add(p0);
    expectNodeEquals(q.root, leaf(p0));
    expect(q.remove(p0), same(q));
    expect(q.root, isNull);
  });

  test('quadtree.remove(datum) removes the only point in the quadtree', () {
    final p0 = <double>[1, 1];
    final q = _listTree().add(p0);
    expect(q.remove(p0), same(q));
    expect(q.extent, ((1.0, 1.0), (2.0, 2.0)));
    expect(q.root, isNull);
    expect(p0, [1.0, 1.0]);
  });

  test('quadtree.remove(datum) removes a first coincident point at the root '
      'in the quadtree', () {
    final p0 = <double>[1, 1];
    final p1 = <double>[1, 1];
    final q = _listTree().addAll([p0, p1]);
    expect(q.remove(p0), same(q));
    expect(q.extent, ((1.0, 1.0), (2.0, 2.0)));
    expect((q.root! as QuadtreeLeafNode<List<double>>).data, same(p1));
    expect(p0, [1.0, 1.0]);
    expect(p1, [1.0, 1.0]);
  });

  test('quadtree.remove(datum) removes another coincident point at the root '
      'in the quadtree', () {
    final p0 = <double>[1, 1];
    final p1 = <double>[1, 1];
    final q = _listTree().addAll([p0, p1]);
    expect(q.remove(p1), same(q));
    expect(q.extent, ((1.0, 1.0), (2.0, 2.0)));
    expect((q.root! as QuadtreeLeafNode<List<double>>).data, same(p0));
    expect(p0, [1.0, 1.0]);
    expect(p1, [1.0, 1.0]);
  });

  test('quadtree.remove(datum) removes a non-root point in the quadtree', () {
    final p0 = <double>[0, 0];
    final p1 = <double>[1, 1];
    final q = _listTree().addAll([p0, p1]);
    expect(q.remove(p0), same(q));
    expect(q.extent, ((0.0, 0.0), (2.0, 2.0)));
    expect((q.root! as QuadtreeLeafNode<List<double>>).data, same(p1));
    expect(p0, [0.0, 0.0]);
    expect(p1, [1.0, 1.0]);
  });

  test(
    'quadtree.remove(datum) removes another non-root point in the quadtree',
    () {
      final p0 = <double>[0, 0];
      final p1 = <double>[1, 1];
      final q = _listTree().addAll([p0, p1]);
      expect(q.remove(p1), same(q));
      expect(q.extent, ((0.0, 0.0), (2.0, 2.0)));
      expect((q.root! as QuadtreeLeafNode<List<double>>).data, same(p0));
      expect(p0, [0.0, 0.0]);
      expect(p1, [1.0, 1.0]);
    },
  );

  test('quadtree.remove(datum) ignores a point not in the quadtree', () {
    final p0 = <double>[0, 0];
    final p1 = <double>[1, 1];
    final q0 = _listTree().add(p0);
    final q1 = _listTree().add(p1);
    expect(q0.remove(p1), same(q0));
    expect(q0.extent, ((0.0, 0.0), (1.0, 1.0)));
    expect((q0.root! as QuadtreeLeafNode<List<double>>).data, same(p0));
    expect((q1.root! as QuadtreeLeafNode<List<double>>).data, same(p1));
  });

  test(
    'quadtree.remove(datum) ignores a coincident point not in the quadtree',
    () {
      final p0 = <double>[0, 0];
      final p1 = <double>[0, 0];
      final q0 = _listTree().add(p0);
      final q1 = _listTree().add(p1);
      expect(q0.remove(p1), same(q0));
      expect(q0.extent, ((0.0, 0.0), (1.0, 1.0)));
      expect((q0.root! as QuadtreeLeafNode<List<double>>).data, same(p0));
      expect((q1.root! as QuadtreeLeafNode<List<double>>).data, same(p1));
    },
  );

  test('quadtree.remove(datum) removes another point in the quadtree', () {
    final q = quadtree().setExtent(((0, 0), (959, 959)))
      ..addAll(const [
        (630, 438),
        (715, 464),
        (523, 519),
        (646, 318),
        (434, 620),
        (570, 489),
        (520, 345),
        (459, 443),
        (346, 405),
        (529, 444),
      ]);
    expect(q.remove(q.find(546, 440)!), same(q));
    expect(q.extent, ((0.0, 0.0), (1024.0, 1024.0)));
    expectNodeEquals(
      q.root,
      branch(
        nw: branch(
          se: branch(sw: leaf((346, 405)), se: leaf((459, 443))),
        ),
        ne: branch(
          sw: branch(
            nw: leaf((520, 345)),
            ne: leaf((646, 318)),
            sw: branch(ne: leaf((630, 438)), sw: leaf((570, 489))),
            se: leaf((715, 464)),
          ),
        ),
        sw: leaf((434, 620)),
        se: leaf((523, 519)),
      ),
    );
  });
}
