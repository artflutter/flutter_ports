// Ported from d3-quadtree v3.0.1 src/cover.js (ISC, Mike Bostock).

part of 'quadtree.dart';

// DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, avoids allocating wrapper
// internal nodes while doubling extent when root is null or a leaf.
Quadtree<T> _quadtreeCover<T>(Quadtree<T> tree, double x, double y) {
  if (x.isNaN || y.isNaN) return tree; // ignore invalid points

  var x0 = tree._x0;
  var y0 = tree._y0;
  var x1 = tree._x1;
  var y1 = tree._y1;

  // If the quadtree has no extent, initialize them.
  // Integer extent are necessary so that if we later double the extent,
  // the existing quadrant boundaries don't change due to floating point error!
  if (x0.isNaN) {
    x0 = x.isFinite ? x.floorToDouble() : x;
    x1 = x0 + 1.0;
    y0 = y.isFinite ? y.floorToDouble() : y;
    y1 = y0 + 1.0;
  } else if (x0 > x || x >= x1 || y0 > y || y >= y1) {
    // Otherwise, double repeatedly to cover.
    var z = x1 - x0;
    if (z == 0.0) z = 1.0;
    var node = tree._root;

    if (node is QuadtreeInternalNode<T>) {
      while (x0 > x || x >= x1 || y0 > y || y >= y1) {
        final left = x < x0;
        final top = y < y0;
        z *= 2.0;
        if (top) {
          if (left) {
            node = QuadtreeInternalNode<T>(se: node);
            x0 = x1 - z;
            y0 = y1 - z;
          } else {
            node = QuadtreeInternalNode<T>(sw: node);
            x1 = x0 + z;
            y0 = y1 - z;
          }
        } else {
          if (left) {
            node = QuadtreeInternalNode<T>(ne: node);
            x0 = x1 - z;
            y1 = y0 + z;
          } else {
            node = QuadtreeInternalNode<T>(nw: node);
            x1 = x0 + z;
            y1 = y0 + z;
          }
        }
      }
      tree._root = node;
    } else {
      while (x0 > x || x >= x1 || y0 > y || y >= y1) {
        final left = x < x0;
        final top = y < y0;
        z *= 2.0;
        if (left) {
          x0 = x1 - z;
        } else {
          x1 = x0 + z;
        }
        if (top) {
          y0 = y1 - z;
        } else {
          y1 = y0 + z;
        }
      }
    }
  } else {
    return tree;
  }

  return tree
    .._x0 = x0
    .._y0 = y0
    .._x1 = x1
    .._y1 = y1;
}
