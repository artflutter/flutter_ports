// Ported from d3-hierarchy v3.1.2 src/hierarchy/sum.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/sum.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct unboxed recursive
// post-order summation without `eachAfter` stack allocations or per-node
// closures (with iterative fallback for height > 512).

double _sumRec<T>(HierarchyNode<T> node, num? Function(T d) value) {
  final raw = value(node.data);
  var sum = (raw != null && raw != 0 && raw == raw) ? raw.toDouble() : 0.0;
  final children = node.children;
  if (children != null) {
    for (var i = children.length - 1; i >= 0; --i) {
      sum += _sumRec<T>(children[i], value);
    }
  }
  node.value = sum;
  return sum;
}

/// Evaluates [value] for [root] and every descendant in post-order traversal
/// and assigns `node.value` to the node's own value plus the sum of its
/// children's values, returning [root].
N hierarchySum<T, N extends HierarchyNode<T>>(
  N root,
  num? Function(T d) value,
) {
  if (root.height <= 512) {
    _sumRec<T>(root, value);
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
    final raw = value(node.data);
    var sum = (raw != null && raw != 0 && raw == raw) ? raw.toDouble() : 0.0;
    final children = node.children;
    if (children != null) {
      for (var i = children.length - 1; i >= 0; --i) {
        sum += children[i].value ?? 0.0;
      }
    }
    node.value = sum;
  }
  return root;
}
