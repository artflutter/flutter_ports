// Ported from d3-hierarchy v3.1.2 src/hierarchy/descendants.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/descendants.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, returns the flat FIFO
// BFS queue directly using bulk `addAll` without intermediate `sync*` iterator.

/// Cast-free descendants list on base [HierarchyNode<T>].
List<HierarchyNode<T>> hierarchyDescendantsBase<T>(HierarchyNode<T> root) {
  final queue = <HierarchyNode<T>>[root];
  var head = 0;
  while (head < queue.length) {
    final children = queue[head++].children;
    if (children != null) {
      queue.addAll(children);
    }
  }
  return queue;
}

/// Returns the list of descendant nodes of [root] in breadth-first order,
/// starting with [root].
List<N> hierarchyDescendants<T, N extends HierarchyNode<T>>(N root) {
  final queue = <N>[root];
  var head = 0;
  while (head < queue.length) {
    final children = queue[head++].children;
    if (children != null) {
      queue.addAll(children as List<N>);
    }
  }
  return queue;
}
