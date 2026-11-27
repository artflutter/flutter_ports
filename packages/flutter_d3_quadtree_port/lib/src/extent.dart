// Ported from d3-quadtree v3.0.1 src/extent.js (ISC, Mike Bostock).

part of 'quadtree.dart';

// DIVERGES(d3-quadtree): adapt-quadtree-typed-api, split extent getter and
// setExtent method using typed ((double, double), (double, double)) record.
QuadtreeExtent? _quadtreeGetExtent<T>(Quadtree<T> tree) =>
    tree._x0.isNaN ? null : ((tree._x0, tree._y0), (tree._x1, tree._y1));

Quadtree<T> _quadtreeSetExtent<T>(Quadtree<T> tree, QuadtreeExtent extent) {
  final ((x0, y0), (x1, y1)) = extent;
  return tree.cover(x0, y0).cover(x1, y1);
}
