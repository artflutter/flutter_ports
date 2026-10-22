// Ported from Chart.js v4.5.1+7169e651 src/plugins/plugin.filler/simpleArc.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names

/// Port of `src/plugins/plugin.filler/simpleArc.js`.
///
/// [SimpleArc] is the class `simpleArc`, the fill target of a radar chart
/// on a circular grid (`filler.target.js:81-88`). It implements the
/// port-only interface `types.SimpleArc`, which `filler.drawing.dart`
/// dispatches on (Chart.js ADR 0040, sections 4 and 5). It does not
/// implement `types.LineElement`: `_segments` (filler.segment.js:15) takes
/// the `simpleArc` branch for it.
///
/// This library is a pure layer (Chart.js ADR 0038, section 9).
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart' show CanvasPath;
import 'package:flutter_chartjs_port/src/helpers/helpers.interpolation.dart'
    show InterpolatedPoint;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart' show tau;
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// simpleArc.js:4 `class simpleArc`.
///
/// simpleArc.js:3: "TODO: use elements.ArcElement instead".
final class SimpleArc implements types.SimpleArc {
  /// simpleArc.js:5 `constructor(opts)`. The keys `x`, `y` and `radius` of
  /// `opts` are named parameters.
  SimpleArc({required this.x, required this.y, required this.radius});

  /// simpleArc.js:6 `this.x = opts.x`.
  final double x;

  /// simpleArc.js:7 `this.y = opts.y`.
  final double y;

  /// simpleArc.js:8 `this.radius = opts.radius`.
  final double radius;

  /// simpleArc.js:11 `pathSegment(ctx, bounds, opts)`.
  ///
  /// Dart `null` for [bounds] is JS `undefined`, and `bounds ||
  /// {start: 0, end: TAU}` gives the full circle. A negative [radius] throws
  /// at `ctx.arc`, as the DOM throws an `IndexSizeError` (Chart.js ADR 0040,
  /// section 5).
  @override
  bool pathSegment(
    CanvasPath ctx,
    ({String property, double start, double end})? bounds,
    AnyObject opts,
  ) {
    ctx.arc(x, y, radius, bounds?.end ?? tau, bounds?.start ?? 0, true);
    return !jsTruthy(jsGet(opts, 'bounds'));
  }

  /// simpleArc.js:18 `interpolate(point)`.
  ///
  /// `point.angle` is the read by name of `PointElementProperty`: NaN for
  /// the `undefined` state, as `Math.cos(undefined)` is NaN. The upstream
  /// result also has `angle`. Its only reader reads `x` and `y`
  /// (filler.drawing.js:203).
  @override
  InterpolatedPoint interpolate(types.PointElement point) {
    final angle = point['angle'];
    return InterpolatedPoint(
      // js-ok: display only, the value reaches ctx.lineTo (Chart.js ADR 0034).
      x + math.cos(angle) * radius,
      // js-ok: display only, the value reaches ctx.lineTo (Chart.js ADR 0034).
      y + math.sin(angle) * radius,
    );
  }
}
