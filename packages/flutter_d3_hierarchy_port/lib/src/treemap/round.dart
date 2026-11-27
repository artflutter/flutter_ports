// Ported from d3-hierarchy v3.1.2 src/treemap/round.js (ISC, Mike Bostock).

/// Port of `src/treemap/round.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

/// Rounds a double following JS `Math.round` semantics (ties toward +Infinity).
@pragma('vm:prefer-inline')
double _jsRound(double x) {
  if (!x.isFinite) return x;
  if (x >= 0) return x.roundToDouble();
  final f = x.floorToDouble();
  return x - f >= 0.5 ? x.ceilToDouble() : f;
}

/// Rounds the rectangular bounds `x0, y0, x1, y1` of [node] to integer doubles.
void treemapRoundNode<T>(HierarchyRectangularNode<T> node) {
  node
    ..x0 = _jsRound(node.x0)
    ..y0 = _jsRound(node.y0)
    ..x1 = _jsRound(node.x1)
    ..y1 = _jsRound(node.y1);
}
