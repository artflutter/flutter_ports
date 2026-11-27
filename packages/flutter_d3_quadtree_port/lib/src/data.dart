// Ported from d3-quadtree v3.0.1 src/data.js (ISC, Mike Bostock).

part of 'quadtree.dart';

// DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, direct pre-order
// collection without bounds math or callback closures, with iterative fallback
// for extreme depths.
List<T> _quadtreeData<T>(Quadtree<T> tree) {
  final root = tree._root;
  if (root == null) return <T>[];
  final data = <T>[];
  _collectData(root, data, 0);
  return data;
}

void _collectData<T>(QuadtreeNode<T> node, List<T> out, int depth) {
  switch (node) {
    case final QuadtreeLeafNode<T> leafNode:
      out.add(leafNode.data);
      var leaf = leafNode.next;
      while (leaf != null) {
        out.add(leaf.data);
        leaf = leaf.next;
      }
    case final QuadtreeInternalNode<T> branch:
      if (depth >= 128) {
        _collectDataIterative(branch, out);
        return;
      }
      final nextDepth = depth + 1;
      final c0 = branch.nw;
      if (c0 != null) _collectData(c0, out, nextDepth);
      final c1 = branch.ne;
      if (c1 != null) _collectData(c1, out, nextDepth);
      final c2 = branch.sw;
      if (c2 != null) _collectData(c2, out, nextDepth);
      final c3 = branch.se;
      if (c3 != null) _collectData(c3, out, nextDepth);
  }
}

void _collectDataIterative<T>(QuadtreeInternalNode<T> root, List<T> out) {
  final stack = <QuadtreeNode<T>>[root];
  while (stack.isNotEmpty) {
    switch (stack.removeLast()) {
      case final QuadtreeInternalNode<T> branch:
        final c3 = branch.se;
        if (c3 != null) stack.add(c3);
        final c2 = branch.sw;
        if (c2 != null) stack.add(c2);
        final c1 = branch.ne;
        if (c1 != null) stack.add(c1);
        final c0 = branch.nw;
        if (c0 != null) stack.add(c0);
      case final QuadtreeLeafNode<T> leafNode:
        out.add(leafNode.data);
        var leaf = leafNode.next;
        while (leaf != null) {
          out.add(leaf.data);
          leaf = leaf.next;
        }
    }
  }
}
