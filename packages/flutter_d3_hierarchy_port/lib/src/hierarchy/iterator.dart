// Ported from d3-hierarchy v3.1.2 src/hierarchy/iterator.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/iterator.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct FIFO queue
// iterator replacing `sync*` generator and per-level list reversal.

final class _BfsIterator<T, N extends HierarchyNode<T>>(N root)
    implements Iterator<N> {
  final List<N> _queue = <N>[root];
  int _head = 0;
  late N _current;

  @override
  N get current => _current;

  @override
  bool moveNext() {
    if (_head >= _queue.length) return false;
    final node = _queue[_head++];
    _current = node;
    final children = node.children;
    if (children != null) {
      for (var i = 0, n = children.length; i < n; ++i) {
        _queue.add(children[i] as N);
      }
    }
    return true;
  }
}

final class const _BfsIterable<T, N extends HierarchyNode<T>>(final N _root)
    extends Iterable<N> {
  @override
  Iterator<N> get iterator => _BfsIterator<T, N>(_root);
}

/// Returns a breadth-first [Iterable] over [root] and all its descendants.
Iterable<N> hierarchyIterable<T, N extends HierarchyNode<T>>(N root) =>
    _BfsIterable<T, N>(root);

/// Returns a breadth-first [Iterator] over [root] and all its descendants.
Iterator<N> hierarchyIterator<T, N extends HierarchyNode<T>>(N root) =>
    _BfsIterator<T, N>(root);
