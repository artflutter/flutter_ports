// Ported from d3-quadtree v3.0.1 src/y.js (ISC, Mike Bostock).

part of 'quadtree.dart';

/// Default y-coordinate accessor for `(double, double)` point records.
// DIVERGES(d3-quadtree): adapt-quadtree-typed-api, typed (double, double)
// record accessor replacing untyped d[1] indexing.
double defaultQuadtreeY((double, double) d) => d.$2;

QuadtreeAccessor<T> _quadtreeGetY<T>(Quadtree<T> tree) => tree._y;

void _quadtreeSetY<T>(Quadtree<T> tree, QuadtreeAccessor<T> accessor) {
  tree
    .._y = accessor
    .._isDefaultPoint =
        identical(tree._x, defaultQuadtreeX) &&
        identical(accessor, defaultQuadtreeY);
}
