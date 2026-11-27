// Ported from d3-hierarchy v3.1.2 src/hierarchy/sort.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/sort.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-stable-sort, uses stable insertion
// and merge sort so sibling tie-breaking matches ES2019 Array.prototype.sort
// for any child count (Dart's List.sort is not guaranteed stable for n > 32).
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct cast-free typed
// list sorting and allocation-free recursive tree walk for height <= 512.

void _sortBaseRec<T>(
  HierarchyNode<T> node,
  num Function(HierarchyNode<T> a, HierarchyNode<T> b) compare,
) {
  final children = node.children;
  if (children != null) {
    final n = children.length;
    if (n > 1) {
      _stableSort<HierarchyNode<T>>(children, compare);
    }
    for (var i = 0; i < n; ++i) {
      _sortBaseRec<T>(children[i], compare);
    }
  }
}

void _sortRec<T, N extends HierarchyNode<T>>(
  N node,
  num Function(N a, N b) compare,
) {
  final children = node.children;
  if (children != null) {
    final typed = children as List<N>;
    final n = typed.length;
    if (n > 1) {
      _stableSort<N>(typed, compare);
    }
    for (var i = 0; i < n; ++i) {
      _sortRec<T, N>(typed[i], compare);
    }
  }
}

/// Cast-free stable sort on base [HierarchyNode<T>].
HierarchyNode<T> hierarchySortBase<T>(
  HierarchyNode<T> root,
  num Function(HierarchyNode<T> a, HierarchyNode<T> b) compare,
) {
  if (root.height <= 512) {
    _sortBaseRec<T>(root, compare);
    return root;
  }
  final stack = <HierarchyNode<T>>[root];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    final children = node.children;
    if (children != null) {
      final n = children.length;
      if (n > 1) {
        _stableSort<HierarchyNode<T>>(children, compare);
      }
      for (var i = n - 1; i >= 0; --i) {
        stack.add(children[i]);
      }
    }
  }
  return root;
}

/// Sorts the children of [root] and every descendant using [compare],
/// preserving ES2019 sort stability, and returns [root].
N hierarchySort<T, N extends HierarchyNode<T>>(
  N root,
  num Function(N a, N b) compare,
) {
  if (root.height <= 512) {
    _sortRec<T, N>(root, compare);
    return root;
  }
  final stack = <N>[root];
  while (stack.isNotEmpty) {
    final node = stack.removeLast();
    final children = node.children;
    if (children != null) {
      final typed = children as List<N>;
      final n = typed.length;
      if (n > 1) {
        _stableSort<N>(typed, compare);
      }
      for (var i = n - 1; i >= 0; --i) {
        stack.add(typed[i]);
      }
    }
  }
  return root;
}

void _stableSort<N>(List<N> list, num Function(N a, N b) compare) {
  final n = list.length;
  if (n <= 16) {
    for (var i = 1; i < n; ++i) {
      final key = list[i];
      var j = i - 1;
      while (j >= 0 && compare(list[j], key) > 0) {
        list[j + 1] = list[j];
        --j;
      }
      list[j + 1] = key;
    }
    return;
  }
  final scratch = List<N>.of(list, growable: false);
  _mergeSort<N>(scratch, list, 0, n, compare);
}

void _mergeSort<N>(
  List<N> src,
  List<N> dst,
  int start,
  int end,
  num Function(N a, N b) compare,
) {
  final len = end - start;
  if (len <= 16) {
    for (var i = start + 1; i < end; ++i) {
      final key = dst[i];
      var j = i - 1;
      while (j >= start && compare(dst[j], key) > 0) {
        dst[j + 1] = dst[j];
        --j;
      }
      dst[j + 1] = key;
    }
    return;
  }
  final mid = (start + end) >>> 1;
  _mergeSort<N>(dst, src, start, mid, compare);
  _mergeSort<N>(dst, src, mid, end, compare);
  if (compare(src[mid - 1], src[mid]) <= 0) {
    for (var i = start; i < end; ++i) {
      dst[i] = src[i];
    }
    return;
  }
  var i = start;
  var j = mid;
  var k = start;
  while (i < mid && j < end) {
    if (compare(src[i], src[j]) <= 0) {
      dst[k++] = src[i++];
    } else {
      dst[k++] = src[j++];
    }
  }
  while (i < mid) {
    dst[k++] = src[i++];
  }
  while (j < end) {
    dst[k++] = src[j++];
  }
}
