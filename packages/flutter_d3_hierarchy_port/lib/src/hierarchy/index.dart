// Ported from d3-hierarchy v3.1.2 src/hierarchy/index.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/index.js` of d3-hierarchy 3.1.2: [hierarchy],
/// [HierarchyDatum], [HierarchyNode], [HierarchyRectangularNode],
/// [HierarchyCircularNode], [HierarchyPointNode], and typed link records.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/ancestors.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/count.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/descendants.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/each.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/eachAfter.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/eachBefore.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/find.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/iterator.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/leaves.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/links.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/path.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/sort.dart';
import 'package:flutter_d3_hierarchy_port/src/hierarchy/sum.dart';
import 'package:flutter_d3_hierarchy_port/src/pack/enclose.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, typed HierarchyDatum
// interface, typed HierarchyLink records, and typed layout subclasses
// (HierarchyRectangularNode, HierarchyCircularNode, HierarchyPointNode)
// replacing JS duck-typing and dynamic property mutation.

/// Interface implemented by hierarchical data objects that expose their own
/// [children] iterable for the default accessor of [hierarchy].
abstract interface class HierarchyDatum<T>() {
  /// Child data elements of this datum, or `null` if it is a leaf.
  Iterable<T>? get children;
}

/// A directed parent-to-child link between two [HierarchyNode]s.
typedef HierarchyLink<T> = ({HierarchyNode<T> source, HierarchyNode<T> target});

/// A directed parent-to-child link between two [HierarchyRectangularNode]s.
typedef HierarchyRectangularLink<T> = ({
  HierarchyRectangularNode<T> source,
  HierarchyRectangularNode<T> target,
});

/// A directed parent-to-child link between two [HierarchyCircularNode]s.
typedef HierarchyCircularLink<T> = ({
  HierarchyCircularNode<T> source,
  HierarchyCircularNode<T> target,
});

/// A directed parent-to-child link between two [HierarchyPointNode]s.
typedef HierarchyPointLink<T> = ({
  HierarchyPointNode<T> source,
  HierarchyPointNode<T> target,
});

/// Cached row partition entry stored by `treemapResquarify`.
final class TreemapSquarifyRow<T>({
  /// Total aggregated value of the nodes in this row.
  required var double value,

  /// Whether this row is diced horizontally (`true`) or sliced vertically.
  required final bool dice,

  /// Child nodes belonging to this row.
  required final List<HierarchyRectangularNode<T>> children,
}) {
  /// Creates a cached squarify row partition.
  this;
}

/// Cached squarify row partition table stored on a [HierarchyRectangularNode]
/// by `treemapResquarify`.
final class TreemapResquarifyCache<T>({
  /// Target aspect ratio used when [rows] were computed.
  required final double ratio,

  /// Cached squarify rows for the parent node.
  required final List<TreemapSquarifyRow<T>> rows,
}) {
  /// Creates a resquarify cache for [ratio] and [rows].
  this;
}

Iterable<T>? _defaultChildren<T>(T d) =>
    d is HierarchyDatum<T> ? d.children : null;

HierarchyNode<T> _buildHierarchyRec<T>(
  T data,
  int depth,
  HierarchyNode<T>? parent,
  Iterable<T>? Function(T d) childAccessor,
) {
  final node = HierarchyNode<T>(data, depth: depth, parent: parent);
  final rawChildren = childAccessor(data);
  if (rawChildren != null) {
    final childDepth = depth + 1;
    if (rawChildren is List<T>) {
      final n = rawChildren.length;
      if (n > 0) {
        final first = _buildHierarchyRec<T>(
          rawChildren[0],
          childDepth,
          node,
          childAccessor,
        );
        var maxH = first.height;
        final childNodes = List<HierarchyNode<T>>.filled(
          n,
          first,
          growable: true,
        );
        for (var i = 1; i < n; ++i) {
          final c = _buildHierarchyRec<T>(
            rawChildren[i],
            childDepth,
            node,
            childAccessor,
          );
          childNodes[i] = c;
          if (c.height > maxH) maxH = c.height;
        }
        node
          ..children = childNodes
          ..height = maxH + 1;
      }
    } else {
      final childNodes = <HierarchyNode<T>>[];
      var maxH = -1;
      for (final item in rawChildren) {
        final c = _buildHierarchyRec<T>(item, childDepth, node, childAccessor);
        childNodes.add(c);
        if (c.height > maxH) maxH = c.height;
      }
      if (childNodes.isNotEmpty) {
        node
          ..children = childNodes
          ..height = maxH + 1;
      }
    }
  }
  return node;
}

/// Constructs a root [HierarchyNode] from hierarchical [data].
///
/// If [children] is omitted, data implementing [HierarchyDatum<T>] supply
/// their children via [HierarchyDatum.children]; other values are treated as
/// leaves.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, single-pass recursive
// construction computing depth on descent and height on ascent without a
// queue allocation, second `eachBefore(computeHeight)` pass, or closures.
HierarchyNode<T> hierarchy<T>(T data, [Iterable<T>? Function(T d)? children]) =>
    _buildHierarchyRec<T>(data, 0, null, children ?? _defaultChildren<T>);

/// Recomputes `height` bottom-up from [node] toward the root.
void computeHeight<T>(HierarchyNode<T> node) {
  var height = 0;
  HierarchyNode<T>? current = node;
  while (current != null) {
    current.height = height;
    final parent = current.parent;
    if (parent == null || parent.height >= ++height) break;
    current = parent;
  }
}

/// A node in a D3 hierarchy, carrying typed [data], topology ([depth],
/// [height], [parent], [children]), optional aggregated [value], and optional
/// [id] (assigned by `stratify`).
class HierarchyNode<T>(
  /// Associated datum for this node.
  var T data, {

  /// Distance from the root (`0` for the root node).
  var int depth = 0,

  /// Greatest distance from any descendant leaf (`0` for a leaf node).
  var int height = 0,

  /// Parent node, or `null` for the root node.
  var HierarchyNode<T>? parent,

  /// Child nodes, or `null` for a leaf node.
  var List<HierarchyNode<T>>? children,

  /// Summed numeric value assigned by [sum] or [count].
  var double? value,

  /// Optional unique identifier assigned by `stratify`.
  var String? id,
}) extends Iterable<HierarchyNode<T>> {
  /// Creates a [HierarchyNode] wrapping [data].
  this;

  @override
  Iterator<HierarchyNode<T>> get iterator =>
      hierarchyIterator<T, HierarchyNode<T>>(this);

  /// Returns the list of ancestor nodes, starting with this node up to the
  /// root.
  List<HierarchyNode<T>> ancestors() =>
      hierarchyAncestors<T, HierarchyNode<T>>(this);

  /// Returns the list of descendant nodes in breadth-first order, starting
  /// with this node.
  List<HierarchyNode<T>> descendants() => hierarchyDescendantsBase<T>(this);

  /// Returns the list of leaf nodes under this node in traversal order.
  List<HierarchyNode<T>> leaves() => hierarchyLeavesBase<T>(this);

  /// Returns a list of `(source: parent, target: child)` links for this
  /// subtree.
  List<HierarchyLink<T>> links() => hierarchyLinks<T, HierarchyNode<T>>(this);

  /// Returns the shortest path through the hierarchy from this node to
  /// [target].
  List<HierarchyNode<T>> path(HierarchyNode<T> target) =>
      hierarchyPath<T, HierarchyNode<T>>(this, target);

  /// Returns the first node in breadth-first order satisfying [filter], or
  /// `null`.
  HierarchyNode<T>? find(bool Function(HierarchyNode<T> node) filter) =>
      hierarchyFind<T, HierarchyNode<T>>(this, filter);

  /// Returns the first node in breadth-first order satisfying [filter] with
  /// `(node, index, root)`, or `null`.
  HierarchyNode<T>? findIndexed(
    bool Function(HierarchyNode<T> node, int index, HierarchyNode<T> root)
    filter,
  ) => hierarchyFindIndexed<T, HierarchyNode<T>>(this, filter);

  /// Invokes [callback] for this node and each descendant in breadth-first
  /// order.
  HierarchyNode<T> each(void Function(HierarchyNode<T> node) callback) =>
      hierarchyEachBase<T>(this, callback);

  /// Invokes [callback] with `(node, index, root)` in breadth-first order.
  HierarchyNode<T> eachIndexed(
    void Function(HierarchyNode<T> node, int index, HierarchyNode<T> root)
    callback,
  ) => hierarchyEachIndexed<T, HierarchyNode<T>>(this, callback);

  /// Invokes [callback] for this node and each descendant in pre-order.
  HierarchyNode<T> eachBefore(void Function(HierarchyNode<T> node) callback) =>
      hierarchyEachBeforeBase<T>(this, callback);

  /// Invokes [callback] with `(node, index, root)` in pre-order.
  HierarchyNode<T> eachBeforeIndexed(
    void Function(HierarchyNode<T> node, int index, HierarchyNode<T> root)
    callback,
  ) => hierarchyEachBeforeIndexed<T, HierarchyNode<T>>(this, callback);

  /// Invokes [callback] for this node and each descendant in post-order.
  HierarchyNode<T> eachAfter(void Function(HierarchyNode<T> node) callback) =>
      hierarchyEachAfterBase<T>(this, callback);

  /// Invokes [callback] with `(node, index, root)` in post-order.
  HierarchyNode<T> eachAfterIndexed(
    void Function(HierarchyNode<T> node, int index, HierarchyNode<T> root)
    callback,
  ) => hierarchyEachAfterIndexed<T, HierarchyNode<T>>(this, callback);

  /// Evaluates [value] for each node in post-order and assigns the cumulative
  /// sum to `node.value`.
  HierarchyNode<T> sum(num? Function(T d) value) =>
      hierarchySum<T, HierarchyNode<T>>(this, value);

  /// Computes the number of leaves under each node and assigns it to
  /// `node.value`.
  HierarchyNode<T> count() => hierarchyCount<T, HierarchyNode<T>>(this);

  /// Stably sorts the children of this node and every descendant using
  /// [compare].
  HierarchyNode<T> sort(
    num Function(HierarchyNode<T> a, HierarchyNode<T> b) compare,
  ) => hierarchySortBase<T>(this, compare);

  /// Returns a deep copy of the subtree rooted at this node (with `parent`
  /// cleared and `depth` re-based to `0`), copying `value` and `id`.
  HierarchyNode<T> copy() {
    final cloneRoot = HierarchyNode<T>(
      data,
      height: height,
      value: value,
      id: id,
    );
    final srcStack = <HierarchyNode<T>>[this];
    final dstStack = <HierarchyNode<T>>[cloneRoot];
    while (srcStack.isNotEmpty) {
      final src = srcStack.removeLast();
      final dst = dstStack.removeLast();
      final srcChildren = src.children;
      if (srcChildren != null && srcChildren.isNotEmpty) {
        final n = srcChildren.length;
        final dstChildren = List<HierarchyNode<T>>.generate(n, (i) {
          final sc = srcChildren[i];
          return HierarchyNode<T>(
            sc.data,
            depth: dst.depth + 1,
            height: sc.height,
            parent: dst,
            value: sc.value,
            id: sc.id,
          );
        });
        dst.children = dstChildren;
        for (var i = n - 1; i >= 0; --i) {
          srcStack.add(srcChildren[i]);
          dstStack.add(dstChildren[i]);
        }
      }
    }
    return cloneRoot;
  }
}

/// A [HierarchyNode] positioned into a rectangle `[x0, y0] .. [x1, y1]` by
/// `treemap` or `partition`.
final class HierarchyRectangularNode<T>(
  super.data, {
  super.depth,
  super.height,
  HierarchyRectangularNode<T>? super.parent,
  List<HierarchyRectangularNode<T>>? super.children,
  super.value,
  super.id,

  /// Left edge of the node's rectangle.
  var double x0 = 0,

  /// Top edge of the node's rectangle.
  var double y0 = 0,

  /// Right edge of the node's rectangle.
  var double x1 = 0,

  /// Bottom edge of the node's rectangle.
  var double y1 = 0,
}) extends HierarchyNode<T> {
  /// Creates a rectangular hierarchy node with optional layout bounds.
  this;

  /// Internal row cache populated by `treemapResquarify`.
  TreemapResquarifyCache<T>? resquarifyCache;

  @override
  HierarchyRectangularNode<T>? get parent =>
      super.parent as HierarchyRectangularNode<T>?;

  @override
  set parent(covariant HierarchyRectangularNode<T>? value) =>
      super.parent = value;

  @override
  List<HierarchyRectangularNode<T>>? get children =>
      super.children as List<HierarchyRectangularNode<T>>?;

  @override
  set children(covariant List<HierarchyRectangularNode<T>>? value) =>
      super.children = value;

  @override
  Iterator<HierarchyRectangularNode<T>> get iterator =>
      hierarchyIterator<T, HierarchyRectangularNode<T>>(this);

  @override
  List<HierarchyRectangularNode<T>> ancestors() =>
      hierarchyAncestors<T, HierarchyRectangularNode<T>>(this);

  @override
  List<HierarchyRectangularNode<T>> descendants() =>
      hierarchyDescendants<T, HierarchyRectangularNode<T>>(this);

  @override
  List<HierarchyRectangularNode<T>> leaves() =>
      hierarchyLeaves<T, HierarchyRectangularNode<T>>(this);

  @override
  List<HierarchyRectangularLink<T>> links() =>
      hierarchyLinks<T, HierarchyRectangularNode<T>>(this);

  @override
  List<HierarchyRectangularNode<T>> path(
    covariant HierarchyRectangularNode<T> target,
  ) => hierarchyPath<T, HierarchyRectangularNode<T>>(this, target);

  @override
  HierarchyRectangularNode<T>? find(
    bool Function(HierarchyRectangularNode<T> node) filter,
  ) => hierarchyFind<T, HierarchyRectangularNode<T>>(this, filter);

  @override
  HierarchyRectangularNode<T>? findIndexed(
    bool Function(
      HierarchyRectangularNode<T> node,
      int index,
      HierarchyRectangularNode<T> root,
    )
    filter,
  ) => hierarchyFindIndexed<T, HierarchyRectangularNode<T>>(this, filter);

  @override
  HierarchyRectangularNode<T> each(
    void Function(HierarchyRectangularNode<T> node) callback,
  ) => hierarchyEach<T, HierarchyRectangularNode<T>>(this, callback);

  @override
  HierarchyRectangularNode<T> eachIndexed(
    void Function(
      HierarchyRectangularNode<T> node,
      int index,
      HierarchyRectangularNode<T> root,
    )
    callback,
  ) => hierarchyEachIndexed<T, HierarchyRectangularNode<T>>(this, callback);

  @override
  HierarchyRectangularNode<T> eachBefore(
    void Function(HierarchyRectangularNode<T> node) callback,
  ) => hierarchyEachBefore<T, HierarchyRectangularNode<T>>(this, callback);

  @override
  HierarchyRectangularNode<T> eachBeforeIndexed(
    void Function(
      HierarchyRectangularNode<T> node,
      int index,
      HierarchyRectangularNode<T> root,
    )
    callback,
  ) => hierarchyEachBeforeIndexed<T, HierarchyRectangularNode<T>>(
    this,
    callback,
  );

  @override
  HierarchyRectangularNode<T> eachAfter(
    void Function(HierarchyRectangularNode<T> node) callback,
  ) => hierarchyEachAfter<T, HierarchyRectangularNode<T>>(this, callback);

  @override
  HierarchyRectangularNode<T> eachAfterIndexed(
    void Function(
      HierarchyRectangularNode<T> node,
      int index,
      HierarchyRectangularNode<T> root,
    )
    callback,
  ) =>
      hierarchyEachAfterIndexed<T, HierarchyRectangularNode<T>>(this, callback);

  @override
  HierarchyRectangularNode<T> sum(num? Function(T d) value) =>
      hierarchySum<T, HierarchyRectangularNode<T>>(this, value);

  @override
  HierarchyRectangularNode<T> count() =>
      hierarchyCount<T, HierarchyRectangularNode<T>>(this);

  @override
  HierarchyRectangularNode<T> sort(
    num Function(HierarchyRectangularNode<T> a, HierarchyRectangularNode<T> b)
    compare,
  ) => hierarchySort<T, HierarchyRectangularNode<T>>(this, compare);

  @override
  HierarchyRectangularNode<T> copy() {
    final cloneRoot = HierarchyRectangularNode<T>(
      data,
      height: height,
      value: value,
      id: id,
      x0: x0,
      y0: y0,
      x1: x1,
      y1: y1,
    );
    final srcStack = <HierarchyRectangularNode<T>>[this];
    final dstStack = <HierarchyRectangularNode<T>>[cloneRoot];
    while (srcStack.isNotEmpty) {
      final src = srcStack.removeLast();
      final dst = dstStack.removeLast();
      final srcChildren = src.children;
      if (srcChildren != null && srcChildren.isNotEmpty) {
        final n = srcChildren.length;
        final dstChildren = List<HierarchyRectangularNode<T>>.generate(n, (i) {
          final sc = srcChildren[i];
          return HierarchyRectangularNode<T>(
            sc.data,
            depth: dst.depth + 1,
            height: sc.height,
            parent: dst,
            value: sc.value,
            id: sc.id,
            x0: sc.x0,
            y0: sc.y0,
            x1: sc.x1,
            y1: sc.y1,
          );
        });
        dst.children = dstChildren;
        for (var i = n - 1; i >= 0; --i) {
          srcStack.add(srcChildren[i]);
          dstStack.add(dstChildren[i]);
        }
      }
    }
    return cloneRoot;
  }
}

/// A [HierarchyNode] positioned into a circle `([x], [y], [r])` by `pack`.
final class HierarchyCircularNode<T>(
  super.data, {
  super.depth,
  super.height,
  HierarchyCircularNode<T>? super.parent,
  List<HierarchyCircularNode<T>>? super.children,
  super.value,
  super.id,

  /// Center x-coordinate of the packed circle.
  @override var double x = 0,

  /// Center y-coordinate of the packed circle.
  @override var double y = 0,

  /// Radius of the packed circle.
  @override var double r = 0,
}) extends HierarchyNode<T> implements PackCircle {
  /// Creates a circular hierarchy node with optional center and radius.
  this;

  @override
  HierarchyCircularNode<T>? get parent =>
      super.parent as HierarchyCircularNode<T>?;

  @override
  set parent(covariant HierarchyCircularNode<T>? value) => super.parent = value;

  @override
  List<HierarchyCircularNode<T>>? get children =>
      super.children as List<HierarchyCircularNode<T>>?;

  @override
  set children(covariant List<HierarchyCircularNode<T>>? value) =>
      super.children = value;

  @override
  Iterator<HierarchyCircularNode<T>> get iterator =>
      hierarchyIterator<T, HierarchyCircularNode<T>>(this);

  @override
  List<HierarchyCircularNode<T>> ancestors() =>
      hierarchyAncestors<T, HierarchyCircularNode<T>>(this);

  @override
  List<HierarchyCircularNode<T>> descendants() =>
      hierarchyDescendants<T, HierarchyCircularNode<T>>(this);

  @override
  List<HierarchyCircularNode<T>> leaves() =>
      hierarchyLeaves<T, HierarchyCircularNode<T>>(this);

  @override
  List<HierarchyCircularLink<T>> links() =>
      hierarchyLinks<T, HierarchyCircularNode<T>>(this);

  @override
  List<HierarchyCircularNode<T>> path(
    covariant HierarchyCircularNode<T> target,
  ) => hierarchyPath<T, HierarchyCircularNode<T>>(this, target);

  @override
  HierarchyCircularNode<T>? find(
    bool Function(HierarchyCircularNode<T> node) filter,
  ) => hierarchyFind<T, HierarchyCircularNode<T>>(this, filter);

  @override
  HierarchyCircularNode<T>? findIndexed(
    bool Function(
      HierarchyCircularNode<T> node,
      int index,
      HierarchyCircularNode<T> root,
    )
    filter,
  ) => hierarchyFindIndexed<T, HierarchyCircularNode<T>>(this, filter);

  @override
  HierarchyCircularNode<T> each(
    void Function(HierarchyCircularNode<T> node) callback,
  ) => hierarchyEach<T, HierarchyCircularNode<T>>(this, callback);

  @override
  HierarchyCircularNode<T> eachIndexed(
    void Function(
      HierarchyCircularNode<T> node,
      int index,
      HierarchyCircularNode<T> root,
    )
    callback,
  ) => hierarchyEachIndexed<T, HierarchyCircularNode<T>>(this, callback);

  @override
  HierarchyCircularNode<T> eachBefore(
    void Function(HierarchyCircularNode<T> node) callback,
  ) => hierarchyEachBefore<T, HierarchyCircularNode<T>>(this, callback);

  @override
  HierarchyCircularNode<T> eachBeforeIndexed(
    void Function(
      HierarchyCircularNode<T> node,
      int index,
      HierarchyCircularNode<T> root,
    )
    callback,
  ) => hierarchyEachBeforeIndexed<T, HierarchyCircularNode<T>>(this, callback);

  @override
  HierarchyCircularNode<T> eachAfter(
    void Function(HierarchyCircularNode<T> node) callback,
  ) => hierarchyEachAfter<T, HierarchyCircularNode<T>>(this, callback);

  @override
  HierarchyCircularNode<T> eachAfterIndexed(
    void Function(
      HierarchyCircularNode<T> node,
      int index,
      HierarchyCircularNode<T> root,
    )
    callback,
  ) => hierarchyEachAfterIndexed<T, HierarchyCircularNode<T>>(this, callback);

  @override
  HierarchyCircularNode<T> sum(num? Function(T d) value) =>
      hierarchySum<T, HierarchyCircularNode<T>>(this, value);

  @override
  HierarchyCircularNode<T> count() =>
      hierarchyCount<T, HierarchyCircularNode<T>>(this);

  @override
  HierarchyCircularNode<T> sort(
    num Function(HierarchyCircularNode<T> a, HierarchyCircularNode<T> b)
    compare,
  ) => hierarchySort<T, HierarchyCircularNode<T>>(this, compare);

  @override
  HierarchyCircularNode<T> copy() {
    final cloneRoot = HierarchyCircularNode<T>(
      data,
      height: height,
      value: value,
      id: id,
      x: x,
      y: y,
      r: r,
    );
    final srcStack = <HierarchyCircularNode<T>>[this];
    final dstStack = <HierarchyCircularNode<T>>[cloneRoot];
    while (srcStack.isNotEmpty) {
      final src = srcStack.removeLast();
      final dst = dstStack.removeLast();
      final srcChildren = src.children;
      if (srcChildren != null && srcChildren.isNotEmpty) {
        final n = srcChildren.length;
        final dstChildren = List<HierarchyCircularNode<T>>.generate(n, (i) {
          final sc = srcChildren[i];
          return HierarchyCircularNode<T>(
            sc.data,
            depth: dst.depth + 1,
            height: sc.height,
            parent: dst,
            value: sc.value,
            id: sc.id,
            x: sc.x,
            y: sc.y,
            r: sc.r,
          );
        });
        dst.children = dstChildren;
        for (var i = n - 1; i >= 0; --i) {
          srcStack.add(srcChildren[i]);
          dstStack.add(dstChildren[i]);
        }
      }
    }
    return cloneRoot;
  }
}

/// A [HierarchyNode] positioned at 2D coordinates `([x], [y])` by `tree` or
/// `cluster`.
final class HierarchyPointNode<T>(
  super.data, {
  super.depth,
  super.height,
  HierarchyPointNode<T>? super.parent,
  List<HierarchyPointNode<T>>? super.children,
  super.value,
  super.id,

  /// Horizontal coordinate assigned by `tree` or `cluster`.
  var double x = 0,

  /// Vertical coordinate assigned by `tree` or `cluster`.
  var double y = 0,
}) extends HierarchyNode<T> {
  /// Creates a point hierarchy node with optional coordinates.
  this;

  @override
  HierarchyPointNode<T>? get parent => super.parent as HierarchyPointNode<T>?;

  @override
  set parent(covariant HierarchyPointNode<T>? value) => super.parent = value;

  @override
  List<HierarchyPointNode<T>>? get children =>
      super.children as List<HierarchyPointNode<T>>?;

  @override
  set children(covariant List<HierarchyPointNode<T>>? value) =>
      super.children = value;

  @override
  Iterator<HierarchyPointNode<T>> get iterator =>
      hierarchyIterator<T, HierarchyPointNode<T>>(this);

  @override
  List<HierarchyPointNode<T>> ancestors() =>
      hierarchyAncestors<T, HierarchyPointNode<T>>(this);

  @override
  List<HierarchyPointNode<T>> descendants() =>
      hierarchyDescendants<T, HierarchyPointNode<T>>(this);

  @override
  List<HierarchyPointNode<T>> leaves() =>
      hierarchyLeaves<T, HierarchyPointNode<T>>(this);

  @override
  List<HierarchyPointLink<T>> links() =>
      hierarchyLinks<T, HierarchyPointNode<T>>(this);

  @override
  List<HierarchyPointNode<T>> path(covariant HierarchyPointNode<T> target) =>
      hierarchyPath<T, HierarchyPointNode<T>>(this, target);

  @override
  HierarchyPointNode<T>? find(
    bool Function(HierarchyPointNode<T> node) filter,
  ) => hierarchyFind<T, HierarchyPointNode<T>>(this, filter);

  @override
  HierarchyPointNode<T>? findIndexed(
    bool Function(
      HierarchyPointNode<T> node,
      int index,
      HierarchyPointNode<T> root,
    )
    filter,
  ) => hierarchyFindIndexed<T, HierarchyPointNode<T>>(this, filter);

  @override
  HierarchyPointNode<T> each(
    void Function(HierarchyPointNode<T> node) callback,
  ) => hierarchyEach<T, HierarchyPointNode<T>>(this, callback);

  @override
  HierarchyPointNode<T> eachIndexed(
    void Function(
      HierarchyPointNode<T> node,
      int index,
      HierarchyPointNode<T> root,
    )
    callback,
  ) => hierarchyEachIndexed<T, HierarchyPointNode<T>>(this, callback);

  @override
  HierarchyPointNode<T> eachBefore(
    void Function(HierarchyPointNode<T> node) callback,
  ) => hierarchyEachBefore<T, HierarchyPointNode<T>>(this, callback);

  @override
  HierarchyPointNode<T> eachBeforeIndexed(
    void Function(
      HierarchyPointNode<T> node,
      int index,
      HierarchyPointNode<T> root,
    )
    callback,
  ) => hierarchyEachBeforeIndexed<T, HierarchyPointNode<T>>(this, callback);

  @override
  HierarchyPointNode<T> eachAfter(
    void Function(HierarchyPointNode<T> node) callback,
  ) => hierarchyEachAfter<T, HierarchyPointNode<T>>(this, callback);

  @override
  HierarchyPointNode<T> eachAfterIndexed(
    void Function(
      HierarchyPointNode<T> node,
      int index,
      HierarchyPointNode<T> root,
    )
    callback,
  ) => hierarchyEachAfterIndexed<T, HierarchyPointNode<T>>(this, callback);

  @override
  HierarchyPointNode<T> sum(num? Function(T d) value) =>
      hierarchySum<T, HierarchyPointNode<T>>(this, value);

  @override
  HierarchyPointNode<T> count() =>
      hierarchyCount<T, HierarchyPointNode<T>>(this);

  @override
  HierarchyPointNode<T> sort(
    num Function(HierarchyPointNode<T> a, HierarchyPointNode<T> b) compare,
  ) => hierarchySort<T, HierarchyPointNode<T>>(this, compare);

  @override
  HierarchyPointNode<T> copy() {
    final cloneRoot = HierarchyPointNode<T>(
      data,
      height: height,
      value: value,
      id: id,
      x: x,
      y: y,
    );
    final srcStack = <HierarchyPointNode<T>>[this];
    final dstStack = <HierarchyPointNode<T>>[cloneRoot];
    while (srcStack.isNotEmpty) {
      final src = srcStack.removeLast();
      final dst = dstStack.removeLast();
      final srcChildren = src.children;
      if (srcChildren != null && srcChildren.isNotEmpty) {
        final n = srcChildren.length;
        final dstChildren = List<HierarchyPointNode<T>>.generate(n, (i) {
          final sc = srcChildren[i];
          return HierarchyPointNode<T>(
            sc.data,
            depth: dst.depth + 1,
            height: sc.height,
            parent: dst,
            value: sc.value,
            id: sc.id,
            x: sc.x,
            y: sc.y,
          );
        });
        dst.children = dstChildren;
        for (var i = n - 1; i >= 0; --i) {
          srcStack.add(srcChildren[i]);
          dstStack.add(dstChildren[i]);
        }
      }
    }
    return cloneRoot;
  }
}

/// Returns [root] as a [HierarchyRectangularNode<T>] (in-place if already
/// rectangular, otherwise cloning the hierarchy into rectangular nodes).
HierarchyRectangularNode<T> hierarchyToRectangular<T>(HierarchyNode<T> root) {
  if (root is HierarchyRectangularNode<T>) return root;
  final rectRoot = HierarchyRectangularNode<T>(
    root.data,
    depth: root.depth,
    height: root.height,
    value: root.value,
    id: root.id,
  );
  final srcStack = <HierarchyNode<T>>[root];
  final dstStack = <HierarchyRectangularNode<T>>[rectRoot];
  while (srcStack.isNotEmpty) {
    final src = srcStack.removeLast();
    final dst = dstStack.removeLast();
    final srcChildren = src.children;
    if (srcChildren != null && srcChildren.isNotEmpty) {
      final n = srcChildren.length;
      final dstChildren = List<HierarchyRectangularNode<T>>.generate(n, (i) {
        final sc = srcChildren[i];
        return HierarchyRectangularNode<T>(
          sc.data,
          depth: sc.depth,
          height: sc.height,
          parent: dst,
          value: sc.value,
          id: sc.id,
        );
      });
      dst.children = dstChildren;
      for (var i = n - 1; i >= 0; --i) {
        srcStack.add(srcChildren[i]);
        dstStack.add(dstChildren[i]);
      }
    }
  }
  return rectRoot;
}

/// Returns [root] as a [HierarchyCircularNode<T>] (in-place if already
/// circular, otherwise cloning the hierarchy into circular nodes).
HierarchyCircularNode<T> hierarchyToCircular<T>(HierarchyNode<T> root) {
  if (root is HierarchyCircularNode<T>) return root;
  final circRoot = HierarchyCircularNode<T>(
    root.data,
    depth: root.depth,
    height: root.height,
    value: root.value,
    id: root.id,
  );
  final srcStack = <HierarchyNode<T>>[root];
  final dstStack = <HierarchyCircularNode<T>>[circRoot];
  while (srcStack.isNotEmpty) {
    final src = srcStack.removeLast();
    final dst = dstStack.removeLast();
    final srcChildren = src.children;
    if (srcChildren != null && srcChildren.isNotEmpty) {
      final n = srcChildren.length;
      final dstChildren = List<HierarchyCircularNode<T>>.generate(n, (i) {
        final sc = srcChildren[i];
        return HierarchyCircularNode<T>(
          sc.data,
          depth: sc.depth,
          height: sc.height,
          parent: dst,
          value: sc.value,
          id: sc.id,
        );
      });
      dst.children = dstChildren;
      for (var i = n - 1; i >= 0; --i) {
        srcStack.add(srcChildren[i]);
        dstStack.add(dstChildren[i]);
      }
    }
  }
  return circRoot;
}

/// Returns [root] as a [HierarchyPointNode<T>] (in-place if already a point
/// node, otherwise cloning the hierarchy into point nodes).
HierarchyPointNode<T> hierarchyToPoint<T>(HierarchyNode<T> root) {
  if (root is HierarchyPointNode<T>) return root;
  final pointRoot = HierarchyPointNode<T>(
    root.data,
    depth: root.depth,
    height: root.height,
    value: root.value,
    id: root.id,
  );
  final srcStack = <HierarchyNode<T>>[root];
  final dstStack = <HierarchyPointNode<T>>[pointRoot];
  while (srcStack.isNotEmpty) {
    final src = srcStack.removeLast();
    final dst = dstStack.removeLast();
    final srcChildren = src.children;
    if (srcChildren != null && srcChildren.isNotEmpty) {
      final n = srcChildren.length;
      final dstChildren = List<HierarchyPointNode<T>>.generate(n, (i) {
        final sc = srcChildren[i];
        return HierarchyPointNode<T>(
          sc.data,
          depth: sc.depth,
          height: sc.height,
          parent: dst,
          value: sc.value,
          id: sc.id,
        );
      });
      dst.children = dstChildren;
      for (var i = n - 1; i >= 0; --i) {
        srcStack.add(srcChildren[i]);
        dstStack.add(dstChildren[i]);
      }
    }
  }
  return pointRoot;
}
