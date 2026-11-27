// Ported from d3-hierarchy v3.1.2 test/pack/flare-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

import '../port/test_data.dart';

double _round(double x) => (x * 100).roundToDouble() / 100;

void _expectPackTree(
  HierarchyCircularNode<FlareCsvRow> actual,
  ExpectedPackNode expected,
) {
  final id = actual.data.id;
  final name = id.substring(id.lastIndexOf('.') + 1);
  expect(name, expected.name);
  expect(actual.value, expected.value, reason: 'value for $id');
  expect(_round(actual.x), expected.x, reason: 'x for $id');
  expect(_round(actual.y), expected.y, reason: 'y for $id');
  expect(_round(actual.r), expected.r, reason: 'r for $id');
  final ac = actual.children;
  final ec = expected.children;
  if (ec == null) {
    expect(ac, isNull, reason: 'leaf $id');
  } else {
    expect(ac, isNotNull, reason: 'children for $id');
    expect(ac!.length, ec.length, reason: 'children length for $id');
    for (var i = 0; i < ec.length; ++i) {
      _expectPackTree(ac[i], ec[i]);
    }
  }
}

void main() {
  test('pack(flare) produces the expected result', () {
    final stratifier = stratify<FlareCsvRow>(
      id: (d) => d.id,
      parentId: (d) {
        final i = d.id.lastIndexOf('.');
        return i >= 0 ? d.id.substring(0, i) : null;
      },
    );
    final packer = pack<FlareCsvRow>(size: (960, 960));
    final root = stratifier(flareCsvData)
      ..sum((d) => d.value)
      ..sort((a, b) {
        final dv = (b.value ?? 0) - (a.value ?? 0);
        return dv != 0 ? dv : a.data.id.compareTo(b.data.id);
      });
    final actual = packer(root);
    _expectPackTree(actual, flarePackExpected);
  });
}
