// Ported from d3-shape v3.2.0 test/symbols-test.js (ISC, Mike Bostock).
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter_d3_shape_port/d3_shape.dart';
import 'package:test/test.dart';

void main() {
  test('symbols is a deprecated alias for symbolsFill', () {
    expect(symbols, same(symbolsFill));
  });

  test('symbolsFill is the array of symbol types', () {
    expect(symbolsFill, [
      symbolCircle,
      symbolCross,
      symbolDiamond,
      symbolSquare,
      symbolStar,
      symbolTriangle,
      symbolWye,
    ]);
  });

  test('symbolsStroke is the array of symbol types', () {
    expect(symbolsStroke, [
      symbolCircle,
      symbolPlus,
      symbolTimes,
      symbolTriangle2,
      symbolAsterisk,
      symbolSquare2,
      symbolDiamond2,
    ]);
  });
}
