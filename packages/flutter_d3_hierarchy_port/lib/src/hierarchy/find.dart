// Ported from d3-hierarchy v3.1.2 src/hierarchy/find.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/find.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, split 1-arg and 3-arg
// indexed find predicates without JS `this` binding.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct flat FIFO BFS
// search without `sync*` generator overhead.

/// Returns the first node in breadth-first order for which [filter] returns
/// `true`, or `null` if no node matches.
N? hierarchyFind<T, N extends HierarchyNode<T>>(
  N root,
  bool Function(N node) filter,
) {
  final queue = <N>[root];
  var head = 0;
  while (head < queue.length) {
    final node = queue[head++];
    if (filter(node)) return node;
    final children = node.children;
    if (children != null) {
      for (var i = 0, n = children.length; i < n; ++i) {
        queue.add(children[i] as N);
      }
    }
  }
  return null;
}

/// Returns the first node in breadth-first order for which [filter] returns
/// `true` when invoked with `(node, index, root)`, or `null` if none matches.
N? hierarchyFindIndexed<T, N extends HierarchyNode<T>>(
  N root,
  bool Function(N node, int index, N root) filter,
) {
  final queue = <N>[root];
  var head = 0;
  while (head < queue.length) {
    final node = queue[head];
    if (filter(node, head, root)) return node;
    ++head;
    final children = node.children;
    if (children != null) {
      for (var i = 0, n = children.length; i < n; ++i) {
        queue.add(children[i] as N);
      }
    }
  }
  return null;
}
