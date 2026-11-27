// Ported from d3-quadtree v3.0.1 src/remove.js (ISC, Mike Bostock).

part of 'quadtree.dart';

// DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, unboxed (double, double)
// default-accessor fast path and direct 4-field quadrant access.
Quadtree<T> _quadtreeRemove<T>(Quadtree<T> tree, T d) {
  final double x;
  final double y;
  if (tree._isDefaultPoint) {
    final p = d as (double, double);
    x = p.$1;
    y = p.$2;
  } else {
    x = tree._x(d);
    y = tree._y(d);
  }
  if (x.isNaN || y.isNaN) return tree; // ignore invalid points

  QuadtreeInternalNode<T>? parent;
  var node = tree._root;
  QuadtreeInternalNode<T>? retainer;
  QuadtreeLeafNode<T>? previous;
  var x0 = tree._x0;
  var y0 = tree._y0;
  var x1 = tree._x1;
  var y1 = tree._y1;
  var i = 0;
  var j = 0;

  // If the tree is empty, nothing to remove.
  if (node == null) return tree;

  // Find the leaf node for the point.
  // While descending, also retain the deepest parent with a non-removed
  // sibling.
  if (node is QuadtreeInternalNode<T>) {
    while (true) {
      final xm = (x0 + x1) * 0.5;
      final ym = (y0 + y1) * 0.5;
      parent = node! as QuadtreeInternalNode<T>;
      final bool hasSibling;
      if (y >= ym) {
        y0 = ym;
        if (x >= xm) {
          x0 = xm;
          node = parent.se;
          if (node == null) return tree;
          i = 3;
          if (node is QuadtreeLeafNode<T>) break;
          hasSibling =
              parent.nw != null || parent.ne != null || parent.sw != null;
        } else {
          x1 = xm;
          node = parent.sw;
          if (node == null) return tree;
          i = 2;
          if (node is QuadtreeLeafNode<T>) break;
          hasSibling =
              parent.nw != null || parent.ne != null || parent.se != null;
        }
      } else {
        y1 = ym;
        if (x >= xm) {
          x0 = xm;
          node = parent.ne;
          if (node == null) return tree;
          i = 1;
          if (node is QuadtreeLeafNode<T>) break;
          hasSibling =
              parent.nw != null || parent.sw != null || parent.se != null;
        } else {
          x1 = xm;
          node = parent.nw;
          if (node == null) return tree;
          i = 0;
          if (node is QuadtreeLeafNode<T>) break;
          hasSibling =
              parent.ne != null || parent.sw != null || parent.se != null;
        }
      }
      if (hasSibling) {
        retainer = parent;
        j = i;
      }
    }
  }

  // Find the point to remove.
  var leaf = node as QuadtreeLeafNode<T>;
  while (leaf.data != d) {
    previous = leaf;
    final nextLeaf = leaf.next;
    if (nextLeaf == null) return tree;
    leaf = nextLeaf;
  }
  final next = leaf.next;
  if (next != null) leaf.next = null;

  // If there are multiple coincident points, remove just the point.
  if (previous != null) {
    previous.next = next;
    return tree;
  }

  // If this is the root point, remove it.
  if (parent == null) {
    tree._root = next;
    return tree;
  }

  // Remove this leaf.
  switch (i) {
    case 0:
      parent.nw = next;
    case 1:
      parent.ne = next;
    case 2:
      parent.sw = next;
    default:
      parent.se = next;
  }

  // If the parent now contains exactly one leaf, collapse superfluous parents.
  final c0 = parent.nw;
  final c1 = parent.ne;
  final c2 = parent.sw;
  final c3 = parent.se;
  final first = c0 ?? c1 ?? c2 ?? c3;
  final last = c3 ?? c2 ?? c1 ?? c0;
  if (first != null && identical(first, last) && first is QuadtreeLeafNode<T>) {
    if (retainer != null) {
      _setChild(retainer, j, first);
    } else {
      tree._root = first;
    }
  }

  return tree;
}

Quadtree<T> _quadtreeRemoveAll<T>(Quadtree<T> tree, Iterable<T> data) {
  data.forEach(tree.remove);
  return tree;
}
