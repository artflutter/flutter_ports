// Ported from d3-hierarchy v3.1.2 src/treemap/dice.js (ISC, Mike Bostock).

/// Port of `src/treemap/dice.js` of d3-hierarchy 3.1.2: [treemapDice].
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

/// Divides the rectangular area `[x0, y0] .. [x1, y1]` horizontally among the
/// children of [parent] proportionally to each child's `value`.
void treemapDice<T>(
  HierarchyRectangularNode<T> parent,
  double x0,
  double y0,
  double x1,
  double y1,
) {
  final nodes = parent.children;
  if (nodes == null) return;
  final parentValue = parent.value ?? 0.0;
  final k = parentValue != 0 ? (x1 - x0) / parentValue : 0.0;
  var x = x0;
  for (var i = 0, n = nodes.length; i < n; ++i) {
    final node = nodes[i]
      ..y0 = y0
      ..y1 = y1
      ..x0 = x;
    x += (node.value ?? 0.0) * k;
    node.x1 = x;
  }
}

/// Dices a subrange `[start, end)` of [nodes] with total [sumValue].
void treemapDiceRange<T>(
  List<HierarchyRectangularNode<T>> nodes,
  int start,
  int end,
  double sumValue,
  double x0,
  double y0,
  double x1,
  double y1,
) {
  final k = sumValue != 0 ? (x1 - x0) / sumValue : 0.0;
  var x = x0;
  for (var i = start; i < end; ++i) {
    final node = nodes[i]
      ..y0 = y0
      ..y1 = y1
      ..x0 = x;
    x += (node.value ?? 0.0) * k;
    node.x1 = x;
  }
}
