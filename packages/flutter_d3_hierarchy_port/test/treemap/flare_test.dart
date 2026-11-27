// Ported from d3-hierarchy v3.1.2 test/treemap/flare-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

import '../port/test_data.dart';

double _round(double x) => (x * 100).roundToDouble() / 100;

void _expectTreemapTree(
  HierarchyRectangularNode<FlareCsvRow> actual,
  ExpectedTreemapNode expected,
) {
  final id = actual.data.id;
  final name = id.substring(id.lastIndexOf('.') + 1);
  expect(name, expected.name);
  expect(actual.depth, expected.depth, reason: 'depth for $id');
  expect(actual.value, expected.value, reason: 'value for $id');
  expect(_round(actual.x0), expected.x0, reason: 'x0 for $id');
  expect(_round(actual.y0), expected.y0, reason: 'y0 for $id');
  expect(_round(actual.x1), expected.x1, reason: 'x1 for $id');
  expect(_round(actual.y1), expected.y1, reason: 'y1 for $id');
  final ac = actual.children;
  final ec = expected.children;
  if (ec == null) {
    expect(ac, isNull, reason: 'leaf $id');
  } else {
    expect(ac, isNotNull, reason: 'children for $id');
    expect(ac!.length, ec.length, reason: 'children length for $id');
    for (var i = 0; i < ec.length; ++i) {
      _expectTreemapTree(ac[i], ec[i]);
    }
  }
}

void _runFlareTest(
  ExpectedTreemapNode expected,
  TreemapTile<FlareCsvRow> tile,
) {
  final stratifier = stratify<FlareCsvRow>(
    id: (d) => d.id,
    parentId: (d) {
      final i = d.id.lastIndexOf('.');
      return i >= 0 ? d.id.substring(0, i) : null;
    },
  );
  final treemapper = treemap<FlareCsvRow>(tile: tile, size: (960, 500));
  final root = stratifier(flareCsvData)
    ..sum((d) => d.value)
    ..sort((a, b) {
      final dv = (b.value ?? 0) - (a.value ?? 0);
      return dv != 0 ? dv : a.data.id.compareTo(b.data.id);
    });
  final actual = treemapper(root);
  _expectTreemapTree(actual, expected);
}

void main() {
  test(
    'treemap(flare) produces the expected result with a squarified ratio of φ',
    () => _runFlareTest(flarePhiExpected, treemapSquarify.call),
  );

  test(
    'treemap(flare) produces the expected result with a squarified ratio of 1',
    () => _runFlareTest(flareOneExpected, treemapSquarify.ratio(1).call),
  );
}
