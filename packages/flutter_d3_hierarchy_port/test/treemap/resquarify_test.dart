// Ported from d3-hierarchy v3.1.2 test/treemap/resquarify-test.js (ISC, Mike Bostock).

import 'dart:math' as math;

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

import 'round.dart';

final class const _Node({
  final double? value,
  @override final List<_Node>? children,
}) implements HierarchyDatum<_Node>;

void main() {
  test(
    'treemapResquarify(parent, x0, y0, x1, y1) produces a stable update',
    () {
      const tile = treemapResquarify;
      final root = HierarchyRectangularNode<int>(
        0,
        value: 20,
        children: [
          HierarchyRectangularNode<int>(10, value: 10),
          HierarchyRectangularNode<int>(10, value: 10),
        ],
      );
      tile(root, 0, 0, 20, 10);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.0, y0: 0.0, x1: 10.0, y1: 10.0),
        (x0: 10.0, y0: 0.0, x1: 20.0, y1: 10.0),
      ]);
      tile(root, 0, 0, 10, 20);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.0, y0: 0.0, x1: 5.0, y1: 20.0),
        (x0: 5.0, y0: 0.0, x1: 10.0, y1: 20.0),
      ]);
    },
  );

  test('treemapResquarify.ratio(ratio) observes the specified ratio', () {
    final tile = treemapResquarify.ratio(1);
    final root = HierarchyRectangularNode<int>(
      0,
      value: 24,
      children: [
        for (final v in [6, 6, 4, 3, 2, 2, 1])
          HierarchyRectangularNode<int>(v, value: v.toDouble()),
      ],
    );
    tile(root, 0, 0, 6, 4);
    expect(root.children!.map(roundRect).toList(), [
      (x0: 0.00, y0: 0.00, x1: 3.00, y1: 2.00),
      (x0: 0.00, y0: 2.00, x1: 3.00, y1: 4.00),
      (x0: 3.00, y0: 0.00, x1: 4.71, y1: 2.33),
      (x0: 4.71, y0: 0.00, x1: 6.00, y1: 2.33),
      (x0: 3.00, y0: 2.33, x1: 4.20, y1: 4.00),
      (x0: 4.20, y0: 2.33, x1: 5.40, y1: 4.00),
      (x0: 5.40, y0: 2.33, x1: 6.00, y1: 4.00),
    ]);
  });

  test(
    'treemapResquarify.ratio(ratio) is stable if the ratio is unchanged',
    () {
      final root = HierarchyRectangularNode<int>(
        0,
        value: 20,
        children: [
          HierarchyRectangularNode<int>(10, value: 10),
          HierarchyRectangularNode<int>(10, value: 10),
        ],
      );
      treemapResquarify(root, 0, 0, 20, 10);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.0, y0: 0.0, x1: 10.0, y1: 10.0),
        (x0: 10.0, y0: 0.0, x1: 20.0, y1: 10.0),
      ]);
      treemapResquarify.ratio((1 + math.sqrt(5)) / 2)(root, 0, 0, 10, 20);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.0, y0: 0.0, x1: 5.0, y1: 20.0),
        (x0: 5.0, y0: 0.0, x1: 10.0, y1: 20.0),
      ]);
    },
  );

  test(
    'treemapResquarify.ratio(ratio) is unstable if the ratio is changed',
    () {
      final root = HierarchyRectangularNode<int>(
        0,
        value: 20,
        children: [
          HierarchyRectangularNode<int>(10, value: 10),
          HierarchyRectangularNode<int>(10, value: 10),
        ],
      );
      treemapResquarify(root, 0, 0, 20, 10);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.0, y0: 0.0, x1: 10.0, y1: 10.0),
        (x0: 10.0, y0: 0.0, x1: 20.0, y1: 10.0),
      ]);
      treemapResquarify.ratio(1)(root, 0, 0, 10, 20);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.0, y0: 0.0, x1: 10.0, y1: 10.0),
        (x0: 0.0, y0: 10.0, x1: 10.0, y1: 20.0),
      ]);
    },
  );

  test('treemapResquarify does not break on 0-sized inputs', () {
    final root = hierarchy(
      const _Node(
        children: [
          _Node(children: [_Node(value: 0)]),
          _Node(value: 1),
        ],
      ),
    );
    final treemapper = treemap<_Node>(tile: treemapResquarify.call);
    final laid = treemapper(root.sum((d) => d.value));
    treemapper(laid.sum((_) => null));
    final a = laid.leaves().map((d) => [d.x0, d.x1, d.y0, d.y1]).toList();
    expect(a, [
      [0.0, 1.0, 0.0, 0.0],
      [0.0, 1.0, 0.0, 0.0],
    ]);
  });
}
