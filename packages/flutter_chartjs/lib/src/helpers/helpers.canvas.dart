// Ported from Chart.js v4.5.1 src/helpers/helpers.canvas.ts (MIT, Chart.js Contributors).

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

import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isArray, isNullOrUndef;
import 'package:flutter_chartjs/src/helpers/helpers.math.dart'
    show halfPi, pi, quarterPi, radPerDeg, tau, twoThirdsPi;
import 'package:flutter_chartjs/src/js/js_math.dart' show jsMax, jsRound;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_chartjs/src/types/index.dart';

/// helpers.canvas.ts:25 `toFontString`.
///
/// Converts the given font object into a CSS font string.
/// @param font - A font object.
/// @return The CSS font string. See https://developer.mozilla.org/en-US/docs/Web/CSS/font
/// @private
///
/// A null [font] stands for a falsy JavaScript value: `null` or `undefined`.
/// `font.weight` and `font.size` become strings through `ToString`
/// ([jsToString], [jsNumberToString]), so `12` gives `'12px'`, not `'12.0px'`.
String? toFontString(FontSpec? font) {
  if (font == null || isNullOrUndef(font.size) || isNullOrUndef(font.family)) {
    return null;
  }

  return '${jsTruthy(font.style) ? '${font.style} ' : ''}'
      '${jsTruthy(font.weight) ? '${jsToString(font.weight)} ' : ''}'
      '${jsNumberToString(font.size!)}px '
      '${font.family}';
}

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

  /// `font?: string`: the font of [data].
  String? font;
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
/// no data to drop.
double longestText(
  CanvasRenderingContext2D ctx,
  String? font,
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
  /// `PointStyle` (index.d.ts:1995) is the union of the style names
  /// `'circle'`, `'cross'`, `'crossRot'`, `'dash'`, `'line'`, `'rect'`,
  /// `'rectRounded'`, `'rectRot'`, `'star'` and `'triangle'`, of `false`, and
  /// of `HTMLImageElement` and `HTMLCanvasElement`. Dart cannot declare the
  /// union, so the Dart form is `Object?`, as for every option value
  /// (Chart.js ADR 0006): a `String`, a `bool`, or a [CanvasImageSource].
  /// A [CanvasImageSource] draws as an image. An [HTMLCanvasElement] is not
  /// a [CanvasImageSource]: pass its `toImageSource()` snapshot to draw it
  /// as an image. A canvas element itself draws the default circle
  /// (`platform-canvas-point-style`, differences.md). Another value draws a
  /// circle, as upstream.
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
/// The image branch: upstream tests `style && typeof style === 'object'`
/// and then `style.toString()` for `'[object HTMLImageElement]'` and
/// `'[object HTMLCanvasElement]'`. In the canvas layer, an image is a
/// [CanvasImageSource], so one type test replaces both tests. An
/// [HTMLCanvasElement] is not a [CanvasImageSource] (Chart.js ADR 0013), so
/// a canvas element draws the default circle. A caller passes its
/// `toImageSource()` snapshot to get the image draw
/// (`platform-canvas-point-style`, differences.md). Any other object goes
/// on to the radius test and the `default` branch, as upstream.
///
/// The `switch` compares with `===` upstream. A Dart constant pattern
/// compares with `==`, which gives the same result for a `String` and a
/// `bool`. Upstream places `default` first. A JS `switch` takes `default`
/// only when no case matches, whatever its place, so here it is last. The
/// two upstream fall-throughs (`rect` with a rotation into `rectRot`,
/// `crossRot` into `cross`) are `continue` to the labelled case.
void drawPointLegend(
  CanvasRenderingContext2D ctx,
  DrawPointOptions options,
  double x,
  double y,
  double? w,
) {
  double xOffset;
  double yOffset;
  double size;
  double cornerRadius;
  double width;
  double xOffsetW;
  double yOffsetW;
  final style = options.pointStyle;
  final rotation = options.rotation;
  final radius = options.radius;
  var rad = (jsTruthy(rotation) ? rotation! : 0) * radPerDeg;
  final hasW = jsTruthy(w);

  // DIVERGES(chartjs): platform-canvas-point-style, a canvas is not an image.
  if (style is CanvasImageSource) {
    ctx
      ..save()
      ..translate(x, y)
      ..rotate(rad)
      ..drawImage(
        style,
        -style.width / 2,
        -style.height / 2,
        style.width,
        style.height,
      )
      ..restore();
    return;
  }

  // `isNaN(radius)`: radius is a number, so ToNumber changes nothing.
  if (radius.isNaN || radius <= 0) {
    return;
  }

  ctx.beginPath();

  switch (style) {
    case 'triangle':
      width = hasW ? w! / 2 : radius;
      ctx.moveTo(x + math.sin(rad) * width, y - math.cos(rad) * radius);
      rad += twoThirdsPi;
      ctx.lineTo(x + math.sin(rad) * width, y - math.cos(rad) * radius);
      rad += twoThirdsPi;
      ctx
        ..lineTo(x + math.sin(rad) * width, y - math.cos(rad) * radius)
        ..closePath();
    case 'rectRounded':
      // NOTE: the rounded rect implementation changed to use `arc` instead
      // of `quadraticCurveTo` since it generates better results when rect
      // is almost a circle. 0.516 (instead of 0.5) produces results with
      // visually closer proportion to the previous impl and it is inscribed
      // in the circle with `radius`. For more details, see the following
      // PRs:
      // https://github.com/chartjs/Chart.js/issues/5597
      // https://github.com/chartjs/Chart.js/issues/5858
      cornerRadius = radius * 0.516;
      size = radius - cornerRadius;
      xOffset = math.cos(rad + quarterPi) * size;
      xOffsetW =
          math.cos(rad + quarterPi) * (hasW ? w! / 2 - cornerRadius : size);
      yOffset = math.sin(rad + quarterPi) * size;
      yOffsetW =
          math.sin(rad + quarterPi) * (hasW ? w! / 2 - cornerRadius : size);
      ctx
        ..arc(x - xOffsetW, y - yOffset, cornerRadius, rad - pi, rad - halfPi)
        ..arc(x + yOffsetW, y - xOffset, cornerRadius, rad - halfPi, rad)
        ..arc(x + xOffsetW, y + yOffset, cornerRadius, rad, rad + halfPi)
        ..arc(x - yOffsetW, y + xOffset, cornerRadius, rad + halfPi, rad + pi)
        ..closePath();
    case 'rect':
      if (!jsTruthy(rotation)) {
        size = math.sqrt1_2 * radius;
        width = hasW ? w! / 2 : size;
        ctx.rect(x - width, y - size, 2 * width, 2 * size);
        break;
      }
      rad += quarterPi;
      /* falls through */
      continue rectRot;
    rectRot:
    case 'rectRot':
      xOffsetW = math.cos(rad) * (hasW ? w! / 2 : radius);
      xOffset = math.cos(rad) * radius;
      yOffset = math.sin(rad) * radius;
      yOffsetW = math.sin(rad) * (hasW ? w! / 2 : radius);
      ctx
        ..moveTo(x - xOffsetW, y - yOffset)
        ..lineTo(x + yOffsetW, y - xOffset)
        ..lineTo(x + xOffsetW, y + yOffset)
        ..lineTo(x - yOffsetW, y + xOffset)
        ..closePath();
    case 'crossRot':
      rad += quarterPi;
      /* falls through */
      continue cross;
    cross:
    case 'cross':
      xOffsetW = math.cos(rad) * (hasW ? w! / 2 : radius);
      xOffset = math.cos(rad) * radius;
      yOffset = math.sin(rad) * radius;
      yOffsetW = math.sin(rad) * (hasW ? w! / 2 : radius);
      ctx
        ..moveTo(x - xOffsetW, y - yOffset)
        ..lineTo(x + xOffsetW, y + yOffset)
        ..moveTo(x + yOffsetW, y - xOffset)
        ..lineTo(x - yOffsetW, y + xOffset);
    case 'star':
      xOffsetW = math.cos(rad) * (hasW ? w! / 2 : radius);
      xOffset = math.cos(rad) * radius;
      yOffset = math.sin(rad) * radius;
      yOffsetW = math.sin(rad) * (hasW ? w! / 2 : radius);
      ctx
        ..moveTo(x - xOffsetW, y - yOffset)
        ..lineTo(x + xOffsetW, y + yOffset)
        ..moveTo(x + yOffsetW, y - xOffset)
        ..lineTo(x - yOffsetW, y + xOffset);
      rad += quarterPi;
      xOffsetW = math.cos(rad) * (hasW ? w! / 2 : radius);
      xOffset = math.cos(rad) * radius;
      yOffset = math.sin(rad) * radius;
      yOffsetW = math.sin(rad) * (hasW ? w! / 2 : radius);
      ctx
        ..moveTo(x - xOffsetW, y - yOffset)
        ..lineTo(x + xOffsetW, y + yOffset)
        ..moveTo(x + yOffsetW, y - xOffset)
        ..lineTo(x - yOffsetW, y + xOffset);
    case 'line':
      xOffset = hasW ? w! / 2 : math.cos(rad) * radius;
      yOffset = math.sin(rad) * radius;
      ctx
        ..moveTo(x - xOffset, y - yOffset)
        ..lineTo(x + xOffset, y + yOffset);
    case 'dash':
      ctx
        ..moveTo(x, y)
        ..lineTo(
          x + math.cos(rad) * (hasW ? w! / 2 : radius),
          y + math.sin(rad) * radius,
        );
    case false:
      ctx.closePath();
    // Default includes circle
    default:
      if (hasW) {
        ctx.ellipse(x, y, w! / 2, radius, 0, 0, tau);
      } else {
        ctx.arc(x, y, radius, 0, tau);
      }
      ctx.closePath();
  }

  ctx.fill();
  if (options.borderWidth > 0) {
    ctx.stroke();
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
/// writes `point.x ?? 0` (Chart.js ADR 0010).
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
  margin = jsTruthy(margin)
      ? margin!
      : 0.5; // margin - default is to match rounded decimals

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
/// `stepped` option value (`element.line.js:89`): `true`, `'before'`,
/// `'after'` or `'middle'`. A null coordinate is JS `null`, which `ToNumber`
/// makes 0 (Chart.js ADR 0010).
void steppedLineTo(
  CanvasPath ctx,
  Point? previous,
  Point target, [
  // The upstream signature.
  // ignore: avoid_positional_boolean_parameters
  bool? flip,
  Object? mode,
]) {
  if (previous == null) {
    return ctx.lineTo(target.x ?? 0, target.y ?? 0);
  }
  if (mode == 'middle') {
    final midpoint = ((previous.x ?? 0) + (target.x ?? 0)) / 2.0;
    ctx
      ..lineTo(midpoint, previous.y ?? 0)
      ..lineTo(midpoint, target.y ?? 0);
  } else if ((mode == 'after') != (flip ?? false)) {
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
  // The upstream signature.
  // ignore: avoid_positional_boolean_parameters
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

  if (jsTruthy(opts.color)) {
    ctx.fillStyle = opts.color;
  }

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
    ..fillStyle = opts.color
    ..fillRect(opts.left, opts.top, opts.width, opts.height)
    ..fillStyle = oldColor;
}

/// The JS object `{}`: the default of the `opts` parameter of `renderText`
/// (helpers.canvas.ts:455).
final class _EmptyRenderTextOpts implements RenderTextOpts {
  const _EmptyRenderTextOpts();

  @override
  Object? get color => null;

  @override
  double? get decorationWidth => null;

  @override
  double? get maxWidth => null;

  @override
  double? get rotation => null;

  @override
  bool? get strikethrough => null;

  @override
  Object? get strokeColor => null;

  @override
  double? get strokeWidth => null;

  @override
  String? get textAlign => null;

  @override
  String? get textBaseline => null;

  @override
  (double, double)? get translation => null;

  @override
  bool? get underline => null;

  @override
  BackdropOptions? get backdrop => null;
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
/// `Number(font.lineHeight)` is [jsToNumber]: a `String` line height gives
/// its `ToNumber`, NaN for `'1.2em'`.
void renderText(
  CanvasRenderingContext2D ctx,
  Object? text,
  double x,
  double y,
  CanvasFontSpec font, [
  RenderTextOpts opts = const _EmptyRenderTextOpts(),
]) {
  final lines = isArray(text) ? text! as List<Object?> : [text];
  final strokeWidth = opts.strokeWidth;
  // `undefined > 0` and `NaN > 0` are false.
  final stroke =
      strokeWidth != null && strokeWidth > 0 && opts.strokeColor != '';
  int i;
  String line;

  ctx
    ..save()
    ..font = font.string;
  _setRenderOpts(ctx, opts);

  for (i = 0; i < lines.length; ++i) {
    line = jsToString(lines[i]);

    final backdrop = opts.backdrop;
    if (backdrop != null) {
      _drawBackdrop(ctx, backdrop);
    }

    if (stroke) {
      if (jsTruthy(opts.strokeColor)) {
        ctx.strokeStyle = opts.strokeColor;
      }

      if (!isNullOrUndef(opts.strokeWidth)) {
        ctx.lineWidth = opts.strokeWidth;
      }

      ctx.strokeText(line, x, y, opts.maxWidth);
    }

    ctx.fillText(line, x, y, opts.maxWidth);
    _decorateText(ctx, x, y, line, opts);

    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    y += jsToNumber(font.lineHeight);
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
void addRoundedRectPath(CanvasRenderingContext2D ctx, RoundedRect rect) {
  final RoundedRect(:x, :y, :w, :h) = rect;
  final radius = rect.radius! as TRBLCorners;

  ctx
    // top left arc
    ..arc(
      x + radius.topLeft,
      y + radius.topLeft,
      radius.topLeft,
      1.5 * pi,
      pi,
      true,
    )
    // line from top left to bottom left
    ..lineTo(x, y + h - radius.bottomLeft)
    // bottom left arc
    ..arc(
      x + radius.bottomLeft,
      y + h - radius.bottomLeft,
      radius.bottomLeft,
      pi,
      halfPi,
      true,
    )
    // line from bottom left to bottom right
    ..lineTo(x + w - radius.bottomRight, y + h)
    // bottom right arc
    ..arc(
      x + w - radius.bottomRight,
      y + h - radius.bottomRight,
      radius.bottomRight,
      halfPi,
      0,
      true,
    )
    // line from bottom right to top right
    ..lineTo(x + w, y + radius.topRight)
    // top right arc
    ..arc(
      x + w - radius.topRight,
      y + radius.topRight,
      radius.topRight,
      0,
      -halfPi,
      true,
    )
    // line from top right to top left
    ..lineTo(x + radius.topLeft, y);
}
