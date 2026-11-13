// Ported from Chart.js v4.6.1 src/helpers/helpers.canvas.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.canvas.ts`.
///
/// The functions draw on the canvas interface of `lib/src/canvas/canvas.dart`
/// (porting-flow.md 2.2): the `dart:ui` context of `canvas_ui.dart` in an
/// app, the mock context of `chartjs_test_utils` in the specs. This file
/// stays a pure layer: it reaches neither `dart:ui` nor `package:flutter`,
/// and it does not import `canvas_ui.dart`.
///
/// Upstream `_`-prefixed exports drop the underscore (Chart.js ADR 0012):
/// `_measureText` is [measureText], `_longestText` is [longestText],
/// `_alignPixel` is [alignPixel], `_isPointInArea` is [isPointInArea],
/// `_steppedLineTo` is [steppedLineTo] and `_bezierCurveTo` is
/// [bezierCurveTo]. The functions that upstream does not export
/// (`setRenderOpts`, `decorateText`, `drawBackdrop`) are private.
library;

import 'dart:math' as math;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isArray, isNullOrUndef;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show halfPi, pi, quarterPi, radPerDeg, tau, twoThirdsPi;
import 'package:flutter_chartjs_port/src/helpers/point_style.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsRound;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart';
import 'package:flutter_chartjs_port/src/types/line_option_enums.dart'
    show SteppedLine;

// DIVERGES(chartjs): adapt-text-style-fonts, helpers.canvas.ts:25
// `toFontString` is gone: the canvas takes the ChartTextStyle itself.

/// helpers.canvas.ts:39 `_measureText`.
///
/// @private
///
/// [data] is the JS object `Record<string, number>` of the measured widths,
/// keyed by text. [gc] lists the texts in the order of their measurement.
/// `core.scale.js:837` passes the `{data, gc}` cache of one font.
///
/// A width of 0 (an empty text) is falsy, so the text is measured and
/// listed again, as upstream does.
double measureText(
  CanvasRenderingContext2D ctx,
  Map<String, double> data,
  List<String> gc,
  double longest,
  String string,
) {
  // DIVERGES(chartjs): adapt-measure-text-proto, no Object.prototype keys.
  var textWidth = data[string];
  if (!jsTruthy(textWidth)) {
    textWidth = data[string] = ctx.measureText(string).width;
    gc.add(string);
  }
  if (textWidth! > longest) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    longest = textWidth;
  }
  return longest;
}

/// helpers.canvas.ts:68 the inline type of the `cache` parameter of
/// `_longestText`: `{data?, garbageCollect?, font?}`.
///
/// Upstream passes a JS object, and `_longestText` writes its three
/// properties. Here it is a class with three fields. Dart `null` stands for
/// an absent property, JS `undefined`. The spec passes `{}`, which is
/// `LongestTextCache()`.
final class LongestTextCache {
  /// An empty cache, the JS object `{}`.
  LongestTextCache();

  /// `data?: Record<string, number>`: the measured widths, keyed by text.
  Map<String, double>? data;

  /// `garbageCollect?: string[]`: the measured texts, in order.
  List<String>? garbageCollect;

  /// `font?: string`: the font of [data], a `TextStyle` (row
  /// `adapt-text-style-fonts`).
  TextStyle? font;
}

/// helpers.canvas.ts:64 `_longestText`.
///
/// @private
///
/// [arrayOfThings] is the upstream `Things`, `(Thing | Thing[])[]` with
/// `Thing = string | undefined | null`. An item is a `String`, a `List` of
/// such values, Dart `null` or the `undefined` sentinel. An item of another
/// type (a number label) is measured as its `ToString` ([jsToString]): upstream
/// passes it to `ctx.measureText`, which converts it, and uses it as a
/// property key of `data`, which converts it the same way.
///
/// A null [cache] is the absent argument: upstream makes a new `{}`.
///
/// Upstream compares `cache.font !== font`. On a new cache, `cache.font` is
/// `undefined`, and a JS `null` [font] differs from it. Here a null [font]
/// equals the null of a new cache. The result is the same: a new cache has
/// no data to drop. [font] is a `TextStyle`, compared with `==` (row
/// `adapt-text-style-fonts`).
double longestText(
  CanvasRenderingContext2D ctx,
  TextStyle? font,
  List<Object?> arrayOfThings, [
  LongestTextCache? cache,
]) {
  // `cache || {}`: a cache object is truthy.
  cache ??= LongestTextCache();
  // `cache.data || {}` and `cache.garbageCollect || []`: an object and an
  // array are truthy.
  var data = cache.data ??= {};
  var gc = cache.garbageCollect ??= [];

  if (cache.font != font) {
    data = cache.data = {};
    gc = cache.garbageCollect = [];
    cache.font = font;
  }

  ctx
    ..save()
    ..font = font;
  var longest = 0.0;
  final ilen = arrayOfThings.length;
  int i;
  for (i = 0; i < ilen; i++) {
    final thing = arrayOfThings[i];

    // Undefined strings and arrays should not be measured
    if (!isNullOrUndef(thing) && !isArray(thing)) {
      longest = measureText(ctx, data, gc, longest, jsToString(thing));
    } else if (isArray(thing)) {
      // if it is an array lets measure each element
      // to do maybe simplify this function a bit so we can do this more
      // recursively?
      final things = thing! as List<Object?>;
      for (var j = 0, jlen = things.length; j < jlen; j++) {
        final nestedThing = things[j];
        // Undefined strings and arrays should not be measured
        if (!isNullOrUndef(nestedThing) && !isArray(nestedThing)) {
          longest = measureText(
            ctx,
            data,
            gc,
            longest,
            jsToString(nestedThing),
          );
        }
      }
    }
  }

  ctx.restore();

  // An odd length gives a fraction. The loop then deletes one more key than
  // `splice` removes from `gc`, whose `deleteCount` truncates the fraction.
  final gcLen = gc.length / 2;
  if (gcLen > arrayOfThings.length) {
    for (i = 0; i < gcLen; i++) {
      data.remove(gc[i]);
    }
    // gcLen is finite and positive: toInt() truncates it, as the
    // ToIntegerOrInfinity of `splice` does.
    gc.removeRange(0, gcLen.toInt());
  }
  return longest;
}

/// helpers.canvas.ts:125 `_alignPixel`.
///
/// Returns the aligned pixel value to avoid anti-aliasing blur
/// @param chart - The chart instance.
/// @param pixel - A pixel value.
/// @param width - The width of the element.
/// @returns The aligned pixel value.
/// @private
///
/// `Math.round` is [jsRound]: the result places the grid lines and ticks.
double alignPixel(Chart chart, double pixel, double width) {
  final devicePixelRatio = chart.currentDevicePixelRatio;
  final halfWidth = width != 0 ? jsMax(width / 2, 0.5) : 0.0;
  return jsRound((pixel - halfWidth) * devicePixelRatio) / devicePixelRatio +
      halfWidth;
}

/// helpers.canvas.ts:134 `clearCanvas`.
///
/// Clears the entire canvas.
///
/// A null [canvas] or [ctx] is an absent argument or JS `null`. As upstream,
/// a [ctx] without a [canvas] throws (a `TypeError` in JS, at
/// `canvas.width`). [HTMLCanvasElement.width] is an `int`, the DOM
/// attribute, so it converts to a `double` for `clearRect`.
void clearCanvas([HTMLCanvasElement? canvas, CanvasRenderingContext2D? ctx]) {
  if (ctx == null && canvas == null) {
    return;
  }

  ctx ??= canvas!.getContext('2d');

  ctx!
    ..save()
    // canvas.width and canvas.height do not consider the canvas transform,
    // while clearRect does
    ..resetTransform()
    ..clearRect(0, 0, canvas!.width.toDouble(), canvas.height.toDouble())
    ..restore();
}

/// helpers.canvas.ts:149 `DrawPointOptions`.
///
/// `element.point.ts:99` passes the resolved options of a point, and
/// `plugin.legend.js:328` and `plugin.tooltip.js:808` pass an object
/// literal. Their ports implement this interface.
abstract interface class DrawPointOptions {
  /// helpers.canvas.ts:150 `pointStyle: PointStyle`.
  ///
  /// `PointStyle` (index.d.ts:2040) is the union of ten style names, of
  /// `false`, and of `HTMLImageElement` and `HTMLCanvasElement`. In the
  /// port, the value is a [PointStyle] or `false` (row
  /// `adapt-point-style-objects`): the ten classes below, [ImagePointStyle]
  /// for an image, or a style of an app or a plugin. Another value draws a
  /// circle, as upstream does for a value that is not a style. A canvas
  /// element is no image: pass its `toImageSource()` snapshot to
  /// [ImagePointStyle] (`platform-canvas-point-style`, differences.md).
  Object? get pointStyle;

  /// helpers.canvas.ts:151 `rotation?: number`, in degrees. Dart `null` is
  /// JS `undefined`. A falsy value is no rotation.
  double? get rotation;

  /// helpers.canvas.ts:152 `radius: number`. A value that is not a number
  /// is NaN (its `ToNumber`), which draws nothing.
  double get radius;

  /// helpers.canvas.ts:153 `borderWidth: number`. A value that is not a
  /// number is NaN, which strokes nothing.
  double get borderWidth;
}

/// helpers.canvas.ts:156 `drawPoint`.
void drawPoint(
  CanvasRenderingContext2D ctx,
  DrawPointOptions options,
  double x,
  double y,
) {
  drawPointLegend(ctx, options, x, y, null);
}

/// helpers.canvas.ts:167 `drawPointLegend`.
///
/// [w] is the width of the point style in the legend
/// (`plugin.legend.js:336` passes `labelOpts.pointStyleWidth && boxWidth`).
/// Dart `null` stands for JS `null` and `undefined`. A falsy [w] (null, 0 or
/// NaN) draws the style with [DrawPointOptions.radius] alone.
///
/// Upstream switches on the style name, and draws an image for an image
/// value. In the port, a [PointStyle] draws itself ([PointStyle.draw]): the
/// code of each `case` is the `addPath` of its class below, and the image
/// branch is [ImagePointStyle]. `false` and a value that is not a style
/// keep the upstream lines: the radius test, then the `case false` or the
/// default circle.
// DIVERGES(chartjs): adapt-point-style-objects, the style draws itself.
void drawPointLegend(
  CanvasRenderingContext2D ctx,
  DrawPointOptions options,
  double x,
  double y,
  double? w,
) {
  final style = options.pointStyle;
  final rotation = options.rotation;
  final radius = options.radius;
  final rad = (jsTruthy(rotation) ? rotation! : 0) * radPerDeg;
  final width = jsTruthy(w) ? w : null;

  if (PointStyle.of(style) case final pointStyle?) {
    pointStyle.draw(
      ctx,
      x: x,
      y: y,
      radius: radius,
      rad: rad,
      rotated: jsTruthy(rotation),
      width: width,
      borderWidth: options.borderWidth,
    );
    return;
  }

  // `isNaN(radius)`: radius is a number, so ToNumber changes nothing.
  if (radius.isNaN || radius <= 0) {
    return;
  }

  ctx.beginPath();

  if (style == false) {
    ctx.closePath();
  } else {
    // Default includes circle
    // DIVERGES(chartjs): platform-canvas-point-style, a canvas is no style.
    _circlePath(ctx, x, y, radius, width);
  }

  ctx.fill();
  if (options.borderWidth > 0) {
    ctx.stroke();
  }
}

/// The `default` branch of helpers.canvas.ts:196-203: the circle, or an
/// ellipse of the legend width [w].
void _circlePath(
  CanvasRenderingContext2D ctx,
  double x,
  double y,
  double radius,
  double? w,
) {
  if (w != null) {
    ctx.ellipse(x, y, w / 2, radius, 0, 0, tau);
  } else {
    ctx.arc(x, y, radius, 0, tau);
  }
  ctx.closePath();
}

/// The `case 'rectRot'` of helpers.canvas.ts:238-247, also the end of a
/// rotated `rect`.
void _rectRotPath(
  CanvasRenderingContext2D ctx,
  double x,
  double y,
  double radius,
  double rad,
  double? w,
) {
  final xOffsetW = math.cos(rad) * (w != null ? w / 2 : radius);
  final xOffset = math.cos(rad) * radius;
  final yOffset = math.sin(rad) * radius;
  final yOffsetW = math.sin(rad) * (w != null ? w / 2 : radius);
  ctx
    ..moveTo(x - xOffsetW, y - yOffset)
    ..lineTo(x + yOffsetW, y - xOffset)
    ..lineTo(x + xOffsetW, y + yOffset)
    ..lineTo(x - yOffsetW, y + xOffset)
    ..closePath();
}

/// The `case 'cross'` of helpers.canvas.ts:252-261, also the end of
/// `crossRot` and each half of `star`.
void _crossPath(
  CanvasRenderingContext2D ctx,
  double x,
  double y,
  double radius,
  double rad,
  double? w,
) {
  final xOffsetW = math.cos(rad) * (w != null ? w / 2 : radius);
  final xOffset = math.cos(rad) * radius;
  final yOffset = math.sin(rad) * radius;
  final yOffsetW = math.sin(rad) * (w != null ? w / 2 : radius);
  ctx
    ..moveTo(x - xOffsetW, y - yOffset)
    ..lineTo(x + xOffsetW, y + yOffset)
    ..moveTo(x + yOffsetW, y - xOffset)
    ..lineTo(x - yOffsetW, y + xOffset);
}

/// `pointStyle: 'circle'` (index.d.ts:2040), the default of a point: a
/// circle, or an ellipse of the legend width.
final class CirclePointStyle extends PathPointStyle {
  /// The circle.
  const CirclePointStyle();

  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) => _circlePath(ctx, x, y, radius, width);
}

/// `pointStyle: 'triangle'` (helpers.canvas.ts:204-212).
final class TrianglePointStyle extends PathPointStyle {
  /// The triangle.
  const TrianglePointStyle();

  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) {
    final w = width != null ? width / 2 : radius;
    var r = rad;
    ctx.moveTo(x + math.sin(r) * w, y - math.cos(r) * radius);
    r += twoThirdsPi;
    ctx.lineTo(x + math.sin(r) * w, y - math.cos(r) * radius);
    r += twoThirdsPi;
    ctx
      ..lineTo(x + math.sin(r) * w, y - math.cos(r) * radius)
      ..closePath();
  }
}

/// `pointStyle: 'rectRounded'` (helpers.canvas.ts:213-230).
final class RectRoundedPointStyle extends PathPointStyle {
  /// The square with round corners.
  const RectRoundedPointStyle();

  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) {
    // NOTE: the rounded rect implementation changed to use `arc` instead
    // of `quadraticCurveTo` since it generates better results when rect
    // is almost a circle. 0.516 (instead of 0.5) produces results with
    // visually closer proportion to the previous impl and it is inscribed
    // in the circle with `radius`. For more details, see the following
    // PRs:
    // https://github.com/chartjs/Chart.js/issues/5597
    // https://github.com/chartjs/Chart.js/issues/5858
    final cornerRadius = radius * 0.516;
    final size = radius - cornerRadius;
    final xOffset = math.cos(rad + quarterPi) * size;
    final xOffsetW =
        math.cos(rad + quarterPi) *
        (width != null ? width / 2 - cornerRadius : size);
    final yOffset = math.sin(rad + quarterPi) * size;
    final yOffsetW =
        math.sin(rad + quarterPi) *
        (width != null ? width / 2 - cornerRadius : size);
    ctx
      ..arc(x - xOffsetW, y - yOffset, cornerRadius, rad - pi, rad - halfPi)
      ..arc(x + yOffsetW, y - xOffset, cornerRadius, rad - halfPi, rad)
      ..arc(x + xOffsetW, y + yOffset, cornerRadius, rad, rad + halfPi)
      ..arc(x - yOffsetW, y + xOffset, cornerRadius, rad + halfPi, rad + pi)
      ..closePath();
  }
}

/// `pointStyle: 'rect'` (helpers.canvas.ts:231-237): a square, or the
/// `rectRot` path turned by a quarter of pi when the rotation is truthy
/// (the fall-through of upstream).
final class RectPointStyle extends PathPointStyle {
  /// The square.
  const RectPointStyle();

  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) {
    if (!rotated) {
      final size = math.sqrt1_2 * radius;
      final w = width != null ? width / 2 : size;
      ctx.rect(x - w, y - size, 2 * w, 2 * size);
      return;
    }
    /* falls through */
    _rectRotPath(ctx, x, y, radius, rad + quarterPi, width);
  }
}

/// `pointStyle: 'rectRot'` (helpers.canvas.ts:238-247): a square turned by
/// a quarter of pi.
final class RectRotPointStyle extends PathPointStyle {
  /// The turned square.
  const RectRotPointStyle();

  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) => _rectRotPath(ctx, x, y, radius, rad, width);
}

/// `pointStyle: 'crossRot'` (helpers.canvas.ts:248-251): the cross turned
/// by a quarter of pi (the fall-through of upstream).
final class CrossRotPointStyle extends PathPointStyle {
  /// The turned cross.
  const CrossRotPointStyle();

  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) {
    /* falls through */
    _crossPath(ctx, x, y, radius, rad + quarterPi, width);
  }
}

/// `pointStyle: 'cross'` (helpers.canvas.ts:252-261).
final class CrossPointStyle extends PathPointStyle {
  /// The cross.
  const CrossPointStyle();

  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) => _crossPath(ctx, x, y, radius, rad, width);
}

/// `pointStyle: 'star'` (helpers.canvas.ts:262-281): a cross and the cross
/// turned by a quarter of pi.
final class StarPointStyle extends PathPointStyle {
  /// The star.
  const StarPointStyle();

  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) {
    _crossPath(ctx, x, y, radius, rad, width);
    _crossPath(ctx, x, y, radius, rad + quarterPi, width);
  }
}

/// `pointStyle: 'line'` (helpers.canvas.ts:282-287).
final class LinePointStyle extends PathPointStyle {
  /// The line.
  const LinePointStyle();

  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) {
    final xOffset = width != null ? width / 2 : math.cos(rad) * radius;
    final yOffset = math.sin(rad) * radius;
    ctx
      ..moveTo(x - xOffset, y - yOffset)
      ..lineTo(x + xOffset, y + yOffset);
  }
}

/// `pointStyle: 'dash'` (helpers.canvas.ts:288-291).
final class DashPointStyle extends PathPointStyle {
  /// The dash.
  const DashPointStyle();

  @override
  void addPath(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
  }) {
    ctx
      ..moveTo(x, y)
      ..lineTo(
        x + math.cos(rad) * (width != null ? width / 2 : radius),
        y + math.sin(rad) * radius,
      );
  }
}

/// An image as the point style (helpers.canvas.ts:179-187): `pointStyle`
/// with an `HTMLImageElement` or an `HTMLCanvasElement` upstream. The image
/// draws at its own size, centered and turned by the rotation, with no fill
/// and no stroke, also for a radius of 0.
final class ImagePointStyle extends PointStyle {
  /// The style that draws [image].
  const ImagePointStyle(this.image);

  /// The image.
  final CanvasImageSource image;

  @override
  void draw(
    CanvasRenderingContext2D ctx, {
    required double x,
    required double y,
    required double radius,
    required double rad,
    required bool rotated,
    required double? width,
    required double borderWidth,
  }) {
    ctx
      ..save()
      ..translate(x, y)
      ..rotate(rad)
      ..drawImage(
        image,
        -image.width / 2,
        -image.height / 2,
        image.width,
        image.height,
      )
      ..restore();
  }
}

/// helpers.canvas.ts:317 `_isPointInArea`.
///
/// Returns true if the point is inside the rectangle
/// @param point - The point to test
/// @param area - The rectangle
/// @param margin - allowed margin
/// @private
///
/// A null [point] or [area] stands for a falsy JavaScript value: `null` or
/// `undefined`. A null [margin] stands for `undefined`. A null `point.x` or
/// `point.y` is JS `null`, which the relational operators make 0: the port
/// writes `point.x ?? 0` (Chart.js ADR 0045).
///
/// Upstream returns `point` itself when `point` is falsy and [area] is not.
/// Here the result is `false` (`adapt-point-in-area-bool`, differences.md).
/// Every caller reads the result as a boolean (`core.controller.js:817`,
/// `core.interaction.js:122`, `scale.radialLinear.js:171-172`,
/// `element.point.ts:92`, `helpers.curve.ts:163-167`), and `ToBoolean` of a
/// falsy value is `false`.
bool isPointInArea(Point? point, TRBL? area, [double? margin]) {
  // Upstream reassigns its parameter.
  // ignore: parameter_assignments
  margin = margin == null || margin == 0 || margin.isNaN
      ? 0.5
      : margin; // margin - default is to match rounded decimals

  return area == null ||
      // DIVERGES(chartjs): adapt-point-in-area-bool, false for a falsy point.
      (point != null &&
          (point.x ?? 0) > area.left - margin &&
          (point.x ?? 0) < area.right + margin &&
          (point.y ?? 0) > area.top - margin &&
          (point.y ?? 0) < area.bottom + margin);
}

/// helpers.canvas.ts:328 `clipArea`.
void clipArea(CanvasRenderingContext2D ctx, TRBL area) {
  ctx
    ..save()
    ..beginPath()
    ..rect(area.left, area.top, area.right - area.left, area.bottom - area.top)
    ..clip();
}

/// helpers.canvas.ts:335 `unclipArea`.
void unclipArea(CanvasRenderingContext2D ctx) {
  ctx.restore();
}

/// helpers.canvas.ts:342 `_steppedLineTo`.
///
/// @private
///
/// [ctx] is a [CanvasPath], not a [CanvasRenderingContext2D]: upstream
/// declares the context, but `element.line.js:89` also passes a `Path2D`
/// (`strokePathWithCache`, `element.line.js:203`). Both implement
/// [CanvasPath] here.
///
/// A null [previous] stands for JS `undefined`, the `prev` of the first
/// point of a segment. A null [flip] is JS `undefined`. [mode] is the
/// `stepped` option value (`element.line.js:89`): `true` or a [SteppedLine]
/// (row `adapt-stepped-line-enum`). A null coordinate is JS `null`, which
/// `ToNumber` makes 0 (Chart.js ADR 0045).
void steppedLineTo(
  CanvasPath ctx,
  Point? previous,
  Point target, [
  bool? flip,
  Object? mode,
]) {
  if (previous == null) {
    return ctx.lineTo(target.x ?? 0, target.y ?? 0);
  }
  // DIVERGES(chartjs): adapt-stepped-line-enum, the enum values.
  if (mode == SteppedLine.middle) {
    final midpoint = ((previous.x ?? 0) + (target.x ?? 0)) / 2.0;
    ctx
      ..lineTo(midpoint, previous.y ?? 0)
      ..lineTo(midpoint, target.y ?? 0);
  } else if ((mode == SteppedLine.after) != (flip ?? false)) {
    ctx.lineTo(previous.x ?? 0, target.y ?? 0);
  } else {
    ctx.lineTo(target.x ?? 0, previous.y ?? 0);
  }
  ctx.lineTo(target.x ?? 0, target.y ?? 0);
}

/// helpers.canvas.ts:367 `_bezierCurveTo`.
///
/// @private
///
/// [ctx] is a [CanvasPath], as for [steppedLineTo]. A null [previous] is JS
/// `undefined`, and a null [flip] is JS `undefined`. A control point that
/// was never set is NaN (`adapt-spline-control-point-nan`), which the
/// context ignores, as the DOM ignores `undefined` (ToNumber NaN).
void bezierCurveTo(
  CanvasPath ctx,
  SplinePoint? previous,
  SplinePoint target, [
  bool? flip,
]) {
  if (previous == null) {
    return ctx.lineTo(target.x, target.y);
  }
  final reverse = flip ?? false;
  ctx.bezierCurveTo(
    reverse ? previous.cp1x : previous.cp2x,
    reverse ? previous.cp1y : previous.cp2y,
    reverse ? target.cp2x : target.cp1x,
    reverse ? target.cp2y : target.cp1y,
    target.x,
    target.y,
  );
}

/// helpers.canvas.ts:385 `setRenderOpts`.
void _setRenderOpts(CanvasRenderingContext2D ctx, RenderTextOpts opts) {
  // An array is truthy, so a non-null record is.
  final translation = opts.translation;
  if (translation != null) {
    ctx.translate(translation.$1, translation.$2);
  }

  final rotation = opts.rotation;
  if (!isNullOrUndef(rotation)) {
    ctx.rotate(rotation!);
  }

  // A paint is truthy. Without one, the fill style stays.
  final fillStyle = opts.color;
  ctx.fillStyle = fillStyle;

  if (jsTruthy(opts.textAlign)) {
    ctx.textAlign = opts.textAlign;
  }

  if (jsTruthy(opts.textBaseline)) {
    ctx.textBaseline = opts.textBaseline;
  }
}

/// helpers.canvas.ts:407 `decorateText`.
void _decorateText(
  CanvasRenderingContext2D ctx,
  double x,
  double y,
  String line,
  RenderTextOpts opts,
) {
  if (jsTruthy(opts.strikethrough) || jsTruthy(opts.underline)) {
    /**
     * Now that IE11 support has been dropped, we can use more
     * of the TextMetrics object. The actual bounding boxes
     * are unflagged in Chrome, Firefox, Edge, and Safari so they
     * can be safely used.
     * See https://developer.mozilla.org/en-US/docs/Web/API/TextMetrics#Browser_compatibility
     */
    final metrics = ctx.measureText(line);
    final left = x - metrics.actualBoundingBoxLeft;
    final right = x + metrics.actualBoundingBoxRight;
    final top = y - metrics.actualBoundingBoxAscent;
    final bottom = y + metrics.actualBoundingBoxDescent;
    final yDecoration = jsTruthy(opts.strikethrough)
        ? (top + bottom) / 2
        : bottom;

    ctx
      ..strokeStyle = ctx.fillStyle
      ..beginPath()
      ..lineWidth = jsTruthy(opts.decorationWidth) ? opts.decorationWidth : 2
      ..moveTo(left, yDecoration)
      ..lineTo(right, yDecoration)
      ..stroke();
  }
}

/// helpers.canvas.ts:438 `drawBackdrop`.
void _drawBackdrop(CanvasRenderingContext2D ctx, BackdropOptions opts) {
  final oldColor = ctx.fillStyle;

  ctx
    // The setter keeps the fill style for Dart `null`, the value of
    // `ChartPaint.unchanged`.
    ..fillStyle = opts.color
    ..fillRect(opts.left, opts.top, opts.width, opts.height)
    ..fillStyle = oldColor;
}

/// helpers.canvas.ts:449 `renderText`.
///
/// Render text onto the canvas
///
/// [text] is the union `string | string[]`: a `String` or a `List`. The DOM
/// converts the text argument of `fillText`, `strokeText` and `measureText`
/// with `ToString`. Here [jsToString] converts each line, so a number line
/// draws as JS draws it.
///
/// [font] is a [ChartTextStyle] (row `adapt-text-style-fonts`): the canvas
/// takes it as its font, and each line advances by its
/// [ChartTextStyle.lineHeight].
void renderText(
  CanvasRenderingContext2D ctx,
  Object? text,
  double x,
  double y,
  ChartTextStyle font, [
  // The JS object `{}`, the default of helpers.canvas.ts:455.
  RenderTextOpts opts = const RenderTextOpts(),
]) {
  final lines = isArray(text) ? text! as List<Object?> : [text];
  final strokeWidth = opts.strokeWidth;
  // `undefined > 0` and `NaN > 0` are false.
  // DIVERGES(chartjs): adapt-direct-colors, a paint is never the string ''.
  final stroke = strokeWidth != null && strokeWidth > 0;
  final strokeStyle = opts.strokeColor;
  int i;
  String line;

  ctx
    ..save()
    // DIVERGES(chartjs): adapt-text-style-fonts, the font is a ChartTextStyle.
    ..font = font;
  _setRenderOpts(ctx, opts);

  for (i = 0; i < lines.length; ++i) {
    line = jsToString(lines[i]);

    final backdrop = opts.backdrop;
    if (backdrop != null) {
      _drawBackdrop(ctx, backdrop);
    }

    if (stroke) {
      ctx.strokeStyle = strokeStyle;

      if (!isNullOrUndef(opts.strokeWidth)) {
        ctx.lineWidth = opts.strokeWidth;
      }

      ctx.strokeText(line, x, y, opts.maxWidth);
    }

    ctx.fillText(line, x, y, opts.maxWidth);
    _decorateText(ctx, x, y, line, opts);

    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    y += font.lineHeight!;
  }

  ctx.restore();
}

/// helpers.canvas.ts:498 `addRoundedRectPath`.
///
/// Add a path of a rectangle with rounded corners to the current sub-path
/// @param ctx - Context
/// @param rect - Bounding rect
///
/// Upstream types [rect] as `RoundedRect & { radius: TRBLCorners }`. Dart
/// has no intersection type, so the function takes a [RoundedRect] and
/// reads its radius as a [TRBLCorners]. Every caller passes one (see
/// [RoundedRect]).
///
/// Upstream adds four arcs and four lines (helpers.canvas.ts:504-526). The
/// port makes one `roundRect` call with the four radii, which the `dart:ui`
/// canvas adds as one rounded rectangle and fills with `drawRRect` (the
/// performance rule of porting-flow.md §1.1, differences.md
/// `adapt-rounded-rect-path`). The fill and clip area is the same.
void addRoundedRectPath(CanvasRenderingContext2D ctx, RoundedRect rect) {
  final RoundedRect(:x, :y, :w, :h) = rect;
  final radius = rect.radius! as TRBLCorners;

  // DIVERGES(chartjs): adapt-rounded-rect-path, one roundRect call.
  ctx.roundRect(x, y, w, h, [
    radius.topLeft,
    radius.topRight,
    radius.bottomRight,
    radius.bottomLeft,
  ]);
}
