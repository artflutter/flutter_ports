// Ported from d3-color v3.1.0 test/lch-test.js (ISC, Mike Bostock).
import 'package:flutter_d3_color_port/d3_color.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  test('lch(color) is equivalent to hcl(color)', () {
    assertHclEqual(
      Hcl.parse('#abc'),
      252.37145234745182,
      11.223567114593477,
      74.96879980931759,
      1,
    );
    assertHclEqual(
      Hcl.from(Rgb.parse('#abc')),
      252.37145234745182,
      11.223567114593477,
      74.96879980931759,
      1,
    );
  });

  test('lch(l, c, h[, opacity]) is equivalent to hcl(h, c, l[, opacity])', () {
    assertHclEqual(lch(74, 11, 252), 252, 11, 74, 1);
    assertHclEqual(lch(74, 11, 252), 252, 11, 74, 1);
    // `lch(74, 11, 252, null)`: an omitted opacity is 1.
    assertHclEqual(lch(74, 11, 252), 252, 11, 74, 1);
    // `lch(74, 11, 252, undefined)`: an omitted opacity is 1.
    assertHclEqual(lch(74, 11, 252), 252, 11, 74, 1);
    assertHclEqual(lch(74, 11, 252, 0.5), 252, 11, 74, 0.5);
  });
}
