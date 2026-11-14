// Ported from d3-color v3.1.0 test/gray-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('gray(l[, opacity]) is an alias for lab(l, 0, 0[, opacity])', () {
    assertLabEqual(gray(120), 120, 0, 0, 1);
    assertLabEqual(gray(120, 0.5), 120, 0, 0, 0.5);
    // `gray(120, null)` and `gray(120, undefined)`: an omitted opacity is 1.
    assertLabEqual(gray(120), 120, 0, 0, 1);
    assertLabEqual(gray(120), 120, 0, 0, 1);
  });
}
