// Ported from d3-quadtree v3.0.1 src/size.js (ISC, Mike Bostock).

part of 'quadtree.dart';

// DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, direct leaf counting
// without bounds math or callback closures, with iterative fallback for extreme
// depths.
int _quadtreeSize<T>(Quadtree<T> tree) {
  final root = tree._root;
  if (root == null) return 0;
  return _countSize(root, 0);
}

int _countSize<T>(QuadtreeNode<T> node, int depth) {
  switch (node) {
    case final QuadtreeLeafNode<T> leafNode:
      var count = 1;
      var leaf = leafNode.next;
      while (leaf != null) {
        ++count;
        leaf = leaf.next;
      }
      return count;
    case final QuadtreeInternalNode<T> branch:
      if (depth >= 128) return _countSizeIterative(branch);
      final nextDepth = depth + 1;
      var count = 0;
      final c0 = branch.nw;
      if (c0 != null) count += _countSize(c0, nextDepth);
      final c1 = branch.ne;
      if (c1 != null) count += _countSize(c1, nextDepth);
      final c2 = branch.sw;
      if (c2 != null) count += _countSize(c2, nextDepth);
      final c3 = branch.se;
      if (c3 != null) count += _countSize(c3, nextDepth);
      return count;
  }
}

int _countSizeIterative<T>(QuadtreeInternalNode<T> root) {
  var count = 0;
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
        ++count;
        var leaf = leafNode.next;
        while (leaf != null) {
          ++count;
          leaf = leaf.next;
        }
    }
  }
  return count;
}
