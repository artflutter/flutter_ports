// Ported from d3-hierarchy v3.1.2 src/hierarchy/count.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/count.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct unboxed recursive
// post-order leaf counting without `eachAfter` stack allocations or closures.

double _countRec<T>(HierarchyNode<T> node) {
  final children = node.children;
  if (children == null || children.isEmpty) {
    return node.value = 1.0;
  }
  var sum = 0.0;
  for (var i = children.length - 1; i >= 0; --i) {
    sum += _countRec<T>(children[i]);
  }
  return node.value = sum;
}

/// Computes the number of leaves under [root] and assigns it to `node.value`
/// for [root] and every descendant, returning [root].
N hierarchyCount<T, N extends HierarchyNode<T>>(N root) {
  if (root.height <= 512) {
    _countRec<T>(root);
    return root;
  }
  final nodes = <HierarchyNode<T>>[root];
  final next = <HierarchyNode<T>>[];
  while (nodes.isNotEmpty) {
    final node = nodes.removeLast();
    next.add(node);
    final children = node.children;
    if (children != null) {
      for (var i = 0, n = children.length; i < n; ++i) {
        nodes.add(children[i]);
      }
    }
  }
  while (next.isNotEmpty) {
    final node = next.removeLast();
    final children = node.children;
    if (children == null || children.isEmpty) {
      node.value = 1.0;
    } else {
      var sum = 0.0;
      for (var i = children.length - 1; i >= 0; --i) {
        sum += children[i].value ?? 0.0;
      }
      node.value = sum;
    }
  }
  return root;
}
