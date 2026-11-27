// Original code, not ported from d3-quadtree: Node.js reference parity tests.

import 'package:flutter_d3_quadtree_port/d3_quadtree.dart';
import 'package:test/test.dart';

import 'd3_quadtree_reference.dart';

void main() {
  test(
    'extent, size, data, visit, and visitAfter match Node.js d3-quadtree',
    () {
      final tree = quadtree(refPoints);
      expect(tree.extent, refExtent);
      expect(tree.size(), refSize);
      expect(tree.data(), refData);

      final pre = <(double, double, double, double, bool)>[];
      tree.visit((node, x0, y0, x1, y1) {
        pre.add((
          x0,
          y0,
          x1,
          y1,
          node is QuadtreeInternalNode<(double, double)>,
        ));
        return false;
      });
      expect(pre, refPreVisit);

      final post = <(double, double, double, double, bool)>[];
      tree.visitAfter((node, x0, y0, x1, y1) {
        post.add((
          x0,
          y0,
          x1,
          y1,
          node is QuadtreeInternalNode<(double, double)>,
        ));
      });
      expect(post, refPostVisit);
    },
  );

  test('pruned rectangular range query matches Node.js d3-quadtree', () {
    final tree = quadtree(refPoints);
    final (rx0, ry0, rx1, ry1) = refRangeBox;
    final visited = <(double, double, double, double)>[];
    final hits = <(double, double)>[];

    tree.visit((node, x0, y0, x1, y1) {
      visited.add((x0, y0, x1, y1));
      if (node is QuadtreeLeafNode<(double, double)>) {
        QuadtreeLeafNode<(double, double)>? leaf = node;
        while (leaf != null) {
          final (px, py) = leaf.data;
          if (px >= rx0 && px < rx1 && py >= ry0 && py < ry1) {
            hits.add(leaf.data);
          }
          leaf = leaf.next;
        }
      }
      return x0 >= rx1 || y0 >= ry1 || x1 < rx0 || y1 < ry0;
    });

    expect(visited, refRangeVisited);
    expect(hits, refRangeHits);
  });

  test('nearest-neighbor find (unbounded and bounded) matches Node.js', () {
    final tree = quadtree(refPoints);
    for (var i = 0; i < refQueries.length; ++i) {
      final (qx, qy, r) = refQueries[i];
      expect(tree.find(qx, qy), refFindUnbounded[i], reason: 'unbounded #$i');
      expect(tree.find(qx, qy, r), refFindBounded[i], reason: 'bounded #$i');
    }
  });

  test('copy and remove sequence matches Node.js d3-quadtree', () {
    final tree = quadtree(refPoints);
    final copy = tree.copy();
    for (var i = 0; i < refPoints.length; i += 3) {
      copy.remove(refPoints[i]);
    }
    expect(tree.size(), refSize);
    expect(copy.size(), refAfterRemoveSize);
    expect(copy.data(), refAfterRemoveData);
    for (var i = 0; i < refAfterRemoveFind.length; ++i) {
      final (qx, qy, _) = refQueries[i];
      expect(
        copy.find(qx, qy),
        refAfterRemoveFind[i],
        reason: 'afterRemove #$i',
      );
    }
  });

  test('incremental add extent sequence matches Node.js d3-quadtree', () {
    final inc = quadtree();
    const pts = <(double, double)>[
      (10.25, -5.75),
      (25.5, 40.0),
      (-100.0, 12.0),
      (500.0, -300.0),
      (10.25, -5.75),
    ];
    for (var i = 0; i < pts.length; ++i) {
      inc.add(pts[i]);
      expect(inc.extent, refIncExtents[i], reason: 'step $i');
    }
  });
}
