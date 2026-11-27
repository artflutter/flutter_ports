// Ported from d3-hierarchy v3.1.2 src/hierarchy/ancestors.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/ancestors.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

/// Returns the list of ancestor nodes, starting with [start], then followed by
/// each parent up to the root.
List<N> hierarchyAncestors<T, N extends HierarchyNode<T>>(N start) {
  final nodes = <N>[start];
  HierarchyNode<T>? node = start;
  while (true) {
    final parent = node!.parent;
    if (parent == null) break;
    nodes.add(parent as N);
    node = parent;
  }
  return nodes;
}
