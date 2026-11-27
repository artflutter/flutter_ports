// Ported from d3-hierarchy v3.1.2 test/pack/enclose-test.js (ISC, Mike Bostock).

import 'package:flutter_d3_hierarchy_port/d3_hierarchy.dart';
import 'package:test/test.dart';

void main() {
  // https://github.com/d3/d3-hierarchy/issues/188
  test('packEnclose(circles) handles a tricky case', () {
    final result = packEnclose([
      PackCircle(x: 14.5, y: 48.5, r: 7.585),
      PackCircle(x: 9.5, y: 79.5, r: 2.585),
      PackCircle(x: 15.5, y: 73.5, r: 8.585),
    ])!;
    expect(result.r, closeTo(20.790781637717107, 1e-12));
    expect(result.x, closeTo(12.80193548387092, 1e-12));
    expect(result.y, closeTo(61.59615384615385, 1e-12));
  });
}
