// Ported from Chart.js v4.5.1+7169e651 src/elements/element.point.ts (MIT, Chart.js Contributors).

/// Port of `src/elements/element.point.ts`.
///
/// [PointElement] follows the element design of Chart.js ADR 0017: typed
/// properties with the `undefined` state, the access by name of
/// `operator []` and `operator []=`, and the options as a Map.
///
/// The options Map is the resolved options object of the point (Chart.js
/// ADR 0006). It is a [PointOptions] or a plain Map. The methods read each
/// option through one small function, for example `_radius`, which gives
/// [PointOptions.radiusValue] or `jsGet(options, 'radius')` (Chart.js ADR
/// 0018, section 4). Both give the upstream value: JS `undefined` for an
/// absent key. Thus the methods read the options as upstream reads the
/// object:
/// - A numeric option in arithmetic or in a comparison is read with
///   `jsToNumber`, where an absent key (JS `undefined`) gives NaN and JS
///   `null` gives 0. The read also throws the `TypeError` of a property read
///   of `undefined` options.
/// - The `|| 0` reads of [PointElement.size] give 0 for JS `undefined` and
///   for JS `null` (Chart.js ADR 0017, section 8).
///
/// This library is a pure layer (Chart.js ADR 0017, section 10). It imports
/// neither `dart:ui` nor `package:flutter`.
library;

import 'package:flutter_chartjs_port/src/canvas/canvas.dart'
    show CanvasRenderingContext2D;
import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show PointOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show DrawPointOptions, drawPoint, isPointInArea;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsSquare;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// element.point.ts:11 `inRange`, the hit test of [el] on one [axis].
///
/// [axis] is `'x'` or `'y'`. The value of the axis comes from
/// [Element.getProps] through `ToNumber`, as the upstream subtraction
/// applies it. Dart `null` for [pos] is JS `null`, which the subtraction
/// reads as 0.
bool _inRange(
  PointElement el,
  double? pos,
  String axis,
  bool? useFinalPosition,
) {
  final options = el.options;
  final value = jsToNumber(el.getProps([axis], useFinalPosition)[axis]);

  // `options.radius + options.hitRadius` is the JS `+`: a string option
  // joins (`'07' + 1` is `'071'`). The `<` applies `ToNumber` to the sum.
  return ((pos ?? 0) - value).abs() <
      jsToNumber(jsAdd(_radius(options), _hitRadius(options)));
}

/// The option `radius` of [options]: [PointOptions.radiusValue] for typed
/// options, else `jsGet(options, 'radius')` (Chart.js ADR 0018, section 4).
///
/// Both give JS `undefined` for an absent key. `jsGet` throws a [TypeError]
/// for Dart `null`, the `undefined` state of the options. The other option
/// functions of this file work in the same way.
Object? _radius(Object? options) =>
    options is PointOptions ? options.radiusValue : jsGet(options, 'radius');

/// The option `hitRadius` of [options], as [_radius] reads `radius`.
Object? _hitRadius(Object? options) => options is PointOptions
    ? options.hitRadiusValue
    : jsGet(options, 'hitRadius');

/// The option `hoverRadius` of [options], as [_radius] reads `radius`.
Object? _hoverRadius(Object? options) => options is PointOptions
    ? options.hoverRadiusValue
    : jsGet(options, 'hoverRadius');

/// The option `borderWidth` of [options], as [_radius] reads `radius`.
Object? _borderWidth(Object? options) => options is PointOptions
    ? options.borderWidthValue
    : jsGet(options, 'borderWidth');

/// The option `borderColor` of [options], as [_radius] reads `radius`.
Object? _borderColor(Object? options) => options is PointOptions
    ? options.borderColorValue
    : jsGet(options, 'borderColor');

/// The option `backgroundColor` of [options], as [_radius] reads `radius`.
Object? _backgroundColor(Object? options) => options is PointOptions
    ? options.backgroundColorValue
    : jsGet(options, 'backgroundColor');

/// element.point.ts:18 `PointProps = Point`, the animated properties of a
/// point element.
typedef PointProps = Point;

/// element.point.ts:20 `PointElement extends Element<PointProps,
/// PointOptions & PointHoverOptions>`.
///
/// The properties of element.point.ts:24-26 are [parsed], [skip] and [stop].
/// The class also declares five properties that upstream code adds to a
/// point element, because ported code reads them through a type (Chart.js
/// ADR 0017, section 3):
/// - [cp1x], [cp1y], [cp2x] and [cp2y], the control points that
///   `_updateBezierControlPoints` writes (helpers.curve.ts:105-111 through
///   `splineCurveMonotone`, :173-178 through `capBezierPoints`, and
///   :212-215). `types.PointElement` implements [SplinePoint], as
///   TypeScript accepts a point element by structure (`element.line.js:303`
///   passes the points).
/// - [angle], the angle that the radar controller assigns
///   (controller.radar.js:96). Thus a point element is a
///   [types.RadialPointElement], and `helpers.segment.js` reads its `angle`.
///
/// The other properties that a controller adds, for example `$context`, go
/// to the Map of extra properties of [Element].
///
/// The class implements `types.VisualElementRange`, because upstream has a
/// [getRange] (element.point.ts:102, Chart.js ADR 0020, section 9).
class PointElement extends Element
    implements types.RadialPointElement, types.VisualElementRange {
  /// element.point.ts:49 `constructor(cfg)`.
  ///
  /// element.point.ts:52-55 set `options`, `parsed`, `skip` and `stop` to
  /// `undefined`, which is their start state here. Then [cfg] goes through
  /// [assign], as `Object.assign(this, cfg)` (element.point.ts:57-59). A
  /// Map is always truthy, so Dart `null` stands for a falsy `cfg`.
  PointElement([AnyObject? cfg]) {
    if (cfg != null) assign(cfg);
  }

  /// element.point.ts:22 `static id = 'point'`.
  static const String id = 'point';

  /// element.point.ts:31 `static defaults`.
  static final AnyObject defaults = {
    'borderWidth': 1.0,
    'hitRadius': 1.0,
    'hoverBorderWidth': 1.0,
    'hoverRadius': 4.0,
    'pointStyle': 'circle',
    'radius': 3.0,
    'rotation': 0.0,
  };

  /// element.point.ts:44 `static defaultRoutes`.
  static final AnyObject defaultRoutes = {
    'backgroundColor': 'backgroundColor',
    'borderColor': 'borderColor',
  };

  /// element.point.ts:20 `class PointElement extends Element` as a value
  /// (Chart.js ADR 0020, section 3).
  ///
  /// Its statics are [id], [defaults] and [defaultRoutes], in the upstream
  /// order of declaration (element.point.ts:22-47). They are the objects of the
  /// static fields. Its `construct` calls `PointElement(cfg)` with the `cfg` of
  /// [elementCfgArg].
  static final JsClass jsClass = JsClass(
    'PointElement',
    superclass: Element.jsClass,
    statics: {'id': id, 'defaults': defaults, 'defaultRoutes': defaultRoutes},
    construct: (newTarget, args) => PointElement(elementCfgArg(args)),
  );

  /// The value of [parsed]. Dart `null` stands for JS `undefined`.
  Object? _parsed;

  /// The value of [skip]. Dart `null` stands for JS `undefined`.
  bool? _skip;

  /// The value of [stop]. Dart `null` stands for JS `undefined`.
  bool? _stop;

  /// The value of [cp1x]. Dart `null` stands for JS `undefined`.
  double? _cp1x;

  /// The value of [cp1y]. Dart `null` stands for JS `undefined`.
  double? _cp1y;

  /// The value of [cp2x]. Dart `null` stands for JS `undefined`.
  double? _cp2x;

  /// The value of [cp2y]. Dart `null` stands for JS `undefined`.
  double? _cp2y;

  /// The value of [angle]. Dart `null` stands for JS `undefined`.
  double? _angle;

  /// The [DrawPointOptions] of the last [draw] with plain Map options: an
  /// adapter over [options].
  ///
  /// [draw] runs for each point in each frame. Thus it keeps the adapter
  /// while [options] is the identical Map, and allocates a new adapter only
  /// when the Map changes. The adapter reads the Map at each call. Thus a
  /// change of the values in the same Map needs no new adapter. Typed
  /// options ([PointOptions]) need no adapter.
  _MapPointOptions? _drawPointOptions;

  /// element.point.ts:24 `parsed: CartesianParsedData`, the parsed data of
  /// the point. `controller.line.js:106` and `controller.scatter.js:135`
  /// assign it.
  ///
  /// Dart `null` stands for JS `undefined`, the start value. JS `null` never
  /// reaches it. No ported code reads it, so `CartesianParsedData` has no
  /// Dart type yet (Chart.js ADR 0003). The value is the parsed object that
  /// the dataset controller gives (phase 5).
  Object? get parsed => _parsed;

  set parsed(Object value) => _parsed = value;

  /// element.point.ts:25 `skip?: boolean`.
  ///
  /// Dart `null` stands for JS `undefined`, the start value. JS `null` never
  /// reaches it.
  @override
  bool? get skip => _skip;

  set skip(bool value) => _skip = value;

  /// element.point.ts:26 `stop?: boolean`.
  ///
  /// Dart `null` stands for JS `undefined`, the start value. JS `null` never
  /// reaches it.
  @override
  bool? get stop => _stop;

  set stop(bool value) => _stop = value;

  /// geometric.d.ts:48 `cp1x?: number` of [SplinePoint], which
  /// `_updateBezierControlPoints` writes (helpers.curve.ts:105-111, :173-178,
  /// :212-215).
  ///
  /// NaN in the `undefined` state, the start value, as [SplinePoint.cp1x]
  /// states. `this['cp1x']` gives [undefined] in that state.
  @override
  double get cp1x => _cp1x ?? double.nan;

  @override
  set cp1x(double value) => _cp1x = value;

  /// geometric.d.ts:49 `cp1y?: number` of [SplinePoint]. NaN in the
  /// `undefined` state, as [cp1x].
  @override
  double get cp1y => _cp1y ?? double.nan;

  @override
  set cp1y(double value) => _cp1y = value;

  /// geometric.d.ts:50 `cp2x?: number` of [SplinePoint]. NaN in the
  /// `undefined` state, as [cp1x].
  @override
  double get cp2x => _cp2x ?? double.nan;

  @override
  set cp2x(double value) => _cp2x = value;

  /// geometric.d.ts:51 `cp2y?: number` of [SplinePoint]. NaN in the
  /// `undefined` state, as [cp1x].
  @override
  double get cp2y => _cp2y ?? double.nan;

  @override
  set cp2y(double value) => _cp2y = value;

  /// controller.radar.js:96 `angle: pointPosition.angle`, the angle of a
  /// radar point ([types.RadialPointElement.angle]).
  ///
  /// Dart `null` stands for JS `undefined`, the value of a point that the
  /// radar controller does not update. JS `null` never reaches it.
  @override
  double? get angle => _angle;

  set angle(double value) => _angle = value;

  /// The JS property read `element[prop]` (Chart.js ADR 0017, section 5).
  ///
  /// It handles `parsed`, `skip`, `stop`, the control points and `angle`,
  /// and passes the other names to [Element]. A property in the `undefined`
  /// state gives the [undefined] sentinel.
  @override
  Object? operator [](String prop) => switch (prop) {
    'parsed' => _parsed ?? undefined,
    'skip' => _skip ?? undefined,
    'stop' => _stop ?? undefined,
    'cp1x' => _cp1x ?? undefined,
    'cp1y' => _cp1y ?? undefined,
    'cp2x' => _cp2x ?? undefined,
    'cp2y' => _cp2y ?? undefined,
    'angle' => _angle ?? undefined,
    _ => super[prop],
  };

  /// The JS property write `element[prop] = value` (Chart.js ADR 0017,
  /// section 5).
  ///
  /// - `parsed` accepts any object or [undefined].
  /// - `skip` and `stop` accept a `bool` or [undefined].
  /// - `cp1x`, `cp1y`, `cp2x`, `cp2y` and `angle` accept a `num` or
  ///   [undefined].
  /// - [Element] handles the other names.
  ///
  /// Throws an [ArgumentError] for a value outside the type of a declared
  /// property, also for Dart `null` (JS `null`).
  @override
  void operator []=(String prop, Object? value) {
    switch (prop) {
      case 'parsed':
        _parsed = toObjectProp<Object>(prop, value);
      case 'skip':
        _skip = toBoolProp(prop, value);
      case 'stop':
        _stop = toBoolProp(prop, value);
      case 'cp1x':
        _cp1x = toNumberProp(prop, value);
      case 'cp1y':
        _cp1y = toNumberProp(prop, value);
      case 'cp2x':
        _cp2x = toNumberProp(prop, value);
      case 'cp2y':
        _cp2y = toNumberProp(prop, value);
      case 'angle':
        _angle = toNumberProp(prop, value);
      default:
        super[prop] = value;
    }
  }

  /// element.point.ts:62 `inRange(mouseX, mouseY, useFinalPosition?)`.
  ///
  /// The test is strict: a mouse position at the distance `hitRadius +
  /// radius` is not in range. `Math.pow(v, 2)` is [jsSquare] (Chart.js ADR
  /// 0032). Throws a [TypeError] when [options] is in the `undefined` state,
  /// as the upstream property read of `undefined` does. Dart `null` for
  /// [mouseX] or [mouseY] is JS `null`, which the subtraction reads as 0.
  @override
  bool inRange(
    double? mouseX,
    double? mouseY, [
    bool? useFinalPosition,
  ]) {
    final options = this.options;
    final props = getProps(const ['x', 'y'], useFinalPosition);
    final x = jsToNumber(props['x']);
    final y = jsToNumber(props['y']);
    // `options.hitRadius + options.radius` is the JS `+`: a string option
    // joins (`1 + '07'` is `'107'`). `Math.pow` applies `ToNumber` to the
    // sum.
    return (jsSquare((mouseX ?? 0) - x) + jsSquare((mouseY ?? 0) - y)) <
        jsSquare(jsToNumber(jsAdd(_hitRadius(options), _radius(options))));
  }

  /// element.point.ts:68 `inXRange(mouseX, useFinalPosition?)`.
  @override
  bool inXRange(
    double? mouseX, [
    bool? useFinalPosition,
  ]) {
    return _inRange(this, mouseX, 'x', useFinalPosition);
  }

  /// element.point.ts:72 `inYRange(mouseY, useFinalPosition?)`.
  @override
  bool inYRange(
    double? mouseY, [
    bool? useFinalPosition,
  ]) {
    return _inRange(this, mouseY, 'y', useFinalPosition);
  }

  /// element.point.ts:76 `getCenterPoint(useFinalPosition?)`.
  ///
  /// The result stands for the literal `{x, y}` (Chart.js ADR 0017,
  /// section 9). A property in the `undefined` state gives NaN, the
  /// `ToNumber` of a copied `undefined`, as in [tooltipPosition].
  @override
  ElementPoint getCenterPoint([
    bool? useFinalPosition,
  ]) {
    final props = getProps(const ['x', 'y'], useFinalPosition);
    return ElementPoint(jsToNumber(props['x']), jsToNumber(props['y']));
  }

  /// element.point.ts:81 `size(options?)`, the diameter of the point with
  /// its hover radius and its border.
  ///
  /// Dart `null` for [options] stands for a falsy argument: `undefined` or
  /// no argument. A Map is always truthy. The option functions give JS
  /// `undefined` for an absent key, and [jsOrZero] applies the `|| 0` and
  /// the `ToNumber` of the arithmetic. `|| 0` gives 0 for JS `undefined` and
  /// for JS `null` (Chart.js ADR 0017, section 8). A string `borderWidth`
  /// joins in the JS `+` of element.point.ts:86.
  @override
  double size([AnyObject? options]) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    options = options ?? this.options ?? const <String, Object?>{};
    // `options.radius || 0` keeps the raw option value, and `radius &&`
    // tests it before the `ToNumber` of `Math.max`: a truthy value whose
    // number is 0, such as '0', still adds the hover radius.
    final rawRadius = _radius(options);
    final rawTruthy = jsTruthy(rawRadius);
    final radius = jsMax(
      rawTruthy ? jsToNumber(rawRadius) : 0,
      rawTruthy ? jsOrZero(_hoverRadius(options)) : 0,
    );
    // `radius && options.borderWidth || 0` keeps the raw option value, and
    // `(radius + borderWidth) * 2` is the JS `+` ([jsAdd]): a string
    // `borderWidth` joins (`3 + '1'` is `'31'`), and the `*` applies
    // `ToNumber`.
    final Object? borderWidth;
    if (jsTruthy(radius)) {
      final value = _borderWidth(options);
      borderWidth = jsTruthy(value) ? value : 0.0;
    } else {
      borderWidth = 0.0;
    }
    return jsToNumber(jsAdd(radius, borderWidth)) * 2;
  }

  /// element.point.ts:89 `draw(ctx, area)`.
  ///
  /// It draws nothing when [skip] is true, when the radius is below 0.1, or
  /// when the point is not inside [area] with a margin of half of its
  /// [size] (`isPointInArea`, strict comparisons). Dart `null` for [area]
  /// stands for no area, JS `undefined`: then the point is always in the
  /// area.
  ///
  /// The canvas setters get the option values through [canvasStyle] and
  /// [canvasNumber]: Dart `null` for an absent key, which the canvas
  /// ignores as the DOM ignores `undefined`, and the `ToNumber` of the DOM
  /// setter for `lineWidth`. `drawPoint` gets [options] itself when it is a
  /// [PointOptions] (Chart.js ADR 0018, section 4), else the adapter
  /// [_MapPointOptions] over [options] (Chart.js ADR 0017, section 8).
  ///
  /// Throws a [TypeError] when [skip] is not true and [options] is in the
  /// `undefined` state, as the upstream property read of `undefined` does.
  @override
  void draw(CanvasRenderingContext2D ctx, [ChartArea? area]) {
    final options = this.options;

    if (skip == true ||
        jsToNumber(_radius(options)) < 0.1 ||
        !isPointInArea(this, area, size(options) / 2)) {
      return;
    }

    // _radius threw a TypeError above when options is null.
    final opts = options!;
    ctx
      ..strokeStyle = canvasStyle(_borderColor(opts))
      ..lineWidth = canvasNumber(_borderWidth(opts))
      ..fillStyle = canvasStyle(_backgroundColor(opts));
    drawPoint(ctx, _drawPointOptionsOf(opts), x, y);
  }

  /// element.point.ts:102 `getRange()`.
  ///
  /// Upstream takes no argument. `core.interaction.js:54` calls it with the
  /// axis. [axis] has no effect, as JavaScript ignores an extra argument
  /// (Chart.js ADR 0017, section 1).
  ///
  /// The result is the JS `+` of the two options ([jsAdd]): a `double`, or a
  /// `String` when an option is a string (`'07' + 1` is `'071'`).
  @override
  Object getRange([String? axis]) {
    final options = this.options ?? const <String, Object?>{};
    // @ts-expect-error Fallbacks should never be hit in practice
    return jsAdd(_radius(options), _hitRadius(options));
  }

  /// The [DrawPointOptions] of [options]: [options] itself for a
  /// [PointOptions]. For a plain Map, the adapter of the last [draw] when
  /// its Map is [options], else a new adapter that [draw] keeps.
  DrawPointOptions _drawPointOptionsOf(AnyObject options) {
    if (options is PointOptions) return options;
    final cached = _drawPointOptions;
    if (cached != null && identical(cached.options, options)) return cached;
    return _drawPointOptions = _MapPointOptions(options);
  }
}

/// The options object of element.point.ts:99 `drawPoint(ctx, options, …)` as
/// a [DrawPointOptions], for plain Map options (Chart.js ADR 0017, section
/// 8). [PointOptions] implements [DrawPointOptions] with the same results.
///
/// Each member reads [options] at the call, as upstream reads the object.
/// The reads are typed Map reads, because they give the upstream result
/// also for an absent key. An absent key reads as Dart `null`, whose
/// `ToNumber` is 0, where upstream reads `undefined`, whose `ToNumber` is
/// NaN. `drawPointLegend` treats 0 and NaN alike for these three numbers:
/// `rotation || 0` (helpers.canvas.ts:178) and `!rotation` (:238),
/// `isNaN(radius) || radius <= 0` (:192), and `borderWidth > 0` (:305).
final class _MapPointOptions implements DrawPointOptions {
  _MapPointOptions(this.options);

  /// The options Map of the point.
  final AnyObject options;

  /// helpers.canvas.ts:150 `pointStyle`, the value as it is.
  @override
  Object? get pointStyle => options['pointStyle'];

  /// helpers.canvas.ts:151 `rotation`, in degrees: its `ToNumber`.
  @override
  double get rotation => jsToNumber(options['rotation']);

  /// helpers.canvas.ts:152 `radius`: its `ToNumber`.
  @override
  double get radius => jsToNumber(options['radius']);

  /// helpers.canvas.ts:153 `borderWidth`: its `ToNumber`.
  @override
  double get borderWidth => jsToNumber(options['borderWidth']);
}
