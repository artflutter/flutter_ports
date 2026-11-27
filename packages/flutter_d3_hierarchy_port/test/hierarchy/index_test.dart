// Ported from d3-hierarchy v3.1.2 test/hierarchy/index-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

final class _SetNode(
  final String id, [
  @override final Iterable<_SetNode>? children,
]) implements HierarchyDatum<_SetNode>;

void main() {
  test('d3.hierarchy(data, children) supports iterable children', () {
    final root = hierarchy(
      _SetNode('root', {
        _SetNode('a'),
        _SetNode('b', {_SetNode('ba')}),
      }),
    );
    final a = root.children![0];
    final b = root.children![1];
    final ba = root.children![1].children![0];
    expect(root.links(), [
      (source: root, target: a),
      (source: root, target: b),
      (source: b, target: ba),
    ]);
  });

  test('d3.hierarchy(data, children) ignores non-iterable children', () {
    // DIVERGES(d3-hierarchy): adapt-hierarchy-typed-api, Dart statically
    // requires Iterable<T>? children (non-iterable numeric `42` is a
    // compile-time error; null and empty iterables are ignored).
    final root = hierarchy(
      _SetNode('root', [_SetNode('a'), _SetNode('b', const [])]),
    );
    final a = root.children![0];
    final b = root.children![1];
    expect(root.links(), [
      (source: root, target: a),
      (source: root, target: b),
    ]);
  });
}
