// Ported from d3-hierarchy v3.1.2 src/cluster.js (ISC, Mike Bostock).

/// Port of `src/cluster.js` of d3-hierarchy 3.1.2: [ClusterLayout] and
/// [cluster].
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';
import 'package:flutter_d3_hierarchy_port/src/tree.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, typed ClusterLayout<T>
// returning HierarchyPointNode<T> and using immutable `(double, double)?` size
// records.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct allocation-free
// post-order and scaling walks with inlined default separation.

double _defaultSeparation<T>(
  HierarchyPointNode<T> a,
  HierarchyPointNode<T> b,
) => identical(a.parent, b.parent) ? 1.0 : 2.0;

HierarchyPointNode<T> _leafLeft<T>(HierarchyPointNode<T> node) {
  var current = node;
  List<HierarchyPointNode<T>>? children;
  while ((children = current.children) != null) {
    current = children![0];
  }
  return current;
}

HierarchyPointNode<T> _leafRight<T>(HierarchyPointNode<T> node) {
  var current = node;
  List<HierarchyPointNode<T>>? children;
  while ((children = current.children) != null) {
    current = children![children.length - 1];
  }
  return current;
}

void _scaleNodeSize<T>(
  HierarchyPointNode<T> node,
  double rx,
  double ry,
  double dx,
  double dy,
) {
  node
    ..x = (node.x - rx) * dx
    ..y = (ry - node.y) * dy;
  final children = node.children;
  if (children != null) {
    for (var i = 0, n = children.length; i < n; ++i) {
      _scaleNodeSize<T>(children[i], rx, ry, dx, dy);
    }
  }
}

void _scaleSize<T>(
  HierarchyPointNode<T> node,
  double x0,
  double invSpanDx,
  double invRy,
  double dy,
  bool hasRy,
) {
  node
    ..x = (node.x - x0) * invSpanDx
    ..y = (1.0 - (hasRy ? node.y * invRy : 1.0)) * dy;
  final children = node.children;
  if (children != null) {
    for (var i = 0, n = children.length; i < n; ++i) {
      _scaleSize<T>(children[i], x0, invSpanDx, invRy, dy, hasRy);
    }
  }
}

/// Produces a dendrogram layout placing all leaf nodes at the same depth.
final class ClusterLayout<T>({
  TreeSeparation<T>? separation,
  (double, double)? size,
  (double, double)? nodeSize,
}) {
  /// Creates a [ClusterLayout] with optional [size], [nodeSize], and
  /// [separation].
  this;

  /// Separation function between adjacent leaf nodes.
  TreeSeparation<T> separation = separation ?? _defaultSeparation<T>;

  double _dx = nodeSize != null ? nodeSize.$1 : (size != null ? size.$1 : 1.0);
  double _dy = nodeSize != null ? nodeSize.$2 : (size != null ? size.$2 : 1.0);
  bool _nodeSize = nodeSize != null;

  /// Overall layout size `(width, height)`, or `null` when [nodeSize] is
  /// active.
  (double, double)? get size => _nodeSize ? null : (_dx, _dy);

  /// Sets the overall layout size and disables [nodeSize].
  set size((double, double)? value) {
    if (value == null) {
      _nodeSize = true;
    } else {
      _nodeSize = false;
      _dx = value.$1;
      _dy = value.$2;
    }
  }

  /// Fixed node spacing `(dx, dy)`, or `null` when [size] is active.
  (double, double)? get nodeSize => _nodeSize ? (_dx, _dy) : null;

  /// Sets the fixed node spacing and disables [size].
  set nodeSize((double, double)? value) {
    if (value == null) {
      _nodeSize = false;
    } else {
      _nodeSize = true;
      _dx = value.$1;
      _dy = value.$2;
    }
  }

  /// Lays out [root] as a dendrogram and returns a [HierarchyPointNode<T>].
  HierarchyPointNode<T> call(HierarchyNode<T> root) {
    final pointRoot = hierarchyToPoint<T>(root);
    HierarchyPointNode<T>? previousNode;
    var x = 0.0;
    final sep = separation;
    final isDefaultSep = identical(sep, _defaultSeparation<T>);

    void firstWalk(HierarchyPointNode<T> node) {
      final children = node.children;
      if (children != null) {
        final n = children.length;
        var sumX = 0.0;
        var maxY = 0.0;
        for (var i = 0; i < n; ++i) {
          final c = children[i];
          firstWalk(c);
          sumX += c.x;
          if (c.y > maxY) maxY = c.y;
        }
        node
          ..x = sumX / n
          ..y = 1.0 + maxY;
      } else {
        if (previousNode != null) {
          x += isDefaultSep
              ? (identical(node.parent, previousNode!.parent) ? 1.0 : 2.0)
              : sep(node, previousNode!);
          node.x = x;
        } else {
          node.x = 0.0;
        }
        node.y = 0.0;
        previousNode = node;
      }
    }

    if (pointRoot.height <= 512) {
      firstWalk(pointRoot);
    } else {
      pointRoot.eachAfter((node) {
        final children = node.children;
        if (children != null) {
          final n = children.length;
          var sumX = 0.0;
          var maxY = 0.0;
          for (var i = 0; i < n; ++i) {
            final c = children[i];
            sumX += c.x;
            if (c.y > maxY) maxY = c.y;
          }
          node
            ..x = sumX / n
            ..y = 1.0 + maxY;
        } else {
          if (previousNode != null) {
            x += isDefaultSep
                ? (identical(node.parent, previousNode!.parent) ? 1.0 : 2.0)
                : sep(node, previousNode!);
            node.x = x;
          } else {
            node.x = 0.0;
          }
          node.y = 0.0;
          previousNode = node;
        }
      });
    }

    final left = _leafLeft(pointRoot);
    final right = _leafRight(pointRoot);
    final x0 = left.x - sep(left, right) * 0.5;
    final x1 = right.x + sep(right, left) * 0.5;

    // Second walk, normalizing x & y to the desired size.
    if (_nodeSize) {
      final rx = pointRoot.x;
      final ry = pointRoot.y;
      if (pointRoot.height <= 512) {
        _scaleNodeSize<T>(pointRoot, rx, ry, _dx, _dy);
      } else {
        final dx = _dx;
        final dy = _dy;
        pointRoot.eachAfter((node) {
          node
            ..x = (node.x - rx) * dx
            ..y = (ry - node.y) * dy;
        });
      }
    } else {
      final ry = pointRoot.y;
      final span = x1 - x0;
      if (pointRoot.height <= 512) {
        _scaleSize<T>(
          pointRoot,
          x0,
          _dx / span,
          ry != 0 ? 1.0 / ry : 0.0,
          _dy,
          ry != 0,
        );
      } else {
        final dx = _dx;
        final dy = _dy;
        pointRoot.eachAfter((node) {
          node
            ..x = (node.x - x0) / span * dx
            ..y = (1.0 - (ry != 0 ? node.y / ry : 1.0)) * dy;
        });
      }
    }

    return pointRoot;
  }
}

/// Creates a new [ClusterLayout<T>] dendrogram generator.
ClusterLayout<T> cluster<T>({
  TreeSeparation<T>? separation,
  (double, double)? size,
  (double, double)? nodeSize,
}) => ClusterLayout<T>(separation: separation, size: size, nodeSize: nodeSize);
