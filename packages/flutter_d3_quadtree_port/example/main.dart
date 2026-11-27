// Original code, not ported from d3-quadtree: package example.

// Example prints computed summaries.
// ignore_for_file: avoid_print

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';

typedef _City = ({String name, double x, double y});

void main() {
  // 1. Default (double, double) point quadtree.
  final tree = quadtree(const <(double, double)>[
    (10, 20),
    (45, 80),
    (72, 35),
    (90, 95),
    (25, 60),
  ]);
  print('Extent:  ${tree.extent}');
  print('Size:    ${tree.size()}');
  print('Nearest to (40, 75): ${tree.find(40, 75)}');
  print('Within radius 15 of (40, 75): ${tree.find(40, 75, 15)}');

  // 2. Rectangular range query using visit with quadrant pruning.
  final inBox = <(double, double)>[];
  tree.visit((node, x0, y0, x1, y1) {
    if (node is QuadtreeLeafNode<(double, double)>) {
      QuadtreeLeafNode<(double, double)>? leaf = node;
      while (leaf != null) {
        final (px, py) = leaf.data;
        if (px >= 20 && px <= 80 && py >= 20 && py <= 85) {
          inBox.add(leaf.data);
        }
        leaf = leaf.next;
      }
    }
    return x0 > 80 || y0 > 85 || x1 < 20 || y1 < 20;
  });
  print('In [20..80, 20..85]: $inBox');

  // 3. Strongly typed custom datum with quadtreeBy.
  final cities = quadtreeBy<_City>(
    x: (c) => c.x,
    y: (c) => c.y,
    data: const <_City>[
      (name: 'Alpha', x: 12, y: 18),
      (name: 'Beta', x: 64, y: 42),
      (name: 'Gamma', x: 88, y: 76),
    ],
  );
  print('Closest city to (60, 40): ${cities.find(60, 40)?.name}');
}
