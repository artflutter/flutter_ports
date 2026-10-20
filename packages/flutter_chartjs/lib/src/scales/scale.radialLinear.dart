// Ported from Chart.js v4.5.1 src/scales/scale.radialLinear.js (MIT, Chart.js Contributors).

/// Port of `src/scales/scale.radialLinear.js`.
///
/// [RadialLinearScale] is the scale of the radar and polar area charts. It
/// maps a value to a distance from the center, and an index to an angle. It
/// draws the point labels, the angle lines and the grid lines around the
/// center: circles, or polygons through the points of the labels.
///
/// - Options are the resolvers of `helpers.config` (Chart.js ADR 0006). The
///   scale reads an option with `options[key]` or [jsGet], tests it with
///   [jsTruthy], and applies [jsToNumber] before arithmetic.
/// - Numbers are `double` (Chart.js ADR 0010). A property that starts JS
///   `undefined` and holds a number starts as NaN.
/// - The value methods take any JS value (Chart.js ADR 0025, section 1).
///   They have no fast path (Chart.js ADR 0025, Open 1). The object
///   `{x, y, angle}` of [RadialLinearScale.getPointPosition] is a record
///   (Chart.js ADR 0003).
/// - The specs read `_pointLabels` and `_pointLabelItems`. Thus these
///   members drop the underscore and carry `@internal`
///   ([RadialLinearScale.pointLabels], [RadialLinearScale.pointLabelItems],
///   Chart.js ADR 0012, Chart.js ADR 0025, section 6). `_padding` has
///   readers only in this file. It keeps the underscore.
/// - A point label item is the public class [PointLabelItem]: the specs read
///   it, and the port writes its `visible` (Chart.js ADR 0025, section 6).
///
/// `core.scale.dart` imports `helpers.extras`, which is not a pure layer.
/// Thus this library is not a pure layer.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/core/core.ticks.dart' show formatters;
import 'package:flutter_chartjs/src/helpers/helpers.canvas.dart'
    show addRoundedRectPath, isPointInArea, longestText, renderText;
import 'package:flutter_chartjs/src/helpers/helpers.config.dart'
    show ContextProxy;
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show callback, isArray, isFinite, isNullOrUndef, valueOrDefault;
import 'package:flutter_chartjs/src/helpers/helpers.math.dart'
    show halfPi, normalizeAngle, pi, tau, toDegrees, toRadians;
import 'package:flutter_chartjs/src/helpers/helpers.options.dart'
    show ParsedFont, createContext, toFont, toPadding, toTRBLCorners;
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_math.dart' show jsMax, jsMin, jsRound;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/js/js_webidl.dart';
import 'package:flutter_chartjs/src/scales/scale.linearbase.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/geometric.dart' as types;
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// The object `{w, h}` of `measureLabelSize` (scale.radialLinear.js:21-24):
/// the width and the height of a point label.
typedef _LabelSize = ({double w, double h});

/// The object `{start, end}` of `determineLimits`
/// (scale.radialLinear.js:29-43).
typedef _Limit = ({double start, double end});

/// The object `itemOpts` of `buildPointLabelItems`
/// (scale.radialLinear.js:181-184, :188-189): `extra`, `additionalAngle`,
/// and the `padding` option and the label size of one index.
typedef _ItemOpts = ({
  double extra,
  double additionalAngle,
  Object? padding,
  _LabelSize size,
});

/// The objects `orig` and `limits` of `fitWithPointLabels`
/// (scale.radialLinear.js:79-85): the left, right, top and bottom edges.
///
/// `updateLimits` writes the edges of `limits`.
final class _Limits {
  _Limits({required this.l, required this.r, required this.t, required this.b});

  /// `Object.assign({}, orig)`: a copy of [orig].
  _Limits.of(_Limits orig) : l = orig.l, r = orig.r, t = orig.t, b = orig.b;

  /// `l`, the left edge.
  double l;

  /// `r`, the right edge.
  double r;

  /// `t`, the top edge.
  double t;

  /// `b`, the bottom edge.
  double b;
}

/// The object literal `{x, y}` of `isNotOverlapped`
/// (scale.radialLinear.js:171-172), a corner of a label box.
final class _Point implements types.Point {
  _Point(this.x, this.y);

  @override
  final double x;

  @override
  final double y;
}

/// The object literal `{x, y, w, h, radius}` of `drawPointLabelBox`
/// (scale.radialLinear.js:247-253).
final class _RoundedRect implements types.RoundedRect {
  _RoundedRect({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.radius,
  });

  @override
  final double x;

  @override
  final double y;

  @override
  final double w;

  @override
  final double h;

  @override
  final types.TRBLCorners radius;
}

/// The text options of a point label (scale.radialLinear.js:281-285) and of
/// a tick label (scale.radialLinear.js:670-674). The members that the
/// object literals leave out are Dart `null`, JS `undefined`.
final class _RenderTextOpts implements types.RenderTextOpts {
  _RenderTextOpts({
    this.color,
    this.strokeColor,
    this.strokeWidth,
    this.textAlign,
    this.textBaseline,
  });

  @override
  final Object? color;

  @override
  final Object? strokeColor;

  @override
  final double? strokeWidth;

  @override
  final String? textAlign;

  @override
  final String? textBaseline;

  @override
  types.BackdropOptions? get backdrop => null;

  @override
  double? get decorationWidth => null;

  @override
  double? get maxWidth => null;

  @override
  double? get rotation => null;

  @override
  bool? get strikethrough => null;

  @override
  (double, double)? get translation => null;

  @override
  bool? get underline => null;
}

/// The `setContext` of an option resolver: `options.setContext(context)`.
///
/// The option objects of a scale are `ContextProxy` resolvers. Another value
/// has no `setContext`. JavaScript then throws a `TypeError` at the call.
/// Here the cast throws it. The callers give the context of a point label
/// in the range of the labels, or of a tick: [context] is not Dart `null`.
ContextProxy _setContext(Object? options, AnyObject? context) =>
    (options! as ContextProxy).setContext(context!);

/// scale.radialLinear.js:9 `getTickBackdropHeight(opts)`.
///
/// [opts] are the options of the scale. `tickOpts.font && tickOpts.font.size`
/// gives the font itself when it is falsy. The font size is a raw option
/// value: a string size joins the padding height (`'12' + 4` gives
/// `'124'`, [jsAdd]). The three callers divide the result. Thus the
/// function gives the [jsToNumber] of the sum.
double _getTickBackdropHeight(Map<String, Object?> opts) {
  final tickOpts = opts['ticks'];

  if (jsTruthy(jsGet(tickOpts, 'display')) && jsTruthy(opts['display'])) {
    final padding = toPadding(jsGet(tickOpts, 'backdropPadding'));
    final font = jsGet(tickOpts, 'font');
    return jsToNumber(
      jsAdd(
        valueOrDefault<Object?>(
          jsTruthy(font) ? jsGet(font, 'size') : font,
          jsGet(defaults['font'], 'size'),
        ),
        padding.height,
      ),
    );
  }
  return 0;
}

/// scale.radialLinear.js:19 `measureLabelSize(ctx, font, label)`.
///
/// [label] is a label of the callback: an array gives one line for each
/// item.
_LabelSize _measureLabelSize(
  CanvasRenderingContext2D ctx,
  ParsedFont font,
  Object? label,
) {
  // Upstream reassigns its parameter with the List of the lines.
  final lines = isArray(label) ? label! as List<Object?> : <Object?>[label];
  return (
    w: longestText(ctx, font.string, lines),
    h: lines.length * font.lineHeight,
  );
}

/// scale.radialLinear.js:27 `determineLimits(angle, pos, size, min, max)`.
_Limit _determineLimits(
  double angle,
  double pos,
  double size,
  double min,
  double max,
) {
  if (angle == min || angle == max) {
    return (start: pos - (size / 2), end: pos + (size / 2));
  } else if (angle < min || angle > max) {
    return (start: pos - size, end: pos);
  }

  return (start: pos, end: pos + size);
}

/// scale.radialLinear.js:49 `fitWithPointLabels(scale)`.
///
/// Helper function to fit a radial linear scale with point labels
///
/// `padding[i]` is the raw `padding` option of the label `i`.
/// `scale.drawingArea + padding[i]` is [jsAdd]: a string padding joins the
/// drawing area. `getPointPosition` applies [jsToNumber] to the sum.
void _fitWithPointLabels(RadialLinearScale scale) {
  // Right, this is really confusing and there is a lot of maths going on
  // here
  // The gist of the problem is here:
  // https://gist.github.com/nnnick/696cc9c55f4b0beb8fe9
  //
  // Reaction: https://dl.dropboxusercontent.com/u/34601363/toomuchscience.gif
  //
  // Solution:
  //
  // We assume the radius of the polygon is half the size of the canvas at
  // first at each index we check if the text overlaps.
  //
  // Where it does, we store that angle and that index.
  //
  // After finding the largest index and angle we calculate how much we need
  // to remove from the shape radius to move the point inwards by that x.
  //
  // We average the left and right distances to get the maximum shape radius
  // that can fit in the box along with labels.
  //
  // Once we have that, we can find the centre point for the chart, by taking
  // the x text protrusion on each side, removing that from the size, halving
  // it and adding the left x protrusion width.
  //
  // This will mean we have a shape fitted to the canvas, as large as it can
  // be with the labels and position it in the most space efficient manner
  //
  // https://dl.dropboxusercontent.com/u/34601363/yeahscience.gif

  // Get maximum radius of the polygon. Either half the height (minus the text
  // width) or half the width.
  // Use this to calculate the offset + change. - Make sure L/R protrusion is
  // at least 0 to stop issues with centre points
  final orig = _Limits(
    l: scale.left + scale._padding!.left,
    r: scale.right - scale._padding!.right,
    t: scale.top + scale._padding!.top,
    b: scale.bottom - scale._padding!.bottom,
  );
  final limits = _Limits.of(orig);
  final labelSizes = <_LabelSize>[];
  final padding = <Object?>[];
  final valueCount = scale.pointLabels.length;
  final pointLabelOpts = scale.options['pointLabels'];
  final additionalAngle = jsTruthy(jsGet(pointLabelOpts, 'centerPointLabels'))
      ? pi / valueCount
      : 0.0;

  for (var i = 0; i < valueCount; i++) {
    final opts = _setContext(pointLabelOpts, scale.getPointLabelContext(i));
    padding.add(opts['padding']);
    final pointPosition = scale.getPointPosition(
      i.toDouble(),
      jsToNumber(jsAdd(scale.drawingArea, padding[i])),
      additionalAngle,
    );
    final plFont = toFont(opts['font']);
    final textSize = _measureLabelSize(
      scale.ctx!,
      plFont,
      scale.pointLabels[i],
    );
    labelSizes.add(textSize);

    final angleRadians = normalizeAngle(
      scale.getIndexAngle(i.toDouble()) + additionalAngle,
    );
    final angle = jsRound(toDegrees(angleRadians));
    final hLimits = _determineLimits(
      angle,
      pointPosition.x,
      textSize.w,
      0,
      180,
    );
    final vLimits = _determineLimits(
      angle,
      pointPosition.y,
      textSize.h,
      90,
      270,
    );
    _updateLimits(limits, orig, angleRadians, hLimits, vLimits);
  }

  scale
    ..setCenterPoint(
      orig.l - limits.l,
      limits.r - orig.r,
      orig.t - limits.t,
      limits.b - orig.b,
    )
    // Now that text size is determined, compute the full positions
    ..pointLabelItems = _buildPointLabelItems(scale, labelSizes, padding);
}

/// scale.radialLinear.js:118 `updateLimits(limits, orig, angle, hLimits,
/// vLimits)`.
void _updateLimits(
  _Limits limits,
  _Limits orig,
  double angle,
  _Limit hLimits,
  _Limit vLimits,
) {
  final sin = math.sin(angle).abs();
  final cos = math.cos(angle).abs();
  double x;
  double y;
  if (hLimits.start < orig.l) {
    x = (orig.l - hLimits.start) / sin;
    limits.l = jsMin(limits.l, orig.l - x);
  } else if (hLimits.end > orig.r) {
    x = (hLimits.end - orig.r) / sin;
    limits.r = jsMax(limits.r, orig.r + x);
  }
  if (vLimits.start < orig.t) {
    y = (orig.t - vLimits.start) / cos;
    limits.t = jsMin(limits.t, orig.t - y);
  } else if (vLimits.end > orig.b) {
    y = (vLimits.end - orig.b) / cos;
    limits.b = jsMax(limits.b, orig.b + y);
  }
}

/// scale.radialLinear.js:139 `createPointLabelItem(scale, index, itemOpts)`.
///
/// The `padding` of [itemOpts] is the raw `padding` option.
/// `outerDistance + extra + padding` is [jsAdd] for the last `+`: a string
/// padding joins the sum. `getPointPosition` applies [jsToNumber] to it.
PointLabelItem _createPointLabelItem(
  RadialLinearScale scale,
  int index,
  _ItemOpts itemOpts,
) {
  final outerDistance = scale.drawingArea;
  final (:extra, :additionalAngle, :padding, :size) = itemOpts;
  final pointLabelPosition = scale.getPointPosition(
    index.toDouble(),
    jsToNumber(jsAdd(outerDistance + extra, padding)),
    additionalAngle,
  );
  final angle = jsRound(
    toDegrees(normalizeAngle(pointLabelPosition.angle + halfPi)),
  );
  final y = _yForAngle(pointLabelPosition.y, size.h, angle);
  final textAlign = _getTextAlignForAngle(angle);
  final left = _leftForTextAlign(pointLabelPosition.x, size.w, textAlign);
  return PointLabelItem(
    // Text position
    x: pointLabelPosition.x,
    y: y,

    // Text rendering data
    textAlign: textAlign,

    // Bounding box
    left: left,
    top: y,
    right: left + size.w,
    bottom: y + size.h,
  );
}

/// scale.radialLinear.js:166 `isNotOverlapped(item, area)`.
///
/// Dart `null` for [area] stands for JS `undefined`: no label is visible
/// yet.
bool _isNotOverlapped(PointLabelItem item, PointLabelItem? area) {
  if (area == null) {
    return true;
  }
  final PointLabelItem(:left, :top, :right, :bottom) = item;
  final apexesInArea =
      isPointInArea(_Point(left, top), area) ||
      isPointInArea(_Point(left, bottom), area) ||
      isPointInArea(_Point(right, top), area) ||
      isPointInArea(_Point(right, bottom), area);
  return !apexesInArea;
}

/// scale.radialLinear.js:176 `buildPointLabelItems(scale, labelSizes,
/// padding)`.
///
/// Upstream writes the `padding` and the `size` of each index into one
/// object `itemOpts`. Here each index gets a record with the same members.
List<PointLabelItem> _buildPointLabelItems(
  RadialLinearScale scale,
  List<_LabelSize> labelSizes,
  List<Object?> padding,
) {
  final items = <PointLabelItem>[];
  final valueCount = scale.pointLabels.length;
  final opts = scale.options;
  final pointLabels = opts['pointLabels'];
  final centerPointLabels = jsGet(pointLabels, 'centerPointLabels');
  final display = jsGet(pointLabels, 'display');
  final extra = _getTickBackdropHeight(opts) / 2;
  final additionalAngle = jsTruthy(centerPointLabels) ? pi / valueCount : 0.0;
  PointLabelItem? area;

  for (var i = 0; i < valueCount; i++) {
    final itemOpts = (
      extra: extra,
      additionalAngle: additionalAngle,
      padding: padding[i],
      size: labelSizes[i],
    );

    final item = _createPointLabelItem(scale, i, itemOpts);
    items.add(item);
    if (display == 'auto') {
      item.visible = _isNotOverlapped(item, area);
      if (item.visible) {
        area = item;
      }
    }
  }
  return items;
}

/// scale.radialLinear.js:203 `getTextAlignForAngle(angle)`.
String _getTextAlignForAngle(double angle) {
  if (angle == 0 || angle == 180) {
    return 'center';
  } else if (angle < 180) {
    return 'left';
  }

  return 'right';
}

/// scale.radialLinear.js:213 `leftForTextAlign(x, w, align)`.
double _leftForTextAlign(double x, double w, String align) {
  if (align == 'right') {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    x -= w;
  } else if (align == 'center') {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    x -= w / 2;
  }
  return x;
}

/// scale.radialLinear.js:222 `yForAngle(y, h, angle)`.
double _yForAngle(double y, double h, double angle) {
  if (angle == 90 || angle == 270) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    y -= h / 2;
  } else if (angle > 270 || angle < 90) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    y -= h;
  }
  return y;
}

/// scale.radialLinear.js:231 `drawPointLabelBox(ctx, opts, item)`.
///
/// `Object.values(borderRadius).some(v => v !== 0)` tests the four corners.
/// A NaN corner differs from 0, in Dart as in JavaScript.
void _drawPointLabelBox(
  CanvasRenderingContext2D ctx,
  Map<String, Object?> opts,
  PointLabelItem item,
) {
  final PointLabelItem(:left, :top, :right, :bottom) = item;
  final backdropColor = opts['backdropColor'];

  if (!isNullOrUndef(backdropColor)) {
    final borderRadius = toTRBLCorners(opts['borderRadius']);
    final padding = toPadding(opts['backdropPadding']);
    ctx.fillStyle = canvasStyle(backdropColor);

    final backdropLeft = left - padding.left;
    final backdropTop = top - padding.top;
    final backdropWidth = right - left + padding.width;
    final backdropHeight = bottom - top + padding.height;

    if (borderRadius.topLeft != 0 ||
        borderRadius.topRight != 0 ||
        borderRadius.bottomLeft != 0 ||
        borderRadius.bottomRight != 0) {
      ctx.beginPath();
      addRoundedRectPath(
        ctx,
        _RoundedRect(
          x: backdropLeft,
          y: backdropTop,
          w: backdropWidth,
          h: backdropHeight,
          radius: borderRadius,
        ),
      );
      ctx.fill();
    } else {
      ctx.fillRect(backdropLeft, backdropTop, backdropWidth, backdropHeight);
    }
  }
}

/// scale.radialLinear.js:261 `drawPointLabels(scale, labelCount)`.
void _drawPointLabels(RadialLinearScale scale, int labelCount) {
  final ctx = scale.ctx;
  final pointLabels = scale.options['pointLabels'];

  for (var i = labelCount - 1; i >= 0; i--) {
    final item = scale.pointLabelItems[i];
    if (!item.visible) {
      // overlapping
      continue;
    }
    final optsAtIndex = _setContext(pointLabels, scale.getPointLabelContext(i));
    _drawPointLabelBox(ctx!, optsAtIndex, item);
    final plFont = toFont(optsAtIndex['font']);
    final PointLabelItem(:x, :y, :textAlign) = item;

    renderText(
      ctx,
      scale.pointLabels[i],
      x,
      y + (plFont.lineHeight / 2),
      plFont,
      _RenderTextOpts(
        color: optsAtIndex['color'],
        textAlign: textAlign,
        textBaseline: 'middle',
      ),
    );
  }
}

/// scale.radialLinear.js:290 `pathRadiusLine(scale, radius, circular,
/// labelCount)`.
///
/// [circular] is the `grid.circular` option, a truthiness test.
void _pathRadiusLine(
  RadialLinearScale scale,
  double radius,
  Object? circular,
  int labelCount,
) {
  final ctx = scale.ctx!;
  if (jsTruthy(circular)) {
    // Draw circular arcs between the points
    ctx.arc(scale.xCenter, scale.yCenter, radius, 0, tau);
  } else {
    // Draw straight lines connecting each index
    var pointPosition = scale.getPointPosition(0, radius);
    ctx.moveTo(pointPosition.x, pointPosition.y);

    for (var i = 1; i < labelCount; i++) {
      pointPosition = scale.getPointPosition(i.toDouble(), radius);
      ctx.lineTo(pointPosition.x, pointPosition.y);
    }
  }
}

/// scale.radialLinear.js:307 `drawRadiusLine(scale, gridLineOpts, radius,
/// labelCount, borderOpts)`.
///
/// `circular`, `color` and `lineWidth` are option values: truthiness tests.
void _drawRadiusLine(
  RadialLinearScale scale,
  Map<String, Object?> gridLineOpts,
  double radius,
  int labelCount,
  Map<String, Object?> borderOpts,
) {
  final ctx = scale.ctx;
  final circular = gridLineOpts['circular'];

  final color = gridLineOpts['color'];
  final lineWidth = gridLineOpts['lineWidth'];

  if ((!jsTruthy(circular) && labelCount == 0) ||
      !jsTruthy(color) ||
      !jsTruthy(lineWidth) ||
      radius < 0) {
    return;
  }

  final dash = borderOpts['dash'];
  ctx!
    ..save()
    ..strokeStyle = canvasStyle(color)
    ..lineWidth = canvasNumber(lineWidth)
    ..setLineDash(canvasLineDash(jsTruthy(dash) ? dash : <Object?>[]))
    ..lineDashOffset = canvasNumber(borderOpts['dashOffset'])
    ..beginPath();
  _pathRadiusLine(scale, radius, circular, labelCount);
  ctx
    ..closePath()
    ..stroke()
    ..restore();
}

/// scale.radialLinear.js:330 `createPointLabelContext(parent, index,
/// label)`.
///
/// The index of the context is a number, which a scriptable option reads.
AnyObject _createPointLabelContext(AnyObject parent, int index, Object? label) {
  return createContext(parent, <String, Object?>{
    'label': label,
    'index': index.toDouble(),
    'type': 'pointLabel',
  });
}

/// scale.radialLinear.js:147-163 the object of `createPointLabelItem`: the
/// position, the text alignment and the box of a point label.
///
/// It is a class, not a record: the specs read [x] and [y]
/// (scale.radialLinear.tests.js:651-652), and `buildPointLabelItems` writes
/// [visible] (Chart.js ADR 0025, section 6). `isNotOverlapped` gives it to
/// `_isPointInArea` as the area. Thus it implements [types.TRBL].
final class PointLabelItem implements types.TRBL {
  /// The item of a label at ([x], [y]) with the alignment [textAlign] and
  /// the box [left], [top], [right] and [bottom].
  PointLabelItem({
    required this.x,
    required this.y,
    required this.textAlign,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// scale.radialLinear.js:149 `visible: true`, if to draw or overlapped.
  /// `buildPointLabelItems` writes it for the `display` option `'auto'`
  /// (scale.radialLinear.js:194).
  bool visible = true;

  /// scale.radialLinear.js:152 `x`, the text position.
  final double x;

  /// scale.radialLinear.js:153 `y`, the text position: the top of the
  /// first line.
  final double y;

  /// scale.radialLinear.js:156 `textAlign`: `'left'`, `'right'` or
  /// `'center'`.
  final String textAlign;

  /// scale.radialLinear.js:159 `left`, the bounding box.
  @override
  final double left;

  /// scale.radialLinear.js:160 `top`, the bounding box.
  @override
  final double top;

  /// scale.radialLinear.js:161 `right`, the bounding box.
  @override
  final double right;

  /// scale.radialLinear.js:162 `bottom`, the bounding box.
  @override
  final double bottom;
}

/// scale.radialLinear.js:338 `RadialLinearScale extends LinearScaleBase`.
class RadialLinearScale extends LinearScaleBase {
  /// scale.radialLinear.js:412 `constructor(cfg)`.
  ///
  /// [cfg] is the object `{id, type, ctx, chart}` of [Scale.new]. The fields
  /// get their start values in their declarations
  /// (scale.radialLinear.js:415-423).
  RadialLinearScale(super.cfg);

  // scale.radialLinear.js:340 `static id = 'radialLinear'`. Scale has the
  // instance field `id`. Thus the value is only in the statics of jsClass.

  /// scale.radialLinear.js:345 `static defaults`.
  static final AnyObject defaults = {
    'display': true,

    // Boolean - Whether to animate scaling the chart from the centre
    'animate': true,
    'position': 'chartArea',

    'angleLines': <String, Object?>{
      'display': true,
      'lineWidth': 1.0,
      'borderDash': <Object?>[],
      'borderDashOffset': 0.0,
    },

    'grid': <String, Object?>{'circular': false},

    'startAngle': 0.0,

    // label settings
    'ticks': <String, Object?>{
      // Boolean - Show a backdrop to the scale label
      'showLabelBackdrop': true,

      'callback': formatters['numeric'],
    },

    'pointLabels': <String, Object?>{
      'backdropColor': undefined,

      // Number - The backdrop padding above & below the label in pixels
      'backdropPadding': 2.0,

      // Boolean - if true, show point labels
      'display': true,

      // Number - Point label font size in pixels
      'font': <String, Object?>{'size': 10.0},

      // Function - Used to convert point labels
      'callback': (Object? label) => label,

      // Number - Additionl padding between scale and pointLabel
      'padding': 5.0,

      // Boolean - if true, center point labels to slices in polar chart
      'centerPointLabels': false,
    },
  };

  /// scale.radialLinear.js:400 `static defaultRoutes`.
  static final AnyObject defaultRoutes = {
    'angleLines.color': 'borderColor',
    'pointLabels.color': 'color',
    'ticks.color': 'color',
  };

  /// scale.radialLinear.js:406 `static descriptors`.
  static final AnyObject descriptors = {
    'angleLines': <String, Object?>{'_fallback': 'grid'},
  };

  /// scale.radialLinear.js:338 `class RadialLinearScale extends
  /// LinearScaleBase` as a value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [LinearScaleBase.jsClass]. Its statics are `id`
  /// (`'radialLinear'`), [defaults], [defaultRoutes] and [descriptors], in
  /// the upstream order of declaration (scale.radialLinear.js:340-410). Its
  /// `construct` calls `RadialLinearScale(cfg)` with the `cfg` of
  /// [scaleCfgArg].
  static final JsClass jsClass = JsClass(
    'RadialLinearScale',
    superclass: LinearScaleBase.jsClass,
    statics: {
      'id': 'radialLinear',
      'defaults': defaults,
      'defaultRoutes': defaultRoutes,
      'descriptors': descriptors,
    },
    construct: (newTarget, args) => RadialLinearScale(scaleCfgArg(args)),
  );

  /// scale.radialLinear.js:416 `xCenter`, the x of the center. NaN stands
  /// for JS `undefined`, the start value.
  double xCenter = double.nan;

  /// scale.radialLinear.js:418 `yCenter`, the y of the center. NaN stands
  /// for JS `undefined`.
  double yCenter = double.nan;

  /// scale.radialLinear.js:420 `drawingArea`, the radius of the value
  /// range. NaN stands for JS `undefined`.
  double drawingArea = double.nan;

  /// scale.radialLinear.js:422 `_pointLabels`. The spec reads it
  /// (scale.radialLinear.tests.js:330, :355, :369, :385). A label is any value
  /// of the callback (scale.radialLinear.js:458-462).
  @internal
  List<Object?> pointLabels = [];

  /// scale.radialLinear.js:423 `_pointLabelItems`. The spec reads it
  /// (scale.radialLinear.tests.js:630).
  @internal
  List<PointLabelItem> pointLabelItems = [];

  /// scale.radialLinear.js:428 `_padding`, the padding of the tick
  /// backdrop. [setDimensions] writes it. Dart `null` stands for JS
  /// `undefined`: the constructor does not declare it.
  types.ChartArea? _padding;

  /// scale.radialLinear.js:426 `setDimensions()`.
  @override
  void setDimensions() {
    // Set the unconstrained dimension before label rotation
    final padding = _padding = toPadding(_getTickBackdropHeight(options) / 2);
    final w = width = maxWidth - padding.width;
    final h = height = maxHeight - padding.height;
    xCenter = (left + w / 2 + padding.left).floorToDouble();
    yCenter = (top + h / 2 + padding.top).floorToDouble();
    drawingArea = (jsMin(w, h) / 2).floorToDouble();
  }

  /// scale.radialLinear.js:436 `determineDataLimits()`.
  @override
  void determineDataLimits() {
    final (:min, :max) = getMinMax(false);

    this.min = isFinite(min) && !min.isNaN ? min : 0;
    this.max = isFinite(max) && !max.isNaN ? max : 0;

    // Common base implementation to handle min, max, beginAtZero
    handleTickRangeOptions();
  }

  /// scale.radialLinear.js:450 `computeTickLimit()`.
  ///
  /// Returns the maximum number of ticks based on the scale dimension
  /// @protected
  @override
  @protected
  double computeTickLimit() {
    return (drawingArea / _getTickBackdropHeight(options)).ceilToDouble();
  }

  /// scale.radialLinear.js:454 `generateTickLabels(ticks)`.
  ///
  /// `LinearScaleBase.prototype.generateTickLabels.call(this, ticks)` is the
  /// `generateTickLabels` of [Scale]: [LinearScaleBase] does not override
  /// it. The callback gets the index as a number. The filter reads the data
  /// visibility of the chart (`types.Chart.getDataVisibility`, Chart.js ADR
  /// 0025, section 4).
  @override
  void generateTickLabels(List<Tick> ticks) {
    super.generateTickLabels(ticks);

    // Point labels
    final labels = getLabels();
    final length = labels.length;
    final mapped = <Object?>[
      for (var index = 0; index < length; index++)
        _pointLabelOf(
          callback(jsGet(options['pointLabels'], 'callback'), [
            labels[index],
            index.toDouble(),
          ], this),
        ),
    ];
    pointLabels = [
      for (var i = 0; i < mapped.length; i++)
        if (chart.getDataVisibility(i.toDouble())) mapped[i],
    ];
  }

  /// `label || label === 0 ? label : ''` of scale.radialLinear.js:461.
  static Object? _pointLabelOf(Object? label) =>
      jsTruthy(label) || (label is num && label == 0) ? label : '';

  /// scale.radialLinear.js:466 `fit()`.
  @override
  void fit() {
    final opts = options;

    if (jsTruthy(opts['display']) &&
        jsTruthy(jsGet(opts['pointLabels'], 'display'))) {
      _fitWithPointLabels(this);
    } else {
      setCenterPoint(0, 0, 0, 0);
    }
  }

  /// scale.radialLinear.js:476 `setCenterPoint(leftMovement, rightMovement,
  /// topMovement, bottomMovement)`.
  void setCenterPoint(
    double leftMovement,
    double rightMovement,
    double topMovement,
    double bottomMovement,
  ) {
    xCenter += ((leftMovement - rightMovement) / 2).floorToDouble();
    yCenter += ((topMovement - bottomMovement) / 2).floorToDouble();
    drawingArea -= jsMin(
      drawingArea / 2,
      jsMax(
        jsMax(leftMovement, rightMovement),
        jsMax(topMovement, bottomMovement),
      ),
    );
  }

  /// scale.radialLinear.js:482 `getIndexAngle(index)`.
  ///
  /// `this._pointLabels.length || 1` gives 1 for no labels.
  /// `this.options.startAngle || 0` is [jsOrZero].
  double getIndexAngle(double index) {
    final angleMultiplier =
        tau / (pointLabels.isEmpty ? 1 : pointLabels.length);
    final startAngle = jsOrZero(options['startAngle']);

    return normalizeAngle(index * angleMultiplier + toRadians(startAngle));
  }

  /// scale.radialLinear.js:489 `getDistanceFromCenterForValue(value)`.
  ///
  /// [value] is any JS value (Chart.js ADR 0025). `null` and `undefined`
  /// give NaN. The `-` applies [jsToNumber] to another value.
  double getDistanceFromCenterForValue(Object? value) {
    if (isNullOrUndef(value)) {
      return double.nan;
    }

    // Take into account half font size + the yPadding of the top value
    final scalingFactor = drawingArea / (max - min);
    if (jsTruthy(options['reverse'])) {
      return (max - jsToNumber(value)) * scalingFactor;
    }
    return (jsToNumber(value) - min) * scalingFactor;
  }

  /// scale.radialLinear.js:502 `getValueForDistanceFromCenter(distance)`.
  ///
  /// Dart `null` is JS `null` and `undefined`: both give NaN. No upstream
  /// file passes a value that is not a number (Chart.js ADR 0025).
  double getValueForDistanceFromCenter(double? distance) {
    if (isNullOrUndef(distance)) {
      return double.nan;
    }

    final scaledDistance = distance! / (drawingArea / (max - min));
    return jsTruthy(options['reverse'])
        ? max - scaledDistance
        : min + scaledDistance;
  }

  /// scale.radialLinear.js:511 `getPointLabelContext(index)`.
  ///
  /// The scriptable context of the point label [index]. Dart `null` stands
  /// for the JS `undefined` of an index out of the range of the labels.
  AnyObject? getPointLabelContext(int index) {
    // `this._pointLabels || []`: a List is truthy.
    final pointLabels = this.pointLabels;

    if (index >= 0 && index < pointLabels.length) {
      final pointLabel = pointLabels[index];
      return _createPointLabelContext(getContext(), index, pointLabel);
    }
    return null;
  }

  /// scale.radialLinear.js:520 `getPointPosition(index, distanceFromCenter,
  /// additionalAngle = 0)`. The result is the object literal `{x, y, angle}`
  /// (:522-526), a record (Chart.js ADR 0003).
  ({double x, double y, double angle}) getPointPosition(
    double index,
    double distanceFromCenter, [
    double additionalAngle = 0,
  ]) {
    final angle = getIndexAngle(index) - halfPi + additionalAngle;
    return (
      x: math.cos(angle) * distanceFromCenter + xCenter,
      y: math.sin(angle) * distanceFromCenter + yCenter,
      angle: angle,
    );
  }

  /// scale.radialLinear.js:529 `getPointPositionForValue(index, value)`.
  ///
  /// [value] is any JS value (Chart.js ADR 0025).
  ({double x, double y, double angle}) getPointPositionForValue(
    double index,
    Object? value,
  ) {
    return getPointPosition(index, getDistanceFromCenterForValue(value));
  }

  /// scale.radialLinear.js:533 `getBasePosition(index)`. `index || 0` is
  /// [jsOrZero].
  ({double x, double y, double angle}) getBasePosition([double? index]) {
    return getPointPositionForValue(jsOrZero(index), getBaseValue());
  }

  /// scale.radialLinear.js:537 `getPointLabelPosition(index)`.
  ///
  /// The result is the object literal `{left, top, right, bottom}`
  /// (:539-544), a record (Chart.js ADR 0003). An index out of the range of
  /// the items throws a [RangeError], where JavaScript throws a `TypeError`
  /// at the read of `undefined`.
  ({double left, double top, double right, double bottom})
  getPointLabelPosition(int index) {
    final PointLabelItem(:left, :top, :right, :bottom) = pointLabelItems[index];
    return (left: left, top: top, right: right, bottom: bottom);
  }

  /// scale.radialLinear.js:550 `drawBackground()`.
  ///
  /// @protected
  ///
  /// The background is the path of the outer grid line, at the distance of
  /// `_endValue` ([endValue]).
  @override
  @protected
  void drawBackground() {
    final backgroundColor = options['backgroundColor'];
    final circular = jsGet(options['grid'], 'circular');
    if (jsTruthy(backgroundColor)) {
      final ctx = this.ctx!
        ..save()
        ..beginPath();
      _pathRadiusLine(
        this,
        getDistanceFromCenterForValue(endValue),
        circular,
        pointLabels.length,
      );
      ctx
        ..closePath()
        ..fillStyle = canvasStyle(backgroundColor)
        ..fill()
        ..restore();
    }
  }

  /// scale.radialLinear.js:567 `drawGrid()`.
  ///
  /// @protected
  ///
  /// `index.d.ts:1296` declares a [chartArea] parameter. The upstream body
  /// does not read it.
  @override
  @protected
  void drawGrid([types.ChartArea? chartArea]) {
    final ctx = this.ctx;
    final opts = options;
    final angleLines = opts['angleLines'];
    final grid = opts['grid'];
    final border = opts['border'];
    final labelCount = pointLabels.length;

    if (jsTruthy(jsGet(opts['pointLabels'], 'display'))) {
      _drawPointLabels(this, labelCount);
    }

    if (jsTruthy(jsGet(grid, 'display'))) {
      final ticks = this.ticks!;
      for (var index = 0; index < ticks.length; index++) {
        final tick = ticks[index];
        if (index != 0 || (index == 0 && min < 0)) {
          final offset = getDistanceFromCenterForValue(tick.value);
          final context = getContext(index);
          final optsAtIndex = _setContext(grid, context);
          final optsAtIndexBorder = _setContext(border, context);

          _drawRadiusLine(
            this,
            optsAtIndex,
            offset,
            labelCount,
            optsAtIndexBorder,
          );
        }
      }
    }

    if (jsTruthy(jsGet(angleLines, 'display'))) {
      ctx!.save();

      for (var i = labelCount - 1; i >= 0; i--) {
        final optsAtIndex = _setContext(angleLines, getPointLabelContext(i));
        final color = optsAtIndex['color'];
        final lineWidth = optsAtIndex['lineWidth'];

        if (!jsTruthy(lineWidth) || !jsTruthy(color)) {
          continue;
        }

        ctx
          ..lineWidth = canvasNumber(lineWidth)
          ..strokeStyle = canvasStyle(color)
          ..setLineDash(canvasLineDash(optsAtIndex['borderDash']))
          ..lineDashOffset = canvasNumber(optsAtIndex['borderDashOffset']);

        final offset = getDistanceFromCenterForValue(
          jsTruthy(opts['reverse']) ? min : max,
        );
        final position = getPointPosition(i.toDouble(), offset);
        ctx
          ..beginPath()
          ..moveTo(xCenter, yCenter)
          ..lineTo(position.x, position.y)
          ..stroke();
      }

      ctx.restore();
    }
  }

  /// scale.radialLinear.js:624 `drawBorder()`.
  ///
  /// @protected
  @override
  @protected
  void drawBorder() {}

  /// scale.radialLinear.js:629 `drawLabels()`.
  ///
  /// @protected
  ///
  /// `index.d.ts:1295` declares a [chartArea] parameter. The upstream body
  /// does not read it. `ctx.measureText(tick.label)` applies the DOM
  /// `ToString` to the label ([jsToString]).
  @override
  @protected
  void drawLabels([types.ChartArea? chartArea]) {
    final ctx = this.ctx;
    final opts = options;
    final tickOpts = opts['ticks'];

    if (!jsTruthy(jsGet(tickOpts, 'display'))) {
      return;
    }

    final startAngle = getIndexAngle(0);

    ctx!
      ..save()
      ..translate(xCenter, yCenter)
      ..rotate(startAngle)
      ..textAlign = 'center'
      ..textBaseline = 'middle';

    final ticks = this.ticks!;
    for (var index = 0; index < ticks.length; index++) {
      final tick = ticks[index];
      if ((index == 0 && min >= 0) && !jsTruthy(opts['reverse'])) {
        continue;
      }

      final optsAtIndex = _setContext(tickOpts, getContext(index));
      final tickFont = toFont(optsAtIndex['font']);
      final offset = getDistanceFromCenterForValue(this.ticks![index].value);

      if (jsTruthy(optsAtIndex['showLabelBackdrop'])) {
        ctx.font = tickFont.string;
        final width = ctx.measureText(jsToString(tick.label)).width;
        ctx.fillStyle = canvasStyle(optsAtIndex['backdropColor']);

        final padding = toPadding(optsAtIndex['backdropPadding']);
        ctx.fillRect(
          -width / 2 - padding.left,
          -offset - jsToNumber(tickFont.size) / 2 - padding.top,
          width + padding.width,
          jsToNumber(tickFont.size) + padding.height,
        );
      }

      renderText(
        ctx,
        tick.label,
        0,
        -offset,
        tickFont,
        _RenderTextOpts(
          color: optsAtIndex['color'],
          strokeColor: optsAtIndex['textStrokeColor'],
          strokeWidth: canvasNumber(optsAtIndex['textStrokeWidth']),
        ),
      );
    }

    ctx.restore();
  }

  /// scale.radialLinear.js:683 `drawTitle()`.
  ///
  /// @protected
  @override
  @protected
  void drawTitle([types.ChartArea? chartArea]) {}
}
