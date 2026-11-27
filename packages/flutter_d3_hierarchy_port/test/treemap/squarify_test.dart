// Ported from d3-hierarchy v3.1.2 test/treemap/squarify-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

import 'round.dart';

void main() {
  test(
    'treemapSquarify(parent, x0, y0, x1, y1) generates a squarified layout',
    () {
      const tile = treemapSquarify;
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
        (x0: 3.00, y0: 2.33, x1: 5.40, y1: 3.17),
        (x0: 3.00, y0: 3.17, x1: 5.40, y1: 4.00),
        (x0: 5.40, y0: 2.33, x1: 6.00, y1: 4.00),
      ]);
    },
  );

  test(
    'treemapSquarify(parent, x0, y0, x1, y1) does not produce a stable update',
    () {
      const tile = treemapSquarify;
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
        (x0: 0.0, y0: 0.0, x1: 10.0, y1: 10.0),
        (x0: 0.0, y0: 10.0, x1: 10.0, y1: 20.0),
      ]);
    },
  );

  test('treemapSquarify.ratio(ratio) observes the specified ratio', () {
    final tile = treemapSquarify.ratio(1);
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
    'treemapSquarify(parent, x0, y0, x1, y1) handles a degenerate tall empty '
    'parent',
    () {
      final root = HierarchyRectangularNode<int>(
        0,
        value: 0,
        children: [
          HierarchyRectangularNode<int>(0, value: 0),
          HierarchyRectangularNode<int>(0, value: 0),
        ],
      );
      treemapSquarify(root, 0, 0, 0, 4);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.00, y0: 0.00, x1: 0.00, y1: 4.00),
        (x0: 0.00, y0: 0.00, x1: 0.00, y1: 4.00),
      ]);
    },
  );

  test(
    'treemapSquarify(parent, x0, y0, x1, y1) handles a degenerate wide empty '
    'parent',
    () {
      final root = HierarchyRectangularNode<int>(
        0,
        value: 0,
        children: [
          HierarchyRectangularNode<int>(0, value: 0),
          HierarchyRectangularNode<int>(0, value: 0),
        ],
      );
      treemapSquarify(root, 0, 0, 4, 0);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.00, y0: 0.00, x1: 4.00, y1: 0.00),
        (x0: 0.00, y0: 0.00, x1: 4.00, y1: 0.00),
      ]);
    },
  );

  test(
    'treemapSquarify(parent, x0, y0, x1, y1) handles a leading zero value',
    () {
      final root = HierarchyRectangularNode<int>(
        0,
        value: 24,
        children: [
          for (final v in [0, 6, 6, 4, 3, 2, 2, 1])
            HierarchyRectangularNode<int>(v, value: v.toDouble()),
        ],
      );
      treemapSquarify(root, 0, 0, 6, 4);
      expect(root.children!.map(roundRect).toList(), [
        (x0: 0.00, y0: 0.00, x1: 3.00, y1: 0.00),
        (x0: 0.00, y0: 0.00, x1: 3.00, y1: 2.00),
        (x0: 0.00, y0: 2.00, x1: 3.00, y1: 4.00),
        (x0: 3.00, y0: 0.00, x1: 4.71, y1: 2.33),
        (x0: 4.71, y0: 0.00, x1: 6.00, y1: 2.33),
        (x0: 3.00, y0: 2.33, x1: 5.40, y1: 3.17),
        (x0: 3.00, y0: 3.17, x1: 5.40, y1: 4.00),
        (x0: 5.40, y0: 2.33, x1: 6.00, y1: 4.00),
      ]);
    },
  );
}
