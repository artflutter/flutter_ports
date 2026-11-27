// Ported from d3-hierarchy v3.1.2 src/hierarchy/path.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/path.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/ancestors.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

/// Returns the shortest path through the hierarchy from [start] to [end].
List<N> hierarchyPath<T, N extends HierarchyNode<T>>(N start, N end) {
  var s = start;
  var e = end;
  final ancestor = _leastCommonAncestor<T, N>(s, e);
  final nodes = <N>[s];
  while (!identical(s, ancestor)) {
    s = s.parent! as N;
    nodes.add(s);
  }
  final k = nodes.length;
  while (!identical(e, ancestor)) {
    nodes.insert(k, e);
    e = e.parent! as N;
  }
  return nodes;
}

N? _leastCommonAncestor<T, N extends HierarchyNode<T>>(N a, N b) {
  if (identical(a, b)) return a;
  final aNodes = hierarchyAncestors<T, N>(a);
  final bNodes = hierarchyAncestors<T, N>(b);
  N? c;
  var curA = aNodes.isNotEmpty ? aNodes.removeLast() : null;
  var curB = bNodes.isNotEmpty ? bNodes.removeLast() : null;
  while (curA != null && identical(curA, curB)) {
    c = curA;
    curA = aNodes.isNotEmpty ? aNodes.removeLast() : null;
    curB = bNodes.isNotEmpty ? bNodes.removeLast() : null;
  }
  return c;
}
