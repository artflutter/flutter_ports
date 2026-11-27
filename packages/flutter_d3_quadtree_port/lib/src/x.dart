// Ported from d3-quadtree v3.0.1 src/x.js (ISC, Mike Bostock).

part of 'quadtree.dart';

/// Default x-coordinate accessor for `(double, double)` point records.
// DIVERGES(d3-quadtree): adapt-quadtree-typed-api, typed (double, double)
// record accessor replacing untyped d[0] indexing.
double defaultQuadtreeX((double, double) d) => d.$1;

QuadtreeAccessor<T> _quadtreeGetX<T>(Quadtree<T> tree) => tree._x;

void _quadtreeSetX<T>(Quadtree<T> tree, QuadtreeAccessor<T> accessor) {
  tree
    .._x = accessor
    .._isDefaultPoint =
        identical(accessor, defaultQuadtreeX) &&
        identical(tree._y, defaultQuadtreeY);
}
