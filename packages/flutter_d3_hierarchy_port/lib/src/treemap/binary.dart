// Ported from d3-hierarchy v3.1.2 src/treemap/binary.js (ISC, Mike Bostock).

/// Port of `src/treemap/binary.js` of d3-hierarchy 3.1.2: [treemapBinary].
library;

import 'dart:typed_data';

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, unboxed `Float64List`
// prefix sums and top-level non-capturing recursive partition helper.

void _binaryPartition<T>(
  List<HierarchyRectangularNode<T>> nodes,
  Float64List sums,
  int i,
  int j,
  double value,
  double rx0,
  double ry0,
  double rx1,
  double ry1,
) {
  if (i >= j - 1) {
    nodes[i]
      ..x0 = rx0
      ..y0 = ry0
      ..x1 = rx1
      ..y1 = ry1;
    return;
  }

  final valueOffset = sums[i];
  final valueTarget = (value * 0.5) + valueOffset;
  var k = i + 1;
  var hi = j - 1;

  while (k < hi) {
    final mid = (k + hi) >>> 1;
    if (sums[mid] < valueTarget) {
      k = mid + 1;
    } else {
      hi = mid;
    }
  }

  if ((valueTarget - sums[k - 1]) < (sums[k] - valueTarget) && i + 1 < k) {
    --k;
  }

  final valueLeft = sums[k] - valueOffset;
  final valueRight = value - valueLeft;

  if ((rx1 - rx0) > (ry1 - ry0)) {
    final xk = value != 0 ? (rx0 * valueRight + rx1 * valueLeft) / value : rx1;
    _binaryPartition<T>(nodes, sums, i, k, valueLeft, rx0, ry0, xk, ry1);
    _binaryPartition<T>(nodes, sums, k, j, valueRight, xk, ry0, rx1, ry1);
  } else {
    final yk = value != 0 ? (ry0 * valueRight + ry1 * valueLeft) / value : ry1;
    _binaryPartition<T>(nodes, sums, i, k, valueLeft, rx0, ry0, rx1, yk);
    _binaryPartition<T>(nodes, sums, k, j, valueRight, rx0, yk, rx1, ry1);
  }
}

/// Recursively partitions the children of [parent] into an approximately
/// balanced binary tree, choosing horizontal partitioning for wide rectangles
/// and vertical partitioning for tall rectangles.
void treemapBinary<T>(
  HierarchyRectangularNode<T> parent,
  double x0,
  double y0,
  double x1,
  double y1,
) {
  final nodes = parent.children;
  if (nodes == null || nodes.isEmpty) return;
  final n = nodes.length;
  final sums = Float64List(n + 1);
  var sum = 0.0;
  for (var i = 0; i < n; ++i) {
    sum += nodes[i].value ?? 0.0;
    sums[i + 1] = sum;
  }
  _binaryPartition<T>(nodes, sums, 0, n, parent.value ?? 0.0, x0, y0, x1, y1);
}
