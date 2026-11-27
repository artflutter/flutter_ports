// Ported from d3-hierarchy v3.1.2 src/treemap/index.js (ISC, Mike Bostock).

/// Port of `src/treemap/index.js` of d3-hierarchy 3.1.2: [TreemapTile],
/// [TreemapPaddingAccessor], [TreemapLayout], and [treemap].
library;

import 'dart:typed_data';

import 'package:flutter_d3_hierarchy_port/src/constant.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/round.dart';
import 'package:flutter_d3_hierarchy_port/src/treemap/squarify.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, typed TreemapLayout<T>
// returning HierarchyRectangularNode<T> with immutable `(double, double)` size
// and typed `*Const` padding setters.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, unboxed `Float64List`
// padding stack and direct closure-free pre-order walk skipping zero padding
// accessors.

/// Callback that tiles the children of [parent] into `[x0, y0] .. [x1, y1]`.
typedef TreemapTile<T> = void Function(
  HierarchyRectangularNode<T> parent,
  double x0,
  double y0,
  double x1,
  double y1,
);

/// Padding accessor evaluated per parent node in [TreemapLayout].
typedef TreemapPaddingAccessor<T> = double Function(
  HierarchyRectangularNode<T> node,
);

void _defaultTile<T>(
  HierarchyRectangularNode<T> parent,
  double x0,
  double y0,
  double x1,
  double y1,
) => treemapSquarify<T>(parent, x0, y0, x1, y1);

/// Produces rectangular treemap layouts.
final class TreemapLayout<T>({
  TreemapTile<T>? tile,

  /// Whether computed node coordinates are rounded to integer values.
  var bool round = false,

  /// Overall layout size `(width, height)`.
  var (double, double) size = const (1.0, 1.0),
}) {
  /// Creates a [TreemapLayout] with optional configuration.
  this;

  /// Tiling method used to subdivide each parent rectangle.
  TreemapTile<T> tile = tile ?? _defaultTile<T>;

  /// Inner padding accessor separating adjacent sibling nodes.
  TreemapPaddingAccessor<T> paddingInner = hierarchyConstantZero;

  /// Top outer padding accessor separating a parent's top edge from children.
  TreemapPaddingAccessor<T> paddingTop = hierarchyConstantZero;

  /// Right outer padding accessor separating a parent's right edge from
  /// children.
  TreemapPaddingAccessor<T> paddingRight = hierarchyConstantZero;

  /// Bottom outer padding accessor separating a parent's bottom edge from
  /// children.
  TreemapPaddingAccessor<T> paddingBottom = hierarchyConstantZero;

  /// Left outer padding accessor separating a parent's left edge from children.
  TreemapPaddingAccessor<T> paddingLeft = hierarchyConstantZero;

  /// Returns [paddingInner] (matching upstream `treemap.padding()`).
  TreemapPaddingAccessor<T> get padding => paddingInner;

  /// Sets both [paddingInner] and [paddingOuter] to [fn].
  set padding(TreemapPaddingAccessor<T> fn) {
    paddingInner = fn;
    paddingOuter = fn;
  }

  /// Sets both [paddingInner] and [paddingOuter] to constant [value].
  void paddingConst(double value) {
    final fn = hierarchyConstant<HierarchyRectangularNode<T>>(value);
    paddingInner = fn;
    paddingTop = fn;
    paddingRight = fn;
    paddingBottom = fn;
    paddingLeft = fn;
  }

  /// Sets [paddingInner] to constant [value].
  void paddingInnerConst(double value) {
    paddingInner = hierarchyConstant<HierarchyRectangularNode<T>>(value);
  }

  /// Returns [paddingTop] (matching upstream `treemap.paddingOuter()`).
  TreemapPaddingAccessor<T> get paddingOuter => paddingTop;

  /// Sets [paddingTop], [paddingRight], [paddingBottom], and [paddingLeft] to
  /// [fn].
  set paddingOuter(TreemapPaddingAccessor<T> fn) {
    paddingTop = fn;
    paddingRight = fn;
    paddingBottom = fn;
    paddingLeft = fn;
  }

  /// Sets [paddingTop], [paddingRight], [paddingBottom], and [paddingLeft] to
  /// constant [value].
  void paddingOuterConst(double value) {
    final fn = hierarchyConstant<HierarchyRectangularNode<T>>(value);
    paddingTop = fn;
    paddingRight = fn;
    paddingBottom = fn;
    paddingLeft = fn;
  }

  /// Sets [paddingTop] to constant [value].
  void paddingTopConst(double value) {
    paddingTop = hierarchyConstant<HierarchyRectangularNode<T>>(value);
  }

  /// Sets [paddingRight] to constant [value].
  void paddingRightConst(double value) {
    paddingRight = hierarchyConstant<HierarchyRectangularNode<T>>(value);
  }

  /// Sets [paddingBottom] to constant [value].
  void paddingBottomConst(double value) {
    paddingBottom = hierarchyConstant<HierarchyRectangularNode<T>>(value);
  }

  /// Sets [paddingLeft] to constant [value].
  void paddingLeftConst(double value) {
    paddingLeft = hierarchyConstant<HierarchyRectangularNode<T>>(value);
  }

  void _positionNode(
    HierarchyRectangularNode<T> node,
    Float64List paddingStack,
  ) {
    var p = paddingStack[node.depth];
    var x0 = node.x0 + p;
    var y0 = node.y0 + p;
    var x1 = node.x1 - p;
    var y1 = node.y1 - p;
    if (x1 < x0) x0 = x1 = (x0 + x1) * 0.5;
    if (y1 < y0) y0 = y1 = (y0 + y1) * 0.5;
    node
      ..x0 = x0
      ..y0 = y0
      ..x1 = x1
      ..y1 = y1;
    final children = node.children;
    if (children != null) {
      p = paddingStack[node.depth + 1] = paddingInner(node) * 0.5;
      x0 += paddingLeft(node) - p;
      y0 += paddingTop(node) - p;
      x1 -= paddingRight(node) - p;
      y1 -= paddingBottom(node) - p;
      if (x1 < x0) x0 = x1 = (x0 + x1) * 0.5;
      if (y1 < y0) y0 = y1 = (y0 + y1) * 0.5;
      tile(node, x0, y0, x1, y1);
      for (var i = 0, n = children.length; i < n; ++i) {
        _positionNode(children[i], paddingStack);
      }
    }
  }

  void _positionNodeNoPad(HierarchyRectangularNode<T> node) {
    var x0 = node.x0;
    var y0 = node.y0;
    var x1 = node.x1;
    var y1 = node.y1;
    if (x1 < x0) x0 = x1 = (x0 + x1) * 0.5;
    if (y1 < y0) y0 = y1 = (y0 + y1) * 0.5;
    node
      ..x0 = x0
      ..y0 = y0
      ..x1 = x1
      ..y1 = y1;
    final children = node.children;
    if (children != null) {
      tile(node, x0, y0, x1, y1);
      for (var i = 0, n = children.length; i < n; ++i) {
        _positionNodeNoPad(children[i]);
      }
    }
  }

  /// Lays out [root] as a treemap and returns a [HierarchyRectangularNode<T>].
  HierarchyRectangularNode<T> call(HierarchyNode<T> root) {
    final rectRoot = hierarchyToRectangular<T>(root)
      ..x0 = 0
      ..y0 = 0
      ..x1 = size.$1
      ..y1 = size.$2;

    final zeroPad =
        identical(paddingInner, hierarchyConstantZero) &&
        identical(paddingTop, hierarchyConstantZero) &&
        identical(paddingRight, hierarchyConstantZero) &&
        identical(paddingBottom, hierarchyConstantZero) &&
        identical(paddingLeft, hierarchyConstantZero);

    if (rectRoot.height <= 512) {
      if (zeroPad) {
        _positionNodeNoPad(rectRoot);
      } else {
        final paddingStack = Float64List(rectRoot.depth + rectRoot.height + 2);
        _positionNode(rectRoot, paddingStack);
      }
    } else {
      final paddingStack = Float64List(rectRoot.depth + rectRoot.height + 2);
      rectRoot.eachBefore((node) {
        var p = paddingStack[node.depth];
        var x0 = node.x0 + p;
        var y0 = node.y0 + p;
        var x1 = node.x1 - p;
        var y1 = node.y1 - p;
        if (x1 < x0) x0 = x1 = (x0 + x1) * 0.5;
        if (y1 < y0) y0 = y1 = (y0 + y1) * 0.5;
        node
          ..x0 = x0
          ..y0 = y0
          ..x1 = x1
          ..y1 = y1;
        if (node.children != null) {
          p = paddingStack[node.depth + 1] = paddingInner(node) * 0.5;
          x0 += paddingLeft(node) - p;
          y0 += paddingTop(node) - p;
          x1 -= paddingRight(node) - p;
          y1 -= paddingBottom(node) - p;
          if (x1 < x0) x0 = x1 = (x0 + x1) * 0.5;
          if (y1 < y0) y0 = y1 = (y0 + y1) * 0.5;
          tile(node, x0, y0, x1, y1);
        }
      });
    }

    if (round) rectRoot.eachBefore(treemapRoundNode);
    return rectRoot;
  }
}

/// Creates a new [TreemapLayout<T>] generator.
TreemapLayout<T> treemap<T>({
  TreemapTile<T>? tile,
  bool round = false,
  (double, double) size = const (1.0, 1.0),
  TreemapPaddingAccessor<T>? padding,
  double? paddingConst,
  TreemapPaddingAccessor<T>? paddingInner,
  double? paddingInnerConst,
  TreemapPaddingAccessor<T>? paddingOuter,
  double? paddingOuterConst,
  TreemapPaddingAccessor<T>? paddingTop,
  double? paddingTopConst,
  TreemapPaddingAccessor<T>? paddingRight,
  double? paddingRightConst,
  TreemapPaddingAccessor<T>? paddingBottom,
  double? paddingBottomConst,
  TreemapPaddingAccessor<T>? paddingLeft,
  double? paddingLeftConst,
}) {
  final layout = TreemapLayout<T>(tile: tile, round: round, size: size);
  if (paddingConst != null) layout.paddingConst(paddingConst);
  if (padding != null) layout.padding = padding;
  if (paddingInnerConst != null) layout.paddingInnerConst(paddingInnerConst);
  if (paddingInner != null) layout.paddingInner = paddingInner;
  if (paddingOuterConst != null) layout.paddingOuterConst(paddingOuterConst);
  if (paddingOuter != null) layout.paddingOuter = paddingOuter;
  if (paddingTopConst != null) layout.paddingTopConst(paddingTopConst);
  if (paddingTop != null) layout.paddingTop = paddingTop;
  if (paddingRightConst != null) layout.paddingRightConst(paddingRightConst);
  if (paddingRight != null) layout.paddingRight = paddingRight;
  if (paddingBottomConst != null) {
    layout.paddingBottomConst(paddingBottomConst);
  }
  if (paddingBottom != null) layout.paddingBottom = paddingBottom;
  if (paddingLeftConst != null) layout.paddingLeftConst(paddingLeftConst);
  if (paddingLeft != null) layout.paddingLeft = paddingLeft;
  return layout;
}
