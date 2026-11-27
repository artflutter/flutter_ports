// Ported from d3-hierarchy v3.1.2 src/pack/index.js (ISC, Mike Bostock).

/// Port of `src/pack/index.js` of d3-hierarchy 3.1.2: [PackRadiusAccessor],
/// [PackPaddingAccessor], [PackLayout], and [pack].
library;

import 'dart:math' as math;

import 'package:flutter_d3_hierarchy_port/src/constant.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';
import 'package:flutter_d3_hierarchy_port/src/lcg.dart';
import 'package:flutter_d3_hierarchy_port/src/pack/siblings.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, typed PackLayout<T>
// returning HierarchyCircularNode<T> with immutable `(double, double)` size
// and typed `paddingConst` setter.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct closure-free
// pre-order/post-order pack walks avoiding per-pass stacks and closures.

/// Radius accessor for leaf nodes in [PackLayout].
typedef PackRadiusAccessor<T> = double Function(HierarchyCircularNode<T> node);

/// Padding accessor for parent nodes in [PackLayout].
typedef PackPaddingAccessor<T> = double Function(HierarchyCircularNode<T> node);

void _defaultRadiusWalk<T>(HierarchyCircularNode<T> node) {
  final children = node.children;
  if (children == null) {
    final v = math.sqrt(node.value ?? 0.0);
    node.r = v > 0 ? v : 0.0;
  } else {
    for (var i = 0, n = children.length; i < n; ++i) {
      _defaultRadiusWalk<T>(children[i]);
    }
  }
}

void _customRadiusWalk<T>(
  HierarchyCircularNode<T> node,
  PackRadiusAccessor<T> radius,
) {
  final children = node.children;
  if (children == null) {
    final v = radius(node);
    node.r = v > 0 ? v : 0.0;
  } else {
    for (var i = 0, n = children.length; i < n; ++i) {
      _customRadiusWalk<T>(children[i], radius);
    }
  }
}

void _packChildrenZeroWalk<T>(
  HierarchyCircularNode<T> node,
  double Function() random,
) {
  final children = node.children;
  if (children != null) {
    for (var i = 0, n = children.length; i < n; ++i) {
      _packChildrenZeroWalk<T>(children[i], random);
    }
    node.r = packSiblingsRandom<HierarchyCircularNode<T>>(children, random);
  }
}

void _packChildrenPadWalk<T>(
  HierarchyCircularNode<T> node,
  PackPaddingAccessor<T> padding,
  double k,
  double Function() random,
) {
  final children = node.children;
  if (children != null) {
    final n = children.length;
    for (var i = 0; i < n; ++i) {
      _packChildrenPadWalk<T>(children[i], padding, k, random);
    }
    final raw = padding(node) * k;
    final r = raw == raw && raw != 0 ? raw : 0.0;
    if (r != 0) {
      for (var i = 0; i < n; ++i) {
        children[i].r += r;
      }
    }
    final e = packSiblingsRandom<HierarchyCircularNode<T>>(children, random);
    if (r != 0) {
      for (var i = 0; i < n; ++i) {
        children[i].r -= r;
      }
    }
    node.r = e + r;
  }
}

void _translateWalk<T>(HierarchyCircularNode<T> node, double k) {
  final parent = node.parent;
  node.r *= k;
  if (parent != null) {
    node
      ..x = parent.x + k * node.x
      ..y = parent.y + k * node.y;
  }
  final children = node.children;
  if (children != null) {
    for (var i = 0, n = children.length; i < n; ++i) {
      _translateWalk<T>(children[i], k);
    }
  }
}

/// Produces nested enclosure circle-packing diagrams.
final class PackLayout<T>({
  /// Overall layout size `(width, height)`.
  var (double, double) size = const (1.0, 1.0),

  /// Optional custom leaf radius accessor (`null` uses `sqrt(node.value)`).
  var PackRadiusAccessor<T>? radius,

  PackPaddingAccessor<T>? padding,
  double? paddingConst,
}) {
  /// Creates a [PackLayout] with optional [size], [radius], [padding], or
  /// [paddingConst].
  this;

  /// Padding accessor applied around packed sibling groups.
  PackPaddingAccessor<T> padding =
      padding ??
      (paddingConst != null
          ? hierarchyConstant<HierarchyCircularNode<T>>(paddingConst)
          : hierarchyConstantZero);

  /// Sets a constant numeric [value] for [padding].
  void paddingConst(double value) {
    padding = hierarchyConstant<HierarchyCircularNode<T>>(value);
  }

  /// Lays out [root] as nested circles and returns a
  /// [HierarchyCircularNode<T>].
  HierarchyCircularNode<T> call(HierarchyNode<T> root) {
    final circRoot = hierarchyToCircular<T>(root);
    final random = hierarchyLcg();
    final dx = size.$1;
    final dy = size.$2;
    circRoot
      ..x = dx * 0.5
      ..y = dy * 0.5;
    final customRadius = radius;
    final zeroPad = identical(padding, hierarchyConstantZero);
    if (circRoot.height <= 512) {
      if (customRadius != null) {
        _customRadiusWalk<T>(circRoot, customRadius);
        if (zeroPad) {
          _packChildrenZeroWalk<T>(circRoot, random);
        } else {
          _packChildrenPadWalk<T>(circRoot, padding, 0.5, random);
        }
        _translateWalk<T>(circRoot, 1);
      } else {
        final minDim = math.min(dx, dy);
        _defaultRadiusWalk<T>(circRoot);
        _packChildrenZeroWalk<T>(circRoot, random);
        if (zeroPad) {
          _packChildrenZeroWalk<T>(circRoot, random);
        } else {
          _packChildrenPadWalk<T>(
            circRoot,
            padding,
            circRoot.r / minDim,
            random,
          );
        }
        _translateWalk<T>(circRoot, minDim / (2 * circRoot.r));
      }
      return circRoot;
    }

    if (customRadius != null) {
      circRoot
        ..eachBefore((node) {
          if (node.children == null) {
            final v = customRadius(node);
            node.r = v > 0 ? v : 0.0;
          }
        })
        ..eachAfter(_packChildrenRandom<T>(padding, 0.5, random))
        ..eachBefore(_translateChild<T>(1));
    } else {
      final minDim = math.min(dx, dy);
      circRoot
        ..eachBefore((node) {
          if (node.children == null) {
            final v = math.sqrt(node.value ?? 0.0);
            node.r = v > 0 ? v : 0.0;
          }
        })
        ..eachAfter(_packChildrenRandom<T>(hierarchyConstantZero, 1, random))
        ..eachAfter(
          _packChildrenRandom<T>(padding, circRoot.r / minDim, random),
        )
        ..eachBefore(_translateChild<T>(minDim / (2 * circRoot.r)));
    }
    return circRoot;
  }
}

void Function(HierarchyCircularNode<T>) _packChildrenRandom<T>(
  PackPaddingAccessor<T> padding,
  double k,
  double Function() random,
) {
  return (node) {
    final children = node.children;
    if (children != null) {
      final n = children.length;
      final raw = padding(node) * k;
      final r = raw == raw && raw != 0 ? raw : 0.0;
      if (r != 0) {
        for (var i = 0; i < n; ++i) {
          children[i].r += r;
        }
      }
      final e = packSiblingsRandom<HierarchyCircularNode<T>>(children, random);
      if (r != 0) {
        for (var i = 0; i < n; ++i) {
          children[i].r -= r;
        }
      }
      node.r = e + r;
    }
  };
}

void Function(HierarchyCircularNode<T>) _translateChild<T>(double k) {
  return (node) {
    final parent = node.parent;
    node.r *= k;
    if (parent != null) {
      node
        ..x = parent.x + k * node.x
        ..y = parent.y + k * node.y;
    }
  };
}

/// Creates a new [PackLayout<T>] circle-packing generator.
PackLayout<T> pack<T>({
  (double, double) size = const (1.0, 1.0),
  PackRadiusAccessor<T>? radius,
  PackPaddingAccessor<T>? padding,
  double? paddingConst,
}) => PackLayout<T>(
  size: size,
  radius: radius,
  padding: padding,
  paddingConst: paddingConst,
);
