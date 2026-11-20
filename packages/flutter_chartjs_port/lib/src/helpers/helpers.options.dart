// Ported from Chart.js v4.6.1 src/helpers/helpers.options.ts (MIT, Chart.js Contributors).

/// Port of `src/helpers/helpers.options.ts`.
///
/// @alias Chart.helpers.options
/// @namespace
///
/// The JavaScript values map to Dart values as Chart.js ADR 0043 decides: a
/// plain object is a `Map<String, Object?>` ([AnyObject]), an array is a
/// [List], `undefined` is the [undefined] sentinel and `null` is Dart `null`.
/// An option value is an `Object?`, also for the unions of the parameters
/// (see the library documentation of `lib/src/types/geometric.dart`).
///
/// The results of [toTRBL], [toTRBLCorners] and [toPadding] are typed
/// objects (differences.md row `adapt-options-typed-results`). [toFont]
/// gives a [ChartTextStyle] (Chart.js ADR 0116, row
/// `adapt-text-style-fonts`). A context of `createContext` is a
/// [ContextObject] of the typed class of its `type` (Chart.js ADR 0054 §11,
/// differences.md row `adapt-typed-contexts`).
library;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/chartjs_core.dart';

/// helpers.options.ts:43 `numberOrZero`: `+v || 0`.
double _numberOrZero(Object? v) {
  final number = jsToNumber(v);
  return number != 0 && !number.isNaN ? number : 0;
}

/// helpers.options.ts:51 `_readValueToProps`.
///
/// @param value
/// @param props
///
/// [props] is a `List<String>` of keys, or a `Map<String, Object?>` from
/// each key to the shorthand key that gives its fallback value. The result
/// has the keys in that order, and a finite or infinite number for each
/// key: never NaN and never -0.
Map<String, double> readValueToProps(Object? value, Object props) {
  final ret = <String, double>{};
  final objProps = isObject(props);
  final keys = objProps
      ? jsObjectKeys(props as AnyObject)
      : props as List<String>;
  // The type gives the three closures their parameter type.
  // ignore: omit_local_variable_types
  final Object? Function(String prop) read = isObject(value)
      ? objProps
            ? (prop) => valueOrDefault(
                jsGet(value, prop),
                jsGet(value, (props as AnyObject)[prop]),
              )
            : (prop) => jsGet(value, prop)
      : (_) => value;

  for (final prop in keys) {
    ret[prop] = _numberOrZero(read(prop));
  }
  return ret;
}

/// The object of `_readValueToProps` (helpers.options.ts:52-65) that
/// [toTRBL] returns, with the `width` and `height` that [toPadding] adds
/// (:101-102).
///
/// Upstream returns a plain object, and `toPadding` casts it to a
/// `ChartArea` and assigns two more properties. Thus this object implements
/// [ChartArea], and [width] and [height] are `late`: a read before
/// `toPadding` sets them throws, where JavaScript gives `undefined`.
// DIVERGES(chartjs): adapt-options-typed-results, the TRBL object.
final class _TRBLObject implements ChartArea {
  new(Map<String, double> props)
    : top = props['top']!,
      right = props['right']!,
      bottom = props['bottom']!,
      left = props['left']!;

  /// The object for a [value] that is not an object: the same number for
  /// each key (see [toTRBL]).
  new all(double value)
    : top = value,
      right = value,
      bottom = value,
      left = value;

  @override
  final double top;

  @override
  final double right;

  @override
  final double bottom;

  @override
  final double left;

  @override
  late double width;

  @override
  late double height;
}

/// helpers.options.ts:75 `toTRBL`.
///
/// Converts the given value into a TRBL object.
/// @param value - If a number, set the value to all TRBL component,
///  else, if an object, use defined properties and sets undefined ones to 0.
///  x / y are shorthands for same value for left/right and top/bottom.
/// @returns The padding values (top, right, bottom, left)
/// @since 3.0.0
///
/// [value] is a `number | TRBL | Point` upstream: an option value here (see
/// the library documentation of `lib/src/types/geometric.dart`).
TRBL toTRBL(Object? value) {
  // Port-only fast path. For a value that is not an object, each key gets
  // the same number (helpers.options.ts:55-63), so the object needs no Map
  // of the keys. The bar element calls this function for each bar in each
  // frame (performance.md section 8).
  if (!isObject(value)) return _TRBLObject.all(_numberOrZero(value));
  return _TRBLObject(
    readValueToProps(value, const <String, Object?>{
      'top': 'y',
      'right': 'x',
      'bottom': 'y',
      'left': 'x',
    }),
  );
}

/// The object of `_readValueToProps` (helpers.options.ts:52-65) that
/// [toTRBLCorners] returns.
// DIVERGES(chartjs): adapt-options-typed-results, the corners object.
final class _TRBLCornersObject implements TRBLCorners {
  new(Map<String, double> props)
    : topLeft = props['topLeft']!,
      topRight = props['topRight']!,
      bottomLeft = props['bottomLeft']!,
      bottomRight = props['bottomRight']!;

  /// The object for a [value] that is not an object: the same number for
  /// each corner (see [toTRBLCorners]).
  new all(double value)
    : topLeft = value,
      topRight = value,
      bottomLeft = value,
      bottomRight = value;

  @override
  final double topLeft;

  @override
  final double topRight;

  @override
  final double bottomLeft;

  @override
  final double bottomRight;
}

/// helpers.options.ts:86 `toTRBLCorners`.
///
/// Converts the given value into a TRBL corners object (similar with css
/// border-radius).
/// @param value - If a number, set the value to all TRBL corner components,
///  else, if an object, use defined properties and sets undefined ones to 0.
/// @returns The TRBL corner values (topLeft, topRight, bottomLeft,
/// bottomRight)
/// @since 3.0.0
///
/// [value] is a `number | TRBLCorners` upstream: an option value here.
TRBLCorners toTRBLCorners(Object? value) {
  // Port-only fast path, as in [toTRBL]: a value that is not an object gives
  // the same number for each corner (helpers.options.ts:55-63). The bar and
  // arc elements call this function in each draw.
  if (!isObject(value)) return _TRBLCornersObject.all(_numberOrZero(value));
  return _TRBLCornersObject(
    readValueToProps(value, const [
      'topLeft',
      'topRight',
      'bottomLeft',
      'bottomRight',
    ]),
  );
}

/// helpers.options.ts:98 `toPadding`.
///
/// Converts the given value into a padding object with pre-computed
/// width/height.
/// @param value - If a number, set the value to all TRBL component,
///  else, if an object, use defined properties and sets undefined ones to 0.
///  x / y are shorthands for same value for left/right and top/bottom.
/// @returns The padding values (top, right, bottom, left, width, height)
/// @since 2.7.0
///
/// [value] is a `number | TRBL` upstream: an option value here. A call
/// without an argument passes [undefined].
ChartArea toPadding([Object? value = undefined]) {
  // Upstream casts the object to a ChartArea. Dart casts it to the class
  // that has the setters.
  final obj = toTRBL(value) as _TRBLObject;

  obj
    ..width = obj.left + obj.right
    ..height = obj.top + obj.bottom;

  return obj;
}

/// helpers.options.ts:115 `toFont`.
///
/// Parses font options and returns the font object.
/// @param options - A object that contains font options to be parsed.
/// @param fallback - A object that contains fallback font options.
/// @return The font object.
/// @private
///
/// The font is a [ChartTextStyle] (Chart.js ADR 0116, row
/// `adapt-text-style-fonts`). [options] merges over [fallback], else over
/// `defaults.font`, with [TextStyle.merge]: a field of [options] wins, and a
/// null field takes the field of the fallback, as `valueOrDefault` takes each
/// key upstream. The line height in pixels is [ChartTextStyle.lineHeight] of
/// the result. A value that is not a `TextStyle` is no font: the result is
/// the fallback. A font object of Chart.js stops a debug build. The style
/// check, its warning, the `parseInt` of a size text and `toLineHeight` are
/// gone: a `TextStyle` has no text form of them.
// DIVERGES(chartjs): adapt-text-style-fonts, the font is a ChartTextStyle.
ChartTextStyle toFont(Object? options, [Object? fallback]) {
  // A font object, also behind a resolver (a font function that returns a
  // Map), is no font.
  assert(
    options is! Map &&
        options is! JsObjectFace &&
        fallback is! Map &&
        fallback is! JsObjectFace,
    'A font is a ChartTextStyle, not a font object.',
  );
  final TextStyle base;
  if (fallback is TextStyle) {
    base = fallback;
  } else {
    final font = readOption(defaults, OptionKey.font);
    base = font is TextStyle ? font : const ChartTextStyle();
  }
  final merged = options is TextStyle ? base.merge(options) : base;
  return merged is ChartTextStyle ? merged : ChartTextStyle.from(merged);
}

/// The element `array[index]` of a JavaScript array for a number [index]:
/// the element at an integer index from 0 to `length - 1`, else
/// [undefined]. A fractional, negative or NaN index names a property that
/// the array does not have.
Object? _arrayElement(List<Object?> array, int index) =>
    index >= 0 && index < array.length ? array[index] : undefined;

/// helpers.options.ts:154 `resolve`.
///
/// Evaluates the given `inputs` sequentially and returns the first defined
/// value.
/// @param inputs - An array of values, falling back to the last value.
/// @param context - If defined and the current value is a function, the
/// value is called with `context` as first argument and the result becomes
/// the new input.
/// @param index - If defined and the current value is an array, the value
/// at `index` become the new input.
/// @param info - object to return information about resolution in
/// @param info.cacheable - Will be set to `false` if option is not
/// cacheable.
/// @since 2.7.0
///
/// [context] is [undefined] when the caller does not give it. Dart `null`
/// is JS `null`, a defined context. Dart `null` stands for an [index] that
/// is `undefined` (Chart.js ADR 0043): JS `null` never reaches it. [info]
/// is the plain object `{cacheable: boolean}`, and Dart `null` stands for
/// `undefined`. [callScriptable] calls a function value. The result is
/// [undefined] when no input gives a defined value.
Object? resolve(
  List<Object?> inputs, [
  Object? context = undefined,
  int? index,
  AnyObject? info,
]) {
  var cacheable = true;
  Object? value;

  for (var i = 0, ilen = inputs.length; i < ilen; ++i) {
    value = inputs[i];
    if (identical(value, undefined)) {
      continue;
    }
    if (!identical(context, undefined) && value is Function) {
      value = callScriptable(value, context);
      cacheable = false;
    }
    if (index != null && isArray(value)) {
      final array = value! as List<Object?>;
      // `index % 0` is NaN, an index with no element.
      value = array.isEmpty
          ? undefined
          : _arrayElement(array, index.remainder(array.length));
      cacheable = false;
    }
    if (!identical(value, undefined)) {
      if (info != null && !cacheable) {
        info['cacheable'] = false;
      }
      return value;
    }
  }
  return undefined;
}

/// helpers.options.ts:186 `_addGrace`.
///
/// @param minmax
/// @param grace
/// @param beginAtZero
/// @private
///
/// [minmax] is the inline type `{ min: number; max: number; }`, which this
/// function only reads. Thus it is a record. `core.scale.js:429` passes the
/// scale itself: its Dart caller passes `(min: min, max: max)`. The result
/// is the object `{min, max}`, also a record.
///
/// [grace] is a [GraceLength] (row `adapt-length-objects`): it computes its
/// amount, with no text parse.
// DIVERGES(chartjs): adapt-length-objects, the grace computes itself.
({double min, double max}) addGrace(
  ({double min, double max}) minmax,
  GraceLength grace,
  bool beginAtZero,
) {
  final (:min, :max) = minmax;
  final change = grace.amountOf((max - min) / 2);
  double keepZero(double value, double add) =>
      beginAtZero && value == 0 ? 0 : value + add;
  return (min: keepZero(min, -change.abs()), max: keepZero(max, change));
}

/// helpers.options.ts:205 the object `Object.create(parentContext)` of
/// `createContext`: a context object with a parent context.
///
/// Each context is the typed class of its `type` (Chart.js ADR 0054 §11):
/// [ScriptableChartContext], [ScriptableContext], [ScriptableScaleContext],
/// [ScriptableScalePointLabelContext], [ScriptableTooltipContext] and
/// [ScriptableLineSegmentContext]. Each member of the `index.d.ts` context of
/// the type is a typed field. A member that upstream reads through the
/// prototype chain (`chart`, `dataset`, `datasetIndex`, `scale`) is a getter
/// that reads the [parent]. A context has no access by name: an absent member
/// is Dart `null` (differences.md row `adapt-typed-contexts`).
///
/// A scriptable option takes the context class of its option as the type of
/// its parameter, for example `(ScriptableContext context) => ...` for a
/// dataset option. [callScriptable] calls it with the context.
// DIVERGES(chartjs): adapt-typed-contexts, typed fields, no access by name.
sealed class ContextObject(
  /// `Object.getPrototypeOf(this)`: the parent context, or Dart `null` for
  /// the chart context.
  final ContextObject? parent,
) {
  /// A context with the parent context [parent]: `Object.create(parent)`.
  this;

  /// `type`: `'chart'`, `'dataset'`, `'data'`, `'scale'`, `'tick'`,
  /// `'pointLabel'`, `'tooltip'` or `'segment'`.
  String get type;

  /// `chart`: the chart of the chart context at the start of the chain of
  /// parents. A context with no chart context in its chain throws.
  IChart get chart => parent!.chart;

  /// Calls the scriptable option [function] with this context, and with
  /// [options] when it takes two parameters. The type of the parameter of
  /// [function] must accept the class of this context.
  Object? callWith(Object? function, Object? options);
}

/// Throws for a scriptable option that is not a function of this context.
Object? _notScriptable(Object? function, ContextObject context) {
  assert(
    false,
    'A scriptable option of a ${context.runtimeType} takes '
    '(${context.runtimeType}), (${context.runtimeType}, options) or (), not '
    '${function.runtimeType}.',
  );
  return undefined;
}

/// index.d.ts:3252 `ScriptableChartContext`: the chart context `{chart,
/// type: 'chart'}` (core.controller.js:856).
final class ScriptableChartContext(@override final IChart chart)
    extends ContextObject {
  /// The context of [chart], with no parent.
  this : super(null);

  @override
  String get type => 'chart';

  @override
  Object? callWith(Object? function, Object? options) => switch (function) {
    final Object? Function(ScriptableChartContext, Object?) f => f(
      this,
      options,
    ),
    final Object? Function(ScriptableChartContext) f => f(this),
    final Object? Function() f => f(),
    _ => _notScriptable(function, this),
  };
}

/// index.d.ts:23 `ScriptableContext`: the dataset context `{active,
/// dataset, datasetIndex, index, mode, type: 'dataset'}` and the data
/// context `{active, dataIndex, parsed, raw, element, index, mode, type:
/// 'data'}` (core.datasetController.js:182-205).
///
/// A data context reads [dataset] and [datasetIndex] from its parent, the
/// dataset context, as upstream reads them through the prototype.
final class ScriptableContext extends ContextObject {
  /// core.datasetController.js:182 `createDatasetContext(parent, index)`:
  /// `active` false, `dataset` null, `datasetIndex` and `index` [index],
  /// `mode` `default`.
  new dataset(super.parent, int index)
    : _isData = false,
      _datasetIndex = index,
      index = index;

  /// core.datasetController.js:195 `createDataContext(parent, index,
  /// element)`: `active` false, `dataIndex` and `index` [index], `parsed`
  /// and `raw` null, `element` [element], `mode` `default`.
  new data(super.parent, int index, this.element)
    : _isData = true,
      dataIndex = index,
      index = index;

  final bool _isData;

  @override
  String get type => _isData ? 'data' : 'dataset';

  /// `active`: whether the element is active (hovered).
  bool active = false;

  Object? _dataset;

  /// `dataset`: the dataset of the user. A data context reads it from its
  /// parent.
  Object? get dataset => _isData ? _parentDataset?.dataset : _dataset;

  set dataset(Object? value) => _dataset = value;

  int? _datasetIndex;

  /// `datasetIndex`: the index of the dataset. A data context reads it from
  /// its parent.
  int? get datasetIndex =>
      _isData ? _parentDataset?.datasetIndex : _datasetIndex;

  set datasetIndex(int? value) => _datasetIndex = value;

  ScriptableContext? get _parentDataset => switch (parent) {
    final ScriptableContext parent => parent,
    _ => null,
  };

  /// `dataIndex`: the index of the data item. Dart `null` in a dataset
  /// context.
  int? dataIndex;

  /// `parsed`: the parsed item of the data item, a `ParsedItem` or the
  /// number of a doughnut, pie or polar area chart. Dart `null` before the
  /// first `getContext` and in a dataset context.
  Object? parsed;

  /// `raw`: the data item as the app gave it. Dart `null` before the first
  /// `getContext` and in a dataset context.
  Object? raw;

  /// `element`: the element of the data item. Dart `null` in a dataset
  /// context.
  IElement? element;

  /// `index`: the [datasetIndex] of a dataset context, or the [dataIndex] of
  /// a data context.
  int index;

  /// `mode`: the update mode of the resolution. Dart `null` is the
  /// `undefined` of a `getContext` call with no mode.
  UpdateMode? mode = UpdateMode.defaultMode;

  /// The writes of `getContext` (core.datasetController.js:772-785) into a
  /// data context. Dart `null` stands for the [undefined] of an index past the
  /// end of the lists.
  void refresh(
    Object? parsed,
    Object? raw,
    int index,
    bool active,
    UpdateMode? mode,
  ) {
    this.parsed = identical(parsed, undefined) ? null : parsed;
    this.raw = identical(raw, undefined) ? null : raw;
    dataIndex = index;
    this.index = index;
    this.active = active;
    this.mode = mode;
  }

  @override
  Object? callWith(Object? function, Object? options) => switch (function) {
    final Object? Function(ScriptableContext, Object?) f => f(this, options),
    final Object? Function(ScriptableContext) f => f(this),
    final Object? Function() f => f(),
    _ => _notScriptable(function, this),
  };
}

/// index.d.ts:1419 `ScriptableScaleContext`: the scale context `{scale,
/// type: 'scale'}` and the tick context `{tick, index, type: 'tick'}`
/// (core.scale.js:107-119). A tick context reads [scale] from its parent.
final class ScriptableScaleContext extends ContextObject {
  /// core.scale.js:107 `createScaleContext(parent, scale)`.
  new scale(super.parent, IScale this._scale) : tick = null, index = null;

  /// core.scale.js:114 `createTickContext(parent, index, tick)`.
  new tick(super.parent, Tick this.tick, int this.index) : _scale = null;

  final IScale? _scale;

  @override
  String get type => tick == null ? 'scale' : 'tick';

  /// `scale`: the scale. A tick context reads it from its parent.
  IScale? get scale => _scale ?? _parentScale(parent);

  /// `tick`: the tick of a tick context, else Dart `null`.
  final Tick? tick;

  /// `index`: the index of the tick of a tick context, else Dart `null`.
  final int? index;

  @override
  Object? callWith(Object? function, Object? options) => switch (function) {
    final Object? Function(ScriptableScaleContext, Object?) f => f(
      this,
      options,
    ),
    final Object? Function(ScriptableScaleContext) f => f(this),
    final Object? Function() f => f(),
    _ => _notScriptable(function, this),
  };
}

/// The `scale` of a parent context, or Dart `null`.
IScale? _parentScale(ContextObject? parent) => switch (parent) {
  final ScriptableScaleContext parent => parent.scale,
  _ => null,
};

/// index.d.ts:1426 `ScriptableScalePointLabelContext`: `{label, index,
/// type: 'pointLabel'}` (scale.radialLinear.js:330-336). It reads [scale]
/// from its parent, the scale context.
final class ScriptableScalePointLabelContext.pointLabel(
  super.parent,

  /// `label`: the lines of the point label.
  final List<String> label,

  /// `index`: the index of the point label.
  final int index,
) extends ContextObject {
  /// scale.radialLinear.js:330 `createPointLabelContext(parent, index,
  /// label)`.
  this;

  @override
  String get type => 'pointLabel';

  /// `scale`: the scale, from the parent context.
  IScale? get scale => _parentScale(parent);

  @override
  Object? callWith(Object? function, Object? options) => switch (function) {
    final Object? Function(ScriptableScalePointLabelContext, Object?) f => f(
      this,
      options,
    ),
    final Object? Function(ScriptableScalePointLabelContext) f => f(this),
    final Object? Function() f => f(),
    _ => _notScriptable(function, this),
  };
}

/// index.d.ts:2789 `ScriptableTooltipContext`: `{tooltip, tooltipItems,
/// type: 'tooltip'}` (plugin.tooltip.js:348-354).
final class ScriptableTooltipContext(
  super.parent, {

  /// `tooltip`: the tooltip.
  required final TooltipModel? tooltip,

  /// `tooltipItems`: the items of the tooltip.
  required final List<TooltipItem>? tooltipItems,
}) extends ContextObject {
  /// plugin.tooltip.js:348 `createTooltipContext(parent, tooltip,
  /// tooltipItems)`.
  this;

  @override
  String get type => 'tooltip';

  @override
  Object? callWith(Object? function, Object? options) => switch (function) {
    final Object? Function(ScriptableTooltipContext, Object?) f => f(
      this,
      options,
    ),
    final Object? Function(ScriptableTooltipContext) f => f(this),
    final Object? Function() f => f(),
    _ => _notScriptable(function, this),
  };
}

/// index.d.ts:35 `ScriptableLineSegmentContext`: `{type: 'segment', p0, p1,
/// p0DataIndex, p1DataIndex, datasetIndex}` (helpers.segment.js:315), the
/// argument of each function of a `LineSegmentStyle` (Chart.js ADR 0142).
///
/// [p0] and [p1] are the points at the ends of the part, and the indexes are
/// `int`.
final class ScriptableLineSegmentContext.segment(
  super.parent, {

  /// `p0`: the point at the start of the part.
  required final IPointElement p0,

  /// `p1`: the point at the end of the part.
  required final IPointElement p1,

  /// `p0DataIndex`: the data index of [p0].
  required final int p0DataIndex,

  /// `p1DataIndex`: the data index of [p1].
  required final int p1DataIndex,

  /// `datasetIndex`: the index of the dataset of the line. Dart `null` is the
  /// `undefined` of a line without one.
  required final int? datasetIndex,
}) extends ContextObject {
  /// The context of the part from [p0] to [p1] (helpers.segment.js:315-321).
  this;

  @override
  String get type => 'segment';

  @override
  Object? callWith(Object? function, Object? options) => switch (function) {
    final Object? Function(ScriptableLineSegmentContext, Object?) f => f(
      this,
      options,
    ),
    final Object? Function(ScriptableLineSegmentContext) f => f(this),
    final Object? Function() f => f(),
    _ => _notScriptable(function, this),
  };
}

// helpers.options.ts:204 `createContext(parentContext, context)` has no
// port: each caller makes the typed context of its type with the constructor
// of its class (row `adapt-typed-contexts`).
