// Original code, not ported from Chart.js: the simpleArc on dart:ui.
// ignore_for_file: file_names
@TestOn('vm')
library;

// dart:ui: the web legs cannot compile this file. A circular radar with
// `fill: {value: v}` below `min` gets a negative radius from
// `getDistanceFromCenterForValue` (scale.radialLinear.js:489-499). The DOM
// throws an `IndexSizeError` at `arc`, and the canvas layer throws a
// RangeError (canvas/canvas_ui_path.dart). The mock context of Node.js does
// not throw (Chart.js ADR 0040, section 5).

import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/simpleArc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a negative radius throws a RangeError at ctx.arc', () {
    final ctx = UiCanvasElement(width: 50, height: 50).getContext2d();
    final arc = SimpleArc(x: 25, y: 25, radius: -1);
    expect(
      () => arc.pathSegment(ctx, null, <String, Object?>{}),
      throwsA(isA<RangeError>()),
    );
  });

  test('a radius of 0 draws', () {
    final ctx = UiCanvasElement(width: 50, height: 50).getContext2d();
    final arc = SimpleArc(x: 25, y: 25, radius: 0);
    expect(arc.pathSegment(ctx, null, <String, Object?>{}), isTrue);
  });
}
