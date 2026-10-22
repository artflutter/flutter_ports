// Original code, not ported from Chart.js: upstream rounded rect paths.

/// The upstream form of `addRoundedRectPath`, for the tests that compare it
/// with the port.
///
/// Upstream adds four arcs and four lines (helpers.canvas.ts:498-527 at
/// v4.5.1). The port makes one `roundRect` call (differences.md
/// `adapt-rounded-rect-path`). The tests keep this copy of the upstream
/// lines to compare the two forms: the recorded calls, translated back, and
/// the pixels of the `dart:ui` canvas.
library;

import 'dart:math' as math;

import 'package:chartjs_test_utils/pure.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';

/// helpers.canvas.ts:504-526: the four arcs and four lines of the rectangle
/// (x, y, w, h) with the corner radii of `TRBLCorners`.
void upstreamRoundedRectPath(
  CanvasPath ctx,
  double x,
  double y,
  double w,
  double h, {
  required double topLeft,
  required double topRight,
  required double bottomRight,
  required double bottomLeft,
}) {
  ctx
    // top left arc
    ..arc(x + topLeft, y + topLeft, topLeft, 1.5 * math.pi, math.pi, true)
    // line from top left to bottom left
    ..lineTo(x, y + h - bottomLeft)
    // bottom left arc
    ..arc(
      x + bottomLeft,
      y + h - bottomLeft,
      bottomLeft,
      math.pi,
      math.pi / 2,
      true,
    )
    // line from bottom left to bottom right
    ..lineTo(x + w - bottomRight, y + h)
    // bottom right arc
    ..arc(
      x + w - bottomRight,
      y + h - bottomRight,
      bottomRight,
      math.pi / 2,
      0,
      true,
    )
    // line from bottom right to top right
    ..lineTo(x + w, y + topRight)
    // top right arc
    ..arc(x + w - topRight, y + topRight, topRight, 0, -math.pi / 2, true)
    // line from top right to top left
    ..lineTo(x + topLeft, y);
}

/// Replays the `roundRect(x, y, w, h, radii)` call of `addRoundedRectPath`
/// on [ctx] as the upstream arcs and lines: the translation of the row
/// `adapt-rounded-rect-path` back into the upstream calls. [radii] is the
/// list `[topLeft, topRight, bottomRight, bottomLeft]` that
/// `addRoundedRectPath` passes.
void replayRoundRectAsUpstream(
  CanvasPath ctx,
  double x,
  double y,
  double w,
  double h,
  Object? radii,
) {
  final corners = radii! as List<Object?>;
  upstreamRoundedRectPath(
    ctx,
    x,
    y,
    w,
    h,
    topLeft: corners[0]! as double,
    topRight: corners[1]! as double,
    bottomRight: corners[2]! as double,
    bottomLeft: corners[3]! as double,
  );
}

/// A [MockContext] that records each `roundRect` call as the upstream calls
/// of `addRoundedRectPath` ([replayRoundRectAsUpstream]), so that its
/// records compare with an upstream run (differences.md
/// `adapt-rounded-rect-path`).
final class UpstreamRoundedRectContext extends MockContext {
  @override
  void roundRect(double x, double y, double w, double h, [Object? radii]) =>
      replayRoundRectAsUpstream(this, x, y, w, h, radii);
}
