// Ported from d3-hierarchy v3.1.2 src/hierarchy/eachAfter.js (ISC, Mike Bostock).
// ignore_for_file: file_names

/// Port of `src/hierarchy/eachAfter.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, split 1-arg and 3-arg
// indexed post-order callbacks without JS `this` binding.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct allocation-free
// cast-free recursive post-order for trees of height <= 512 with iterative
// fallback.

void _visitAfterBase<T>(
  HierarchyNode<T> node,
  void Function(HierarchyNode<T> node) callback,
) {
  final children = node.children;
  if (children != null) {
    for (var i = 0, n = children.length; i < n; ++i) {
      _visitAfterBase<T>(children[i], callback);
    }
  }
  callback(node);
}

void _visitAfter<T, N extends HierarchyNode<T>>(
  N node,
  void Function(N node) callback,
) {
  final children = node.children;
  if (children != null) {
    final typed = children as List<N>;
    for (var i = 0, n = typed.length; i < n; ++i) {
      _visitAfter<T, N>(typed[i], callback);
    }
  }
  callback(node);
}

int _visitAfterIndexed<T, N extends HierarchyNode<T>>(
  N node,
  int index,
  N root,
  void Function(N node, int index, N root) callback,
) {
  var idx = index;
  final children = node.children;
  if (children != null) {
    final typed = children as List<N>;
    for (var i = 0, n = typed.length; i < n; ++i) {
      idx = _visitAfterIndexed<T, N>(typed[i], idx, root, callback);
    }
  }
  callback(node, ++idx, root);
  return idx;
}

/// Cast-free post-order traversal on base [HierarchyNode<T>].
HierarchyNode<T> hierarchyEachAfterBase<T>(
  HierarchyNode<T> root,
  void Function(HierarchyNode<T> node) callback,
) {
  if (root.height <= 512) {
    _visitAfterBase<T>(root, callback);
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
    callback(next.removeLast());
  }
  return root;
}

/// Invokes [callback] for [root] and each descendant in post-order traversal.
N hierarchyEachAfter<T, N extends HierarchyNode<T>>(
  N root,
  void Function(N node) callback,
) {
  if (root.height <= 512) {
    _visitAfter<T, N>(root, callback);
    return root;
  }
  final nodes = <N>[root];
  final next = <N>[];
  while (nodes.isNotEmpty) {
    final node = nodes.removeLast();
    next.add(node);
    final children = node.children;
    if (children != null) {
      final typed = children as List<N>;
      for (var i = 0, n = typed.length; i < n; ++i) {
        nodes.add(typed[i]);
      }
    }
  }
  while (next.isNotEmpty) {
    callback(next.removeLast());
  }
  return root;
}

/// Invokes [callback] with `(node, index, root)` for [root] and each
/// descendant in post-order traversal.
N hierarchyEachAfterIndexed<T, N extends HierarchyNode<T>>(
  N root,
  void Function(N node, int index, N root) callback,
) {
  if (root.height <= 512) {
    _visitAfterIndexed<T, N>(root, -1, root, callback);
    return root;
  }
  final nodes = <N>[root];
  final next = <N>[];
  while (nodes.isNotEmpty) {
    final node = nodes.removeLast();
    next.add(node);
    final children = node.children;
    if (children != null) {
      final typed = children as List<N>;
      for (var i = 0, n = typed.length; i < n; ++i) {
        nodes.add(typed[i]);
      }
    }
  }
  var index = -1;
  while (next.isNotEmpty) {
    callback(next.removeLast(), ++index, root);
  }
  return root;
}
