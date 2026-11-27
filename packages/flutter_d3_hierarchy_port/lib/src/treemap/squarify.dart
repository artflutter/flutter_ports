// Ported from d3-hierarchy v3.1.2 src/treemap/squarify.js (ISC, Mike Bostock).

/// Port of `src/treemap/squarify.js` of d3-hierarchy 3.1.2: [treemapPhi],
/// [squarifyRatio], [TreemapSquarify], and [treemapSquarify].
library;

import 'dart:math' as math;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/dice.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/slice.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, immutable callable
// TreemapSquarify class with generic `call<T>` and `.ratio(double)` replacing
// JS function-with-property closure.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, slice-free zero-alloc
// `squarifyLayout` fast path for `TreemapSquarify.call` avoiding per-row
// `sublist` and `TreemapSquarifyRow` allocations when row caching is unused.

/// The golden ratio `(1 + sqrt(5)) / 2`, the default target aspect ratio for
/// [treemapSquarify] and `treemapResquarify`.
const double treemapPhi = 1.618033988749895;

/// Allocation-free squarify layout operating directly on index slices
/// `[i0, i1)` of `parent.children`.
void squarifyLayout<T>(
  double ratio,
  HierarchyRectangularNode<T> parent,
  double x0,
  double y0,
  double x1,
  double y1,
) {
  final nodes = parent.children;
  if (nodes == null) return;
  final n = nodes.length;
  var i0 = 0;
  var i1 = 0;
  var value = parent.value ?? 0.0;
  var rx0 = x0;
  var ry0 = y0;

  while (i0 < n) {
    final dx = x1 - rx0;
    final dy = y1 - ry0;

    // Find the next non-empty node.
    double sumValue;
    do {
      sumValue = nodes[i1++].value ?? 0.0;
    } while (sumValue == 0 && i1 < n);
    var minValue = sumValue;
    var maxValue = sumValue;
    final alpha = math.max(dy / dx, dx / dy) / (value * ratio);
    var beta = sumValue * sumValue * alpha;
    var minRatio = math.max(maxValue / beta, beta / minValue);

    // Keep adding nodes while the aspect ratio maintains or improves.
    for (; i1 < n; ++i1) {
      final nodeValue = nodes[i1].value ?? 0.0;
      sumValue += nodeValue;
      if (nodeValue < minValue) minValue = nodeValue;
      if (nodeValue > maxValue) maxValue = nodeValue;
      beta = sumValue * sumValue * alpha;
      final newRatio = math.max(maxValue / beta, beta / minValue);
      if (newRatio > minRatio) {
        sumValue -= nodeValue;
        break;
      }
      minRatio = newRatio;
    }

    if (dx < dy) {
      final startY = ry0;
      final ny = value != 0 ? (ry0 += dy * sumValue / value) : y1;
      treemapDiceRange<T>(nodes, i0, i1, sumValue, rx0, startY, x1, ny);
    } else {
      final startX = rx0;
      final nx = value != 0 ? (rx0 += dx * sumValue / value) : x1;
      treemapSliceRange<T>(nodes, i0, i1, sumValue, startX, ry0, nx, y1);
    }
    value -= sumValue;
    i0 = i1;
  }
}

/// Squarifies the children of [parent] into `[x0, y0] .. [x1, y1]` with target
/// aspect [ratio] and returns the computed rows (used by `treemapResquarify`).
List<TreemapSquarifyRow<T>> squarifyRatio<T>(
  double ratio,
  HierarchyRectangularNode<T> parent,
  double x0,
  double y0,
  double x1,
  double y1,
) {
  final rows = <TreemapSquarifyRow<T>>[];
  final nodes = parent.children;
  if (nodes == null) return rows;
  final n = nodes.length;
  var i0 = 0;
  var i1 = 0;
  var value = parent.value ?? 0.0;
  var rx0 = x0;
  var ry0 = y0;

  while (i0 < n) {
    final dx = x1 - rx0;
    final dy = y1 - ry0;

    // Find the next non-empty node.
    double sumValue;
    do {
      sumValue = nodes[i1++].value ?? 0.0;
    } while (sumValue == 0 && i1 < n);
    var minValue = sumValue;
    var maxValue = sumValue;
    final alpha = math.max(dy / dx, dx / dy) / (value * ratio);
    var beta = sumValue * sumValue * alpha;
    var minRatio = math.max(maxValue / beta, beta / minValue);

    // Keep adding nodes while the aspect ratio maintains or improves.
    for (; i1 < n; ++i1) {
      final nodeValue = nodes[i1].value ?? 0.0;
      sumValue += nodeValue;
      if (nodeValue < minValue) minValue = nodeValue;
      if (nodeValue > maxValue) maxValue = nodeValue;
      beta = sumValue * sumValue * alpha;
      final newRatio = math.max(maxValue / beta, beta / minValue);
      if (newRatio > minRatio) {
        sumValue -= nodeValue;
        break;
      }
      minRatio = newRatio;
    }

    // Position and record the row orientation.
    final dice = dx < dy;
    final rowChildren = nodes.sublist(i0, i1);
    final row = TreemapSquarifyRow<T>(
      value: sumValue,
      dice: dice,
      children: rowChildren,
    );
    rows.add(row);
    if (dice) {
      final startY = ry0;
      final ny = value != 0 ? (ry0 += dy * sumValue / value) : y1;
      treemapDiceRange<T>(
        rowChildren,
        0,
        rowChildren.length,
        sumValue,
        rx0,
        startY,
        x1,
        ny,
      );
    } else {
      final startX = rx0;
      final nx = value != 0 ? (rx0 += dx * sumValue / value) : x1;
      treemapSliceRange<T>(
        rowChildren,
        0,
        rowChildren.length,
        sumValue,
        startX,
        ry0,
        nx,
        y1,
      );
    }
    value -= sumValue;
    i0 = i1;
  }

  return rows;
}

/// Callable squarified treemap tiling algorithm configured with [targetRatio].
final class const TreemapSquarify(
  /// Target aspect ratio (`>= 1.0`).
  final double targetRatio,
) {
  /// Creates a squarified tiling algorithm targeting [targetRatio].
  this;

  /// Tiles [parent]'s children into `[x0, y0] .. [x1, y1]`.
  void call<T>(
    HierarchyRectangularNode<T> parent,
    double x0,
    double y0,
    double x1,
    double y1,
  ) {
    squarifyLayout<T>(targetRatio, parent, x0, y0, x1, y1);
  }

  /// Returns a new [TreemapSquarify] targeting `max(1.0, x)`.
  TreemapSquarify ratio(double x) => TreemapSquarify(x > 1 ? x : 1.0);
}

/// Default squarified treemap tiling algorithm targeting the golden ratio
/// [treemapPhi].
const TreemapSquarify treemapSquarify = TreemapSquarify(treemapPhi);
