// Ported from Chart.js v4.6.1 src/elements/element.point.ts (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-elements, typed elements of Chart.js ADR 0054.

/// Port of `src/elements/element.point.ts`.
///
/// [PointElement] follows the element design of Chart.js ADR 0017 with the
/// storage of Chart.js ADR 0054 §9: typed properties with the `undefined`
/// state, the access by name of `operator []` and `operator []=`, and the
/// options as a Map.
///
/// The options are the resolved options of the point: a [PointOptions], or
/// a plain Map of user code or of a spec. The methods read a [PointOptions]
/// through its typed fields with the presence bit and the foreign slot
/// (`numberOption`, `rawOption` and `plainOption` of `element_options.dart`,
/// Chart.js ADR 0054 §6), and a plain Map by name (`_byName`). Both give the
/// upstream value:
/// - A numeric option in arithmetic or in a comparison is its `ToNumber`
///   ([_number]): an absent key (JS `undefined`) gives NaN and JS `null`
///   gives 0. The read also throws the `TypeError` of a property read of
///   `undefined` options.
/// - The JS `+` of two options ([_sum]) adds two numbers and joins a string.
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
    show PointOptions, numberOption, plainOption, rawOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show DrawPointOptions, drawPoint, isPointInArea;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show ScriptableContext;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsSquare;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/js/js_webidl.dart';
import 'package:flutter_chartjs_port/src/options/animated_prop.dart'
    show AnimatedProp;
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/options/props.dart'
    show PointProperties;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show PointOptionsScope;
import 'package:flutter_chartjs_port/src/options/typed_record.dart'
    show TypedRecord;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// element.point.ts:11 `inRange`, the hit test of [el] on one [axis].
///
/// [axis] is `'x'` or `'y'`. The value of the axis comes from the typed form
/// of [Element.getProps] ([Element.finalNumber]), the `ToNumber` that the
/// upstream subtraction applies. Dart `null` for [pos] is JS `null`, which
/// the subtraction reads as 0.
bool _inRange(
  PointElement el,
  double? pos,
  String axis,
  bool? useFinalPosition,
) {
  final options = el.options;
  // `getProps([axis], useFinalPosition)[axis]` in the typed form.
  final value = axis == 'x'
      ? el.finalNumber(AnimatedProp.x, el.x, useFinalPosition)
      : el.finalNumber(AnimatedProp.y, el.y, useFinalPosition);

  // `options.radius + options.hitRadius` is the JS `+`: a string option
  // joins (`'07' + 1` is `'071'`). The `<` applies `ToNumber` to the sum.
  return ((pos ?? 0) - value).abs() <
      _sum(options, OptionKey.radius, OptionKey.hitRadius);
}

/// `options[key]` of options that are not a [PointOptions]: the read by
/// name of a plain object of user code or of a spec (the face, Chart.js ADR
/// 0054 §5). It gives JS `undefined` for an absent key, and throws a
/// [TypeError] for Dart `null`, the `undefined` state of the options.
Object? _byName(Object? options, OptionKey key) => jsGet(options, key.jsName);

/// The typed `double` field of the numeric option [key] of [options]:
/// `radius`, `hitRadius`, `hoverRadius` or `borderWidth`.
double _numberField(PointOptions options, OptionKey key) => switch (key) {
  OptionKey.radius => options.radius,
  OptionKey.hitRadius => options.hitRadius,
  OptionKey.hoverRadius => options.hoverRadius,
  _ => options.borderWidth,
};

/// `options[key]`, the raw JS value of the numeric option [key]: JS
/// `undefined` for an absent key, a foreign value as it is.
Object? _raw(Object? options, OptionKey key) => options is PointOptions
    ? rawOption(options, key, _numberField(options, key))
    : _byName(options, key);

/// `ToNumber(options[key])` of the numeric option [key]: NaN for an absent
/// key.
double _number(Object? options, OptionKey key) => options is PointOptions
    ? numberOption(options, key, _numberField(options, key))
    : jsToNumber(_byName(options, key));

/// `ToNumber(options[a] + options[b])` with the JS `+` ([jsAdd]): two
/// numbers add, and a string option joins (`'07' + 1` is `'071'`). Two
/// typed fields with their values add with no box.
double _sum(Object? options, OptionKey a, OptionKey b) {
  if (options is PointOptions &&
      plainOption(options, a) &&
      plainOption(options, b)) {
    return _numberField(options, a) + _numberField(options, b);
  }
  return jsToNumber(jsAdd(_raw(options, a), _raw(options, b)));
}

/// The truthiness of a number with no foreign value: not 0 and not NaN.
bool _truthy(double value) => value != 0 && !value.isNaN;

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
/// [getRange] (element.point.ts:102, Chart.js ADR 0020, section 9). It
/// implements `types.PointElementWrites`, the typed writes of the line and
/// scatter controllers (Chart.js ADR 0054 §9).
class PointElement extends Element
    implements
        types.RadialPointElement,
        types.VisualElementRange,
        types.PointElementWrites {
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

  /// element.point.ts:31 `static defaults`, a typed scope of the kind
  /// `PointOptions` (Chart.js ADR 0054 §3).
  static final PointOptionsScope defaults = PointOptionsScope()
    ..borderWidth = 1.0
    ..hitRadius = 1.0
    ..hoverBorderWidth = 1.0
    ..hoverRadius = 4.0
    ..pointStyle = 'circle'
    ..radius = 3.0
    ..rotation = 0.0;

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

  /// The bit of [cp1x] in [_undefinedBits].
  static const int _cp1xBit = 1;

  /// The bit of [cp1y] in [_undefinedBits].
  static const int _cp1yBit = 2;

  /// The bit of [cp2x] in [_undefinedBits].
  static const int _cp2xBit = 4;

  /// The bit of [cp2y] in [_undefinedBits].
  static const int _cp2yBit = 8;

  /// The bit of [angle] in [_undefinedBits].
  static const int _angleBit = 16;

  /// The value of [cp1x]: NaN in the `undefined` state.
  double _cp1x = double.nan;

  /// The value of [cp1y]: NaN in the `undefined` state.
  double _cp1y = double.nan;

  /// The value of [cp2x]: NaN in the `undefined` state.
  double _cp2x = double.nan;

  /// The value of [cp2y]: NaN in the `undefined` state.
  double _cp2y = double.nan;

  /// The value of [angle]: NaN in the `undefined` state.
  double _angle = double.nan;

  /// The bits of the numeric properties of the class in the `undefined`
  /// state (Chart.js ADR 0054 §9). All start set.
  int _undefinedBits = _cp1xBit | _cp1yBit | _cp2xBit | _cp2yBit | _angleBit;

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
  @override
  Object? get parsed => _parsed;

  @override
  set parsed(Object value) => _parsed = value;

  /// element.point.ts:25 `skip?: boolean`.
  ///
  /// Dart `null` stands for JS `undefined`, the start value. JS `null` never
  /// reaches it.
  @override
  bool? get skip => _skip;

  @override
  set skip(bool value) => _skip = value;

  /// element.point.ts:26 `stop?: boolean`.
  ///
  /// Dart `null` stands for JS `undefined`, the start value. JS `null` never
  /// reaches it.
  @override
  bool? get stop => _stop;

  @override
  set stop(bool value) => _stop = value;

  /// geometric.d.ts:48 `cp1x?: number` of [SplinePoint], which
  /// `_updateBezierControlPoints` writes (helpers.curve.ts:105-111, :173-178,
  /// :212-215).
  ///
  /// NaN in the `undefined` state, the start value, as [SplinePoint.cp1x]
  /// states. `this['cp1x']` gives [undefined] in that state.
  @override
  double get cp1x => _cp1x;

  @override
  set cp1x(double value) {
    _cp1x = value;
    _undefinedBits &= ~_cp1xBit;
  }

  /// geometric.d.ts:49 `cp1y?: number` of [SplinePoint]. NaN in the
  /// `undefined` state, as [cp1x].
  @override
  double get cp1y => _cp1y;

  @override
  set cp1y(double value) {
    _cp1y = value;
    _undefinedBits &= ~_cp1yBit;
  }

  /// geometric.d.ts:50 `cp2x?: number` of [SplinePoint]. NaN in the
  /// `undefined` state, as [cp1x].
  @override
  double get cp2x => _cp2x;

  @override
  set cp2x(double value) {
    _cp2x = value;
    _undefinedBits &= ~_cp2xBit;
  }

  /// geometric.d.ts:51 `cp2y?: number` of [SplinePoint]. NaN in the
  /// `undefined` state, as [cp1x].
  @override
  double get cp2y => _cp2y;

  @override
  set cp2y(double value) {
    _cp2y = value;
    _undefinedBits &= ~_cp2yBit;
  }

  /// controller.radar.js:96 `angle: pointPosition.angle`, the angle of a
  /// radar point ([types.RadialPointElement.angle]).
  ///
  /// Dart `null` stands for JS `undefined`, the value of a point that the
  /// radar controller does not update. JS `null` never reaches it.
  @override
  double? get angle => _undefinedBits & _angleBit != 0 ? null : _angle;

  set angle(double value) {
    _angle = value;
    _undefinedBits &= ~_angleBit;
  }

  /// The read by name ([operator []]) of a numeric property with the bit
  /// [bit] and the field value [value]: [undefined] while the bit is set,
  /// else [value].
  Object? _numberOf(int bit, double value) =>
      _undefinedBits & bit != 0 ? undefined : value;

  /// The write by name ([operator []=]) of [value] into the numeric
  /// property [prop] with the bit [bit]: sets or clears the bit, and gives
  /// the new field value, which the caller stores. [toNumberProp] converts
  /// [value] and throws its [ArgumentError].
  double _byNameNumber(int bit, String prop, Object? value) {
    final number = toNumberProp(prop, value);
    if (number == null) {
      _undefinedBits |= bit;
      return double.nan;
    }
    _undefinedBits &= ~bit;
    return number;
  }

  /// core.datasetController.js:767-768 `element.$context`, the data context
  /// of the element: [Element.$context] narrowed to a [ScriptableContext]
  /// (Chart.js ADR 0054 §9). Another value gives Dart `null`.
  @override
  ScriptableContext? get $context => switch (super.$context) {
    final ScriptableContext context => context,
    _ => null,
  };

  @override
  set $context(covariant ScriptableContext? value) => super.$context = value;

  /// Whether the element is of the class [PointElement] itself, not of a user
  /// subclass: the typed writes are for this class only (Chart.js ADR 0054
  /// §9).
  // The `Type` objects of dart2wasm are not canonical: `identical` of two
  // `Type` objects of one class can be false there, so the test is `==`.
  late final bool _builtIn = runtimeType == PointElement;

  /// [Element.typedWrites]: true for the class [PointElement] itself.
  @internal
  @override
  bool get typedWrites => _builtIn;

  /// [Element.takesProperties]: a [PointProperties], for an element of the
  /// class [PointElement] itself.
  @internal
  @override
  bool takesProperties(TypedRecord props) =>
      props is PointProperties && _builtIn;

  /// [Element.writePropertyAt] for a [PointProperties] (the literals of
  /// controller.line.js:91-111, controller.scatter.js:127-140,
  /// controller.bubble.js:128-138 and controller.radar.js:93-99; `raw` is
  /// an extra property of the element): the typed setter of the
  /// key at [position]. An extra key, a foreign value
  /// and a value that the setter does not take (JS `null` or `undefined`)
  /// go by name ([assignKey]).
  @internal
  @override
  void writePropertyAt(TypedRecord props, int position) {
    final values = props as PointProperties;
    final slot = values.slotAt(position);
    if (slot < 0 || values.isForeignSlot(slot)) {
      // An extra key, or a value outside the type of the field.
      assignKey(values, position);
      return;
    }
    switch (slot) {
      case 0:
        x = values.x;
      case 1:
        y = values.y;
      case 2:
        skip = values.skip;
      case 3:
        stop = values.stop;
      case 4:
        final value = values.parsed;
        if (value == null || value is Undefined) {
          assignKey(values, position);
        } else {
          parsed = value;
        }
      case 6:
        final value = values.options;
        if (value == null) {
          assignKey(values, position);
        } else {
          options = value;
        }
      case 7:
        angle = values.angle;
      default:
        assignKey(values, position);
    }
  }

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
    'cp1x' => _numberOf(_cp1xBit, _cp1x),
    'cp1y' => _numberOf(_cp1yBit, _cp1y),
    'cp2x' => _numberOf(_cp2xBit, _cp2x),
    'cp2y' => _numberOf(_cp2yBit, _cp2y),
    'angle' => _numberOf(_angleBit, _angle),
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
        _cp1x = _byNameNumber(_cp1xBit, prop, value);
      case 'cp1y':
        _cp1y = _byNameNumber(_cp1yBit, prop, value);
      case 'cp2x':
        _cp2x = _byNameNumber(_cp2xBit, prop, value);
      case 'cp2y':
        _cp2y = _byNameNumber(_cp2yBit, prop, value);
      case 'angle':
        _angle = _byNameNumber(_angleBit, prop, value);
      default:
        super[prop] = value;
    }
  }

  /// element.point.ts:62 `inRange(mouseX, mouseY, useFinalPosition?)`.
  ///
  /// The test is strict: a mouse position at the distance `hitRadius +
  /// radius` is not in range. `Math.pow(v, 2)` is [jsSquare] (Chart.js ADR
  /// 0045). Throws a [TypeError] when [options] is in the `undefined` state,
  /// as the upstream property read of `undefined` does. Dart `null` for
  /// [mouseX] or [mouseY] is JS `null`, which the subtraction reads as 0.
  @override
  bool inRange(
    double? mouseX,
    double? mouseY, [
    bool? useFinalPosition,
  ]) {
    final options = this.options;
    // `getProps(['x', 'y'], useFinalPosition)` in the typed form.
    final x = finalNumber(AnimatedProp.x, this.x, useFinalPosition);
    final y = finalNumber(AnimatedProp.y, this.y, useFinalPosition);
    // `options.hitRadius + options.radius` is the JS `+`: a string option
    // joins (`1 + '07'` is `'107'`). `Math.pow` applies `ToNumber` to the
    // sum.
    return (jsSquare((mouseX ?? 0) - x) + jsSquare((mouseY ?? 0) - y)) <
        jsSquare(_sum(options, OptionKey.hitRadius, OptionKey.radius));
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
    // `getProps(['x', 'y'], useFinalPosition)` in the typed form.
    return ElementPoint(
      finalNumber(AnimatedProp.x, x, useFinalPosition),
      finalNumber(AnimatedProp.y, y, useFinalPosition),
    );
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
    if (options is PointOptions &&
        plainOption(options, OptionKey.radius) &&
        plainOption(options, OptionKey.hoverRadius) &&
        plainOption(options, OptionKey.borderWidth)) {
      // The typed fields hold the raw numbers: the `||` and `&&` of
      // upstream on numbers, with no box.
      final value = options.radius;
      final r = _truthy(value) ? value : 0.0;
      final hoverRadius = options.hoverRadius;
      final radius = jsMax(
        r,
        _truthy(r) && _truthy(hoverRadius) ? hoverRadius : 0,
      );
      final width = options.borderWidth;
      final borderWidth = _truthy(radius) && _truthy(width) ? width : 0.0;
      return (radius + borderWidth) * 2;
    }
    // `options.radius || 0` keeps the raw option value, and `radius &&`
    // tests it before the `ToNumber` of `Math.max`: a truthy value whose
    // number is 0, such as '0', still adds the hover radius.
    final rawRadius = _raw(options, OptionKey.radius);
    final rawTruthy = jsTruthy(rawRadius);
    final radius = jsMax(
      rawTruthy ? jsToNumber(rawRadius) : 0,
      rawTruthy ? jsOrZero(_raw(options, OptionKey.hoverRadius)) : 0,
    );
    // `radius && options.borderWidth || 0` keeps the raw option value, and
    // `(radius + borderWidth) * 2` is the JS `+` ([jsAdd]): a string
    // `borderWidth` joins (`3 + '1'` is `'31'`), and the `*` applies
    // `ToNumber`.
    final Object? borderWidth;
    if (jsTruthy(radius)) {
      final value = _raw(options, OptionKey.borderWidth);
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
        _number(options, OptionKey.radius) < 0.1 ||
        !isPointInArea(this, area, size(options) / 2)) {
      return;
    }

    // _number threw a TypeError above when options is null.
    final opts = options!;
    if (opts is PointOptions) {
      // A color field holds the raw value: Dart `null` for an absent key,
      // which the canvas ignores as it ignores `undefined`.
      ctx
        ..strokeStyle = canvasStyle(opts.borderColor)
        ..lineWidth = plainOption(opts, OptionKey.borderWidth)
            ? opts.borderWidth
            : canvasNumber(_raw(opts, OptionKey.borderWidth))
        ..fillStyle = canvasStyle(opts.backgroundColor);
    } else {
      ctx
        ..strokeStyle = canvasStyle(_byName(opts, OptionKey.borderColor))
        ..lineWidth = canvasNumber(_byName(opts, OptionKey.borderWidth))
        ..fillStyle = canvasStyle(_byName(opts, OptionKey.backgroundColor));
    }
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
    if (options is PointOptions &&
        plainOption(options, OptionKey.radius) &&
        plainOption(options, OptionKey.hitRadius)) {
      return options.radius + options.hitRadius;
    }
    // @ts-expect-error Fallbacks should never be hit in practice
    return jsAdd(
      _raw(options, OptionKey.radius),
      _raw(options, OptionKey.hitRadius),
    );
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
/// Each member reads [options] by name at the call ([_byName]), as upstream
/// reads the object. An absent key reads as `undefined`, whose `ToNumber`
/// is NaN. `drawPointLegend` treats 0 and NaN alike for these three
/// numbers: `rotation || 0` (helpers.canvas.ts:178) and `!rotation` (:238),
/// `isNaN(radius) || radius <= 0` (:192), and `borderWidth > 0` (:305).
final class _MapPointOptions implements DrawPointOptions {
  _MapPointOptions(this.options);

  /// The options Map of the point.
  final AnyObject options;

  /// helpers.canvas.ts:150 `pointStyle`, the value as it is.
  @override
  Object? get pointStyle => _byName(options, OptionKey.pointStyle);

  /// helpers.canvas.ts:151 `rotation`, in degrees: its `ToNumber`.
  @override
  double get rotation => jsToNumber(_byName(options, OptionKey.rotation));

  /// helpers.canvas.ts:152 `radius`: its `ToNumber`.
  @override
  double get radius => jsToNumber(_byName(options, OptionKey.radius));

  /// helpers.canvas.ts:153 `borderWidth`: its `ToNumber`.
  @override
  double get borderWidth => jsToNumber(_byName(options, OptionKey.borderWidth));
}
