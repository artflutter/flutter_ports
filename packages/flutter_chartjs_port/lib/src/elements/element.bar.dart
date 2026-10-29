// Ported from Chart.js v4.6.1 src/elements/element.bar.js (MIT, Chart.js Contributors).

/// Port of `src/elements/element.bar.js`.
///
/// [BarElement] follows the element design of Chart.js ADR 0017: typed
/// properties with the `undefined` state, the access by name, and the
/// constructor that writes `cfg` through `operator []=`.
///
/// The functions that upstream does not export (`getBarBounds`,
/// `skipOrLimit`, `parseBorderWidth`, `parseBorderRadius`, `boundingRects`,
/// `inRange`, `hasRadius`, `addNormalRectPath` and `inflateRect`) are
/// private. Their object literals are private types: the bounds
/// `{left, top, right, bottom}` and the border widths `{t, r, b, l}` are
/// records, a rectangle `{x, y, w, h, radius}` is a [RoundedRect] and a
/// corner object `{topLeft, topRight, bottomLeft, bottomRight}` is a
/// [TRBLCorners].
///
/// The options of a bar are a [BarOptions] or a plain Map (Chart.js ADR
/// 0043). Each option read goes through one small function for each option,
/// for example `_borderWidth`, which gives [BarOptions.borderWidthValue] or
/// `jsGet(options, 'borderWidth')` (Chart.js ADR 0018, section 4). Both give
/// JS `undefined` for an absent key, and `jsGet` throws the [TypeError] of a
/// property read of `undefined` options.
///
/// This library is a pure layer (Chart.js ADR 0017, section 10). It imports
/// neither `dart:ui` nor `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show BarOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show addRoundedRectPath;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isObject;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show isBetween, limitValue;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show toTRBL, toTRBLCorners;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// The option `borderWidth` of [options]: [BarOptions.borderWidthValue] for
/// typed options, else `jsGet(options, 'borderWidth')` (Chart.js ADR 0018,
/// section 4).
///
/// Both give JS `undefined` for an absent key. `jsGet` throws a [TypeError]
/// for Dart `null`, the `undefined` state of the options. The other option
/// functions of this file work in the same way.
Object? _borderWidth(Object? options) => options is BarOptions
    ? options.borderWidthValue
    : jsGet(options, 'borderWidth');

/// The option `borderRadius` of [options], as [_borderWidth] reads
/// `borderWidth`.
Object? _borderRadius(Object? options) => options is BarOptions
    ? options.borderRadiusValue
    : jsGet(options, 'borderRadius');

/// The option `borderColor` of [options], as [_borderWidth] reads
/// `borderWidth`.
Object? _borderColor(Object? options) => options is BarOptions
    ? options.borderColorValue
    : jsGet(options, 'borderColor');

/// The option `backgroundColor` of [options], as [_borderWidth] reads
/// `borderWidth`.
Object? _backgroundColor(Object? options) => options is BarOptions
    ? options.backgroundColorValue
    : jsGet(options, 'backgroundColor');

/// element.bar.js:34 the bounds literal `{left, top, right, bottom}` of
/// `getBarBounds`.
typedef _Bounds = ({double left, double top, double right, double bottom});

/// element.bar.js:46-51 the border widths literal `{t, r, b, l}` of
/// `parseBorderWidth`.
typedef _BorderWidths = ({double t, double r, double b, double l});

/// element.bar.js:15 `getBarBounds`.
///
/// Helper function to get the bounds of the bar regardless of the
/// orientation
/// @param bar the bar
/// @param [useFinalPosition]
/// @return bounds of the bar
/// @private
///
/// The numbers of `getProps` are read with `jsToNumber`, the `ToNumber` of
/// the upstream arithmetic (Chart.js ADR 0017, section 7). Dart `null` for
/// [useFinalPosition] stands for JS `undefined`.
_Bounds _getBarBounds(BarElement bar, [bool? useFinalPosition]) {
  final props = bar.getProps(const [
    'x',
    'y',
    'base',
    'width',
    'height',
  ], useFinalPosition);
  final x = jsToNumber(props['x']);
  final y = jsToNumber(props['y']);
  final base = jsToNumber(props['base']);
  final width = jsToNumber(props['width']);
  final height = jsToNumber(props['height']);

  // Upstream declares `let left, right, top, bottom, half;`.
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double half;

  if (bar.horizontal == true) {
    half = height / 2;
    left = jsMin(x, base);
    right = jsMax(x, base);
    top = y - half;
    bottom = y + half;
  } else {
    half = width / 2;
    left = x - half;
    right = x + half;
    top = jsMin(y, base);
    bottom = jsMax(y, base);
  }

  return (left: left, top: top, right: right, bottom: bottom);
}

/// element.bar.js:37 `skipOrLimit`.
///
/// [skip] is the `ToBoolean` of the upstream `skip` value.
double _skipOrLimit(bool skip, double value, double min, double max) {
  return skip ? 0 : limitValue(value, min, max);
}

/// element.bar.js:41 `parseBorderWidth`.
///
/// `bar.options.borderWidth` and `skip.<edge>` are property reads
/// ([_borderWidth] and [jsGet]). Thus an element without `options` or
/// without `borderSkipped` throws a [TypeError], as upstream does.
_BorderWidths _parseBorderWidth(BarElement bar, double maxW, double maxH) {
  final value = _borderWidth(bar.options);
  final skip = bar.borderSkipped;
  final o = toTRBL(value);

  return (
    t: _skipOrLimit(jsTruthy(jsGet(skip, 'top')), o.top, 0, maxH),
    r: _skipOrLimit(jsTruthy(jsGet(skip, 'right')), o.right, 0, maxW),
    b: _skipOrLimit(jsTruthy(jsGet(skip, 'bottom')), o.bottom, 0, maxH),
    l: _skipOrLimit(jsTruthy(jsGet(skip, 'left')), o.left, 0, maxW),
  );
}

/// element.bar.js:54 `parseBorderRadius`.
///
/// `enableBorderRadius` is read by name through `getProps`. The JS `||`
/// operands are tested with `ToBoolean` ([jsTruthy]) in the upstream order.
TRBLCorners _parseBorderRadius(BarElement bar, double maxW, double maxH) {
  final enableBorderRadius = bar.getProps(const [
    'enableBorderRadius',
  ])['enableBorderRadius'];
  final value = _borderRadius(bar.options);
  final o = toTRBLCorners(value);
  final maxR = jsMin(maxW, maxH);
  final skip = bar.borderSkipped;

  // If the value is an object, assume the user knows what they are doing
  // and apply as directed.
  final enableBorder = jsTruthy(enableBorderRadius) || isObject(value);

  return _Corners(
    topLeft: _skipOrLimit(
      !enableBorder ||
          jsTruthy(jsGet(skip, 'top')) ||
          jsTruthy(jsGet(skip, 'left')),
      o.topLeft,
      0,
      maxR,
    ),
    topRight: _skipOrLimit(
      !enableBorder ||
          jsTruthy(jsGet(skip, 'top')) ||
          jsTruthy(jsGet(skip, 'right')),
      o.topRight,
      0,
      maxR,
    ),
    bottomLeft: _skipOrLimit(
      !enableBorder ||
          jsTruthy(jsGet(skip, 'bottom')) ||
          jsTruthy(jsGet(skip, 'left')),
      o.bottomLeft,
      0,
      maxR,
    ),
    bottomRight: _skipOrLimit(
      !enableBorder ||
          jsTruthy(jsGet(skip, 'bottom')) ||
          jsTruthy(jsGet(skip, 'right')),
      o.bottomRight,
      0,
      maxR,
    ),
  );
}

/// element.bar.js:73 `boundingRects`: the `outer` and the `inner`
/// rectangle of the bar.
({_Rect outer, _Rect inner}) _boundingRects(BarElement bar) {
  final bounds = _getBarBounds(bar);
  final width = bounds.right - bounds.left;
  final height = bounds.bottom - bounds.top;
  final border = _parseBorderWidth(bar, width / 2, height / 2);
  final radius = _parseBorderRadius(bar, width / 2, height / 2);

  return (
    outer: _Rect(
      x: bounds.left,
      y: bounds.top,
      w: width,
      h: height,
      radius: radius,
    ),
    inner: _Rect(
      x: bounds.left + border.l,
      y: bounds.top + border.t,
      w: width - border.l - border.r,
      h: height - border.t - border.b,
      radius: _Corners(
        topLeft: jsMax(0, radius.topLeft - jsMax(border.t, border.l)),
        topRight: jsMax(0, radius.topRight - jsMax(border.t, border.r)),
        bottomLeft: jsMax(0, radius.bottomLeft - jsMax(border.b, border.l)),
        bottomRight: jsMax(0, radius.bottomRight - jsMax(border.b, border.r)),
      ),
    ),
  );
}

/// element.bar.js:103 `inRange`.
///
/// Dart `null` for [x] or [y] is JS `null`: the `null` that `inXRange` and
/// `inYRange` pass, or a `null` coordinate of the event position that an
/// interaction mode passes to `inRange`. Upstream also tests that `bar` is
/// truthy. The callers pass `this`, which is never null. Thus the port omits
/// that test.
bool _inRange(
  BarElement bar,
  double? x,
  double? y,
  bool? useFinalPosition,
) {
  final skipX = x == null;
  final skipY = y == null;
  final skipBoth = skipX && skipY;
  final bounds = !skipBoth ? _getBarBounds(bar, useFinalPosition) : null;

  return bounds != null &&
      (skipX || isBetween(x, bounds.left, bounds.right)) &&
      (skipY || isBetween(y, bounds.top, bounds.bottom));
}

/// element.bar.js:114 `hasRadius`: whether a corner radius is truthy (not
/// 0 and not NaN).
bool _hasRadius(TRBLCorners radius) {
  return jsTruthy(radius.topLeft) ||
      jsTruthy(radius.topRight) ||
      jsTruthy(radius.bottomLeft) ||
      jsTruthy(radius.bottomRight);
}

/// element.bar.js:123 `addNormalRectPath`.
///
/// Add a path of a rectangle to the current sub-path
/// @param ctx Context
/// @param rect Bounding rect
void _addNormalRectPath(CanvasRenderingContext2D ctx, RoundedRect rect) {
  ctx.rect(rect.x, rect.y, rect.w, rect.h);
}

/// element.bar.js:127 `inflateRect`.
///
/// Dart `null` for [refRect] stands for the default `{}`. Its `x` and `w`
/// are `undefined`, so each `!==` test of upstream gives true.
_Rect _inflateRect(_Rect rect, double amount, [_Rect? refRect]) {
  final x = refRect == null || rect.x != refRect.x ? -amount : 0.0;
  final y = refRect == null || rect.y != refRect.y ? -amount : 0.0;
  final w =
      (refRect == null || rect.x + rect.w != refRect.x + refRect.w
          ? amount
          : 0.0) -
      x;
  final h =
      (refRect == null || rect.y + rect.h != refRect.y + refRect.h
          ? amount
          : 0.0) -
      y;
  return _Rect(
    x: rect.x + x,
    y: rect.y + y,
    w: rect.w + w,
    h: rect.h + h,
    radius: rect.radius,
  );
}

/// element.bar.js:141 `BarElement`.
///
/// The properties follow Chart.js ADR 0017: a nullable private field for the
/// `undefined` state, a getter that gives NaN (a number) or `null` (a
/// boolean or an object) in that state, and a setter that takes the
/// non-null type.
///
/// Upstream declares `horizontal`, `base`, `width`, `height` and
/// `inflateAmount` in the constructor (:167-172). `controller.bar.js` also
/// writes `enableBorderRadius` (:410, :219) and `borderSkipped` (:202-232)
/// through `updateElement`. The element reads both in each [draw]. Thus the
/// port declares them too (Chart.js ADR 0017, section 3).
///
/// The class implements `types.VisualElementRange`, because upstream has a
/// [getRange] (element.bar.js:223, Chart.js ADR 0020, section 9).
class BarElement extends Element implements types.VisualElementRange {
  /// element.bar.js:164 `constructor(cfg)`.
  ///
  /// `options`, [horizontal], [base], [width], [height] and [inflateAmount]
  /// start in the `undefined` state (:167-172). Then the constructor writes
  /// each key of [cfg] through `operator []=`, as `Object.assign(this,
  /// cfg)` does (:174-176). A Map is always truthy, so `if (cfg)` is a test
  /// for `null`.
  BarElement([AnyObject? cfg]) {
    if (cfg != null) assign(cfg);
  }

  /// element.bar.js:143 `static id = 'bar'`.
  static const String id = 'bar';

  /// element.bar.js:148 `static defaults`, in the upstream key order.
  static final AnyObject defaults = {
    'borderSkipped': 'start',
    'borderWidth': 0.0,
    'borderRadius': 0.0,
    'inflateAmount': 'auto',
    'pointStyle': undefined,
  };

  /// element.bar.js:159 `static defaultRoutes`, in the upstream key order.
  static final AnyObject defaultRoutes = {
    'backgroundColor': 'backgroundColor',
    'borderColor': 'borderColor',
  };

  /// element.bar.js:141 `class BarElement extends Element` as a value (Chart.js
  /// ADR 0020, section 3).
  ///
  /// Its statics are [id], [defaults] and [defaultRoutes], in the upstream
  /// order of declaration (element.bar.js:143-162). They are the objects of the
  /// static fields. Its `construct` calls `BarElement(cfg)` with the `cfg` of
  /// [elementCfgArg].
  static final JsClass jsClass = JsClass(
    'BarElement',
    superclass: Element.jsClass,
    statics: {'id': id, 'defaults': defaults, 'defaultRoutes': defaultRoutes},
    construct: (newTarget, args) => BarElement(elementCfgArg(args)),
  );

  /// The value of [horizontal]. Dart `null` stands for JS `undefined`.
  bool? _horizontal;

  /// The value of [base]. Dart `null` stands for JS `undefined`.
  double? _base;

  /// The value of [width]. Dart `null` stands for JS `undefined`.
  double? _width;

  /// The value of [height]. Dart `null` stands for JS `undefined`.
  double? _height;

  /// The value of [inflateAmount]. Dart `null` stands for JS `undefined`.
  double? _inflateAmount;

  /// The value of [borderSkipped]. Dart `null` stands for JS `undefined`.
  Map<String, Object?>? _borderSkipped;

  /// The value of [enableBorderRadius]. Dart `null` stands for JS
  /// `undefined`.
  bool? _enableBorderRadius;

  /// element.bar.js:168 `this.horizontal = undefined`: whether the value
  /// axis of the bar is horizontal (`BarProps.horizontal`, index.d.ts:2143).
  ///
  /// Dart `null` stands for JS `undefined`, the start value, which is falsy.
  /// JS `null` never reaches it.
  bool? get horizontal => _horizontal;

  set horizontal(bool value) => _horizontal = value;

  /// element.bar.js:169 `this.base = undefined`: the pixel of the base of
  /// the bar on the value axis (`BarProps.base`, index.d.ts:2142).
  ///
  /// NaN in the `undefined` state, the start value. JS `null` never reaches
  /// it. `this['base']` gives `undefined` in that state.
  double get base => _base ?? double.nan;

  set base(double value) => _base = value;

  /// element.bar.js:170 `this.width = undefined` (`BarProps.width`,
  /// index.d.ts:2144). NaN in the `undefined` state, as [base].
  double get width => _width ?? double.nan;

  set width(double value) => _width = value;

  /// element.bar.js:171 `this.height = undefined` (`BarProps.height`,
  /// index.d.ts:2145). NaN in the `undefined` state, as [base].
  double get height => _height ?? double.nan;

  set height(double value) => _height = value;

  /// element.bar.js:172 `this.inflateAmount = undefined`: the pixels that
  /// [draw] adds to the rectangles. `controller.bar.js:252-256` sets it from
  /// the `inflateAmount` option. NaN in the `undefined` state, as [base].
  double get inflateAmount => _inflateAmount ?? double.nan;

  set inflateAmount(double value) => _inflateAmount = value;

  /// controller.bar.js:202-232 `properties.borderSkipped`, which
  /// element.bar.js:43 and :59 read: the skipped edges of the border.
  ///
  /// It is a JS plain object, thus a `Map<String, Object?>` (Chart.js ADR
  /// 0043). Each key that `controller.bar.js` writes has the value true:
  /// `'top'`, `'right'`, `'bottom'` or `'left'`, or another edge name of the
  /// `borderSkipped` option, which [draw] ignores. [draw] reads the four
  /// edges with [jsGet] and tests them with `ToBoolean` ([jsTruthy]).
  ///
  /// Dart `null` stands for JS `undefined`, the value before the first
  /// update. Then [draw] throws a [TypeError], as upstream does. JS `null`
  /// never reaches it.
  Map<String, Object?>? get borderSkipped => _borderSkipped;

  set borderSkipped(Map<String, Object?> value) => _borderSkipped = value;

  /// controller.bar.js:410 and :219 `properties.enableBorderRadius`, which
  /// element.bar.js:55 reads: whether a number `borderRadius` rounds the
  /// corners.
  ///
  /// Dart `null` stands for JS `undefined`, the value before the first
  /// update, which is falsy. JS `null` never reaches it.
  bool? get enableBorderRadius => _enableBorderRadius;

  set enableBorderRadius(bool value) => _enableBorderRadius = value;

  /// The JS property read `bar[prop]` (Chart.js ADR 0017, section 5).
  ///
  /// It handles `horizontal`, `base`, `width`, `height`, `inflateAmount`,
  /// `borderSkipped` and `enableBorderRadius`, and passes the other names to
  /// [Element]. A property in the `undefined` state gives the [undefined]
  /// sentinel.
  @override
  Object? operator [](String prop) => switch (prop) {
    'horizontal' => _horizontal ?? undefined,
    'base' => _base ?? undefined,
    'width' => _width ?? undefined,
    'height' => _height ?? undefined,
    'inflateAmount' => _inflateAmount ?? undefined,
    'borderSkipped' => _borderSkipped ?? undefined,
    'enableBorderRadius' => _enableBorderRadius ?? undefined,
    _ => super[prop],
  };

  /// The JS property write `bar[prop] = value` (Chart.js ADR 0017,
  /// section 5).
  ///
  /// - `base`, `width`, `height` and `inflateAmount` accept a `num` or
  ///   [undefined].
  /// - `horizontal` and `enableBorderRadius` accept a `bool` or [undefined].
  /// - `borderSkipped` accepts a `Map<String, Object?>` or [undefined].
  /// - [Element] handles the other names.
  ///
  /// Throws an [ArgumentError] for a value outside the type of a declared
  /// property.
  @override
  void operator []=(String prop, Object? value) {
    switch (prop) {
      case 'horizontal':
        _horizontal = toBoolProp(prop, value);
      case 'base':
        _base = toNumberProp(prop, value);
      case 'width':
        _width = toNumberProp(prop, value);
      case 'height':
        _height = toNumberProp(prop, value);
      case 'inflateAmount':
        _inflateAmount = toNumberProp(prop, value);
      case 'borderSkipped':
        _borderSkipped = toObjectProp<Map<String, Object?>>(prop, value);
      case 'enableBorderRadius':
        _enableBorderRadius = toBoolProp(prop, value);
      default:
        super[prop] = value;
    }
  }

  /// element.bar.js:179 `draw(ctx)`.
  ///
  /// Upstream `draw` takes only the context. Thus the port ignores [area],
  /// as JavaScript ignores an extra argument (Chart.js ADR 0017, section 1).
  /// The colors are property reads of `options` ([_borderColor] and
  /// [_backgroundColor], in the order of the upstream destructuring). An
  /// element without `options` throws a [TypeError], as the upstream
  /// destructuring does. `ctx.fillStyle` gets a color through
  /// [canvasStyle]: an absent color gives Dart `null`, which the canvas
  /// ignores, as the DOM ignores `undefined`.
  ///
  /// When [inflateAmount] is 0, the port does not call `ctx.clip()` (the
  /// performance rule of porting-flow.md §1.1, differences.md
  /// `adapt-bar-clip`). Then the clip is the outer rectangle, and the inner
  /// rectangle of `boundingRects` is inside it: its edges are inside by the
  /// border widths, and its corner arcs have a radius smaller by the
  /// larger border width. Thus the border ring and the fill are inside the
  /// clip, which changes only the anti-aliasing of the edges.
  @override
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]) {
    final inflateAmount = this.inflateAmount;
    final options = this.options;
    final borderColor = _borderColor(options);
    final backgroundColor = _backgroundColor(options);
    final (:inner, :outer) = _boundingRects(this);
    final addRectPath = _hasRadius(outer.radius)
        ? addRoundedRectPath
        : _addNormalRectPath;

    ctx.save();

    if (outer.w != inner.w || outer.h != inner.h) {
      ctx.beginPath();
      addRectPath(ctx, _inflateRect(outer, inflateAmount, inner));
      // DIVERGES(chartjs): adapt-bar-clip, no clip for inflateAmount 0.
      if (inflateAmount != 0) ctx.clip();
      addRectPath(ctx, _inflateRect(inner, -inflateAmount, outer));
      ctx
        ..fillStyle = canvasStyle(borderColor)
        ..fill('evenodd');
    }

    ctx.beginPath();
    addRectPath(ctx, _inflateRect(inner, inflateAmount));
    ctx
      ..fillStyle = canvasStyle(backgroundColor)
      ..fill()
      ..restore();
  }

  /// element.bar.js:203 `inRange(mouseX, mouseY, useFinalPosition)`.
  @override
  bool inRange(double? mouseX, double? mouseY, [bool? useFinalPosition]) {
    return _inRange(this, mouseX, mouseY, useFinalPosition);
  }

  /// element.bar.js:207 `inXRange(mouseX, useFinalPosition)`.
  @override
  bool inXRange(double? mouseX, [bool? useFinalPosition]) {
    return _inRange(this, mouseX, null, useFinalPosition);
  }

  /// element.bar.js:211 `inYRange(mouseY, useFinalPosition)`.
  @override
  bool inYRange(double? mouseY, [bool? useFinalPosition]) {
    return _inRange(this, null, mouseY, useFinalPosition);
  }

  /// element.bar.js:215 `getCenterPoint(useFinalPosition)`.
  ///
  /// The numbers of `getProps` are read with `jsToNumber` and `horizontal`
  /// with `jsTruthy` (Chart.js ADR 0017, section 7). A copied `undefined`
  /// gives NaN in the [ElementPoint].
  @override
  ElementPoint getCenterPoint([bool? useFinalPosition]) {
    final props = getProps(const [
      'x',
      'y',
      'base',
      'horizontal',
    ], useFinalPosition);
    final x = jsToNumber(props['x']);
    final y = jsToNumber(props['y']);
    final base = jsToNumber(props['base']);
    final horizontal = jsTruthy(props['horizontal']);
    return ElementPoint(
      horizontal ? (x + base) / 2 : x,
      horizontal ? y : (y + base) / 2,
    );
  }

  /// element.bar.js:223 `getRange(axis)`: half the [width] for the axis
  /// `'x'`, else half the [height].
  @override
  double getRange(String axis) {
    return axis == 'x' ? width / 2 : height / 2;
  }
}

/// element.bar.js:65-70 and :93-98 the corner literal
/// `{topLeft, topRight, bottomLeft, bottomRight}`.
final class _Corners implements TRBLCorners {
  const _Corners({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  @override
  final double topLeft;

  @override
  final double topRight;

  @override
  final double bottomLeft;

  @override
  final double bottomRight;
}

/// element.bar.js:81-99 and :132-138 the rectangle literal
/// `{x, y, w, h, radius}` of `boundingRects` and `inflateRect`.
final class _Rect implements RoundedRect {
  const _Rect({
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

  /// The corner radii. `addRoundedRectPath` reads them as a [TRBLCorners].
  @override
  final TRBLCorners radius;
}
