// Ported from d3-hierarchy v3.1.2 src/stratify.js (ISC, Mike Bostock).

/// Port of `src/stratify.js` of d3-hierarchy 3.1.2: [StratifyDatum],
/// [StratifyOperator], [stratify], and [stratifyPath].
library;

import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, typed StratifyDatum
// interface, StratifyOperator<T> with 1-arg and 3-arg accessors, and sound
// null-safe `callPath` / `stratifyPath` returning `HierarchyNode<T?>` for
// imputed internal nodes.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, single-pass depth/height
// BFS assignment, integer-indexed path table eliminating imputed-node HashMap,
// and `codeUnitAt` path scanning.

/// Interface implemented by tabular rows exposing default [id] and [parentId]
/// fields for [stratify].
abstract interface class StratifyDatum() {
  /// Unique identifier of this row, or `null` for an anonymous leaf.
  String? get id;

  /// Identifier of this row's parent, or `null` / `''` for the root.
  String? get parentId;
}

/// 1-argument string identifier accessor for [StratifyOperator].
typedef StratifyAccessor<T> = String? Function(T d);

/// 3-argument indexed string identifier accessor for [StratifyOperator].
typedef StratifyIndexedAccessor<T> = String? Function(
  T d,
  int index,
  Iterable<T> data,
);

/// 1-argument slash-delimited path accessor for [StratifyOperator].
typedef StratifyPathAccessor<T> = String Function(T d);

/// 3-argument indexed path accessor for [StratifyOperator].
typedef StratifyPathIndexedAccessor<T> = String Function(
  T d,
  int index,
  Iterable<T> data,
);

String? _defaultId<T>(T d) => d is StratifyDatum ? d.id : null;

String? _defaultParentId<T>(T d) => d is StratifyDatum ? d.parentId : null;

final class const _AmbiguousMarker();

const _AmbiguousMarker _ambiguous = _AmbiguousMarker();

/// Assigns `depth` and `height` to every reachable node from [root] in a
/// single BFS + reverse-BFS pass and verifies no unreachable cycle remains.
void _finalizeTree<T>(HierarchyNode<T> root, int expectedCount) {
  root.depth = 0;
  final order = <HierarchyNode<T>>[root];
  var head = 0;
  while (head < order.length) {
    final node = order[head++];
    final children = node.children;
    if (children != null) {
      final nextDepth = node.depth + 1;
      for (var i = 0, n = children.length; i < n; ++i) {
        final child = children[i]..depth = nextDepth;
        order.add(child);
      }
    }
  }
  if (order.length < expectedCount) throw StateError('cycle');
  for (var i = order.length - 1; i > 0; --i) {
    final node = order[i];
    final parent = node.parent!;
    final h = node.height + 1;
    if (h > parent.height) parent.height = h;
  }
}

/// Converts flat tabular data into a [HierarchyNode] tree via `id`/`parentId`
/// links or slash-delimited `path` strings.
final class StratifyOperator<T>({
  StratifyAccessor<T>? id,
  StratifyIndexedAccessor<T>? idIndexed,
  StratifyAccessor<T>? parentId,
  StratifyIndexedAccessor<T>? parentIdIndexed,
  StratifyPathAccessor<T>? path,
  StratifyPathIndexedAccessor<T>? pathIndexed,
}) {
  /// Creates a [StratifyOperator] with optional accessors.
  this;

  StratifyAccessor<T>? _id = id ?? (idIndexed == null ? _defaultId<T> : null);
  StratifyIndexedAccessor<T>? _idIndexed = idIndexed;
  StratifyAccessor<T>? _parentId =
      parentId ?? (parentIdIndexed == null ? _defaultParentId<T> : null);
  StratifyIndexedAccessor<T>? _parentIdIndexed = parentIdIndexed;
  StratifyPathAccessor<T>? _path = path;
  StratifyPathIndexedAccessor<T>? _pathIndexed = pathIndexed;

  /// Current 1-argument `id` accessor, or `null`.
  StratifyAccessor<T>? get id => _id;

  /// Sets the 1-argument `id` accessor (clears [idIndexed]).
  set id(StratifyAccessor<T>? value) {
    _id = value;
    _idIndexed = null;
  }

  /// Current 3-argument indexed `id` accessor, or `null`.
  StratifyIndexedAccessor<T>? get idIndexed => _idIndexed;

  /// Sets the 3-argument indexed `id` accessor (clears [id]).
  set idIndexed(StratifyIndexedAccessor<T>? value) {
    _idIndexed = value;
    _id = null;
  }

  /// Current 1-argument `parentId` accessor, or `null`.
  StratifyAccessor<T>? get parentId => _parentId;

  /// Sets the 1-argument `parentId` accessor (clears [parentIdIndexed]).
  set parentId(StratifyAccessor<T>? value) {
    _parentId = value;
    _parentIdIndexed = null;
  }

  /// Current 3-argument indexed `parentId` accessor, or `null`.
  StratifyIndexedAccessor<T>? get parentIdIndexed => _parentIdIndexed;

  /// Sets the 3-argument indexed `parentId` accessor (clears [parentId]).
  set parentIdIndexed(StratifyIndexedAccessor<T>? value) {
    _parentIdIndexed = value;
    _parentId = null;
  }

  /// Current 1-argument `path` accessor, or `null`.
  StratifyPathAccessor<T>? get path => _path;

  /// Sets the 1-argument `path` accessor (clears [pathIndexed]).
  set path(StratifyPathAccessor<T>? value) {
    _path = value;
    _pathIndexed = null;
  }

  /// Current 3-argument indexed `path` accessor, or `null`.
  StratifyPathIndexedAccessor<T>? get pathIndexed => _pathIndexed;

  /// Sets the 3-argument indexed `path` accessor (clears [path]).
  set pathIndexed(StratifyPathIndexedAccessor<T>? value) {
    _pathIndexed = value;
    _path = null;
  }

  /// Stratifies [data] into a [HierarchyNode<T>].
  ///
  /// When [path] or [pathIndexed] is configured and missing ancestor nodes are
  /// imputed, `T` must be nullable (or call [callPath] to receive
  /// `HierarchyNode<T?>` directly).
  HierarchyNode<T> call(Iterable<T> data) {
    if (_path != null || _pathIndexed != null) {
      return _stratifyByPathNonNull(data);
    }
    return _stratifyByIds(data);
  }

  /// Stratifies [data] using the configured [path] / [pathIndexed] accessor,
  /// returning `HierarchyNode<T?>` where imputed internal nodes have
  /// `data == null`.
  HierarchyNode<T?> callPath(Iterable<T> data) {
    if (_path == null && _pathIndexed == null) {
      throw StateError('stratify.callPath requires a path accessor');
    }
    return _stratifyByPathNullable(data);
  }

  HierarchyNode<T> _stratifyByIds(Iterable<T> data) {
    final items = data is List<T> ? data : List<T>.of(data);
    final n = items.length;
    if (n == 0) throw StateError('no root');
    final nodes = List<HierarchyNode<T>?>.filled(n, null);
    final parentIds = List<String?>.filled(n, null);
    final nodeByKey = HashMap<String, Object>();
    final idFn = _id;
    final idIdxFn = _idIndexed;
    final pidFn = _parentId;
    final pidIdxFn = _parentIdIndexed;

    for (var i = 0; i < n; ++i) {
      final d = items[i];
      final nodeId = idIdxFn != null
          ? idIdxFn(d, i, data)
          : (idFn != null ? idFn(d) : null);
      final node = HierarchyNode<T>(d);
      nodes[i] = node;
      if (nodeId != null && nodeId.isNotEmpty) {
        node.id = nodeId;
        final existing = nodeByKey[nodeId];
        nodeByKey[nodeId] = existing == null ? node : _ambiguous;
      }
      final parentId = pidIdxFn != null
          ? pidIdxFn(d, i, data)
          : (pidFn != null ? pidFn(d) : null);
      if (parentId != null && parentId.isNotEmpty) {
        parentIds[i] = parentId;
      }
    }

    HierarchyNode<T>? root;
    for (var i = 0; i < n; ++i) {
      final node = nodes[i]!;
      final pid = parentIds[i];
      if (pid != null) {
        final parentEntry = nodeByKey[pid];
        if (parentEntry == null) throw StateError('missing: $pid');
        if (identical(parentEntry, _ambiguous)) {
          throw StateError('ambiguous: $pid');
        }
        final parent = parentEntry as HierarchyNode<T>;
        final children = parent.children;
        if (children != null) {
          children.add(node);
        } else {
          parent.children = <HierarchyNode<T>>[node];
        }
        node.parent = parent;
      } else {
        if (root != null) throw StateError('multiple roots');
        root = node;
      }
    }

    if (root == null) throw StateError('no root');
    _finalizeTree<T>(root, n);
    return root;
  }

  HierarchyNode<T?> _stratifyByPathNullable(Iterable<T> data) {
    final items = data is List<T> ? data : List<T>.of(data);
    final originalCount = items.length;
    if (originalCount == 0) throw StateError('no root');
    final pathFn = _path;
    final pathIdxFn = _pathIndexed;

    final ids = <String>[
      for (var i = 0; i < originalCount; ++i)
        _normalizePath(
          pathIdxFn != null ? pathIdxFn(items[i], i, data) : pathFn!(items[i]),
        ),
    ];
    final parents = <String>[for (final id in ids) _parentOfPath(id)];
    final indexByKey = HashMap<String, int>();
    for (var i = 0; i < originalCount; ++i) {
      final id = ids[i];
      final existing = indexByKey[id];
      indexByKey[id] = existing == null ? i : -1;
    }

    for (var i = 0; i < parents.length; ++i) {
      final p = parents[i];
      if (p.isNotEmpty && !indexByKey.containsKey(p)) {
        final idx = ids.length;
        indexByKey[p] = idx;
        ids.add(p);
        parents.add(_parentOfPath(p));
      }
    }

    final total = ids.length;
    final nodes = List<HierarchyNode<T?>?>.filled(total, null);
    for (var i = 0; i < total; ++i) {
      final nodeId = ids[i];
      nodes[i] = HierarchyNode<T?>(
        i < originalCount ? items[i] : null,
        id: nodeId.isNotEmpty ? nodeId : null,
      );
    }

    final firstChildIdx = Int32List(total)..fillRange(0, total, -1);
    var rootIdx = -1;
    for (var i = 0; i < total; ++i) {
      final node = nodes[i]!;
      final pid = parents[i];
      if (pid.isNotEmpty) {
        final pIdx = indexByKey[pid];
        if (pIdx == null) throw StateError('missing: $pid');
        if (pIdx < 0) throw StateError('ambiguous: $pid');
        final parent = nodes[pIdx]!;
        final children = parent.children;
        if (children != null) {
          children.add(node);
        } else {
          parent.children = <HierarchyNode<T?>>[node];
          firstChildIdx[pIdx] = i;
        }
        node.parent = parent;
      } else {
        if (rootIdx >= 0) throw StateError('multiple roots');
        rootIdx = i;
      }
    }

    if (rootIdx < 0) throw StateError('no root');

    var remaining = total;
    while (rootIdx >= originalCount) {
      final children = nodes[rootIdx]!.children;
      if (children != null && children.length == 1) {
        rootIdx = firstChildIdx[rootIdx];
        nodes[rootIdx]!.parent = null;
        --remaining;
      } else {
        break;
      }
    }

    final root = nodes[rootIdx]!;
    _finalizeTree<T?>(root, remaining);
    return root;
  }

  HierarchyNode<T> _stratifyByPathNonNull(Iterable<T> data) {
    final nullableRoot = _stratifyByPathNullable(data);
    return _retypeNullableTree<T>(nullableRoot);
  }
}

HierarchyNode<T> _retypeNullableTree<T>(HierarchyNode<T?> source) {
  T unwrap(T? d, String? id) {
    if (d is T) return d;
    throw StateError(
      'stratify().path imputed an internal node (${id ?? ''}) with null data; '
      'use stratify<T?>() or callPath(data) instead.',
    );
  }

  final root = HierarchyNode<T>(
    unwrap(source.data, source.id),
    depth: source.depth,
    height: source.height,
    value: source.value,
    id: source.id,
  );
  final srcStack = <HierarchyNode<T?>>[source];
  final dstStack = <HierarchyNode<T>>[root];
  while (srcStack.isNotEmpty) {
    final s = srcStack.removeLast();
    final d = dstStack.removeLast();
    final sc = s.children;
    if (sc != null && sc.isNotEmpty) {
      final n = sc.length;
      final dc = List<HierarchyNode<T>>.generate(n, (i) {
        final child = sc[i];
        return HierarchyNode<T>(
          unwrap(child.data, child.id),
          depth: child.depth,
          height: child.height,
          parent: d,
          value: child.value,
          id: child.id,
        );
      });
      d.children = dc;
      for (var i = n - 1; i >= 0; --i) {
        srcStack.add(sc[i]);
        dstStack.add(dc[i]);
      }
    }
  }
  return root;
}

/// Creates a new [StratifyOperator<T>].
StratifyOperator<T> stratify<T>({
  StratifyAccessor<T>? id,
  StratifyIndexedAccessor<T>? idIndexed,
  StratifyAccessor<T>? parentId,
  StratifyIndexedAccessor<T>? parentIdIndexed,
  StratifyPathAccessor<T>? path,
  StratifyPathIndexedAccessor<T>? pathIndexed,
}) => StratifyOperator<T>(
  id: id,
  idIndexed: idIndexed,
  parentId: parentId,
  parentIdIndexed: parentIdIndexed,
  path: path,
  pathIndexed: pathIndexed,
);

/// Convenience helper that stratifies [data] by slash-delimited [path],
/// returning `HierarchyNode<T?>` (with `data == null` for imputed internal
/// nodes).
HierarchyNode<T?> stratifyPath<T>(
  Iterable<T> data,
  StratifyPathAccessor<T> path,
) => StratifyOperator<T>(path: path).callPath(data);

String _normalizePath(String path) {
  var p = path;
  final i = p.length;
  if (_isUnescapedSlash(p, i - 1) && !_isUnescapedSlash(p, i - 2)) {
    p = p.substring(0, i - 1);
  }
  return p.isNotEmpty && p.codeUnitAt(0) == 0x2F ? p : '/$p';
}

String _parentOfPath(String path) {
  var i = path.length;
  if (i < 2) return '';
  while (--i > 1) {
    if (_isUnescapedSlash(path, i)) break;
  }
  return path.substring(0, i);
}

bool _isUnescapedSlash(String path, int i) {
  if (i >= 0 && i < path.length && path.codeUnitAt(i) == 0x2F) {
    var k = 0;
    var j = i;
    while (j > 0 && path.codeUnitAt(--j) == 0x5C) {
      ++k;
    }
    if ((k & 1) == 0) return true;
  }
  return false;
}
