// Ported from d3-hierarchy v3.1.2 src/hierarchy/eachBefore.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/hierarchy/eachBefore.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, split 1-arg and 3-arg
// indexed pre-order callbacks without JS `this` binding.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct allocation-free
// cast-free recursive pre-order for trees of height <= 512 with iterative
// fallback.

void _visitBeforeBase<T>(
  HierarchyNode<T> node,
  void Function(HierarchyNode<T> node) callback,
) {
  callback(node);
  final children = node.children;
  if (children != null) {
    for (var i = 0, n = children.length; i < n; ++i) {
      _visitBeforeBase<T>(children[i], callback);
    }
  }
}

void _visitBefore<T, N extends HierarchyNode<T>>(
  N node,
  void Function(N node) callback,
) {
  callback(node);
  final children = node.children;
  if (children != null) {
    final typed = children as List<N>;
    for (var i = 0, n = typed.length; i < n; ++i) {
      _visitBefore<T, N>(typed[i], callback);
    }
  }
}

int _visitBeforeIndexed<T, N extends HierarchyNode<T>>(
  N node,
  int index,
  N root,
  void Function(N node, int index, N root) callback,
) {
  var idx = index + 1;
  callback(node, idx, root);
  final children = node.children;
  if (children != null) {
    final typed = children as List<N>;
    for (var i = 0, n = typed.length; i < n; ++i) {
      idx = _visitBeforeIndexed<T, N>(typed[i], idx, root, callback);
    }
  }
  return idx;
}

/// Cast-free pre-order traversal on base [HierarchyNode<T>].
HierarchyNode<T> hierarchyEachBeforeBase<T>(
  HierarchyNode<T> root,
  void Function(HierarchyNode<T> node) callback,
) {
  if (root.height <= 512) {
    _visitBeforeBase<T>(root, callback);
    return root;
  }
  final nodes = <HierarchyNode<T>>[root];
  while (nodes.isNotEmpty) {
    final node = nodes.removeLast();
    callback(node);
    final children = node.children;
    if (children != null) {
      for (var i = children.length - 1; i >= 0; --i) {
        nodes.add(children[i]);
      }
    }
  }
  return root;
}

/// Invokes [callback] for [root] and each descendant in pre-order traversal.
N hierarchyEachBefore<T, N extends HierarchyNode<T>>(
  N root,
  void Function(N node) callback,
) {
  if (root.height <= 512) {
    _visitBefore<T, N>(root, callback);
    return root;
  }
  final nodes = <N>[root];
  while (nodes.isNotEmpty) {
    final node = nodes.removeLast();
    callback(node);
    final children = node.children;
    if (children != null) {
      final typed = children as List<N>;
      for (var i = typed.length - 1; i >= 0; --i) {
        nodes.add(typed[i]);
      }
    }
  }
  return root;
}

/// Invokes [callback] with `(node, index, root)` for [root] and each
/// descendant in pre-order traversal.
N hierarchyEachBeforeIndexed<T, N extends HierarchyNode<T>>(
  N root,
  void Function(N node, int index, N root) callback,
) {
  if (root.height <= 512) {
    _visitBeforeIndexed<T, N>(root, -1, root, callback);
    return root;
  }
  final nodes = <N>[root];
  var index = -1;
  while (nodes.isNotEmpty) {
    final node = nodes.removeLast();
    callback(node, ++index, root);
    final children = node.children;
    if (children != null) {
      final typed = children as List<N>;
      for (var i = typed.length - 1; i >= 0; --i) {
        nodes.add(typed[i]);
      }
    }
  }
  return root;
}
