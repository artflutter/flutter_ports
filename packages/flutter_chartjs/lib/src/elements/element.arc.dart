// Ported from Chart.js v4.5.1 src/elements/element.arc.ts (MIT, Chart.js Contributors).

/// Port of `src/elements/element.arc.ts`: the arc element of the doughnut,
/// pie and polar area charts.
///
/// [ArcElement] follows the element design of Chart.js ADR 0017. Its
/// properties are typed members with an `undefined` state. The access by
/// name of `Element` reads and writes them by their upstream names. Its
/// [ArcElement.options] are the resolved options, a Map.
///
/// The module functions of upstream (`clipSelf`, `clipArc`,
/// `parseBorderRadius`, `pathArc`, `drawArc` and `drawBorder`) are private
/// here, because upstream does not export them.
///
/// ## Options
///
/// The options are an [ArcOptions] or a plain Map. Each read goes through
/// one small function for each option, for example `_offset`, which gives
/// [ArcOptions.offsetValue] or `jsGet(options, 'offset')` (Chart.js ADR 0018,
/// section 4). Both give JS `undefined` for an absent key. The code reads
/// the options as Chart.js ADR 0017 (section 8) states:
/// - A number in arithmetic reads with `jsToNumber`: `undefined` gives NaN,
///   and `null` gives 0.
/// - A test with `jsTruthy`, a compare with a string or with 0, `|| 0` and
///   `toRadiusCorners` give the same result for JS `undefined` and for JS
///   `null`. Thus these sites give the same result as the typed Map read
///   `options[key]`, which gives Dart `null` for an absent key.
/// - A canvas setter gets its value through `canvasStyle`, `canvasNumber`,
///   `canvasKeyword` or `canvasLineDash` of `lib/src/js/js_webidl.dart`, as
///   in the other element classes.
/// - `value || 0` before arithmetic is `jsOrZero`.
///
/// This library is a pure layer (Chart.js ADR 0017, section 10). It imports
/// neither `dart:ui` nor `package:flutter`.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs/src/canvas/canvas.dart';
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart'
    show ArcOptions;
// Upstream imports _angleBetween, getAngleFromPoint, TAU, HALF_PI and
// valueOrDefault from helpers/index.js. helpers/index.dart exports
// helpers.extras, which is not a pure layer. Thus the port imports the
// helper files.
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show valueOrDefault;
import 'package:flutter_chartjs/src/helpers/helpers.math.dart'
    show
        angleBetween,
        getAngleFromPoint,
        halfPi,
        isBetween,
        limitValue,
        normalizeAngle,
        pi,
        tau;
import 'package:flutter_chartjs/src/helpers/helpers.options.dart'
    show readValueToProps;
import 'package:flutter_chartjs/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/js/js_webidl.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/geometric.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

/// The option `borderAlign` of [options]: [ArcOptions.borderAlignValue] for
/// typed options, else `jsGet(options, 'borderAlign')` (Chart.js ADR 0018,
/// section 4).
///
/// Both give JS `undefined` for an absent key. `jsGet` throws a [TypeError]
/// for Dart `null`, the `undefined` state of the options. The other option
/// functions of this file work in the same way.
Object? _borderAlign(Object? options) => options is ArcOptions
    ? options.borderAlignValue
    : jsGet(options, 'borderAlign');

/// The option `borderColor` of [options], as [_borderAlign] reads
/// `borderAlign`.
Object? _borderColor(Object? options) => options is ArcOptions
    ? options.borderColorValue
    : jsGet(options, 'borderColor');

/// The option `borderDash` of [options], as [_borderAlign] reads
/// `borderAlign`.
Object? _borderDash(Object? options) => options is ArcOptions
    ? options.borderDashValue
    : jsGet(options, 'borderDash');

/// The option `borderDashOffset` of [options], as [_borderAlign] reads
/// `borderAlign`.
Object? _borderDashOffset(Object? options) => options is ArcOptions
    ? options.borderDashOffsetValue
    : jsGet(options, 'borderDashOffset');

/// The option `borderJoinStyle` of [options], as [_borderAlign] reads
/// `borderAlign`.
Object? _borderJoinStyle(Object? options) => options is ArcOptions
    ? options.borderJoinStyleValue
    : jsGet(options, 'borderJoinStyle');

/// The option `borderRadius` of [options], as [_borderAlign] reads
/// `borderAlign`.
Object? _borderRadius(Object? options) => options is ArcOptions
    ? options.borderRadiusValue
    : jsGet(options, 'borderRadius');

/// The option `borderWidth` of [options], as [_borderAlign] reads
/// `borderAlign`.
Object? _borderWidth(Object? options) => options is ArcOptions
    ? options.borderWidthValue
    : jsGet(options, 'borderWidth');

/// The option `offset` of [options], as [_borderAlign] reads `borderAlign`.
Object? _offset(Object? options) =>
    options is ArcOptions ? options.offsetValue : jsGet(options, 'offset');

/// The option `spacing` of [options], as [_borderAlign] reads `borderAlign`.
Object? _spacing(Object? options) =>
    options is ArcOptions ? options.spacingValue : jsGet(options, 'spacing');

/// The option `circular` of [options], as [_borderAlign] reads
/// `borderAlign`.
Object? _circular(Object? options) =>
    options is ArcOptions ? options.circularValue : jsGet(options, 'circular');

/// The option `selfJoin` of [options], as [_borderAlign] reads
/// `borderAlign`.
Object? _selfJoin(Object? options) =>
    options is ArcOptions ? options.selfJoinValue : jsGet(options, 'selfJoin');

/// The option `backgroundColor` of [options], as [_borderAlign] reads
/// `borderAlign`.
Object? _backgroundColor(Object? options) => options is ArcOptions
    ? options.backgroundColorValue
    : jsGet(options, 'backgroundColor');

/// element.arc.ts:7 `clipSelf`.
///
/// It reads `ctx.canvas`. The mock context of chartjs-test-utils has no
/// canvas, in JavaScript and in Dart.
void _clipSelf(
  CanvasRenderingContext2D ctx,
  ArcElement element,
  double endAngle,
) {
  final ArcElement(:startAngle, :x, :y, :outerRadius, :innerRadius) = element;
  final options = element.options!;
  final borderWidth = jsToNumber(_borderWidth(options));
  // Compared with strings only: JS undefined and JS null give one result.
  final borderJoinStyle = _borderJoinStyle(options);
  final outerAngleClip = jsMin(
    borderWidth / outerRadius,
    normalizeAngle(startAngle - endAngle),
  );
  ctx
    ..beginPath()
    ..arc(
      x,
      y,
      outerRadius - borderWidth / 2,
      startAngle + outerAngleClip / 2,
      endAngle - outerAngleClip / 2,
    );

  if (innerRadius > 0) {
    final innerAngleClip = jsMin(
      borderWidth / innerRadius,
      normalizeAngle(startAngle - endAngle),
    );
    ctx.arc(
      x,
      y,
      innerRadius + borderWidth / 2,
      endAngle - innerAngleClip / 2,
      startAngle + innerAngleClip / 2,
      true,
    );
  } else {
    final clipWidth = jsMin(
      borderWidth / 2,
      outerRadius * normalizeAngle(startAngle - endAngle),
    );

    if (borderJoinStyle == 'round') {
      ctx.arc(x, y, clipWidth, endAngle - pi / 2, startAngle + pi / 2, true);
    } else if (borderJoinStyle == 'bevel') {
      final r = 2 * clipWidth * clipWidth;
      final endX = -r * math.cos(endAngle + pi / 2) + x;
      final endY = -r * math.sin(endAngle + pi / 2) + y;
      final startX = r * math.cos(startAngle + pi / 2) + x;
      final startY = r * math.sin(startAngle + pi / 2) + y;
      ctx
        ..lineTo(endX, endY)
        ..lineTo(startX, startY);
    }
  }
  ctx
    ..closePath()
    ..moveTo(0, 0)
    ..rect(0, 0, ctx.canvas.width.toDouble(), ctx.canvas.height.toDouble())
    ..clip('evenodd');
}

/// element.arc.ts:41 `clipArc`.
void _clipArc(
  CanvasRenderingContext2D ctx,
  ArcElement element,
  double endAngle,
) {
  final ArcElement(
    :startAngle,
    :pixelMargin,
    :x,
    :y,
    :outerRadius,
    :innerRadius,
  ) = element;
  var angleMargin = pixelMargin / outerRadius;

  // Draw an inner border by clipping the arc and drawing a double-width
  // border
  // Enlarge the clipping arc by 0.33 pixels to eliminate glitches between
  // borders
  ctx
    ..beginPath()
    ..arc(x, y, outerRadius, startAngle - angleMargin, endAngle + angleMargin);
  if (innerRadius > pixelMargin) {
    angleMargin = pixelMargin / innerRadius;
    ctx.arc(
      x,
      y,
      innerRadius,
      endAngle + angleMargin,
      startAngle - angleMargin,
      true,
    );
  } else {
    ctx.arc(x, y, pixelMargin, endAngle + halfPi, startAngle - halfPi);
  }
  ctx
    ..closePath()
    ..clip();
}

/// element.arc.ts:59 `toRadiusCorners`.
Map<String, double> _toRadiusCorners(Object? value) {
  return readValueToProps(value, const [
    'outerStart',
    'outerEnd',
    'innerStart',
    'innerEnd',
  ]);
}

/// The object literal `{outerStart, outerEnd, innerStart, innerEnd}` of
/// `parseBorderRadius` (element.arc.ts:83-88).
typedef _BorderRadius = ({
  double outerStart,
  double outerEnd,
  double innerStart,
  double innerEnd,
});

/// element.arc.ts:66 `parseBorderRadius`.
///
/// Parse border radius from the provided options
_BorderRadius _parseBorderRadius(
  ArcElement arc,
  double innerRadius,
  double outerRadius,
  double angleDelta,
) {
  // toRadiusCorners gives 0 for each corner of JS undefined and JS null.
  // _borderRadius throws a TypeError for undefined options, as `!` did.
  final o = _toRadiusCorners(_borderRadius(arc.options));
  final halfThickness = (outerRadius - innerRadius) / 2;
  final innerLimit = jsMin(halfThickness, angleDelta * innerRadius / 2);

  // Outer limits are complicated. We want to compute the available angular
  // distance at a radius of outerRadius - borderRadius because for small
  // angular distances, this term limits. We compute at r = outerRadius -
  // borderRadius because this circle defines the center of the border
  // corners.
  //
  // If the borderRadius is large, that value can become negative.
  // This causes the outer borders to lose their radius entirely, which is
  // rather unexpected. To solve that, if borderRadius > outerRadius we know
  // that the thickness term will dominate and compute the limits at that
  // point
  double computeOuterLimit(double val) {
    final outerArcLimit =
        (outerRadius - jsMin(halfThickness, val)) * angleDelta / 2;
    return limitValue(val, 0, jsMin(halfThickness, outerArcLimit));
  }

  return (
    outerStart: computeOuterLimit(o['outerStart']!),
    outerEnd: computeOuterLimit(o['outerEnd']!),
    innerStart: limitValue(o['innerStart']!, 0, innerLimit),
    innerEnd: limitValue(o['innerEnd']!, 0, innerLimit),
  );
}

/// element.arc.ts:94 `rThetaToXY`.
///
/// Convert (r, 𝜃) to (x, y)
({double x, double y}) _rThetaToXY(
  double r,
  double theta,
  double x,
  double y,
) {
  return (x: x + r * math.cos(theta), y: y + r * math.sin(theta));
}

/// element.arc.ts:116 `pathArc`.
///
/// Path the arc, respecting border radius by separating into left and right
/// halves.
///
/// ```text
///   Start      End
///
///    1--->a--->2    Outer
///   /           \
///   8           3
///   |           |
///   |           |
///   7           4
///   \           /
///    6<---b<---5    Inner
/// ```
void _pathArc(
  CanvasRenderingContext2D ctx,
  ArcElement element,
  double offset,
  double spacing,
  double end,
  bool circular,
) {
  final ArcElement(
    :x,
    :y,
    startAngle: start,
    :pixelMargin,
    innerRadius: innerR,
  ) = element;

  final outerRadius = jsMax(
    element.outerRadius + spacing + offset - pixelMargin,
    0,
  );
  final innerRadius = innerR > 0
      ? innerR + spacing + offset + pixelMargin
      : 0.0;

  var spacingOffset = 0.0;
  final alpha = end - start;

  if (jsTruthy(spacing)) {
    // When spacing is present, it is the same for all items
    // So we adjust the start and end angle of the arc such that
    // the distance is the same as it would be without the spacing
    final noSpacingInnerRadius = innerR > 0 ? innerR - spacing : 0.0;
    final noSpacingOuterRadius = outerRadius > 0 ? outerRadius - spacing : 0.0;
    final avNogSpacingRadius =
        (noSpacingInnerRadius + noSpacingOuterRadius) / 2;
    final adjustedAngle = avNogSpacingRadius != 0
        ? (alpha * avNogSpacingRadius) / (avNogSpacingRadius + spacing)
        : alpha;
    spacingOffset = (alpha - adjustedAngle) / 2;
  }

  final beta = jsMax(0.001, alpha * outerRadius - offset / pi) / outerRadius;
  final angleOffset = (alpha - beta) / 2;
  final startAngle = start + angleOffset + spacingOffset;
  final endAngle = end - angleOffset - spacingOffset;
  final (:outerStart, :outerEnd, :innerStart, :innerEnd) = _parseBorderRadius(
    element,
    innerRadius,
    outerRadius,
    endAngle - startAngle,
  );

  final outerStartAdjustedRadius = outerRadius - outerStart;
  final outerEndAdjustedRadius = outerRadius - outerEnd;
  final outerStartAdjustedAngle =
      startAngle + outerStart / outerStartAdjustedRadius;
  final outerEndAdjustedAngle = endAngle - outerEnd / outerEndAdjustedRadius;

  final innerStartAdjustedRadius = innerRadius + innerStart;
  final innerEndAdjustedRadius = innerRadius + innerEnd;
  final innerStartAdjustedAngle =
      startAngle + innerStart / innerStartAdjustedRadius;
  final innerEndAdjustedAngle = endAngle - innerEnd / innerEndAdjustedRadius;

  ctx.beginPath();

  if (circular) {
    // The first arc segments from point 1 to point a to point 2
    final outerMidAdjustedAngle =
        (outerStartAdjustedAngle + outerEndAdjustedAngle) / 2;
    ctx
      ..arc(x, y, outerRadius, outerStartAdjustedAngle, outerMidAdjustedAngle)
      ..arc(x, y, outerRadius, outerMidAdjustedAngle, outerEndAdjustedAngle);

    // The corner segment from point 2 to point 3
    if (outerEnd > 0) {
      final pCenter = _rThetaToXY(
        outerEndAdjustedRadius,
        outerEndAdjustedAngle,
        x,
        y,
      );
      ctx.arc(
        pCenter.x,
        pCenter.y,
        outerEnd,
        outerEndAdjustedAngle,
        endAngle + halfPi,
      );
    }

    // The line from point 3 to point 4
    final p4 = _rThetaToXY(innerEndAdjustedRadius, endAngle, x, y);
    ctx.lineTo(p4.x, p4.y);

    // The corner segment from point 4 to point 5
    if (innerEnd > 0) {
      final pCenter = _rThetaToXY(
        innerEndAdjustedRadius,
        innerEndAdjustedAngle,
        x,
        y,
      );
      ctx.arc(
        pCenter.x,
        pCenter.y,
        innerEnd,
        endAngle + halfPi,
        innerEndAdjustedAngle + math.pi,
      );
    }

    // The inner arc from point 5 to point b to point 6
    final innerMidAdjustedAngle =
        ((endAngle - (innerEnd / innerRadius)) +
            (startAngle + (innerStart / innerRadius))) /
        2;
    ctx
      ..arc(
        x,
        y,
        innerRadius,
        endAngle - (innerEnd / innerRadius),
        innerMidAdjustedAngle,
        true,
      )
      ..arc(
        x,
        y,
        innerRadius,
        innerMidAdjustedAngle,
        startAngle + (innerStart / innerRadius),
        true,
      );

    // The corner segment from point 6 to point 7
    if (innerStart > 0) {
      final pCenter = _rThetaToXY(
        innerStartAdjustedRadius,
        innerStartAdjustedAngle,
        x,
        y,
      );
      ctx.arc(
        pCenter.x,
        pCenter.y,
        innerStart,
        innerStartAdjustedAngle + math.pi,
        startAngle - halfPi,
      );
    }

    // The line from point 7 to point 8
    final p8 = _rThetaToXY(outerStartAdjustedRadius, startAngle, x, y);
    ctx.lineTo(p8.x, p8.y);

    // The corner segment from point 8 to point 1
    if (outerStart > 0) {
      final pCenter = _rThetaToXY(
        outerStartAdjustedRadius,
        outerStartAdjustedAngle,
        x,
        y,
      );
      ctx.arc(
        pCenter.x,
        pCenter.y,
        outerStart,
        startAngle - halfPi,
        outerStartAdjustedAngle,
      );
    }
  } else {
    ctx.moveTo(x, y);

    final outerStartX = math.cos(outerStartAdjustedAngle) * outerRadius + x;
    final outerStartY = math.sin(outerStartAdjustedAngle) * outerRadius + y;
    ctx.lineTo(outerStartX, outerStartY);

    final outerEndX = math.cos(outerEndAdjustedAngle) * outerRadius + x;
    final outerEndY = math.sin(outerEndAdjustedAngle) * outerRadius + y;
    ctx.lineTo(outerEndX, outerEndY);
  }

  ctx.closePath();
}

/// element.arc.ts:218 `drawArc`.
double _drawArc(
  CanvasRenderingContext2D ctx,
  ArcElement element,
  double offset,
  double spacing,
  bool circular,
) {
  final ArcElement(:fullCircles, :startAngle, :circumference) = element;
  var endAngle = element.endAngle;
  if (jsTruthy(fullCircles)) {
    _pathArc(ctx, element, offset, spacing, endAngle, circular);
    for (var i = 0; i < fullCircles; ++i) {
      ctx.fill();
    }
    // The getter gives NaN for undefined, and isNaN(undefined) is true.
    if (!circumference.isNaN) {
      endAngle = startAngle + _orTau(circumference.remainder(tau));
    }
  }
  _pathArc(ctx, element, offset, spacing, endAngle, circular);
  ctx.fill();
  return endAngle;
}

/// element.arc.ts:241 `drawBorder`.
void _drawBorder(
  CanvasRenderingContext2D ctx,
  ArcElement element,
  double offset,
  double spacing,
  bool circular,
) {
  final ArcElement(:fullCircles, :startAngle, :circumference) = element;
  final options = element.options!;
  // borderWidth, borderJoinStyle and borderDash reach the canvas only when
  // they are truthy. borderJoinStyle and borderRadius are compared with a
  // string and with 0. Thus JS undefined and JS null give one result.
  final borderWidth = _borderWidth(options);
  final borderJoinStyle = _borderJoinStyle(options);
  final borderDash = _borderDash(options);
  // An absent key is undefined, which the canvas ignores. JS null is 0.
  final borderDashOffset = _borderDashOffset(options);
  final borderRadius = _borderRadius(options);
  final inner = _borderAlign(options) == 'inner';

  if (!jsTruthy(borderWidth)) {
    return;
  }

  ctx
    ..setLineDash(
      canvasLineDash(jsTruthy(borderDash) ? borderDash : const <double>[]),
    )
    ..lineDashOffset = canvasNumber(borderDashOffset);

  if (inner) {
    ctx
      ..lineWidth = jsToNumber(borderWidth) * 2
      ..lineJoin = canvasKeyword(
        jsTruthy(borderJoinStyle) ? borderJoinStyle : 'round',
      );
  } else {
    ctx
      ..lineWidth = canvasNumber(borderWidth)
      ..lineJoin = canvasKeyword(
        jsTruthy(borderJoinStyle) ? borderJoinStyle : 'bevel',
      );
  }

  var endAngle = element.endAngle;
  if (jsTruthy(fullCircles)) {
    _pathArc(ctx, element, offset, spacing, endAngle, circular);
    for (var i = 0; i < fullCircles; ++i) {
      ctx.stroke();
    }
    // The getter gives NaN for undefined, and isNaN(undefined) is true.
    if (!circumference.isNaN) {
      endAngle = startAngle + _orTau(circumference.remainder(tau));
    }
  }

  if (inner) {
    _clipArc(ctx, element, endAngle);
  }

  // `borderRadius === 0`: the Dart `==` of a number and 0 is true only for
  // 0 and -0, and false for every value that is not a number.
  if (jsTruthy(_selfJoin(options)) &&
      endAngle - startAngle >= pi &&
      borderRadius == 0 &&
      borderJoinStyle != 'miter') {
    _clipSelf(ctx, element, endAngle);
  }

  if (!jsTruthy(fullCircles)) {
    _pathArc(ctx, element, offset, spacing, endAngle, circular);
    ctx.stroke();
  }
}

/// `value || TAU` for the number [value] (element.arc.ts:233, :274).
double _orTau(double value) => jsTruthy(value) ? value : tau;

/// element.arc.ts:292 `ArcProps`, the animated properties of an
/// [ArcElement]: the `T` of `Element<ArcProps, ArcOptions>`.
///
/// A number is a `double`. It is NaN in the `undefined` state of the
/// element (Chart.js ADR 0017, section 4).
abstract interface class ArcProps implements Point {
  /// element.arc.ts:293 `startAngle: number`.
  double get startAngle;

  /// element.arc.ts:294 `endAngle: number`.
  double get endAngle;

  /// element.arc.ts:295 `innerRadius: number`.
  double get innerRadius;

  /// element.arc.ts:296 `outerRadius: number`.
  double get outerRadius;

  /// element.arc.ts:297 `circumference: number`.
  double get circumference;
}

/// element.arc.ts:300 `ArcElement extends Element<ArcProps, ArcOptions>`.
///
/// The arc of one data value of a doughnut, pie or polar area chart. The
/// center is ([x], [y]). The arc goes from [startAngle] to [endAngle], in
/// radians, between [innerRadius] and [outerRadius].
///
/// ## Properties
///
/// The numeric properties of upstream are typed members (Chart.js ADR 0017,
/// sections 3 and 4). [circumference], [endAngle], [innerRadius],
/// [outerRadius] and [startAngle] start in the `undefined` state, and their
/// getters give NaN in that state. [pixelMargin] and [fullCircles] start at
/// 0. The access by name reads and writes each of them by its upstream
/// name, and stores [undefined] again.
///
/// A reader that must tell `undefined` from NaN reads the property by name
/// or through `getProps`: [inRange] reads `circumference` with
/// `valueOrDefault` (element.arc.ts:364).
///
/// ## Options
///
/// [options] are the resolved options (`ArcOptions`, index.d.ts:1850), a
/// Map. The [defaults] list the keys.
///
/// ## Range on one axis
///
/// Upstream `ArcElement` has no `inXRange` and no `inYRange`. The port
/// implements `types.VisualElement`, which declares them (Chart.js ADR
/// 0017, section 1). Thus [inXRange] and [inYRange] give false (the
/// difference `adapt-arc-axis-range`).
class ArcElement extends Element implements types.VisualElement, ArcProps {
  /// element.arc.ts:336 `constructor(cfg)`.
  ///
  /// [options], [circumference], [startAngle], [endAngle], [innerRadius]
  /// and [outerRadius] start in the `undefined` state. [pixelMargin] and
  /// [fullCircles] start at 0. Then the constructor writes each key of
  /// [cfg] by name, as `Object.assign(this, cfg)` does: an `int` becomes a
  /// `double`, and a value outside the type of a property throws an
  /// [ArgumentError]. Dart `null` for [cfg] stands for JS `undefined`.
  ArcElement([AnyObject? cfg]) {
    pixelMargin = 0;
    fullCircles = 0;

    if (cfg != null) assign(cfg);
  }

  /// element.arc.ts:302 `static id = 'arc'`.
  static const String id = 'arc';

  /// element.arc.ts:304 `static defaults`, in the upstream key order.
  static final AnyObject defaults = {
    'borderAlign': 'center',
    'borderColor': '#fff',
    'borderDash': <Object?>[],
    'borderDashOffset': 0.0,
    'borderJoinStyle': undefined,
    'borderRadius': 0.0,
    'borderWidth': 2.0,
    'offset': 0.0,
    'spacing': 0.0,
    'angle': undefined,
    'circular': true,
    'selfJoin': false,
  };

  /// element.arc.ts:319 `static defaultRoutes`.
  static final AnyObject defaultRoutes = {
    'backgroundColor': 'backgroundColor',
  };

  /// element.arc.ts:323 `static descriptors`. The `_indexable` function is
  /// a Dart closure (Chart.js ADR 0006).
  static final AnyObject descriptors = {
    '_scriptable': true,
    '_indexable': (String name) => name != 'borderDash',
  };

  /// The value of [circumference]. Dart `null` stands for JS `undefined`.
  double? _circumference;

  /// The value of [endAngle]. Dart `null` stands for JS `undefined`.
  double? _endAngle;

  /// The value of [fullCircles]. Dart `null` stands for JS `undefined`.
  double? _fullCircles;

  /// The value of [innerRadius]. Dart `null` stands for JS `undefined`.
  double? _innerRadius;

  /// The value of [outerRadius]. Dart `null` stands for JS `undefined`.
  double? _outerRadius;

  /// The value of [pixelMargin]. Dart `null` stands for JS `undefined`.
  double? _pixelMargin;

  /// The value of [startAngle]. Dart `null` stands for JS `undefined`.
  double? _startAngle;

  /// element.arc.ts:328 `circumference: number`: the sweep of the arc, in
  /// radians.
  ///
  /// NaN in the `undefined` state, the start value. JS `null` never reaches
  /// it. `this['circumference']` gives [undefined] in that state.
  @override
  double get circumference => _circumference ?? double.nan;

  set circumference(double value) => _circumference = value;

  /// element.arc.ts:329 `endAngle: number`. NaN in the `undefined` state,
  /// the start value, as [circumference].
  @override
  double get endAngle => _endAngle ?? double.nan;

  set endAngle(double value) => _endAngle = value;

  /// element.arc.ts:330 `fullCircles: number`: the count of full circles
  /// in [circumference], that [draw] sets.
  ///
  /// It starts at 0. NaN after a write by name of [undefined].
  double get fullCircles => _fullCircles ?? double.nan;

  set fullCircles(double value) => _fullCircles = value;

  /// element.arc.ts:331 `innerRadius: number`. NaN in the `undefined`
  /// state, the start value, as [circumference].
  @override
  double get innerRadius => _innerRadius ?? double.nan;

  set innerRadius(double value) => _innerRadius = value;

  /// element.arc.ts:332 `outerRadius: number`. NaN in the `undefined`
  /// state, the start value, as [circumference].
  @override
  double get outerRadius => _outerRadius ?? double.nan;

  set outerRadius(double value) => _outerRadius = value;

  /// element.arc.ts:333 `pixelMargin: number`: 0.33 for an inner border,
  /// else 0. [draw] sets it.
  ///
  /// It starts at 0. NaN after a write by name of [undefined].
  double get pixelMargin => _pixelMargin ?? double.nan;

  set pixelMargin(double value) => _pixelMargin = value;

  /// element.arc.ts:334 `startAngle: number`. NaN in the `undefined`
  /// state, the start value, as [circumference].
  @override
  double get startAngle => _startAngle ?? double.nan;

  set startAngle(double value) => _startAngle = value;

  /// The JS property read `element[prop]` (Chart.js ADR 0017, section 5),
  /// for the properties of element.arc.ts:328-334. Other names go to
  /// `Element`.
  @override
  Object? operator [](String prop) => switch (prop) {
    'circumference' => _circumference ?? undefined,
    'endAngle' => _endAngle ?? undefined,
    'fullCircles' => _fullCircles ?? undefined,
    'innerRadius' => _innerRadius ?? undefined,
    'outerRadius' => _outerRadius ?? undefined,
    'pixelMargin' => _pixelMargin ?? undefined,
    'startAngle' => _startAngle ?? undefined,
    _ => super[prop],
  };

  /// The JS property write `element[prop] = value` (Chart.js ADR 0017,
  /// section 5), for the properties of element.arc.ts:328-334. Each accepts
  /// a `num` or [undefined], and throws an [ArgumentError] for another
  /// value. Other names go to `Element`.
  @override
  void operator []=(String prop, Object? value) {
    switch (prop) {
      case 'circumference':
        _circumference = toNumberProp(prop, value);
      case 'endAngle':
        _endAngle = toNumberProp(prop, value);
      case 'fullCircles':
        _fullCircles = toNumberProp(prop, value);
      case 'innerRadius':
        _innerRadius = toNumberProp(prop, value);
      case 'outerRadius':
        _outerRadius = toNumberProp(prop, value);
      case 'pixelMargin':
        _pixelMargin = toNumberProp(prop, value);
      case 'startAngle':
        _startAngle = toNumberProp(prop, value);
      default:
        super[prop] = value;
    }
  }

  /// element.arc.ts:353 `inRange(chartX, chartY, useFinalPosition)`.
  ///
  /// Whether the point ([chartX], [chartY]) is in the arc: its angle is
  /// between the angles, or the circumference is a full circle, and its
  /// distance is between the radii plus half of the spacing and of the
  /// border width. Dart `null` for [useFinalPosition] stands for JS
  /// `undefined`.
  ///
  /// It reads the properties through `getProps` with `jsToNumber`. It reads
  /// `circumference` with `valueOrDefault`: `undefined` gives the sweep from
  /// the angles, and NaN stays NaN. The test `startAngle !== endAngle`
  /// compares the numbers. Both angles in the `undefined` state give NaN,
  /// where upstream compares two `undefined`. `_angleBetween` is false for
  /// NaN, so the result is the same.
  @override
  bool inRange(
    double chartX,
    double chartY, [
    bool? useFinalPosition,
  ]) {
    final point = getProps(const ['x', 'y'], useFinalPosition);
    final (:angle, :distance) = getAngleFromPoint(
      ElementPoint(jsToNumber(point['x']), jsToNumber(point['y'])),
      ElementPoint(chartX, chartY),
    );
    final props = getProps(const [
      'startAngle',
      'endAngle',
      'innerRadius',
      'outerRadius',
      'circumference',
    ], useFinalPosition);
    final startAngle = jsToNumber(props['startAngle']);
    final endAngle = jsToNumber(props['endAngle']);
    final innerRadius = jsToNumber(props['innerRadius']);
    final outerRadius = jsToNumber(props['outerRadius']);
    final circumference = props['circumference'];
    final rAdjust =
        (jsToNumber(_spacing(options)) + jsToNumber(_borderWidth(options))) / 2;
    final circumference_ = jsToNumber(
      valueOrDefault<Object?>(circumference, endAngle - startAngle),
    );
    final nonZeroBetween =
        angleBetween(angle, startAngle, endAngle) && startAngle != endAngle;
    final betweenAngles = circumference_ >= tau || nonZeroBetween;
    final withinRadius = isBetween(
      distance,
      innerRadius + rAdjust,
      outerRadius + rAdjust,
    );

    return betweenAngles && withinRadius;
  }

  /// No upstream counterpart: `ArcElement` has no `inXRange`.
  ///
  /// `types.VisualElement` declares it, so the port gives false. The one
  /// upstream caller tests `element[rangeMethod] &&` before the call
  /// (core.interaction.js:234), and the absent method gives false there. A
  /// direct call gives false where upstream throws a `TypeError`
  /// (differences.md row `adapt-arc-axis-range`).
  // DIVERGES(chartjs): adapt-arc-axis-range, no upstream inXRange.
  @override
  bool inXRange(
    double mouseX, [
    bool? useFinalPosition,
  ]) => false;

  /// No upstream counterpart: `ArcElement` has no `inYRange`. It gives
  /// false, as [inXRange] does.
  // DIVERGES(chartjs): adapt-arc-axis-range, no upstream inYRange.
  @override
  bool inYRange(
    double mouseY, [
    bool? useFinalPosition,
  ]) => false;

  /// element.arc.ts:372 `getCenterPoint(useFinalPosition)`.
  ///
  /// The point at the middle angle and at the middle radius, plus half of
  /// the `offset` and `spacing` options. Dart `null` for [useFinalPosition]
  /// stands for JS `undefined`. A property in the `undefined` state, and an
  /// absent option, give NaN.
  @override
  ElementPoint getCenterPoint([
    bool? useFinalPosition,
  ]) {
    final props = getProps(const [
      'x',
      'y',
      'startAngle',
      'endAngle',
      'innerRadius',
      'outerRadius',
    ], useFinalPosition);
    final x = jsToNumber(props['x']);
    final y = jsToNumber(props['y']);
    final startAngle = jsToNumber(props['startAngle']);
    final endAngle = jsToNumber(props['endAngle']);
    final innerRadius = jsToNumber(props['innerRadius']);
    final outerRadius = jsToNumber(props['outerRadius']);
    final offset = jsToNumber(_offset(options));
    final spacing = jsToNumber(_spacing(options));
    final halfAngle = (startAngle + endAngle) / 2;
    final halfRadius = (innerRadius + outerRadius + spacing + offset) / 2;
    return ElementPoint(
      x + math.cos(halfAngle) * halfRadius,
      y + math.sin(halfAngle) * halfRadius,
    );
  }

  /// element.arc.ts:390 `tooltipPosition(useFinalPosition)`: the
  /// [getCenterPoint].
  @override
  ElementPoint tooltipPosition([
    bool? useFinalPosition,
  ]) {
    return getCenterPoint(useFinalPosition);
  }

  /// element.arc.ts:394 `draw(ctx)`.
  ///
  /// It sets [pixelMargin] and [fullCircles] first. It draws nothing for a
  /// [circumference] of 0 or a negative radius. Upstream `draw` takes no
  /// area, so [area] has no effect. It throws a [TypeError] when [options]
  /// is in the `undefined` state, as upstream does.
  @override
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]) {
    final options = this.options!;
    final circumference = this.circumference;
    // `|| 0`, ToBoolean and a compare with a string: JS undefined and JS
    // null give one result.
    final offset = jsOrZero(_offset(options)) / 4;
    final spacing = jsOrZero(_spacing(options)) / 2;
    // pathArc tests it with `if (circular)`.
    final circular = jsTruthy(_circular(options));
    pixelMargin = (_borderAlign(options) == 'inner') ? 0.33 : 0;
    fullCircles = circumference > tau
        ? (circumference / tau).floorToDouble()
        : 0;

    if (circumference == 0 || innerRadius < 0 || outerRadius < 0) {
      return;
    }

    ctx.save();

    final halfAngle = (startAngle + endAngle) / 2;
    ctx.translate(math.cos(halfAngle) * offset, math.sin(halfAngle) * offset);
    final fix =
        1 - math.sin(jsMin(pi, jsTruthy(circumference) ? circumference : 0));
    final radiusOffset = offset * fix;

    ctx
      ..fillStyle = canvasStyle(_backgroundColor(options))
      ..strokeStyle = canvasStyle(_borderColor(options));

    _drawArc(ctx, this, radiusOffset, spacing, circular);
    _drawBorder(ctx, this, radiusOffset, spacing, circular);

    ctx.restore();
  }
}
