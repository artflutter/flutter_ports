// Ported from d3-hierarchy v3.1.2 src/hierarchy/leaves.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/leaves.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct closure-free
// cast-free leaf collection with stack-safe fallback for deep trees.

void _collectLeavesBase<T>(HierarchyNode<T> node, List<HierarchyNode<T>> out) {
  final children = node.children;
  if (children == null) {
    out.add(node);
  } else {
    for (var i = 0, n = children.length; i < n; ++i) {
      _collectLeavesBase<T>(children[i], out);
    }
  }
}

void _collectLeaves<T, N extends HierarchyNode<T>>(N node, List<N> out) {
  final children = node.children;
  if (children == null) {
    out.add(node);
  } else {
    final typed = children as List<N>;
    for (var i = 0, n = typed.length; i < n; ++i) {
      _collectLeaves<T, N>(typed[i], out);
    }
  }
}

/// Cast-free leaf collection on base [HierarchyNode<T>].
List<HierarchyNode<T>> hierarchyLeavesBase<T>(HierarchyNode<T> root) {
  final leaves = <HierarchyNode<T>>[];
  if (root.height <= 512) {
    _collectLeavesBase<T>(root, leaves);
    return leaves;
  }
  final stack = <HierarchyNode<T>>[root];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    final children = node.children;
    if (children == null) {
      leaves.add(node);
    } else {
      for (var i = children.length - 1; i >= 0; --i) {
        stack.add(children[i]);
      }
    }
  }
  return leaves;
}

/// Returns the list of leaf nodes under [root] in traversal order.
List<N> hierarchyLeaves<T, N extends HierarchyNode<T>>(N root) {
  final leaves = <N>[];
  if (root.height <= 512) {
    _collectLeaves<T, N>(root, leaves);
    return leaves;
  }
  final stack = <N>[root];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    final children = node.children;
    if (children == null) {
      leaves.add(node);
    } else {
      final typed = children as List<N>;
      for (var i = typed.length - 1; i >= 0; --i) {
        stack.add(typed[i]);
      }
    }
  }
  return leaves;
}
