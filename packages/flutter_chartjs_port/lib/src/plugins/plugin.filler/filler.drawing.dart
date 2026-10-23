// Ported from Chart.js v4.5.1+7169e651 src/plugins/plugin.filler/filler.drawing.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.filler/filler.drawing.js`.
///
/// `filler.drawing.js` imports no element module and not `simpleArc`. It
/// calls `segments`, `points`, `pathSegment`, `interpolate` and `first` of a
/// fill target by name. The port reads them through the interfaces
/// `types.LineElement` and `types.SimpleArc`, and another target throws a
/// [TypeError] (Chart.js ADR 0040, section 4, the difference
/// `adapt-filler-target-classes`).
///
/// This library is a pure layer (Chart.js ADR 0038, section 9).
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CanvasPath, CanvasRenderingContext2D;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show clipArea, unclipArea;
import 'package:flutter_chartjs_port/src/helpers/helpers.dataset.dart'
    show getDatasetClipArea;
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsToString, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart' show canvasStyle;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.segment.dart'
    show findSegmentEnd, getBounds, segments;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/filler.target.dart'
    show getTarget;
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart'
    show FillerSource;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// filler.drawing.js:5 `_drawfill(ctx, source, area)`.
///
/// Dart `null` for [area] is the `undefined` chart area of a chart without
/// a layout. A cartesian index scale then throws a [TypeError] in
/// [clipToIndexBounds], as upstream. A radial index scale throws the
/// [TypeError] at the `!` before `clipArea`: upstream `clipArea` first calls
/// `ctx.save()` and `ctx.beginPath()` and then throws at `area.left`
/// (Chart.js ADR 0040, section 8).
void drawfill(
  CanvasRenderingContext2D ctx,
  FillerSource source,
  types.ChartArea? area,
) {
  final target = getTarget(source);
  final chart = source.chart;
  final index = source.index;
  final line = source.line;
  final scale = source.scale;
  final axis = source.axis;
  final lineOpts = line.options;
  final fillOption = jsGet(lineOpts, 'fill');
  final color = jsGet(lineOpts, 'backgroundColor');
  // `{above = color, below = color} = fillOption || {}`: the defaults apply
  // only to `undefined`.
  final above = _orDefault(
    jsTruthy(fillOption) ? jsGet(fillOption, 'above') : undefined,
    color,
  );
  final below = _orDefault(
    jsTruthy(fillOption) ? jsGet(fillOption, 'below') : undefined,
    color,
  );
  final meta = chart.getDatasetMeta(index);
  final clip = getDatasetClipArea(chart, meta);
  if (jsTruthy(target) && line.points.isNotEmpty) {
    // DIVERGES(chartjs): adapt-filler-target-classes, a null area throws here.
    clipArea(ctx, clipToIndexBounds(area, meta.iScale)!);
    _doFill(
      ctx,
      line: line,
      target: target!,
      above: above,
      below: below,
      area: area!,
      scale: scale,
      axis: axis,
      clip: clip,
    );
    unclipArea(ctx);
  }
}

/// [value], or [defaultValue] for the [undefined] sentinel: the default of
/// a JS destructuring.
Object? _orDefault(Object? value, Object? defaultValue) =>
    identical(value, undefined) ? defaultValue : value;

/// filler.drawing.js:25 `clipToIndexBounds(area, iScale)` (#12283).
///
/// The line's stroke is limited to the index scale's min/max pixel bounds
/// (see LineController#update -> _getStartAndCountOfVisiblePoints). Clip the
/// fill to the same bounds so it doesn't extend past the stroke when
/// `offset: true` insets tick pixels from the chart area edges.
///
/// Dart `null` for [area] and for the result is the `undefined` area of a
/// chart without a layout. The spread `{...area, left, right}` is a [_Trbl]:
/// `clipArea` reads only `left`, `top`, `right` and `bottom`
/// (helpers.canvas.ts:328-333). It is not an export of upstream. The tests
/// read it.
@visibleForTesting
types.TRBL? clipToIndexBounds(types.ChartArea? area, types.Scale? iScale) {
  // Radial scales (e.g. radar charts) aren't cartesian: min/max pixels
  // don't correspond to a left/right or top/bottom bound.
  if (iScale == null || iScale is types.RadialLinearScale) {
    return area;
  }
  final p1 = iScale.getPixelForValue(iScale.min);
  final p2 = iScale.getPixelForValue(iScale.max);
  final lo = jsMin(p1, p2);
  final hi = jsMax(p1, p2);
  return iScale.isHorizontal()
      ? _Trbl(
          top: area!.top,
          right: jsMin(area.right, hi),
          bottom: area.bottom,
          left: jsMax(area.left, lo),
        )
      : _Trbl(
          top: jsMax(area!.top, lo),
          right: area.right,
          bottom: jsMin(area.bottom, hi),
          left: area.left,
        );
}

/// The object `{...area, left, right}` or `{...area, top, bottom}` of
/// filler.drawing.js:36-37.
final class _Trbl implements types.TRBL {
  const _Trbl({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  final double left;
}

/// The property key of `cfg.axis` (filler.drawing.js:42): the String
/// itself, else its `ToString`.
String _axisKey(Object? axis) => axis is String ? axis : jsToString(axis);

/// filler.drawing.js:40 `doFill(ctx, cfg)`. The keys of `cfg` are named
/// parameters.
void _doFill(
  CanvasRenderingContext2D ctx, {
  required types.LineElement line,
  required Object target,
  required Object? above,
  required Object? below,
  required types.ChartArea area,
  required types.Scale? scale,
  required Object? axis,
  required types.TRBL? clip,
}) {
  final property = (line.loop ?? false) ? 'angle' : _axisKey(axis);

  ctx.save();

  var fillColor = below;
  if (below != above) {
    if (property == 'x') {
      _clipVertical(ctx, target, area.top);
      _fill(
        ctx,
        line: line,
        target: target,
        color: above,
        scale: scale,
        property: property,
        clip: clip,
      );
      ctx
        ..restore()
        ..save();
      _clipVertical(ctx, target, area.bottom);
    } else if (property == 'y') {
      _clipHorizontal(ctx, target, area.left);
      _fill(
        ctx,
        line: line,
        target: target,
        color: below,
        scale: scale,
        property: property,
        clip: clip,
      );
      ctx
        ..restore()
        ..save();
      _clipHorizontal(ctx, target, area.right);
      fillColor = above;
    }
  }
  _fill(
    ctx,
    line: line,
    target: target,
    color: fillColor,
    scale: scale,
    property: property,
    clip: clip,
  );

  ctx.restore();
}

/// filler.drawing.js:68 `clipVertical(ctx, target, clipY)`.
///
/// `const {segments, points} = target` reads the members of a
/// `types.LineElement`, else Dart `null`. The loop over `segments!` then
/// throws a [TypeError] for `true` and for a `SimpleArc`, after
/// `ctx.beginPath()`, as `for (const segment of undefined)` does.
/// `target.first()` is Dart `null` for the `0` of a line without segments:
/// `(0).x` is `undefined`, and `lineTo(undefined, clipY)` is
/// `lineTo(NaN, clipY)` (Chart.js ADR 0040, section 7).
void _clipVertical(CanvasRenderingContext2D ctx, Object target, double clipY) {
  // DIVERGES(chartjs): adapt-filler-target-classes, the target classes.
  final line = target is types.LineElement ? target : null;
  final segments = line?.segments;
  final points = line?.points;
  var first = true;
  var lineLoop = false;

  ctx.beginPath();
  for (final segment in segments!) {
    final start = segment.start;
    final end = segment.end;
    final firstPoint = points![start.toInt()];
    final lastPoint = points[findSegmentEnd(start, end, points).toInt()];
    if (first) {
      ctx.moveTo(firstPoint.x, firstPoint.y);
      first = false;
    } else {
      ctx
        ..lineTo(firstPoint.x, clipY)
        ..lineTo(firstPoint.x, firstPoint.y);
    }
    lineLoop =
        line!.pathSegment(ctx, segment, <String, Object?>{'move': lineLoop}) ==
        true;
    if (lineLoop) {
      ctx.closePath();
    } else {
      ctx.lineTo(lastPoint.x, clipY);
    }
  }

  ctx
    ..lineTo(line!.first()?.x ?? double.nan, clipY)
    ..closePath()
    ..clip();
}

/// filler.drawing.js:98 `clipHorizontal(ctx, target, clipX)`. See
/// [_clipVertical].
void _clipHorizontal(
  CanvasRenderingContext2D ctx,
  Object target,
  double clipX,
) {
  // DIVERGES(chartjs): adapt-filler-target-classes, the target classes.
  final line = target is types.LineElement ? target : null;
  final segments = line?.segments;
  final points = line?.points;
  var first = true;
  var lineLoop = false;

  ctx.beginPath();
  for (final segment in segments!) {
    final start = segment.start;
    final end = segment.end;
    final firstPoint = points![start.toInt()];
    final lastPoint = points[findSegmentEnd(start, end, points).toInt()];
    if (first) {
      ctx.moveTo(firstPoint.x, firstPoint.y);
      first = false;
    } else {
      ctx
        ..lineTo(clipX, firstPoint.y)
        ..lineTo(firstPoint.x, firstPoint.y);
    }
    lineLoop =
        line!.pathSegment(ctx, segment, <String, Object?>{'move': lineLoop}) ==
        true;
    if (lineLoop) {
      ctx.closePath();
    } else {
      ctx.lineTo(clipX, lastPoint.y);
    }
  }

  ctx
    ..lineTo(clipX, line!.first()?.y ?? double.nan)
    ..closePath()
    ..clip();
}

/// filler.drawing.js:128 `fill(ctx, cfg)`. The keys of `cfg` are named
/// parameters. The local `segments` of upstream is `parts`: the name
/// `segments` is the function of `filler.segment.dart`.
void _fill(
  CanvasRenderingContext2D ctx, {
  required types.LineElement line,
  required Object target,
  required String property,
  required Object? color,
  required types.Scale? scale,
  required types.TRBL? clip,
}) {
  final parts = segments(line, target, property);

  for (final (source: src, target: tgt, :start, :end) in parts) {
    // `const {style: {backgroundColor = color} = {}} = src`.
    final style = src.style;
    final backgroundColor = style == null
        ? color
        : _orDefault(jsGet(style, 'backgroundColor'), color);
    final notShape = target != true;

    ctx
      ..save()
      ..fillStyle = canvasStyle(backgroundColor);

    _clipBounds(
      ctx,
      scale,
      clip,
      notShape ? getBounds(property, start, end) : null,
    );

    ctx.beginPath();

    final lineLoop = line.pathSegment(ctx, src) == true;

    bool? loop;
    if (notShape) {
      if (lineLoop) {
        ctx.closePath();
      } else {
        interpolatedLineTo(ctx, target, end, property);
      }

      final targetLoop =
          _pathSegment(ctx, target, tgt, <String, Object?>{
            'move': lineLoop,
            'reverse': true,
          }) ==
          true;
      loop = lineLoop && targetLoop;
      if (!loop) {
        interpolatedLineTo(ctx, target, start, property);
      }
    }

    ctx
      ..closePath()
      ..fill((loop ?? false) ? 'evenodd' : 'nonzero')
      ..restore();
  }
}

/// `target.pathSegment(ctx, tgt, params)` (filler.drawing.js:153).
///
/// A `types.LineElement` gets the segment [tgt]. A `types.SimpleArc` gets
/// the bounds record [tgt], or Dart `null` for `undefined`. Another target
/// throws a [TypeError], as the call of the missing member `pathSegment`
/// does upstream (Chart.js ADR 0040, section 4).
// DIVERGES(chartjs): adapt-filler-target-classes, the target classes.
bool? _pathSegment(
  CanvasPath ctx,
  Object target,
  Object? tgt,
  AnyObject params,
) => switch (target) {
  final types.LineElement line => line.pathSegment(
    ctx,
    tgt! as types.Segment,
    params,
  ),
  final types.SimpleArc arc => arc.pathSegment(
    ctx,
    tgt as ({String property, double start, double end})?,
    params,
  ),
  _ => throw TypeError(),
};

/// filler.drawing.js:167 `clipBounds(ctx, scale, clip, bounds)`.
///
/// Dart `null` for [bounds] is the `false` of `notShape && _getBounds(...)`
/// and the `undefined` of a loop: `bounds || {}` has no `property`. Dart
/// `null` for [scale] throws the [TypeError] of `scale.chart` of
/// `undefined`. The chart area is read only for a property `x` or `y`: Dart
/// `null` throws the [TypeError] of `chartArea.top` of `undefined`.
void _clipBounds(
  CanvasRenderingContext2D ctx,
  types.Scale? scale,
  types.TRBL? clip,
  ({String property, double start, double end})? bounds,
) {
  final chartArea = scale!.chart.chartArea;
  final property = bounds?.property;

  if (property == 'x' || property == 'y') {
    double left;
    double top;
    double right;
    double bottom;

    if (property == 'x') {
      left = bounds!.start;
      top = chartArea!.top;
      right = bounds.end;
      bottom = chartArea.bottom;
    } else {
      left = chartArea!.left;
      top = bounds!.start;
      right = chartArea.right;
      bottom = bounds.end;
    }

    ctx.beginPath();

    if (clip != null) {
      left = jsMax(left, clip.left);
      right = jsMin(right, clip.right);
      top = jsMax(top, clip.top);
      bottom = jsMin(bottom, clip.bottom);
    }

    ctx
      ..rect(left, top, right - left, bottom - top)
      ..clip();
  }
}

/// filler.drawing.js:200 `interpolatedLineTo(ctx, target, point, property)`.
///
/// A `types.LineElement` gives Dart `null`, one point or a `List` of
/// points. A `types.SimpleArc` gives one point. Another target throws a
/// [TypeError] (Chart.js ADR 0040, section 4). A point calls `lineTo` with
/// the `ToNumber` of its members (`?? 0` for JS `null`). A `List` calls
/// `lineTo(NaN, NaN)`: an Array has no `x` and `y`, and the WebIDL
/// conversion of `undefined` is NaN. Dart `null` makes no call. It is not
/// an export of upstream. The tests read it.
@visibleForTesting
void interpolatedLineTo(
  CanvasRenderingContext2D ctx,
  Object target,
  types.PointElement point,
  String property,
) {
  // DIVERGES(chartjs): adapt-filler-target-classes, the target classes.
  final interpolatedPoint = switch (target) {
    final types.LineElement line => line.interpolate(point, property),
    final types.SimpleArc arc => arc.interpolate(point),
    _ => throw TypeError(),
  };
  switch (interpolatedPoint) {
    case null:
      return;
    case final types.Point p:
      ctx.lineTo(p.x ?? 0, p.y ?? 0);
    default:
      ctx.lineTo(double.nan, double.nan);
  }
}
