// Ported from Chart.js v4.6.1 src/elements/element.line.js (MIT, Chart.js Contributors).

/// Port of `src/elements/element.line.js`.
///
/// [LineElement] follows the element design of Chart.js ADR 0017: typed
/// members, the `undefined` state of a nullable private field, and the
/// access by name of [LineElement.operator []] and [LineElement.operator []=]
/// with the upstream JavaScript names.
///
/// The `_`-prefixed members that other modules read drop the underscore and
/// carry `@internal` (Chart.js ADR 0012): `_chart` is [LineElement.chart],
/// `_loop` is [LineElement.loop], `_fullLoop` is [LineElement.fullLoop],
/// `_decimated` is [LineElement.decimated] and `_datasetIndex` is
/// [LineElement.datasetIndex]. Only this file reads `_path`, `_points`,
/// `_segments` and `_pointsUpdated`. Thus they keep the underscore. Other
/// code reads them by name, for example `line['_path']`. The name `path`
/// is also the method [LineElement.path].
///
/// The points of a line are point elements. `helpers.curve` writes the
/// control points `cp1x`, `cp1y`, `cp2x` and `cp2y` on them
/// (helpers.curve.ts:105-111), and `_bezierCurveTo` and
/// `_bezierInterpolation` read them. `types.PointElement` implements
/// [SplinePoint], as TypeScript accepts a point element by structure. Thus
/// the points go to these functions without a cast.
///
/// Numbers are `double` (Chart.js ADR 0045). A list read converts an index
/// with `toInt()`. Each index comes from a list length or from a segment of
/// the same points, so it is finite. JS `%` is Dart `remainder`.
///
/// `line.options` is an option object (Chart.js ADR 0043): a [LineOptions]
/// or a plain Map. Each read goes through one small function for each
/// option, for example `_stepped`, which gives [LineOptions.steppedValue] or
/// `jsGet(options, 'stepped')` (Chart.js ADR 0018, section 4). Both give JS
/// `undefined` for an absent key. [jsGet] throws a [TypeError] for the
/// `undefined` state, as a JavaScript property read of `undefined` does.
///
/// This library is a pure layer (Chart.js ADR 0017, section 10). It imports
/// neither `dart:ui` nor `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show LineOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show bezierCurveTo, steppedLineTo;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show valueOrDefault;
import 'package:flutter_chartjs_port/src/helpers/helpers.curve.dart'
    show updateBezierControlPoints;
import 'package:flutter_chartjs_port/src/helpers/helpers.interpolation.dart'
    show
        InterpolatedPoint,
        bezierInterpolation,
        pointInLine,
        steppedInterpolation;
import 'package:flutter_chartjs_port/src/helpers/helpers.segment.dart'
    show boundSegments, computeSegments;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// The option `borderCapStyle` of [options]: [LineOptions.borderCapStyleValue]
/// for typed options, else `jsGet(options, 'borderCapStyle')` (Chart.js ADR
/// 0018, section 4).
///
/// Both give JS `undefined` for an absent key. `jsGet` throws a [TypeError]
/// for Dart `null`, the `undefined` state of the options. [options] can also
/// be the style of a segment, a plain Map. The other option functions of
/// this file work in the same way.
Object? _borderCapStyle(Object? options) => options is LineOptions
    ? options.borderCapStyleValue
    : jsGet(options, 'borderCapStyle');

/// The option `borderDash` of [options], as [_borderCapStyle] reads
/// `borderCapStyle`.
Object? _borderDash(Object? options) => options is LineOptions
    ? options.borderDashValue
    : jsGet(options, 'borderDash');

/// The option `borderDashOffset` of [options], as [_borderCapStyle] reads
/// `borderCapStyle`.
Object? _borderDashOffset(Object? options) => options is LineOptions
    ? options.borderDashOffsetValue
    : jsGet(options, 'borderDashOffset');

/// The option `borderJoinStyle` of [options], as [_borderCapStyle] reads
/// `borderCapStyle`.
Object? _borderJoinStyle(Object? options) => options is LineOptions
    ? options.borderJoinStyleValue
    : jsGet(options, 'borderJoinStyle');

/// The option `borderWidth` of [options], as [_borderCapStyle] reads
/// `borderCapStyle`.
Object? _borderWidth(Object? options) => options is LineOptions
    ? options.borderWidthValue
    : jsGet(options, 'borderWidth');

/// The option `borderColor` of [options], as [_borderCapStyle] reads
/// `borderCapStyle`.
Object? _borderColor(Object? options) => options is LineOptions
    ? options.borderColorValue
    : jsGet(options, 'borderColor');

/// The option `cubicInterpolationMode` of [options], as [_borderCapStyle]
/// reads `borderCapStyle`.
Object? _cubicInterpolationMode(Object? options) => options is LineOptions
    ? options.cubicInterpolationModeValue
    : jsGet(options, 'cubicInterpolationMode');

/// The option `spanGaps` of [options], as [_borderCapStyle] reads
/// `borderCapStyle`.
Object? _spanGaps(Object? options) =>
    options is LineOptions ? options.spanGapsValue : jsGet(options, 'spanGaps');

/// The option `stepped` of [options], as [_borderCapStyle] reads
/// `borderCapStyle`.
Object? _stepped(Object? options) =>
    options is LineOptions ? options.steppedValue : jsGet(options, 'stepped');

/// The option `tension` of [options], as [_borderCapStyle] reads
/// `borderCapStyle`.
Object? _tension(Object? options) =>
    options is LineOptions ? options.tensionValue : jsGet(options, 'tension');

/// The option `segment` of [options], which the line controller writes
/// (controller.line.js:66), as [_borderCapStyle] reads `borderCapStyle`.
Object? _segment(Object? options) =>
    options is LineOptions ? options.segmentValue : jsGet(options, 'segment');

/// element.line.js:12 `setStyle(ctx, options, style = options)`.
///
/// Dart `null` for [style] stands for JS `undefined`, which gives the
/// default [options]. A segment without a style has the style `undefined`
/// ([types.Segment.style]).
///
/// The canvas setters take typed values. A value that the DOM converts is
/// converted here in the same way, with [canvasKeyword], [canvasLineDash],
/// [canvasNumber] and [canvasStyle] of `lib/src/js/js_webidl.dart`, as in
/// the other element classes.
void _setStyle(
  CanvasRenderingContext2D ctx,
  Object? options, [
  Object? style,
]) {
  final s = style ?? options;
  ctx
    ..lineCap = canvasKeyword(
      valueOrDefault(_borderCapStyle(s), _borderCapStyle(options)),
    )
    ..setLineDash(
      canvasLineDash(valueOrDefault(_borderDash(s), _borderDash(options))),
    )
    ..lineDashOffset = canvasNumber(
      valueOrDefault(_borderDashOffset(s), _borderDashOffset(options)),
    )
    ..lineJoin = canvasKeyword(
      valueOrDefault(_borderJoinStyle(s), _borderJoinStyle(options)),
    )
    ..lineWidth = canvasNumber(
      valueOrDefault(_borderWidth(s), _borderWidth(options)),
    )
    ..strokeStyle = canvasStyle(
      valueOrDefault(_borderColor(s), _borderColor(options)),
    );
}

/// element.line.js:21 `lineTo(ctx, previous, target)`.
///
/// JavaScript ignores the extra arguments `reverse` and `options.stepped` of
/// a call at element.line.js:89 and :97. Thus the function takes them and
/// does not read them.
void _lineTo(
  CanvasPath ctx,
  types.PointElement? previous,
  types.PointElement target, [
  Object? _,
  Object? _,
]) {
  ctx.lineTo(target.x, target.y);
}

/// `_bezierCurveTo(ctx, prev, point, reverse)` of helpers.canvas.ts:367,
/// as a line method of [_getLineMethod]. JavaScript ignores the extra
/// argument `options.stepped`.
void _bezierCurveTo(
  CanvasPath ctx,
  types.PointElement? previous,
  types.PointElement target, [
  bool? flip,
  Object? _,
]) {
  bezierCurveTo(ctx, previous, target, flip);
}

/// element.line.js:28 `getLineMethod(options)`.
///
/// @returns {any}
///
/// The result is called as `lineMethod(ctx, prev, point, reverse,
/// options.stepped)` (element.line.js:89). A null `previous` stands for JS
/// `undefined`, the `prev` of the first point. The fifth argument is the
/// option value `options.stepped`.
void Function(
  CanvasPath ctx,
  types.PointElement? previous,
  types.PointElement target,
  // The upstream signature.
  // ignore: avoid_positional_boolean_parameters
  bool flip,
  Object? mode,
)
_getLineMethod(Object? options) {
  if (jsTruthy(_stepped(options))) {
    return steppedLineTo;
  }

  if (jsTruthy(_tension(options)) ||
      _cubicInterpolationMode(options) == 'monotone') {
    return _bezierCurveTo;
  }

  return _lineTo;
}

/// The `params` object of element.line.js:65-69: `{move, reverse, start,
/// end}`.
///
/// Dart `null` for `start`, `end` or `move` stands for JS `undefined`, which
/// gives the default of the destructuring at element.line.js:42 and :76.
/// `start` and `end` are the `ToNumber` of the JS values, which each reader
/// applies: `Math.max`, `Math.min`, `<` and `>`. `move` and `reverse` are
/// the `ToBoolean` of the JS values. The internal calls pass `{start, end}`
/// (element.line.js:226, :415).
typedef _PathParams = ({double? start, double? end, bool? move, bool reverse});

/// The `params` of a call without `params`: JS `undefined`, which gives the
/// defaults `{}` and `params || {}`.
const _PathParams _noParams = (
  start: null,
  end: null,
  move: null,
  reverse: false,
);

/// The [_PathParams] of the plain object [params] of
/// [LineElement.pathSegment], or [_noParams] for Dart `null`, which stands
/// for JS `undefined`.
_PathParams _pathParams(AnyObject? params) {
  if (params == null) {
    return _noParams;
  }
  final start = jsGet(params, 'start');
  final end = jsGet(params, 'end');
  final move = jsGet(params, 'move');
  return (
    start: identical(start, undefined) ? null : jsToNumber(start),
    end: identical(end, undefined) ? null : jsToNumber(end),
    move: identical(move, undefined) ? null : jsTruthy(move),
    reverse: jsTruthy(jsGet(params, 'reverse')),
  );
}

/// element.line.js:40 `pathVars(points, segment, params = {})`.
({double count, double start, bool loop, double ilen}) _pathVars(
  List<types.PointElement> points,
  types.Segment segment,
  _PathParams params,
) {
  final count = points.length.toDouble();
  final paramsStart = params.start ?? 0;
  final paramsEnd = params.end ?? count - 1;
  final segmentStart = segment.start;
  final segmentEnd = segment.end;
  final start = jsMax(paramsStart, segmentStart);
  final end = jsMin(paramsEnd, segmentEnd);
  final outside =
      (paramsStart < segmentStart && paramsEnd < segmentStart) ||
      (paramsStart > segmentEnd && paramsEnd > segmentEnd);

  return (
    count: count,
    start: start,
    loop: segment.loop,
    ilen: end < start && !outside ? count + end - start : end - start,
  );
}

/// element.line.js:71 `pathSegment(ctx, line, segment, params)`.
///
/// Create path from points, grouping by truncated x-coordinate
/// Points need to be in order by x-coordinate for this to work efficiently
/// @param {CanvasRenderingContext2D|Path2D} ctx - Context
/// @param {LineElement} line
/// @param {object} segment
/// @param {number} segment.start - start index of the segment, referring the
/// points array
/// @param {number} segment.end - end index of the segment, referring the
/// points array
/// @param {boolean} segment.loop - indicates that the segment is a loop
/// @param {object} params
/// @param {boolean} params.move - move to starting point (vs line to it)
/// @param {boolean} params.reverse - path the segment from end to start
/// @param {number} params.start - limit segment to points starting from
/// `start` index
/// @param {number} params.end - limit segment to points ending at `start` +
/// `count` index
bool? _pathSegment(
  CanvasPath ctx,
  LineElement line,
  types.Segment segment,
  _PathParams params,
) {
  final points = line.points;
  final options = line.options;
  final (:count, :start, :loop, :ilen) = _pathVars(points, segment, params);
  final lineMethod = _getLineMethod(options);
  var move = params.move ?? true;
  final reverse = params.reverse;
  types.PointElement point;
  types.PointElement? prev;

  for (var i = 0.0; i <= ilen; ++i) {
    point = points[(start + (reverse ? ilen - i : i)).remainder(count).toInt()];

    if (point.skip ?? false) {
      // If there is a skipped point inside a segment, spanGaps must be true
      continue;
    } else if (move) {
      ctx.moveTo(point.x, point.y);
      move = false;
    } else {
      lineMethod(ctx, prev, point, reverse, _stepped(options));
    }

    prev = point;
  }

  if (loop) {
    point = points[(start + (reverse ? ilen : 0)).remainder(count).toInt()];
    lineMethod(ctx, prev, point, reverse, _stepped(options));
  }

  return loop;
}

/// Whether the property [prop] of [point] is in the JS `undefined` state.
///
/// The numeric getters give NaN for `undefined`. The read by name of an
/// [Element] gives the [undefined] sentinel (Chart.js ADR 0017, section 5).
/// Another implementation of [types.PointElement] has no `undefined` state.
bool _isUndefined(types.PointElement point, String prop) => switch (point) {
  final Element element => identical(element[prop], undefined),
  _ => false,
};

/// element.line.js:118 `fastPathSegment(ctx, line, segment, params)`.
///
/// Create path from points, grouping by truncated x-coordinate
/// Points need to be in order by x-coordinate for this to work efficiently
/// @param {CanvasRenderingContext2D|Path2D} ctx - Context
/// @param {LineElement} line
/// @param {object} segment
/// @param {number} segment.start - start index of the segment, referring the
/// points array
/// @param {number} segment.end - end index of the segment, referring the
/// points array
/// @param {boolean} segment.loop - indicates that the segment is a loop
/// @param {object} params
/// @param {boolean} params.move - move to starting point (vs line to it)
/// @param {boolean} params.reverse - path the segment from end to start
/// @param {number} params.start - limit segment to points starting from
/// `start` index
/// @param {number} params.end - limit segment to points ending at `start` +
/// `count` index
///
/// Upstream returns `undefined`. The result is Dart `null`.
///
/// The `y` getter of a point element gives NaN for JS `undefined` (Chart.js
/// ADR 0017, section 4). `minY` and `maxY` keep the `undefined` of the first
/// y of a group as Dart `null`, because `minY !== maxY` tells `undefined`
/// from NaN.
bool? _fastPathSegment(
  CanvasPath ctx,
  LineElement line,
  types.Segment segment,
  _PathParams params,
) {
  final points = line.points;
  final (:count, :start, loop: _, :ilen) = _pathVars(points, segment, params);
  final move = params.move ?? true;
  final reverse = params.reverse;
  var avgX = 0.0;
  var countX = 0.0;
  types.PointElement point;
  // JS `undefined` before the first point of a group. `x | 0` is a number,
  // so `truncX === prevX` is false for `undefined`, as `==` is for null.
  double? prevX;
  double? minY;
  double? maxY;
  double? lastY;

  double pointIndex(double index) =>
      (start + (reverse ? ilen - index : index)).remainder(count);
  void drawX() {
    // `!==` of two numbers is `!=`, also for NaN. Dart null stands for JS
    // `undefined`: both are undefined (null), or both are numbers.
    if (minY != maxY) {
      // Draw line to maxY and minY, using the average x-coordinate
      ctx
        ..lineTo(avgX, maxY!)
        ..lineTo(avgX, minY!)
        // Line to y-value of last point in group. So the line continues
        // from correct position. Not using move, to have solid path.
        ..lineTo(avgX, lastY!);
    }
  }

  if (move) {
    point = points[pointIndex(0).toInt()];
    ctx.moveTo(point.x, point.y);
  }

  for (var i = 0.0; i <= ilen; ++i) {
    point = points[pointIndex(i).toInt()];

    if (point.skip ?? false) {
      // If there is a skipped point inside a segment, spanGaps must be true
      continue;
    }

    final x = point.x;
    final y = point.y;
    final truncX = jsToInt32(x); // truncated x-coordinate

    if (truncX == prevX) {
      // Determine `minY` / `maxY` and `avgX` while we stay within same
      // x-position
      // `y < undefined` and `y > undefined` are false. Thus a group whose
      // first y is undefined (null) keeps it.
      final min = minY;
      if (min != null) {
        if (y < min) {
          minY = y;
        } else if (y > maxY!) {
          maxY = y;
        }
      }
      // For first point in group, countX is `0`, so average will be `x` / 1.
      avgX = (countX * avgX + x) / ++countX;
    } else {
      drawX();
      // Draw line to next x-position, using the first (or only)
      // y-value in that group
      ctx.lineTo(x, y);

      prevX = truncX;
      countX = 0;
      // The getter gives NaN for an undefined y, but upstream keeps
      // `undefined`, and `undefined !== undefined` is false where
      // `NaN !== NaN` is true. Thus drawX draws nothing for such a group.
      minY = maxY = y.isNaN && _isUndefined(point, 'y') ? null : y;
    }
    // Keep track of the last y-value in group. NaN and `undefined` both
    // make a lineTo that the DOM ignores.
    lastY = y;
  }
  drawX();
  return null;
}

/// element.line.js:185 `_getSegmentMethod(line)`.
///
/// @param {LineElement} line - the line
/// @returns {function}
/// @private
///
/// The result is called as `segmentMethod(ctx, line, segment, params)`. It
/// gives Dart `null` for the JS `undefined` of [_fastPathSegment].
bool? Function(
  CanvasPath ctx,
  LineElement line,
  types.Segment segment,
  _PathParams params,
)
_getSegmentMethod(LineElement line) {
  final opts = line.options;
  final borderDash = _borderDash(opts);
  final dashLength = jsTruthy(borderDash)
      ? jsGet(borderDash, 'length')
      : borderDash;
  final useFastPath =
      !line.decimated &&
      !(line.loop ?? false) &&
      !jsTruthy(_tension(opts)) &&
      _cubicInterpolationMode(opts) != 'monotone' &&
      !jsTruthy(_stepped(opts)) &&
      !jsTruthy(dashLength);
  return useFastPath ? _fastPathSegment : _pathSegment;
}

/// element.line.js:195 `_getInterpolationMethod(options)`.
///
/// @private
///
/// The result is called as `_interpolate(p1, p2, t, options.stepped)`
/// (element.line.js:373).
InterpolatedPoint Function(
  types.PointElement p1,
  types.PointElement p2,
  double t,
  Object? mode,
)
_getInterpolationMethod(Object? options) {
  if (jsTruthy(_stepped(options))) {
    return steppedInterpolation;
  }

  if (jsTruthy(_tension(options)) ||
      _cubicInterpolationMode(options) == 'monotone') {
    return bezierInterpolation;
  }

  return pointInLine;
}

/// element.line.js:207 `strokePathWithCache(ctx, line, start, count)`.
///
/// Dart `null` for [start] and [count] stands for JS `undefined`.
void _strokePathWithCache(
  CanvasRenderingContext2D ctx,
  LineElement line,
  double? start,
  double? count,
) {
  var path = line._path;
  if (path == null) {
    path = line._path = Path2D();
    if (line.path(path, start, count)) {
      path.closePath();
    }
  }
  _setStyle(ctx, line.options);
  ctx.stroke(path);
}

/// element.line.js:219 `strokePathDirect(ctx, line, start, count)`.
///
/// Dart `null` for [start] and [count] stands for JS `undefined`. The
/// `end` of `{start, end: start + count - 1}` is then NaN, the result of
/// the JS arithmetic.
void _strokePathDirect(
  CanvasRenderingContext2D ctx,
  LineElement line,
  double? start,
  double? count,
) {
  final segments = line.segments;
  final options = line.options;
  final segmentMethod = _getSegmentMethod(line);

  for (final segment in segments) {
    _setStyle(ctx, options, segment.style);
    ctx.beginPath();
    final params = (
      start: start,
      end: (start ?? double.nan) + (count ?? double.nan) - 1,
      move: null,
      reverse: false,
    );
    if (segmentMethod(ctx, line, segment, params) ?? false) {
      ctx.closePath();
    }
    ctx.stroke();
  }
}

/// element.line.js:233 `usePath2D = typeof Path2D === 'function'`.
///
/// The [Path2D] of the canvas interface always exists. Thus the test is the
/// constant `true`, as in every browser that Chart.js supports (Chart.js ADR
/// 0017, section 11).
const bool _usePath2D = true;

/// element.line.js:235 `draw(ctx, line, start, count)`.
///
/// Dart `null` for [start] and [count] stands for JS `undefined`.
void _draw(
  CanvasRenderingContext2D ctx,
  LineElement line,
  double? start,
  double? count,
) {
  if (_usePath2D && !jsTruthy(_segment(line.options))) {
    _strokePathWithCache(ctx, line, start, count);
  } else {
    _strokePathDirect(ctx, line, start, count);
  }
}

/// element.line.js:243 `LineElement`.
///
/// The line of a line or radar dataset (Chart.js ADR 0017). It extends
/// [Element] and implements [types.LineElement], the interface that
/// `helpers.segment` reads, and [types.VisualElement].
///
/// ## Properties
///
/// The constructor sets the start values of element.line.js:282-292.
/// [animated] starts true, [decimated] and `_pointsUpdated` start false, and
/// the other properties start in the `undefined` state.
///
/// - [points] is the list of point elements. The getter throws a
///   [TypeError] in the `undefined` state (see [points]). Upstream also
///   accepts plain points. The port takes only point elements (the
///   difference `adapt-line-points-elements`).
/// - [segments] is computed at the first read and kept until the next write
///   of [points].
/// - `_path` is the cached [Path2D] of the line. Other code reads it by
///   name: `line['_path']`.
///
/// ## Access by name
///
/// [operator []] and [operator []=] handle the upstream names `animated`,
/// `_chart`, `_loop`, `_fullLoop`, `_path`, `_points`, `points`,
/// `_segments`, `segments`, `_decimated`, `_pointsUpdated` and
/// `_datasetIndex`, and pass the other names to [Element].
class LineElement extends Element
    implements types.LineElement, types.VisualElement {
  /// element.line.js:279 `constructor(cfg)`.
  ///
  /// The properties get the start values of element.line.js:282-292. Then
  /// each key of [cfg] is written through [operator []=], as
  /// `Object.assign(this, cfg)` does. A `points` key goes through the
  /// setter [points]. Dart `null` for [cfg] stands for a falsy JS value.
  LineElement([AnyObject? cfg]) {
    if (cfg != null) assign(cfg);
  }

  /// element.line.js:245 `static id = 'line'`.
  static const String id = 'line';

  /// element.line.js:250 `static defaults`.
  static final AnyObject defaults = {
    'borderCapStyle': 'butt',
    'borderDash': <Object?>[],
    'borderDashOffset': 0.0,
    'borderJoinStyle': 'miter',
    'borderWidth': 3.0,
    'capBezierPoints': true,
    'cubicInterpolationMode': 'default',
    'fill': false,
    'spanGaps': false,
    'stepped': false,
    'tension': 0.0,
  };

  /// element.line.js:267 `static defaultRoutes`.
  static final AnyObject defaultRoutes = {
    'backgroundColor': 'backgroundColor',
    'borderColor': 'borderColor',
  };

  /// element.line.js:273 `static descriptors`.
  static final AnyObject descriptors = {
    '_scriptable': true,
    '_indexable': (String name) => name != 'borderDash' && name != 'fill',
  };

  /// element.line.js:243 `class LineElement extends Element` as a value
  /// (Chart.js ADR 0020, section 3).
  ///
  /// Its statics are [id], [defaults], [defaultRoutes] and [descriptors], in
  /// the upstream order of declaration (element.line.js:245-276). They are the
  /// objects of the static fields. Its `construct` calls `LineElement(cfg)`
  /// with the `cfg` of [elementCfgArg].
  static final JsClass jsClass = JsClass(
    'LineElement',
    superclass: Element.jsClass,
    statics: {
      'id': id,
      'defaults': defaults,
      'defaultRoutes': defaultRoutes,
      'descriptors': descriptors,
    },
    construct: (newTarget, args) => LineElement(elementCfgArg(args)),
  );

  /// element.line.js:282 `animated = true`.
  ///
  /// When it is true, [draw] drops the cached path and the control points
  /// after each draw (element.line.js:439-443). `updateElement` writes it
  /// by name (controller.line.js:68). Upstream never writes `undefined` to
  /// it. Thus a write by name accepts only a `bool`.
  bool animated = true;

  /// The value of [chart]. Dart `null` stands for JS `undefined`.
  types.Chart? _chart;

  /// The value of [loop]. Dart `null` stands for JS `undefined`.
  bool? _loop;

  /// The value of [fullLoop]. Dart `null` stands for JS `undefined`.
  bool? _fullLoop;

  /// element.line.js:287 `_path`, the cached path of
  /// [_strokePathWithCache]. Dart `null` stands for JS `undefined`, the
  /// start value and the value after `delete this._path`.
  Path2D? _path;

  /// element.line.js:288 `_points`, the value of [points]. Dart `null`
  /// stands for JS `undefined`, the start value.
  List<types.PointElement>? _points;

  /// element.line.js:289 `_segments`, the cache of [segments]. Dart `null`
  /// stands for JS `undefined`, the start value and the value after
  /// `delete this._segments`.
  List<types.Segment>? _segments;

  /// element.line.js:290 `_decimated = false`.
  ///
  /// The dataset controller writes `!!_dataset._decimated`
  /// (controller.line.js:59). Upstream never writes `undefined` to it.
  /// Thus a write by name accepts only a `bool`.
  @internal
  bool decimated = false;

  /// element.line.js:291 `_pointsUpdated = false`: whether
  /// [updateControlPoints] has set the control points of [points].
  bool _pointsUpdated = false;

  /// The value of [datasetIndex]. Dart `null` stands for JS `undefined`.
  double? _datasetIndex;

  /// element.line.js:284 `_chart`. Dart `null` stands for JS `undefined`,
  /// the start value. `controller.line.js:57` sets it. JS `null` never
  /// reaches it.
  @internal
  @override
  types.Chart? get chart => _chart;

  @internal
  set chart(types.Chart value) => _chart = value;

  /// element.line.js:285 `_loop`. Dart `null` stands for JS `undefined`, the
  /// start value. `controller.radar.js:69` sets it. JS `null` never reaches
  /// it.
  @internal
  @override
  bool? get loop => _loop;

  @internal
  set loop(bool value) => _loop = value;

  /// element.line.js:286 `_fullLoop`. Dart `null` stands for JS
  /// `undefined`, the start value. `controller.radar.js:70` sets it. JS
  /// `null` never reaches it.
  @internal
  @override
  bool? get fullLoop => _fullLoop;

  @internal
  set fullLoop(bool value) => _fullLoop = value;

  /// element.line.js:292 `_datasetIndex`. Dart `null` stands for JS
  /// `undefined`, the start value. `controller.line.js:58` sets it. JS
  /// `null` never reaches it.
  ///
  /// The getter gives `null`, not NaN, in the `undefined` state:
  /// `helpers.segment` copies the `undefined` into the segment context
  /// (helpers.segment.js:282, :321).
  @internal
  @override
  double? get datasetIndex => _datasetIndex;

  @internal
  set datasetIndex(double value) => _datasetIndex = value;

  /// element.line.js:299 `updateControlPoints(chartArea, indexAxis)`.
  ///
  /// Sets the bezier control points of [points] once, for a line with a
  /// tension or the monotone mode and without steps. Dart `null` for
  /// [indexAxis] stands for JS `undefined`, which `splineCurveMonotone`
  /// replaces with its default `'x'` (helpers.curve.ts:122). The other
  /// branch of `_updateBezierControlPoints` does not read it.
  ///
  /// Each point is a [SplinePoint] (`types.PointElement`): `helpers.curve`
  /// writes its control points.
  ///
  /// Dart `null` for [chartArea] is JS `undefined` (no layout yet).
  /// `_updateBezierControlPoints` then throws a [TypeError] only when it caps
  /// a control point (`capBezierPoints`), as upstream does.
  @override
  void updateControlPoints(ChartArea? chartArea, [String? indexAxis]) {
    final options = this.options;
    if ((jsTruthy(_tension(options)) ||
            _cubicInterpolationMode(options) == 'monotone') &&
        !jsTruthy(_stepped(options)) &&
        !_pointsUpdated) {
      final loop = jsTruthy(_spanGaps(options)) ? _loop : _fullLoop;
      // `_updateBezierControlPoints(undefined, …)` throws a TypeError, as the
      // null check of `_points` does.
      updateBezierControlPoints(
        _points!,
        options!,
        chartArea,
        loop ?? false,
        indexAxis ?? 'x',
      );
      _pointsUpdated = true;
    }
  }

  /// element.line.js:308 `set points(points)`.
  ///
  /// It also drops the cached [segments], the cached path and the control
  /// points state, as `delete this._segments` and `delete this._path` do.
  ///
  /// Upstream stores any array: `index.d.ts:2026` declares `points:
  /// Point[]`, and the filler writes plain points (filler.helper.js:28-33,
  /// filler.target.stack.js:29). The port keeps a `List<types.PointElement>`:
  /// `helpers.segment` reads `skip` and `stop`, and `helpers.curve` writes
  /// the control points. A `List<types.PointElement>` stays as it is. Another
  /// list, for example the `meta.data` of a line controller, gives a typed
  /// copy with the same elements in the same order (Chart.js ADR 0028,
  /// section 3). An element that is not a `types.PointElement` throws a
  /// [TypeError] (the difference `adapt-line-points-elements`).
  // DIVERGES(chartjs): adapt-line-points-elements, point elements only.
  set points(List<types.Element> points) => _setPoints(_pointElements(points));

  /// element.line.js:315 `get points()`.
  ///
  /// The point elements of the line. Upstream returns `undefined` before the
  /// first write. `index.d.ts:2026` declares `points: Point[]`, and each
  /// upstream reader dereferences the value, which throws a `TypeError` for
  /// `undefined`: `_computeSegments` (helpers.segment.js:239-241),
  /// `pathVars` (element.line.js:41) and `path` (:412). Thus the getter
  /// throws a [TypeError] in the `undefined` state. [draw] reads the field,
  /// as upstream reads `this.points || []`. A reader that must tell the
  /// `undefined` state reads `line['points']`.
  @override
  List<types.PointElement> get points => _points ?? (throw TypeError());

  /// element.line.js:309-312, the body of `set points(points)`. Dart `null`
  /// for [points] stands for JS `undefined`.
  void _setPoints(List<types.PointElement>? points) {
    _points = points;
    _segments = null;
    _path = null;
    _pointsUpdated = false;
  }

  /// element.line.js:319 `get segments()`.
  ///
  /// The segments of `_computeSegments` with the option `segment`, computed
  /// at the first read. A write of [points] drops them. Throws a
  /// [TypeError] when [options] or [points] is in the `undefined` state.
  @override
  List<types.Segment> get segments =>
      _segments ??= computeSegments(this, _segment(options));

  /// element.line.js:327 `first()`.
  ///
  /// First non-skipped point on this line
  /// @returns {PointElement|undefined}
  ///
  /// Upstream returns `segments.length && points[…]`: the number 0 for a line
  /// without segments, which `index.d.ts:2028` declares as `false`. Dart
  /// `null` stands for that falsy value.
  @override
  types.PointElement? first() {
    final segments = this.segments;
    final points = this.points;
    return segments.isNotEmpty ? points[segments[0].start.toInt()] : null;
  }

  /// element.line.js:337 `last()`.
  ///
  /// Last non-skipped point on this line
  /// @returns {PointElement|undefined}
  ///
  /// Dart `null` stands for the falsy number 0 of a line without segments,
  /// as for [first].
  types.PointElement? last() {
    final segments = this.segments;
    final points = this.points;
    final count = segments.length;
    return count != 0 ? points[segments[count - 1].end.toInt()] : null;
  }

  /// element.line.js:351 `interpolate(point, property)`.
  ///
  /// Interpolate a point in this line at the same value on `property` as
  /// the reference `point` provided
  /// @param {PointElement} point - the reference point
  /// @param {string} property - the property to match on
  /// @returns {PointElement|undefined}
  ///
  /// The result is Dart `null` for JS `undefined` (no segment in the
  /// bounds), one [Point] for one segment, or a `List<Point>`. A [Point] of
  /// the result is a point of [points] or an [InterpolatedPoint].
  ///
  /// `index.d.ts:2030` declares [property] as `'x'` or `'y'`. The value of
  /// another name reads as `point[property]` of `PointElementProperty`
  /// (`'angle'`, or NaN). The write `interpolated[property] =
  /// point[property]` (element.line.js:374) sets the member `x` or `y` of the
  /// [InterpolatedPoint]. It has no member for another name, and the readers
  /// of the result read only `x` and `y` (filler.drawing.js:203).
  @override
  Object? interpolate(Point point, String property) {
    final options = this.options;
    final value = _pointValue(point, property);
    final points = this.points;
    final segments = boundSegments(this, (
      property: property,
      start: value,
      end: value,
    ));

    if (segments.isEmpty) {
      return null;
    }

    final result = <Point>[];
    // Upstream: _interpolate.
    final interpolateMethod = _getInterpolationMethod(options);
    for (var i = 0, ilen = segments.length; i < ilen; ++i) {
      final types.Segment(:start, :end) = segments[i];
      final p1 = points[start.toInt()];
      final p2 = points[end.toInt()];
      if (identical(p1, p2)) {
        result.add(p1);
        continue;
      }
      final t = ((value - p1[property]) / (p2[property] - p1[property])).abs();
      final interpolated = interpolateMethod(p1, p2, t, _stepped(options));
      switch (property) {
        case 'x':
          interpolated.x = point.x;
        case 'y':
          interpolated.y = point.y;
      }
      result.add(interpolated);
    }
    return result.length == 1 ? result[0] : result;
  }

  /// element.line.js:394 `pathSegment(ctx, segment, params)`.
  ///
  /// Append a segment of this line to current path.
  /// @param {CanvasRenderingContext2D} ctx
  /// @param {object} segment
  /// @param {number} segment.start - start index of the segment, referring
  /// the points array
  /// @param {number} segment.end - end index of the segment, referring the
  /// points array
  /// @param {boolean} segment.loop - indicates that the segment is a loop
  /// @param {object} params
  /// @param {boolean} params.move - move to starting point (vs line to it)
  /// @param {boolean} params.reverse - path the segment from end to start
  /// @param {number} params.start - limit segment to points starting from
  /// `start` index
  /// @param {number} params.end - limit segment to points ending at `start`
  /// + `count` index
  /// @returns {undefined|boolean} - true if the segment is a full loop (path
  /// should be closed)
  ///
  /// [ctx] is a context or a [Path2D]. [params] is the plain object `{move,
  /// reverse, start, end}`. Dart `null` stands for JS `undefined`, for
  /// [params] and for the result.
  @override
  bool? pathSegment(
    CanvasPath ctx,
    types.Segment segment, [
    AnyObject? params,
  ]) {
    final segmentMethod = _getSegmentMethod(this);
    return segmentMethod(ctx, this, segment, _pathParams(params));
  }

  /// element.line.js:406 `path(ctx, start, count)`.
  ///
  /// Append all segments of this line to current path.
  /// @param {CanvasRenderingContext2D|Path2D} ctx
  /// @param {number} `[start]`
  /// @param {number} `[count]`
  /// @returns {undefined|boolean} - true if line is a full loop (path should
  /// be closed)
  ///
  /// Dart `null` for [start] and [count] stands for JS `undefined`. `loop &=
  /// result` gives 1 only when `_loop` and each segment result are `true`.
  /// The Dart `&` of two `bool` values gives the same result. It also
  /// evaluates both operands.
  bool path(CanvasPath ctx, [double? start, double? count]) {
    final segments = this.segments;
    final segmentMethod = _getSegmentMethod(this);
    var loop = _loop ?? false;

    // Upstream reassigns its parameters.
    // ignore: parameter_assignments
    start = jsTruthy(start) ? start! : 0;
    // Upstream reassigns its parameters.
    // ignore: parameter_assignments
    count = jsTruthy(count) ? count! : points.length - start;

    for (final segment in segments) {
      loop &=
          segmentMethod(ctx, this, segment, (
            start: start,
            end: start + count - 1,
            move: null,
            reverse: false,
          )) ??
          false;
    }
    return loop;
  }

  /// element.line.js:427 `draw(ctx, chartArea, start, count)`.
  ///
  /// Draw
  /// @param {CanvasRenderingContext2D} ctx
  /// @param {object} chartArea
  /// @param {number} `[start]`
  /// @param {number} `[count]`
  ///
  /// [area] is the upstream `chartArea`, which `draw` does not read. Dart
  /// `null` for [start] and [count] stands for JS `undefined`. The test of
  /// `borderWidth` is `ToBoolean`, which is false for JS `undefined` and for
  /// JS `null`.
  @override
  void draw(
    CanvasRenderingContext2D ctx, [
    ChartArea? area,
    double? start,
    double? count,
  ]) {
    final options = this.options ?? const <String, Object?>{};
    final points = _points ?? const <types.PointElement>[];

    if (points.isNotEmpty && jsTruthy(_borderWidth(options))) {
      ctx.save();

      _draw(ctx, this, start, count);

      ctx.restore();
    }

    if (animated) {
      // When line is animated, the control points and path are not cached.
      _pointsUpdated = false;
      _path = null;
    }
  }

  /// index.d.ts:1848 `inRange`, which `index.d.ts:2022` declares through
  /// `VisualElement`.
  ///
  /// element.line.js has no `inRange`. A JavaScript call throws a
  /// `TypeError`: the method is not a function. Here the call throws a
  /// [NoSuchMethodError].
  @override
  bool inRange(
    double? mouseX,
    double? mouseY, [
    bool? useFinalPosition,
  ]) => throw NoSuchMethodError.withInvocation(
    this,
    Invocation.method(#inRange, [mouseX, mouseY, useFinalPosition]),
  );

  /// index.d.ts:1849 `inXRange`. element.line.js has no `inXRange`: the
  /// call throws a [NoSuchMethodError], as for [inRange].
  @override
  bool inXRange(
    double? mouseX, [
    bool? useFinalPosition,
  ]) => throw NoSuchMethodError.withInvocation(
    this,
    Invocation.method(#inXRange, [mouseX, useFinalPosition]),
  );

  /// index.d.ts:1850 `inYRange`. element.line.js has no `inYRange`: the
  /// call throws a [NoSuchMethodError], as for [inRange].
  @override
  bool inYRange(
    double? mouseY, [
    bool? useFinalPosition,
  ]) => throw NoSuchMethodError.withInvocation(
    this,
    Invocation.method(#inYRange, [mouseY, useFinalPosition]),
  );

  /// index.d.ts:1851 `getCenterPoint`. element.line.js has no
  /// `getCenterPoint`: the call throws a [NoSuchMethodError], as for
  /// [inRange].
  @override
  ElementPoint getCenterPoint([
    bool? useFinalPosition,
  ]) => throw NoSuchMethodError.withInvocation(
    this,
    Invocation.method(#getCenterPoint, [useFinalPosition]),
  );

  /// The JS property read `line[prop]` (Chart.js ADR 0017, section 5).
  ///
  /// It handles the names of element.line.js:282-292 and the accessors
  /// `points` and `segments`. A read of `segments` computes them, as the
  /// upstream getter does. A property in the `undefined` state gives the
  /// [undefined] sentinel. Other names go to [Element].
  @override
  Object? operator [](String prop) => switch (prop) {
    'animated' => animated,
    '_chart' => _chart ?? undefined,
    '_loop' => _loop ?? undefined,
    '_fullLoop' => _fullLoop ?? undefined,
    '_path' => _path ?? undefined,
    '_points' || 'points' => _points ?? undefined,
    '_segments' => _segments ?? undefined,
    'segments' => segments,
    '_decimated' => decimated,
    '_pointsUpdated' => _pointsUpdated,
    '_datasetIndex' => _datasetIndex ?? undefined,
    _ => super[prop],
  };

  /// The JS property write `line[prop] = value` (Chart.js ADR 0017,
  /// section 5).
  ///
  /// - `points` is the setter [points]: it takes a `List<types.Element>` or
  ///   [undefined]. It also drops the cached segments and path.
  /// - `_points` writes the field only, as upstream does.
  /// - `_chart` accepts a `types.Chart`, `_path` a [Path2D] and `_segments`
  ///   a `List<types.Segment>`, or [undefined].
  /// - `_loop` and `_fullLoop` accept a `bool` or [undefined].
  /// - `_datasetIndex` accepts a `num` or [undefined].
  /// - `animated`, `_decimated` and `_pointsUpdated` accept a `bool`.
  /// - `segments` has only a getter. A write throws in the strict mode of a
  ///   JavaScript module. Here it throws an [ArgumentError].
  ///
  /// Throws an [ArgumentError] for a value outside the type of a declared
  /// property. Other names go to [Element].
  @override
  void operator []=(String prop, Object? value) {
    switch (prop) {
      case 'animated':
        animated = toDefinedBoolProp(prop, value);
      case '_chart':
        _chart = toObjectProp<types.Chart>(prop, value);
      case '_loop':
        _loop = toBoolProp(prop, value);
      case '_fullLoop':
        _fullLoop = toBoolProp(prop, value);
      case '_path':
        _path = toObjectProp<Path2D>(prop, value);
      case 'points':
        // DIVERGES(chartjs): adapt-line-points-elements, point elements only.
        _setPoints(
          value is List<types.Element>
              ? _pointElements(value)
              : toObjectProp<List<types.PointElement>>(prop, value),
        );
      case '_points':
        // DIVERGES(chartjs): adapt-line-points-elements, point elements only.
        _points = toObjectProp<List<types.PointElement>>(prop, value);
      case '_segments':
        _segments = toObjectProp<List<types.Segment>>(prop, value);
      case 'segments':
        throw ArgumentError.value(value, prop, 'The property has no setter');
      case '_decimated':
        decimated = toDefinedBoolProp(prop, value);
      case '_pointsUpdated':
        _pointsUpdated = toDefinedBoolProp(prop, value);
      case '_datasetIndex':
        _datasetIndex = toNumberProp(prop, value);
      default:
        super[prop] = value;
    }
  }
}

/// The JS property read `point[property]` of the reference point of
/// [LineElement.interpolate].
///
/// A point element reads through the extension `PointElementProperty`. For
/// another [Point], `'x'` and `'y'` give the `ToNumber` of the member: JS
/// `null` gives 0 (`x ?? 0`, see [Point.x]). Every reader of the value
/// applies `ToNumber`. Another name gives NaN, the `ToNumber` of the
/// absent property.
double _pointValue(Point point, String property) => switch (point) {
  final types.PointElement element => element[property],
  _ => switch (property) {
    'x' => point.x ?? 0,
    'y' => point.y ?? 0,
    _ => double.nan,
  },
};

/// The points of [LineElement.points]: [points] itself when it is a
/// `List<types.PointElement>`, else a typed copy (Chart.js ADR 0028,
/// section 3). `List.generate` is the fastest copy on AOT and wasm.
List<types.PointElement> _pointElements(List<types.Element> points) =>
    points is List<types.PointElement>
    ? points
    : List<types.PointElement>.generate(
        points.length,
        (i) => points[i] as types.PointElement,
        growable: false,
      );
