// Ported from d3-hierarchy v3.1.2 src/partition.js (ISC, Mike Bostock).

/// Port of `src/partition.js` of d3-hierarchy 3.1.2: [PartitionLayout] and
/// [partition].
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/dice.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/round.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, typed PartitionLayout<T>
// returning HierarchyRectangularNode<T> with immutable `(double, double)` size.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct closure-free
// pre-order layout walk with inline dicing.

void _positionPartition<T>(
  HierarchyRectangularNode<T> node,
  double dy,
  int n,
  double pad,
  bool doRound,
) {
  final children = node.children;
  if (children != null) {
    final cy0 = dy * (node.depth + 1) / n;
    final cy1 = dy * (node.depth + 2) / n;
    final parentValue = node.value ?? 0.0;
    final k = parentValue != 0 ? (node.x1 - node.x0) / parentValue : 0.0;
    var cx = node.x0;
    for (var i = 0, len = children.length; i < len; ++i) {
      final child = children[i]
        ..y0 = cy0
        ..y1 = cy1
        ..x0 = cx;
      cx += (child.value ?? 0.0) * k;
      child.x1 = cx;
    }
  }
  var x0 = node.x0;
  var y0 = node.y0;
  var x1 = node.x1 - pad;
  var y1 = node.y1 - pad;
  if (x1 < x0) x0 = x1 = (x0 + x1) * 0.5;
  if (y1 < y0) y0 = y1 = (y0 + y1) * 0.5;
  node
    ..x0 = x0
    ..y0 = y0
    ..x1 = x1
    ..y1 = y1;
  if (doRound) treemapRoundNode(node);
  if (children != null) {
    for (var i = 0, len = children.length; i < len; ++i) {
      _positionPartition<T>(children[i], dy, n, pad, doRound);
    }
  }
}

/// Produces adjacency diagrams (icicle or sunburst layouts).
final class PartitionLayout<T>({
  /// Overall layout size `(width, height)`.
  var (double, double) size = const (1.0, 1.0),

  /// Whether computed node coordinates are rounded to integer values.
  var bool round = false,

  /// Padding separating adjacent nodes.
  var double padding = 0.0,
}) {
  /// Creates a [PartitionLayout].
  this;

  /// Lays out [root] and returns a [HierarchyRectangularNode<T>].
  HierarchyRectangularNode<T> call(HierarchyNode<T> root) {
    final rectRoot = hierarchyToRectangular<T>(root);
    final n = rectRoot.height + 1;
    final dx = size.$1;
    final dy = size.$2;
    final pad = padding;
    rectRoot
      ..x0 = pad
      ..y0 = pad
      ..x1 = dx
      ..y1 = dy / n;
    if (rectRoot.height <= 512) {
      _positionPartition<T>(rectRoot, dy, n, pad, round);
      return rectRoot;
    }
    rectRoot.eachBefore((node) {
      if (node.children != null) {
        treemapDice(
          node,
          node.x0,
          dy * (node.depth + 1) / n,
          node.x1,
          dy * (node.depth + 2) / n,
        );
      }
      var x0 = node.x0;
      var y0 = node.y0;
      var x1 = node.x1 - pad;
      var y1 = node.y1 - pad;
      if (x1 < x0) x0 = x1 = (x0 + x1) * 0.5;
      if (y1 < y0) y0 = y1 = (y0 + y1) * 0.5;
      node
        ..x0 = x0
        ..y0 = y0
        ..x1 = x1
        ..y1 = y1;
    });
    if (round) rectRoot.eachBefore(treemapRoundNode);
    return rectRoot;
  }
}

/// Creates a new [PartitionLayout<T>] generator.
PartitionLayout<T> partition<T>({
  (double, double) size = const (1.0, 1.0),
  bool round = false,
  double padding = 0.0,
}) => PartitionLayout<T>(size: size, round: round, padding: padding);
