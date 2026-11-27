// Ported from d3-quadtree v3.0.1 src/quadtree.js (ISC, Mike Bostock).

/// Port of `src/quadtree.js` of d3-quadtree 3.0.1.
library;

import 'dart:math' as math;
import 'dart:typed_data';

part 'add.dart';
part 'cover.dart';
part 'data.dart';
part 'extent.dart';
part 'find.dart';
part 'remove.dart';
part 'root.dart';
part 'size.dart';
part 'visit.dart';
part 'visitAfter.dart';
part 'x.dart';
part 'y.dart';

/// Accessor extracting a numeric coordinate from a datum of type `T`.
typedef QuadtreeAccessor<T> = double Function(T datum);

/// Bounding extent of a [Quadtree]: `((x0, y0), (x1, y1))`.
typedef QuadtreeExtent = ((double, double), (double, double));

/// Pre-order traversal callback for [Quadtree.visit].
///
/// Returns `true` to skip visiting the children of [node], or `false` to
/// continue descending into child quadrants.
typedef QuadtreeVisitCallback<T> = bool Function(
  QuadtreeNode<T> node,
  double x0,
  double y0,
  double x1,
  double y1,
);

/// Post-order traversal callback for [Quadtree.visitAfter].
typedef QuadtreeVisitAfterCallback<T> = void Function(
  QuadtreeNode<T> node,
  double x0,
  double y0,
  double x1,
  double y1,
);

/// A node in a [Quadtree]: either a [QuadtreeInternalNode] subdividing space
/// into four quadrants, or a [QuadtreeLeafNode] storing a datum and an optional
/// linked list of coincident data.
// DIVERGES(d3-quadtree): adapt-quadtree-typed-api, sealed generic
// QuadtreeNode<T> hierarchy replacing JS 4-element arrays and {data, next}
// leaf objects.
sealed class const QuadtreeNode<T>() {
  /// Base constructor for quadtree nodes.
  this;
}

/// An internal node of a [Quadtree] holding four optional child quadrants:
/// `nw` (`0`, top-left), `ne` (`1`, top-right), `sw` (`2`, bottom-left), and
/// `se` (`3`, bottom-right).
// DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, four concrete nullable
// quadrant fields avoiding a second per-node List allocation and bounds checks.
final class QuadtreeInternalNode<T>({
  /// Top-left quadrant (index `0`, `x < xm && y < ym`).
  var QuadtreeNode<T>? nw,

  /// Top-right quadrant (index `1`, `x >= xm && y < ym`).
  var QuadtreeNode<T>? ne,

  /// Bottom-left quadrant (index `2`, `x < xm && y >= ym`).
  var QuadtreeNode<T>? sw,

  /// Bottom-right quadrant (index `3`, `x >= xm && y >= ym`).
  var QuadtreeNode<T>? se,
}) extends QuadtreeNode<T> {
  /// Creates an internal node with optional quadrant children.
  this;

  /// Returns the child node in quadrant [index] (`0` = `nw`, `1` = `ne`,
  /// `2` = `sw`, `3` = `se`).
  QuadtreeNode<T>? operator [](int index) => switch (index) {
    0 => nw,
    1 => ne,
    2 => sw,
    3 => se,
    _ => throw RangeError.range(index, 0, 3, 'index'),
  };

  /// Sets the child node in quadrant [index] (`0..3`).
  void operator []=(int index, QuadtreeNode<T>? node) {
    switch (index) {
      case 0:
        nw = node;
      case 1:
        ne = node;
      case 2:
        sw = node;
      case 3:
        se = node;
      default:
        throw RangeError.range(index, 0, 3, 'index');
    }
  }
}

/// A leaf node of a [Quadtree] storing [data] and an optional [next] leaf for
/// coincident points at the exact same `(x, y)` coordinates.
final class QuadtreeLeafNode<T>(
  /// The datum stored at this leaf.
  final T data, [

  /// The next coincident datum at the same coordinates, if any.
  var QuadtreeLeafNode<T>? next,
]) extends QuadtreeNode<T> {
  /// Creates a leaf node holding [data] and optional coincident [next] leaf.
  this;
}

/// Creates a new quadtree for `(double, double)` points with optional initial
/// [data] and optional [x]/[y] coordinate accessors (defaulting to
/// [defaultQuadtreeX] and [defaultQuadtreeY]).
// DIVERGES(d3-quadtree): adapt-quadtree-typed-api, strongly typed factory for
// (double, double) point records alongside generic quadtreeBy<T>.
Quadtree<(double, double)> quadtree([
  Iterable<(double, double)>? data,
  QuadtreeAccessor<(double, double)>? x,
  QuadtreeAccessor<(double, double)>? y,
]) {
  final xFn = x ?? defaultQuadtreeX;
  final yFn = y ?? defaultQuadtreeY;
  final tree = Quadtree<(double, double)>._(
    xFn,
    yFn,
    double.nan,
    double.nan,
    double.nan,
    double.nan,
    identical(xFn, defaultQuadtreeX) && identical(yFn, defaultQuadtreeY),
  );
  return data == null ? tree : tree.addAll(data);
}

/// Creates a new quadtree for arbitrary datum type `T` with required [x] and
/// [y] coordinate accessors and optional initial [data].
Quadtree<T> quadtreeBy<T>({
  required QuadtreeAccessor<T> x,
  required QuadtreeAccessor<T> y,
  Iterable<T>? data,
}) {
  final tree = Quadtree<T>._(
    x,
    y,
    double.nan,
    double.nan,
    double.nan,
    double.nan,
    identical(x, defaultQuadtreeX) && identical(y, defaultQuadtreeY),
  );
  return data == null ? tree : tree.addAll(data);
}

@pragma('vm:prefer-inline')
QuadtreeLeafNode<T> _leafCopy<T>(QuadtreeLeafNode<T> leaf) {
  final firstNext = leaf.next;
  if (firstNext == null) return QuadtreeLeafNode<T>(leaf.data);
  final copy = QuadtreeLeafNode<T>(leaf.data);
  var tail = copy;
  QuadtreeLeafNode<T>? current = firstNext;
  while (current != null) {
    final copied = QuadtreeLeafNode<T>(current.data);
    tail.next = copied;
    tail = copied;
    current = current.next;
  }
  return copy;
}

QuadtreeInternalNode<T> _copyBranch<T>(
  QuadtreeInternalNode<T> source,
  int depth,
) {
  if (depth >= 128) return _copyBranchIterative(source);
  final nextDepth = depth + 1;
  final c0 = source.nw;
  final c1 = source.ne;
  final c2 = source.sw;
  final c3 = source.se;
  return QuadtreeInternalNode<T>(
    nw: c0 == null
        ? null
        : switch (c0) {
            QuadtreeInternalNode<T>() => _copyBranch(c0, nextDepth),
            QuadtreeLeafNode<T>() => _leafCopy(c0),
          },
    ne: c1 == null
        ? null
        : switch (c1) {
            QuadtreeInternalNode<T>() => _copyBranch(c1, nextDepth),
            QuadtreeLeafNode<T>() => _leafCopy(c1),
          },
    sw: c2 == null
        ? null
        : switch (c2) {
            QuadtreeInternalNode<T>() => _copyBranch(c2, nextDepth),
            QuadtreeLeafNode<T>() => _leafCopy(c2),
          },
    se: c3 == null
        ? null
        : switch (c3) {
            QuadtreeInternalNode<T>() => _copyBranch(c3, nextDepth),
            QuadtreeLeafNode<T>() => _leafCopy(c3),
          },
  );
}

QuadtreeInternalNode<T> _copyBranchIterative<T>(
  QuadtreeInternalNode<T> rootSource,
) {
  final rootTarget = QuadtreeInternalNode<T>();
  final srcStack = <QuadtreeInternalNode<T>>[rootSource];
  final dstStack = <QuadtreeInternalNode<T>>[rootTarget];

  while (srcStack.isNotEmpty) {
    final source = srcStack.removeLast();
    final target = dstStack.removeLast();

    final c0 = source.nw;
    if (c0 != null) {
      switch (c0) {
        case QuadtreeInternalNode<T>():
          final t0 = QuadtreeInternalNode<T>();
          target.nw = t0;
          srcStack.add(c0);
          dstStack.add(t0);
        case QuadtreeLeafNode<T>():
          target.nw = _leafCopy(c0);
      }
    }

    final c1 = source.ne;
    if (c1 != null) {
      switch (c1) {
        case QuadtreeInternalNode<T>():
          final t1 = QuadtreeInternalNode<T>();
          target.ne = t1;
          srcStack.add(c1);
          dstStack.add(t1);
        case QuadtreeLeafNode<T>():
          target.ne = _leafCopy(c1);
      }
    }

    final c2 = source.sw;
    if (c2 != null) {
      switch (c2) {
        case QuadtreeInternalNode<T>():
          final t2 = QuadtreeInternalNode<T>();
          target.sw = t2;
          srcStack.add(c2);
          dstStack.add(t2);
        case QuadtreeLeafNode<T>():
          target.sw = _leafCopy(c2);
      }
    }

    final c3 = source.se;
    if (c3 != null) {
      switch (c3) {
        case QuadtreeInternalNode<T>():
          final t3 = QuadtreeInternalNode<T>();
          target.se = t3;
          srcStack.add(c3);
          dstStack.add(t3);
        case QuadtreeLeafNode<T>():
          target.se = _leafCopy(c3);
      }
    }
  }
  return rootTarget;
}

/// Reusable mutable frame for zero-allocation iterative traversal across AOT,
/// Wasm, and dart2js (single cache line with unboxed double bounds).
// DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, pooled mutable frame
// avoids per-node Quad heap allocations and multi-array bounds checks.
final class _QuadFrame<T>() {
  QuadtreeNode<T>? node;
  double x0 = 0;
  double y0 = 0;
  double x1 = 0;
  double y1 = 0;
  bool expanded = false;
}

/// Pooled iterative frame stack with a non-reassigned growable [frames] list.
final class _FramePool<T>() {
  final List<_QuadFrame<T>> frames = List<_QuadFrame<T>>.generate(
    64,
    (_) => _QuadFrame<T>(),
  );
  int lastMaxSp = 0;

  void ensureCapacity(int needed) {
    var len = frames.length;
    if (needed <= len) return;
    var next = len << 1;
    while (next < needed) {
      next <<= 1;
    }
    while (len < next) {
      frames.add(_QuadFrame<T>());
      ++len;
    }
  }
}

/// A two-dimensional recursive spatial subdivision tree for data of type `T`.
// DIVERGES(d3-quadtree): adapt-quadtree-typed-api, generic final class
// Quadtree<T> with typed accessors, extent record, sealed nodes, and zero
// dynamic/Object? escape hatches.
// DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, tracks default
// (double, double) accessors and holds a re-entrancy-guarded reusable pool.
final class Quadtree<T>._(
  var QuadtreeAccessor<T> _x,
  var QuadtreeAccessor<T> _y,
  var double _x0,
  var double _y0,
  var double _x1,
  var double _y1,
  var bool _isDefaultPoint,
) {
  /// Creates a new quadtree for data of type `T` using [x] and [y] coordinate
  /// accessors, optionally populated with [data].
  factory({
    required QuadtreeAccessor<T> x,
    required QuadtreeAccessor<T> y,
    Iterable<T>? data,
  }) {
    final tree = Quadtree<T>._(
      x,
      y,
      double.nan,
      double.nan,
      double.nan,
      double.nan,
      identical(x, defaultQuadtreeX) && identical(y, defaultQuadtreeY),
    );
    return data == null ? tree : tree.addAll(data);
  }

  /// Creates a new quadtree for `(double, double)` points with optional initial
  /// [data] and optional [x]/[y] accessors.
  static Quadtree<(double, double)> points([
    Iterable<(double, double)>? data,
    QuadtreeAccessor<(double, double)>? x,
    QuadtreeAccessor<(double, double)>? y,
  ]) => quadtree(data, x, y);

  QuadtreeNode<T>? _root;
  _FramePool<T>? _pool;
  bool _poolInUse = false;

  @pragma('vm:prefer-inline')
  _FramePool<T> _acquirePool() {
    if (!_poolInUse) {
      _poolInUse = true;
      return _pool ??= _FramePool<T>();
    }
    return _FramePool<T>();
  }

  @pragma('vm:prefer-inline')
  void _releasePool(_FramePool<T> pool) {
    if (identical(pool, _pool)) {
      final frames = pool.frames;
      final limit = pool.lastMaxSp;
      for (var k = 0; k < limit; ++k) {
        frames[k].node = null;
      }
      pool.lastMaxSp = 0;
      _poolInUse = false;
    }
  }

  /// The current x-coordinate accessor.
  QuadtreeAccessor<T> get x => _quadtreeGetX(this);

  /// Sets the x-coordinate accessor.
  set x(QuadtreeAccessor<T> accessor) => _quadtreeSetX(this, accessor);

  /// The current y-coordinate accessor.
  QuadtreeAccessor<T> get y => _quadtreeGetY(this);

  /// Sets the y-coordinate accessor.
  set y(QuadtreeAccessor<T> accessor) => _quadtreeSetY(this, accessor);

  /// The current bounding extent `((x0, y0), (x1, y1))`, or `null` if the
  /// quadtree has no extent yet.
  QuadtreeExtent? get extent => _quadtreeGetExtent(this);

  /// Expands the quadtree to cover [value] if non-null.
  set extent(QuadtreeExtent? value) {
    if (value != null) {
      _quadtreeSetExtent(this, value);
    }
  }

  /// Expands the quadtree to cover both corners of [extent] and returns `this`.
  Quadtree<T> setExtent(QuadtreeExtent extent) =>
      _quadtreeSetExtent(this, extent);

  /// Expands the quadtree to cover the point `(x, y)` and returns `this`.
  Quadtree<T> cover(double x, double y) => _quadtreeCover(this, x, y);

  /// Adds [datum] to the quadtree and returns `this`.
  Quadtree<T> add(T datum) => _quadtreeAdd(this, datum);

  /// Adds all elements of [data] to the quadtree, computing their combined
  /// extent first for a more compact tree, and returns `this`.
  Quadtree<T> addAll(Iterable<T> data) => _quadtreeAddAll(this, data);

  /// Removes [datum] from the quadtree if present and returns `this`.
  Quadtree<T> remove(T datum) => _quadtreeRemove(this, datum);

  /// Removes each datum in [data] from the quadtree and returns `this`.
  Quadtree<T> removeAll(Iterable<T> data) => _quadtreeRemoveAll(this, data);

  /// Returns a deep structural copy of this quadtree sharing datum references.
  // DIVERGES(d3-quadtree): adapt-quadtree-fast-forms, direct sealed-node copy
  // with concrete 4-field access and iterative fallback for extreme depths.
  Quadtree<T> copy() {
    final copy = Quadtree<T>._(_x, _y, _x0, _y0, _x1, _y1, _isDefaultPoint);
    final node = _root;
    if (node == null) return copy;
    copy._root = switch (node) {
      QuadtreeLeafNode<T>() => _leafCopy(node),
      QuadtreeInternalNode<T>() => _copyBranch(node, 0),
    };
    return copy;
  }

  /// Returns the root node of this quadtree, or `null` if empty.
  QuadtreeNode<T>? get root => _quadtreeRoot(this);

  /// Returns a list of all data stored in this quadtree.
  List<T> data() => _quadtreeData(this);

  /// Returns the total number of data stored in this quadtree.
  int size() => _quadtreeSize(this);

  /// Returns the datum closest to `(x, y)` within [radius] (defaulting to
  /// `double.infinity`), or `null` if no datum lies within the search radius.
  T? find(double x, double y, [double? radius]) =>
      _quadtreeFind(this, x, y, radius);

  /// Visits each node in pre-order traversal (`nw`, `ne`, `sw`, `se`),
  /// skipping a node's children when [callback] returns `true`, and returns
  /// `this`.
  Quadtree<T> visit(QuadtreeVisitCallback<T> callback) =>
      _quadtreeVisit(this, callback);

  /// Visits each node in post-order traversal and returns `this`.
  Quadtree<T> visitAfter(QuadtreeVisitAfterCallback<T> callback) =>
      _quadtreeVisitAfter(this, callback);
}
