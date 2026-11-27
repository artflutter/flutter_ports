// Ported from d3-quadtree v3.0.1 src/quad.js (ISC, Mike Bostock).

/// Port of `src/quad.js` of d3-quadtree 3.0.1.
library;

import 'package:flutter_d3_quadtree_port/src/quadtree.dart';

/// A traversal frame pairing a [QuadtreeNode] with its quadrant bounds
/// `([x0], [y0])` to `([x1], [y1])`.
// DIVERGES(d3-quadtree): adapt-quadtree-typed-api, typed QuadtreeQuad<T>
// class with primary constructor replacing untyped JS Quad constructor.
final class QuadtreeQuad<T>(
  /// The quadtree node at this quadrant, or `null` when empty.
  final QuadtreeNode<T>? node,

  /// The inclusive lower x-bound of this quadrant.
  final double x0,

  /// The inclusive lower y-bound of this quadrant.
  final double y0,

  /// The upper x-bound of this quadrant.
  final double x1,

  /// The upper y-bound of this quadrant.
  final double y1,
) {
  /// Creates a traversal frame for [node] within `[x0, x1] × [y0, y1]`.
  this;
}
