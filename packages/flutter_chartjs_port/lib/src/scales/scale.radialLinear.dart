// Ported from Chart.js v4.6.1 src/scales/scale.radialLinear.js (MIT, Chart.js Contributors).

/// Port of `src/scales/scale.radialLinear.js`.
///
/// [RadialLinearScale] is the scale of the radar and polar area charts. It
/// maps a value to a distance from the center, and an index to an angle. It
/// draws the point labels, the angle lines and the grid lines around the
/// center: circles, or polygons through the points of the labels.
///
/// - Options are the typed resolver views of `helpers.config` (Chart.js ADR
///   0054 §4), through the facade [RadialLinearScaleOptions]. The scale
///   reads an option with a getter of the facade
///   (`options.pointLabels.padding`), tests it with [jsTruthy], and applies
///   [jsToNumber] before arithmetic. The `setContext` of a facade casts the
///   option object to a `ContextProxy`: another value has no `setContext`,
///   and JavaScript then throws a `TypeError` at the call. The callers give
///   the context of a point label in the range of the labels, or of a tick:
///   it is not Dart `null`.
/// - Numbers are `double` (Chart.js ADR 0045). A property that starts JS
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
/// - The loops over the point labels have guarded static plans for the exact
///   class on the native canvas (Chart.js ADR 0095). Each plan belongs to one
///   fit or one draw and follows one ordinary pass of its first index.
///
/// `core.scale.dart` imports `helpers.extras`, which is not a pure layer.
/// Thus this library is not a pure layer.
library;

import 'dart:ui' show TextAlign;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_line_fan.dart';
import 'package:flutter_chartjs_port/src/core/arc_options.dart'
    show NativeArcScale;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/core.ticks.dart' show formatters;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show nativeDataUpdateList;
import 'package:flutter_chartjs_port/src/core/point_options.dart'
    show nativePointChart;
import 'package:flutter_chartjs_port/src/core/primitive_parse.dart'
    show NativeNumericParseScale;
import 'package:flutter_chartjs_port/src/core/radial_positions.dart';
import 'package:flutter_chartjs_port/src/core/scale_options.dart';
import 'package:flutter_chartjs_port/src/core/tick_font_cache.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show addRoundedRectPath, isPointInArea, longestText, renderText;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionView;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show callback, isArray, isFinite, isNullOrUndef, valueOrDefault;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show halfPi, normalizeAngle, pi, tau, toDegrees, toRadians;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableScalePointLabelContext, toFont, toPadding, toTRBLCorners;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart'
    show jsCos, jsMax, jsMin, jsRound, jsSin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart';
import 'package:flutter_chartjs_port/src/options/opt.dart' show optUndefined;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        AngleLineOptionsScope,
        DescriptorsScope,
        GridLineOptionsScope,
        PointLabelOptionsScope,
        ScaleOptionsScope,
        TickOptionsScope;
import 'package:flutter_chartjs_port/src/scales/scale.linearbase.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart' as types;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:flutter_chartjs_port/src/types/layout.dart' show ChartPosition;
import 'package:meta/meta.dart';

/// The object `{w, h}` of `measureLabelSize` (scale.radialLinear.js:21-24):
/// the width and the height of a point label.
typedef _LabelSize = ({double w, double h});

/// The object `{start, end}` of `determineLimits`
/// (scale.radialLinear.js:29-43).
typedef _Limit = ({double start, double end});

/// The label size before the write of an index: no list item stays at it.
const _LabelSize _noLabelSize = (w: 0.0, h: 0.0);

/// The object `itemOpts` of `buildPointLabelItems`
/// (scale.radialLinear.js:181-184, :188-189): `extra`, `additionalAngle`,
/// and the `padding` option and the label size of one index.
final class _ItemOpts {
  _ItemOpts({required this.extra, required this.additionalAngle});

  /// `extra`.
  final double extra;

  /// `additionalAngle`.
  final double additionalAngle;

  /// `padding`, the raw option of the current index.
  Object? padding;

  /// `size`, the label size of the current index.
  _LabelSize size = _noLabelSize;
}

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
  final TextAlign? textAlign;

  @override
  final CanvasTextBaseline? textBaseline;

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

/// scale.radialLinear.js:9 `getTickBackdropHeight(opts)`.
///
/// [opts] are the options of the scale. The font is a `TextStyle` (row
/// `adapt-text-style-fonts`): `tickOpts.font && tickOpts.font.size` is its
/// `fontSize`, else the `fontSize` of `defaults.font`.
double _getTickBackdropHeight(CoreScaleOptions opts) {
  final tickOpts = opts.ticks;

  if (tickOpts.display && jsTruthy(opts.display)) {
    final padding = toPadding(tickOpts.backdropPadding);
    final font = tickOpts.font;
    // DIVERGES(chartjs): adapt-text-style-fonts, the size of a TextStyle.
    // `tickOpts.font && tickOpts.font.size`: a null font stays null, which
    // valueOrDefault keeps and the `+` reads as 0, as upstream.
    return jsToNumber(
      jsAdd(
        valueOrDefault<Object?>(
          jsTruthy(font)
              ? (font is TextStyle ? font.fontSize : null) ?? undefined
              : font,
          _defaultFontSize(),
        ),
        padding.height,
      ),
    );
  }
  return 0;
}

/// `defaults.font.size` of scale.radialLinear.js:14: the `fontSize` of the
/// font of the typed root `defaults`.
double? _defaultFontSize() {
  final font = defaults.lookup(OptionKey.font)?.raw;
  return font is TextStyle ? font.fontSize : null;
}

/// scale.radialLinear.js:19 `measureLabelSize(ctx, font, label)`.
///
/// [label] is a label of the callback: an array gives one line for each
/// item.
_LabelSize _measureLabelSize(
  CanvasRenderingContext2D ctx,
  ChartTextStyle font,
  Object? label,
) {
  // Upstream reassigns its parameter with the List of the lines.
  final lines = isArray(label) ? label! as List<Object?> : <Object?>[label];
  return (
    w: longestText(ctx, font, lines),
    h: lines.length * font.lineHeight!,
  );
}

/// scale.radialLinear.js:27 `determineLimits(angle, pos, size, min, max)`.
@pragma('vm:prefer-inline')
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
  final valueCount = scale.pointLabels.length;
  final labelSizes = List<_LabelSize>.filled(valueCount, _noLabelSize);
  final padding = List<Object?>.filled(valueCount, null);
  final pointLabelOpts = scale.options.pointLabels;
  final additionalAngle = pointLabelOpts.centerPointLabels
      ? pi / valueCount
      : 0.0;

  for (var i = 0; i < valueCount; i++) {
    final opts = pointLabelOpts.setContext(scale.getPointLabelContext(i)!);
    padding[i] = opts.padding;
    final pointPosition = scale.getPointPosition(
      i * 1.0,
      jsToNumber(jsAdd(scale.drawingArea, padding[i])),
      additionalAngle,
    );
    final plFont = toFont(opts.font);
    final textSize = _measureLabelSize(
      scale.ctx!,
      plFont,
      scale.pointLabels[i],
    );
    labelSizes[i] = textSize;

    final angleRadians = normalizeAngle(
      scale.getIndexAngle(i * 1.0) + additionalAngle,
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

    // DIVERGES(chartjs): adapt-radial-static-plans, one font and one padding.
    if (i == 0 && valueCount > 1 && _nativeStaticPlan(scale)) {
      final view = pointLabelOpts.raw;
      final positions = scale.prepareRadialPositions();
      if (view is OptionView && positions != null) {
        final staticPadding = view.cachedStaticValue(OptionKey.padding);
        if (staticPadding is num && _staticFont(view, plFont)) {
          final next = _fitStaticPointLabels(
            scale,
            positions,
            plFont,
            staticPadding,
            additionalAngle,
            valueCount,
            limits,
            orig,
            labelSizes,
            padding,
          );
          i = next - 1;
        }
      }
    }
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

/// The rest of the loop of `fitWithPointLabels` from the index 1, with the font
/// and the padding of each label known (Chart.js ADR 0095). No context, view or
/// font object is made. Each label still adds its size, its padding and its
/// limits. An empty label has its width, 0 on the native canvas, and keeps the
/// height of one line in the limits.
///
/// It returns the first index that it did not treat: a label that is not a
/// `String`, or [valueCount]. The ordinary loop continues there.
int _fitStaticPointLabels(
  RadialLinearScale scale,
  RadialPositions positions,
  ChartTextStyle font,
  num staticPadding,
  double additionalAngle,
  int valueCount,
  _Limits limits,
  _Limits orig,
  List<_LabelSize> labelSizes,
  List<Object?> padding,
) {
  final ctx = scale.ctx!;
  final labels = scale.pointLabels;
  final distance = jsToNumber(jsAdd(scale.drawingArea, staticPadding));
  final lineHeight = font.lineHeight!;
  _LabelSize? emptySize;
  // `longestText` of one line: a width that is not above 0 gives 0. The font
  // is the state of each measure of the ordinary loop.
  double widthOf(String label) {
    final width = ctx.measureText(label).width;
    return width > 0 ? width : 0;
  }

  ctx
    ..save()
    ..font = font;
  var i = 1;
  for (; i < valueCount; i++) {
    final label = labels[i];
    if (label is! String) break;
    final textSize = label.isEmpty
        ? emptySize ??= (w: widthOf(label), h: lineHeight)
        : (w: widthOf(label), h: lineHeight);
    padding[i] = staticPadding;
    labelSizes[i] = textSize;
    final pointPosition = positions.positionAt(i, distance, additionalAngle);
    final angleRadians = normalizeAngle(
      positions.indexAngleAt(i) + additionalAngle,
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
  ctx.restore();
  return i;
}

/// scale.radialLinear.js:118 `updateLimits(limits, orig, angle, hLimits,
/// vLimits)`.
///
/// `Math.sin` and `Math.cos` are pure: each runs only in a branch that divides
/// by it.
// DIVERGES(chartjs): adapt-radial-static-plans, trig only for a label past a
// limit.
void _updateLimits(
  _Limits limits,
  _Limits orig,
  double angle,
  _Limit hLimits,
  _Limit vLimits,
) {
  double x;
  double y;
  if (hLimits.start < orig.l) {
    x = (orig.l - hLimits.start) / jsSin(angle).abs();
    limits.l = jsMin(limits.l, orig.l - x);
  } else if (hLimits.end > orig.r) {
    x = (hLimits.end - orig.r) / jsSin(angle).abs();
    limits.r = jsMax(limits.r, orig.r + x);
  }
  if (vLimits.start < orig.t) {
    y = (orig.t - vLimits.start) / jsCos(angle).abs();
    limits.t = jsMin(limits.t, orig.t - y);
  } else if (vLimits.end > orig.b) {
    y = (vLimits.end - orig.b) / jsCos(angle).abs();
    limits.b = jsMax(limits.b, orig.b + y);
  }
}

/// scale.radialLinear.js:139 `createPointLabelItem(scale, index, itemOpts)`.
///
/// The `padding` of [itemOpts] is the raw `padding` option.
/// `outerDistance + extra + padding` is [jsAdd] for the last `+`: a string
/// padding joins the sum. `getPointPosition` applies [jsToNumber] to it.
/// [positions] are the inputs of `getPointPosition` for the exact class, else
/// Dart `null` (Chart.js ADR 0095).
PointLabelItem _createPointLabelItem(
  RadialLinearScale scale,
  int index,
  _ItemOpts itemOpts,
  RadialPositions? positions,
) {
  final outerDistance = scale.drawingArea;
  final _ItemOpts(:extra, :additionalAngle, :padding, :size) = itemOpts;
  final distance = jsToNumber(jsAdd(outerDistance + extra, padding));
  // DIVERGES(chartjs): adapt-radial-static-plans, no option read per label.
  final pointLabelPosition = positions != null
      ? positions.positionAt(index, distance, additionalAngle)
      : scale.getPointPosition(index * 1.0, distance, additionalAngle);
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
/// object `itemOpts`, as here. No user code runs in the loop.
List<PointLabelItem> _buildPointLabelItems(
  RadialLinearScale scale,
  List<_LabelSize> labelSizes,
  List<Object?> padding,
) {
  final valueCount = scale.pointLabels.length;
  final opts = scale.options;
  final pointLabels = opts.pointLabels;
  final centerPointLabels = pointLabels.centerPointLabels;
  final display = pointLabels.display;
  final itemOpts = _ItemOpts(
    extra: _getTickBackdropHeight(opts) / 2,
    additionalAngle: centerPointLabels ? pi / valueCount : 0.0,
  );
  final positions = scale.prepareRadialPositions();
  PointLabelItem? area;

  return List<PointLabelItem>.generate(valueCount, (i) {
    itemOpts
      ..padding = padding[i]
      ..size = labelSizes[i];

    final item = _createPointLabelItem(scale, i, itemOpts, positions);
    if (display == 'auto') {
      item.visible = _isNotOverlapped(item, area);
      if (item.visible) {
        area = item;
      }
    }
    return item;
  });
}

/// scale.radialLinear.js:203 `getTextAlignForAngle(angle)`.
// DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
TextAlign _getTextAlignForAngle(double angle) {
  if (angle == 0 || angle == 180) {
    return TextAlign.center;
  } else if (angle < 180) {
    return TextAlign.left;
  }

  return TextAlign.right;
}

/// scale.radialLinear.js:213 `leftForTextAlign(x, w, align)`.
// DIVERGES(chartjs): adapt-flutter-text-align, the Flutter enum.
double _leftForTextAlign(double x, double w, TextAlign align) {
  if (align == TextAlign.right) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    x -= w;
  } else if (align == TextAlign.center) {
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
  PointLabelOptions opts,
  PointLabelItem item,
) {
  final PointLabelItem(:left, :top, :right, :bottom) = item;
  final backdropColor = opts.backdropColor;

  if (!isNullOrUndef(backdropColor)) {
    final borderRadius = toTRBLCorners(opts.borderRadius);
    final padding = toPadding(opts.backdropPadding);
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
  final pointLabels = scale.options.pointLabels;
  var planned = false;

  for (var i = labelCount - 1; i >= 0; i--) {
    final item = scale.pointLabelItems[i];
    if (!item.visible) {
      // overlapping
      continue;
    }
    final optsAtIndex = pointLabels.setContext(scale.getPointLabelContext(i)!);
    _drawPointLabelBox(ctx!, optsAtIndex, item);
    final plFont = toFont(optsAtIndex.font);
    final PointLabelItem(:x, :y, :textAlign) = item;

    renderText(
      ctx,
      scale.pointLabels[i],
      x,
      y + (plFont.lineHeight! / 2),
      plFont,
      _RenderTextOpts(
        color: optsAtIndex.color,
        textAlign: textAlign,
        // DIVERGES(chartjs): adapt-canvas-text-baseline-enum, the enum value.
        textBaseline: CanvasTextBaseline.middle,
      ),
    );

    // DIVERGES(chartjs): adapt-radial-static-plans, one font and one color.
    if (!planned) {
      planned = true;
      final view = pointLabels.raw;
      if (view is OptionView &&
          _nativeStaticPlan(scale) &&
          _staticFont(view, plFont)) {
        final backdropColor = view.cachedStaticValue(OptionKey.backdropColor);
        final color = view.cachedStaticValue(OptionKey.color);
        if (isNullOrUndef(backdropColor) && plainOptionValue(color)) {
          i = _drawStaticPointLabels(scale, plFont, color, i - 1) + 1;
        }
      }
    }
  }
}

/// The rest of the loop of `drawPointLabels` from the index [start], down, with
/// the font and the color of each label known and no backdrop (Chart.js ADR
/// 0095). An empty string draws nothing on the native canvas: its `fillText`
/// returns at once, between a `save` and a `restore`. A label with text takes
/// the ordinary `renderText`.
///
/// It returns the first index that it did not treat: a label that is not a
/// `String`, or -1. The ordinary loop continues there.
int _drawStaticPointLabels(
  RadialLinearScale scale,
  ChartTextStyle font,
  Object? color,
  int start,
) {
  final ctx = scale.ctx!;
  final items = scale.pointLabelItems;
  final labels = scale.pointLabels;
  final middle = font.lineHeight! / 2;
  for (var i = start; i >= 0; i--) {
    final item = items[i];
    if (!item.visible) {
      // overlapping
      continue;
    }
    final label = labels[i];
    if (label is! String) return i;
    if (label.isEmpty) continue;
    renderText(
      ctx,
      label,
      item.x,
      item.y + middle,
      font,
      _RenderTextOpts(
        color: color,
        textAlign: item.textAlign,
        // DIVERGES(chartjs): adapt-canvas-text-baseline-enum, the enum value.
        textBaseline: CanvasTextBaseline.middle,
      ),
    );
  }
  return -1;
}

/// Whether the static plans can apply: the exact class, on a context whose
/// setters and text measures have no effect beyond its state (the capability
/// of the native canvas). A recording context keeps each ordinary call.
bool _nativeStaticPlan(RadialLinearScale scale) =>
    scale._exactClass &&
    switch (scale.ctx) {
      final CanvasTextMetricsSource source =>
        source.textMetricsGeneration != null,
      _ => false,
    };

/// Whether each new context of [pointLabels] gives the font [resolved]: all
/// inputs are cached scalars, and the ordinary resolution gave these inputs.
bool _staticFont(OptionView pointLabels, ChartTextStyle resolved) {
  final inputs = TickFontCache.staticInputs(pointLabels);
  return inputs != null && TickFontCache.matchesResolved(inputs, resolved);
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
    ctx.arc(
      scale.xCenter ?? double.nan,
      scale.yCenter ?? double.nan,
      radius,
      0,
      tau,
    );
  } else {
    // Draw straight lines connecting each index
    var pointPosition = scale.getPointPosition(0, radius);
    ctx.moveTo(pointPosition.x, pointPosition.y);

    for (var i = 1; i < labelCount; i++) {
      pointPosition = scale.getPointPosition(i * 1.0, radius);
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
  GridLineOptions gridLineOpts,
  double radius,
  int labelCount,
  BorderOptions borderOpts,
) {
  final ctx = scale.ctx;
  final circular = gridLineOpts.circular;

  final color = gridLineOpts.color;
  final lineWidth = gridLineOpts.lineWidth;

  if ((!circular && labelCount == 0) ||
      !jsTruthy(color) ||
      !jsTruthy(lineWidth) ||
      radius < 0) {
    return;
  }

  final dash = borderOpts.dash;
  ctx!
    ..save()
    ..strokeStyle = canvasStyle(color)
    ..lineWidth = canvasNumber(lineWidth)
    ..setLineDash(canvasLineDash(jsTruthy(dash) ? dash : <Object?>[]))
    ..lineDashOffset = canvasNumber(borderOpts.dashOffset)
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
/// The context of the type `'pointLabel'` is a
/// [ScriptableScalePointLabelContext] (Chart.js ADR 0054 §11).
ScriptableScalePointLabelContext _createPointLabelContext(
  Object parent,
  int index,
  Object? label,
) {
  // DIVERGES(chartjs): adapt-point-label-context-construction, no Map.
  return ScriptableScalePointLabelContext.pointLabel(
    parent,
    label,
    index * 1.0,
  );
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
  final TextAlign textAlign;

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
///
/// It implements `types.RadialLinearScale` (index.d.ts:3676): the polar
/// area and radar controllers read its members through that interface
/// (Chart.js ADR 0028, section 1).
class RadialLinearScale extends LinearScaleBase
    implements
        types.RadialLinearScale,
        NativeArcScale,
        NativeNumericParseScale,
        NativeRadialPositionScale {
  /// scale.radialLinear.js:412 `constructor(cfg)`.
  ///
  /// [cfg] is the object `{id, type, ctx, chart}` of [Scale.new]. The fields
  /// get their start values in their declarations
  /// (scale.radialLinear.js:415-423).
  RadialLinearScale(super.cfg);

  // scale.radialLinear.js:340 `static id = 'radialLinear'`. Scale has the
  // instance field `id`. Thus the value is only in the statics of jsClass.

  /// Whether this object is of the class itself. `super.runtimeType` is the
  /// class of the object also when a user subclass overrides `runtimeType`.
  // DIVERGES(chartjs): adapt-radial-static-plans, the exact-class guard.
  bool get _exactClass => super.runtimeType == RadialLinearScale;

  /// Native support for the explicit data-only lifecycle.
  @override
  // DIVERGES(chartjs): adapt-incremental-data-update, native opt-in.
  bool get supportsDataUpdates =>
      super.runtimeType == RadialLinearScale &&
      getUserBounds().minDefined &&
      getUserBounds().maxDefined &&
      options.cachedFixedDataBounds;

  /// The exact class, for the options of a polar area loop (Chart.js ADR 0093).
  @internal
  @override
  // DIVERGES(chartjs): adapt-arc-native-options, native scale contract.
  bool get supportsNativeArcOptions => super.runtimeType == RadialLinearScale;

  /// The number parse of [LinearScaleBase], with no override (Chart.js ADR
  /// 0095). Unknown subclasses keep their ordinary parse calls.
  @override
  @internal
  // DIVERGES(chartjs): adapt-radial-numeric-parse, native parse contract.
  bool get supportsNativeNumericParse => super.runtimeType == RadialLinearScale;

  /// The inputs of the position methods for one loop with no user code
  /// (Chart.js ADR 0095). Only the exact class qualifies, and only after an
  /// ordinary read resolved both options.
  @override
  @internal
  // DIVERGES(chartjs): adapt-radial-static-plans, the inputs of one pure loop.
  RadialPositions? prepareRadialPositions() {
    final opts = options;
    if (super.runtimeType != RadialLinearScale ||
        !opts.hasCachedValue(OptionKey.reverse) ||
        !opts.hasCachedValue(OptionKey.startAngle)) {
      return null;
    }
    final min = this.min;
    final max = this.max;
    return RadialPositions(
      angleStep: tau / (pointLabels.isEmpty ? 1 : pointLabels.length),
      startRadians: toRadians(jsOrZero(opts.startAngle)),
      xCenter: xCenter ?? double.nan,
      yCenter: yCenter ?? double.nan,
      min: min,
      max: max,
      scalingFactor: drawingArea / (max - min),
      reverse: opts.reverse,
    );
  }

  /// scale.radialLinear.js:345 `static defaults`, a typed scope of the kind
  /// `ScaleOptions` (Chart.js ADR 0054 §3).

  static final ScaleOptionsScope defaults = ScaleOptionsScope()
    ..display = true
    // Boolean - Whether to animate scaling the chart from the centre
    ..animate = true
    ..position = ChartPosition.chartArea
    ..angleLines = (AngleLineOptionsScope()
      ..display = true
      ..lineWidth = 1.0
      ..borderDash = <Object?>[]
      ..borderDashOffset = 0.0)
    ..grid = (GridLineOptionsScope()..circular = false)
    ..startAngle = 0.0
    // label settings
    ..ticks = (TickOptionsScope()
      // Boolean - Show a backdrop to the scale label
      ..showLabelBackdrop = true
      ..callback = formatters['numeric']!)
    ..pointLabels = (PointLabelOptionsScope()
      ..backdropColorCell = optUndefined
      // Number - The backdrop padding above & below the label in pixels
      ..backdropPadding = 2.0
      // Boolean - if true, show point labels
      ..display = true
      // Number - Point label font size in pixels
      // DIVERGES(chartjs): adapt-text-style-fonts, the font is a style.
      ..font = const ChartTextStyle(fontSize: 10)
      // Function - Used to convert point labels
      ..callback = _pointLabelCallback
      // Number - Additionl padding between scale and pointLabel
      ..padding = 5.0
      // Boolean - if true, center point labels to slices in polar chart
      ..centerPointLabels = false);

  /// scale.radialLinear.js:388 the point label `callback(label)`, which
  /// returns `label`.
  static Object? _pointLabelCallback(Object? label) => label;

  /// scale.radialLinear.js:400 `static defaultRoutes`.
  static final AnyObject defaultRoutes = {
    'angleLines.color': 'borderColor',
    'pointLabels.color': 'color',
    'ticks.color': 'color',
  };

  /// scale.radialLinear.js:406 `static descriptors`, a typed scope of the
  /// kind `Descriptors` (Chart.js ADR 0054 §3).
  static final DescriptorsScope descriptors = DescriptorsScope()
    ..jsWrite('angleLines', DescriptorsScope()..descFallback = 'grid');

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

  /// The options of the scale, through the facade of the radial linear
  /// scale options (index.d.ts:3563).
  @override
  RadialLinearScaleOptions get options =>
      RadialLinearScaleOptions(super.options);

  /// scale.radialLinear.js:416 `xCenter`, the x of the center.
  ///
  /// Dart `null` stands for JS `undefined`, the start value. A controller
  /// reads it before the first layout and writes `undefined` into a new
  /// element (`types.RadialLinearScale.xCenter`). Thus the start value is
  /// not NaN, as [drawingArea] is. In arithmetic and in a canvas call, this
  /// file reads `xCenter ?? double.nan`: `undefined` gives NaN there.
  /// Chart.js ADR 0033 records this form.
  @override
  double? xCenter;

  /// scale.radialLinear.js:418 `yCenter`, the y of the center. Dart `null`
  /// stands for JS `undefined`, as for [xCenter].
  @override
  double? yCenter;

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
  ///
  /// On the exact class (Chart.js ADR 0095), the built-in callback and a native
  /// label list take the labels directly: no user code runs after its first
  /// read. A closure of the shape `Object? Function(Object?, double)` gets the
  /// call of [callback] with no argument list, tested once for each closure.
  /// The other values go through [callback]. The option stays a read for each
  /// label while a user closure runs. On the exact chart, which runs no user
  /// code here, no hidden index gives the list of the callbacks.
  @override
  void generateTickLabels(List<Tick> ticks) {
    super.generateTickLabels(ticks);

    // Point labels
    final labels = getLabels();
    final length = labels.length;
    // DIVERGES(chartjs): adapt-radial-label-dispatch, the same calls, in order.
    final mapped = List<Object?>.filled(length, null, growable: true);
    final exact = super.runtimeType == RadialLinearScale;
    final nativeLabels = exact && nativeDataUpdateList(labels);
    Object? shaped;
    Object? Function(Object?, double)? typed;
    for (var index = 0; index < length; index++) {
      final fn = options.pointLabels.callback;
      if (nativeLabels && identical(fn, _pointLabelCallback)) {
        for (var i = index; i < length; i++) {
          mapped[i] = _pointLabelOf(labels[i]);
        }
        break;
      }
      if (exact && !identical(fn, shaped)) {
        shaped = fn;
        typed = fn is Object? Function(Object?, double) ? fn : null;
      }
      final direct = typed;
      mapped[index] = _pointLabelOf(
        direct != null
            ? direct(labels[index], index * 1.0)
            : callback(fn, [labels[index], index * 1.0], this),
      );
    }
    final chart = this.chart;
    if (nativePointChart(chart)) {
      var visible = 0;
      while (visible < length && chart.getDataVisibility(visible)) {
        visible++;
      }
      if (visible == length) {
        pointLabels = mapped;
        return;
      }
    }
    pointLabels = [
      for (var i = 0; i < mapped.length; i++)
        if (chart.getDataVisibility(i * 1.0)) mapped[i],
    ];
  }

  /// `label || label === 0 ? label : ''` of scale.radialLinear.js:461. A string
  /// gives itself: an empty one is the `''`.
  static Object? _pointLabelOf(Object? label) =>
      label is String || jsTruthy(label) || (label is num && label == 0)
      ? label
      : '';

  /// scale.radialLinear.js:466 `fit()`.
  @override
  void fit() {
    final opts = options;

    if (jsTruthy(opts.display) && jsTruthy(opts.pointLabels.display)) {
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
    xCenter =
        (xCenter ?? double.nan) +
        ((leftMovement - rightMovement) / 2).floorToDouble();
    yCenter =
        (yCenter ?? double.nan) +
        ((topMovement - bottomMovement) / 2).floorToDouble();
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
  @override
  double getIndexAngle(double index) {
    final angleMultiplier =
        tau / (pointLabels.isEmpty ? 1 : pointLabels.length);
    final startAngle = jsOrZero(options.startAngle);

    return normalizeAngle(index * angleMultiplier + toRadians(startAngle));
  }

  /// scale.radialLinear.js:489 `getDistanceFromCenterForValue(value)`.
  ///
  /// [value] is any JS value (Chart.js ADR 0025). `null` and `undefined`
  /// give NaN. The `-` applies [jsToNumber] to another value.
  @override
  double getDistanceFromCenterForValue(Object? value) {
    if (isNullOrUndef(value)) {
      return double.nan;
    }

    // Take into account half font size + the yPadding of the top value
    final scalingFactor = drawingArea / (max - min);
    if (options.reverse) {
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
    return options.reverse ? max - scaledDistance : min + scaledDistance;
  }

  /// scale.radialLinear.js:511 `getPointLabelContext(index)`.
  ///
  /// The scriptable context of the point label [index]. Dart `null` stands
  /// for the JS `undefined` of an index out of the range of the labels.
  ScriptableScalePointLabelContext? getPointLabelContext(int index) {
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
      x: jsCos(angle) * distanceFromCenter + (xCenter ?? double.nan),
      y: jsSin(angle) * distanceFromCenter + (yCenter ?? double.nan),
      angle: angle,
    );
  }

  /// scale.radialLinear.js:529 `getPointPositionForValue(index, value)`.
  ///
  /// [value] is any JS value (Chart.js ADR 0025).
  @override
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
    final backgroundColor = options.backgroundColor;
    final circular = options.grid.circular;
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
  /// `index.d.ts:1326` declares a [chartArea] parameter. The upstream body
  /// does not read it.
  @override
  @protected
  void drawGrid([types.ChartArea? chartArea]) {
    final ctx = this.ctx;
    final opts = options;
    final angleLines = opts.angleLines;
    final grid = opts.grid;
    final border = opts.border;
    final labelCount = pointLabels.length;

    if (jsTruthy(opts.pointLabels.display)) {
      _drawPointLabels(this, labelCount);
    }

    if (grid.display) {
      final ticks = this.ticks!;
      for (var index = 0; index < ticks.length; index++) {
        final tick = ticks[index];
        if (index != 0 || (index == 0 && min < 0)) {
          final offset = getDistanceFromCenterForValue(tick.value);
          final context = getContext(index);
          final optsAtIndex = grid.setContext(context);
          final optsAtIndexBorder = border.setContext(context);

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

    if (angleLines.display) {
      ctx!.save();

      for (var i = labelCount - 1; i >= 0; i--) {
        final optsAtIndex = angleLines.setContext(getPointLabelContext(i)!);
        final color = optsAtIndex.color;
        final lineWidth = optsAtIndex.lineWidth;

        if (!jsTruthy(lineWidth) || !jsTruthy(color)) {
          // DIVERGES(chartjs): adapt-radial-static-plans, no line to draw.
          if (i == labelCount - 1 && _staticAngleLineStyle(angleLines)) break;
          continue;
        }

        ctx
          ..lineWidth = canvasNumber(lineWidth)
          ..strokeStyle = canvasStyle(color)
          ..setLineDash(canvasLineDash(optsAtIndex.borderDash))
          ..lineDashOffset = canvasNumber(optsAtIndex.borderDashOffset);

        final offset = getDistanceFromCenterForValue(
          opts.reverse ? min : max,
        );
        final position = getPointPosition(i * 1.0, offset);
        ctx
          ..beginPath()
          ..moveTo(xCenter ?? double.nan, yCenter ?? double.nan)
          ..lineTo(position.x, position.y)
          ..stroke();

        // DIVERGES(chartjs): adapt-radial-static-plans, one state, each line.
        if (i == labelCount - 1 && _staticAngleLineState(angleLines)) {
          final positions = prepareRadialPositions();
          if (positions != null) {
            _drawStaticAngleLines(ctx, positions, offset, i - 1);
            break;
          }
        }
      }

      ctx.restore();
    }
  }

  /// Whether each new context of [angleLines] gives the `color` and the
  /// `lineWidth` of the first line, on the exact class and the native canvas.
  /// A scriptable or an indexed value is no plain value. The probe reads the
  /// resolved value, so one that comes through the fallback to `grid` counts.
  bool _staticAngleLineStyle(AngleLineOptions angleLines) {
    final view = angleLines.raw;
    return view is OptionView &&
        _nativeStaticPlan(this) &&
        plainOptionValue(view.cachedStaticValue(OptionKey.color)) &&
        plainOptionValue(view.cachedStaticValue(OptionKey.lineWidth));
  }

  /// Whether each new context of [angleLines] gives the state of the first
  /// line: its style, an empty dash list and its dash offset. The setters of
  /// the first line stay the state of each other line.
  bool _staticAngleLineState(AngleLineOptions angleLines) {
    if (!_staticAngleLineStyle(angleLines)) return false;
    final view = angleLines.raw! as OptionView;
    final dash = view.cachedStaticValue(OptionKey.borderDash);
    return dash is List<Object?> &&
        dash.isEmpty &&
        plainOptionValue(view.cachedStaticValue(OptionKey.borderDashOffset));
  }

  /// The rest of the loop of the angle lines from the index [start], down
  /// (Chart.js ADR 0095): the same path and stroke for each line. A translucent
  /// line still blends over the lines before it: each line is its own stroke.
  ///
  /// A native canvas may take these strokes in one call (Chart.js ADR 0103).
  void _drawStaticAngleLines(
    CanvasRenderingContext2D ctx,
    RadialPositions positions,
    double offset,
    int start,
  ) {
    final x = xCenter ?? double.nan;
    final y = yCenter ?? double.nan;
    // DIVERGES(chartjs): adapt-radial-line-fan, one native call for the lines.
    if (ctx case final LineFanCanvas fan when start > 0) {
      final drawn = fan.tryStrokeLineFan(x, y, start + 1, (ends) {
        var k = 0;
        for (var i = start; i >= 0; i--) {
          final position = positions.positionAt(i, offset);
          ends[k] = position.x;
          ends[k + 1] = position.y;
          k += 2;
        }
      });
      if (drawn) return;
    }
    for (var i = start; i >= 0; i--) {
      final position = positions.positionAt(i, offset);
      ctx
        ..beginPath()
        ..moveTo(x, y)
        ..lineTo(position.x, position.y)
        ..stroke();
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
  /// `index.d.ts:1325` declares a [chartArea] parameter. The upstream body
  /// does not read it. `ctx.measureText(tick.label)` applies the DOM
  /// `ToString` to the label ([jsToString]).
  @override
  @protected
  void drawLabels([types.ChartArea? chartArea]) {
    final ctx = this.ctx;
    final opts = options;
    final tickOpts = opts.ticks;

    if (!tickOpts.display) {
      return;
    }

    final startAngle = getIndexAngle(0);

    ctx!
      ..save()
      ..translate(xCenter ?? double.nan, yCenter ?? double.nan)
      ..rotate(startAngle)
      ..textAlign = TextAlign.center
      // DIVERGES(chartjs): adapt-canvas-text-baseline-enum, the enum value.
      ..textBaseline = CanvasTextBaseline.middle;

    final ticks = this.ticks!;
    for (var index = 0; index < ticks.length; index++) {
      final tick = ticks[index];
      if ((index == 0 && min >= 0) && !opts.reverse) {
        continue;
      }

      final optsAtIndex = tickOpts.setContext(getContext(index));
      final tickFont = toFont(optsAtIndex.font);
      final offset = getDistanceFromCenterForValue(this.ticks![index].value);

      if (optsAtIndex.showLabelBackdrop) {
        ctx.font = tickFont;
        final width = ctx.measureText(jsToString(tick.label)).width;
        ctx.fillStyle = canvasStyle(optsAtIndex.backdropColor);

        final padding = toPadding(optsAtIndex.backdropPadding);
        ctx.fillRect(
          -width / 2 - padding.left,
          -offset - tickFont.fontSize! / 2 - padding.top,
          width + padding.width,
          tickFont.fontSize! + padding.height,
        );
      }

      renderText(
        ctx,
        tick.label,
        0,
        -offset,
        tickFont,
        _RenderTextOpts(
          color: optsAtIndex.color,
          strokeColor: optsAtIndex.textStrokeColor,
          strokeWidth: canvasNumber(optsAtIndex.textStrokeWidth),
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
