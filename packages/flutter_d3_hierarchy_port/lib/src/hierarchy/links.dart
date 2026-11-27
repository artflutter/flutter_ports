// Ported from d3-hierarchy v3.1.2 src/hierarchy/links.js (ISC, Mike Bostock).

/// Port of `src/hierarchy/links.js` of d3-hierarchy 3.1.2.
library;

import 'package:flutter_d3_hierarchy_port/src/hierarchy/index.dart';

// DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, returns typed Dart
// records `({N source, N target})` instead of untyped JS `{source, target}`.
// DIVERGES(d3-hierarchy): adapt-hierarchy-fast-forms, direct flat FIFO BFS
// link collection without `each` closure or `sync*` generator.

/// Returns a list of `(source: parent, target: child)` links for [root].
List<({N source, N target})> hierarchyLinks<T, N extends HierarchyNode<T>>(
  N root,
) {
  final links = <({N source, N target})>[];
  final queue = <N>[root];
  var head = 0;
  while (head < queue.length) {
    final node = queue[head++];
    if (head > 1) {
      links.add((source: node.parent! as N, target: node));
    }
    final children = node.children;
    if (children != null) {
      for (var i = 0, n = children.length; i < n; ++i) {
        queue.add(children[i] as N);
      }
    }
  }
  return links;
}
