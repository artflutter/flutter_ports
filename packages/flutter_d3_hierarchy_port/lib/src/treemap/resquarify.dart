// Ported from d3-hierarchy v3.1.2 src/treemap/resquarify.js (ISC, Mike Bostock).

/// Port of `src/treemap/resquarify.js` of d3-hierarchy 3.1.2:
/// [TreemapResquarify] and [treemapResquarify].
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/dice.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/slice.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/squarify.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, immutable callable
// TreemapResquarify class with typed `HierarchyRectangularNode.resquarifyCache`
// replacing JS expando `parent._squarify`.

/// Callable stable squarified treemap tiling algorithm configured with
/// [targetRatio].
final class const TreemapResquarify(
  /// Target aspect ratio (`>= 1.0`).
  final double targetRatio,
) {
  /// Creates a resquarified tiling algorithm targeting [targetRatio].
  this;

  /// Tiles [parent]'s children into `[x0, y0] .. [x1, y1]`, reusing cached
  /// row partitions when [parent] was previously tiled with the same
  /// [targetRatio].
  void call<T>(
    HierarchyRectangularNode<T> parent,
    double x0,
    double y0,
    double x1,
    double y1,
  ) {
    final cache = parent.resquarifyCache;
    if (cache != null && cache.ratio == targetRatio) {
      final rows = cache.rows;
      var value = parent.value ?? 0.0;
      var rx0 = x0;
      var ry0 = y0;
      for (var j = 0, m = rows.length; j < m; ++j) {
        final row = rows[j];
        final nodes = row.children;
        var rowValue = 0.0;
        for (var i = 0, n = nodes.length; i < n; ++i) {
          rowValue += nodes[i].value ?? 0.0;
        }
        row.value = rowValue;
        if (row.dice) {
          final startY = ry0;
          final endY = value != 0 ? (ry0 += (y1 - ry0) * rowValue / value) : y1;
          treemapDiceRange<T>(
            nodes,
            0,
            nodes.length,
            rowValue,
            rx0,
            startY,
            x1,
            endY,
          );
        } else {
          final startX = rx0;
          final endX = value != 0 ? (rx0 += (x1 - rx0) * rowValue / value) : x1;
          treemapSliceRange<T>(
            nodes,
            0,
            nodes.length,
            rowValue,
            startX,
            ry0,
            endX,
            y1,
          );
        }
        value -= rowValue;
      }
    } else {
      final rows = squarifyRatio<T>(targetRatio, parent, x0, y0, x1, y1);
      parent.resquarifyCache = TreemapResquarifyCache<T>(
        ratio: targetRatio,
        rows: rows,
      );
    }
  }

  /// Returns a new [TreemapResquarify] targeting `max(1.0, x)`.
  TreemapResquarify ratio(double x) => TreemapResquarify(x > 1 ? x : 1.0);
}

/// Default stable squarified treemap tiling algorithm targeting [treemapPhi].
const TreemapResquarify treemapResquarify = TreemapResquarify(treemapPhi);
