// Ported from d3-hierarchy v3.1.2 src/hierarchy/each.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/each.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, split 1-arg and 3-arg
// indexed traversal callbacks without JS `this` binding.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct cast-free flat
// FIFO BFS traversal without `sync*` generator or per-level list reversal.

/// Cast-free breadth-first traversal on base [HierarchyNode<T>].
HierarchyNode<T> hierarchyEachBase<T>(
  HierarchyNode<T> root,
  void Function(HierarchyNode<T> node) callback,
) {
  final queue = <HierarchyNode<T>>[root];
  var head = 0;
  while (head < queue.length) {
    final node = queue[head++];
    callback(node);
    final children = node.children;
    if (children != null) {
      queue.addAll(children);
    }
  }
  return root;
}

/// Invokes [callback] for [root] and each descendant in breadth-first order.
N hierarchyEach<T, N extends HierarchyNode<T>>(
  N root,
  void Function(N node) callback,
) {
  final queue = <N>[root];
  var head = 0;
  while (head < queue.length) {
    final node = queue[head++];
    callback(node);
    final children = node.children;
    if (children != null) {
      queue.addAll(children as List<N>);
    }
  }
  return root;
}

/// Invokes [callback] with `(node, index, root)` for [root] and each
/// descendant in breadth-first order.
N hierarchyEachIndexed<T, N extends HierarchyNode<T>>(
  N root,
  void Function(N node, int index, N root) callback,
) {
  final queue = <N>[root];
  var head = 0;
  while (head < queue.length) {
    final node = queue[head];
    callback(node, head, root);
    ++head;
    final children = node.children;
    if (children != null) {
      queue.addAll(children as List<N>);
    }
  }
  return root;
}
