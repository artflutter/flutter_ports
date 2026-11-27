// Ported from d3-hierarchy v3.1.2 test/treemap/slice-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

import 'round.dart';

void main() {
  test('treemapSlice(parent, x0, y0, x1, y1) generates a sliced layout', () {
    final root = HierarchyRectangularNode<int>(
      0,
      value: 24,
      children: [
        for (final v in [6, 6, 4, 3, 2, 2, 1])
          HierarchyRectangularNode<int>(v, value: v.toDouble()),
      ],
    );
    treemapSlice(root, 0, 0, 6, 4);
    expect(root.children!.map(roundRect).toList(), [
      (x0: 0.00, y0: 0.00, x1: 6.00, y1: 1.00),
      (x0: 0.00, y0: 1.00, x1: 6.00, y1: 2.00),
      (x0: 0.00, y0: 2.00, x1: 6.00, y1: 2.67),
      (x0: 0.00, y0: 2.67, x1: 6.00, y1: 3.17),
      (x0: 0.00, y0: 3.17, x1: 6.00, y1: 3.50),
      (x0: 0.00, y0: 3.50, x1: 6.00, y1: 3.83),
      (x0: 0.00, y0: 3.83, x1: 6.00, y1: 4.00),
    ]);
  });

  test(
    'treemapSlice(parent, x0, y0, x1, y1) handles a degenerate empty parent',
    () {
      final root = HierarchyRectangularNode<int>(
        0,
        value: 0,
        children: [
          HierarchyRectangularNode<int>(0, value: 0),
          HierarchyRectangularNode<int>(0, value: 0),
        ],
      );
      treemapSlice(root, 0, 0, 4, 0);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.00, y0: 0.00, x1: 4.00, y1: 0.00),
        (x0: 0.00, y0: 0.00, x1: 4.00, y1: 0.00),
      ]);
    },
  );
}
