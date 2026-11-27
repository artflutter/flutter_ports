// Ported from d3-hierarchy v3.1.2 test/pack/deterministic-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

void _expectEqualTrees<T>(
  HierarchyCircularNode<T> a,
  HierarchyCircularNode<T> b,
) {
  expect(a.x, b.x);
  expect(a.y, b.y);
  expect(a.r, b.r);
  expect(a.value, b.value);
  expect(a.depth, b.depth);
  expect(a.height, b.height);
  final ac = a.children;
  final bc = b.children;
  if (ac == null) {
    expect(bc, isNull);
  } else {
    expect(bc, isNotNull);
    expect(ac.length, bc!.length);
    for (var i = 0; i < ac.length; ++i) {
      _expectEqualTrees(ac[i], bc[i]);
    }
  }
}

void main() {
  test('pack is deterministic', () {
    final paths = <String>[
      for (final (i, n) in [41, 41, 11, 11, 4, 4].indexed)
        for (var j = 0; j < n; ++j) '/$i/$i-$j',
    ];
    final data = stratifyPath<String>(paths, (d) => d);
    final packer = pack<HierarchyNode<String?>>(
      size: (100, 100),
      paddingConst: 0,
    );
    final pack1 = packer(
      hierarchy<HierarchyNode<String?>>(data, (d) => d.children).count(),
    );
    for (var i = 0; i < 40; ++i) {
      final packI = packer(
        hierarchy<HierarchyNode<String?>>(data, (d) => d.children).count(),
      );
      _expectEqualTrees(packI, pack1);
    }
  });
}
