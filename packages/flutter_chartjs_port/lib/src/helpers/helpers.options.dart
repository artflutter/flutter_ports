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
/// The results of [toTRBL], [toTRBLCorners], [toPadding] and [toFont] are
/// typed objects (differences.md row `adapt-options-typed-results`). The
/// result of [createContext] is a [ContextObject]: a Map with a prototype
/// (differences.md row `adapt-create-context-prototype`), of the typed
/// class of its `type` (Chart.js ADR 0054 §11, differences.md row
/// `adapt-typed-contexts`).
library;

import 'dart:collection';

import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/helpers/helpers.canvas.dart'
    show toFontString;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isArray, isNullOrUndef, isObject, toDimension, valueOrDefault;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' show CanvasFontSpec;
import 'package:meta/meta.dart' show protected;

/// helpers.options.ts:7 `LINE_HEIGHT`.
final RegExp _lineHeight = RegExp(r'^(normal|(\d+(?:\.\d+)?)(px|em|%)?)$');

/// helpers.options.ts:8 `FONT_STYLE`.
final RegExp _fontStyle = RegExp(
  r'^(normal|italic|initial|inherit|unset|(oblique( -?[0-9]?[0-9]deg)?))$',
);

/// helpers.options.ts:22 `toLineHeight`.
///
/// Converts the given line height `value` in pixels for a specific font
/// `size`.
/// @param value - The lineHeight to parse (eg. 1.6, '14px', '75%', '1.6em').
/// @param size - The font size (in pixels) used to resolve relative `value`.
/// @returns The effective line height in pixels (size * 1.2 if value is
/// invalid).
/// @see https://developer.mozilla.org/en-US/docs/Web/CSS/line-height
/// @since 2.7.0
///
/// [value] is a `number | string` upstream. Here it is any value, which
/// `'' + value` converts with `ToString` ([jsToString]): `null` gives
/// `'null'` and [undefined] gives `'undefined'`.
double toLineHeight(Object? value, double size) {
  final matches = _lineHeight.firstMatch(jsToString(value));
  if (matches == null || matches[1] == 'normal') {
    return size * 1.2;
  }

  // Upstream reassigns `value`. Its Dart type is `Object?`, so the number
  // gets its own variable.
  var number = jsToNumber(matches[2]);

  switch (matches[3]) {
    case 'px':
      return number;
    case '%':
      number /= 100;
  }

  return size * number;
}

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
  _TRBLObject(Map<String, double> props)
    : top = props['top']!,
      right = props['right']!,
      bottom = props['bottom']!,
      left = props['left']!;

  /// The object for a [value] that is not an object: the same number for
  /// each key (see [toTRBL]).
  _TRBLObject.all(double value)
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
  _TRBLCornersObject(Map<String, double> props)
    : topLeft = props['topLeft']!,
      topRight = props['topRight']!,
      bottomLeft = props['bottomLeft']!,
      bottomRight = props['bottomRight']!;

  /// The object for a [value] that is not an object: the same number for
  /// each corner (see [toTRBLCorners]).
  _TRBLCornersObject.all(double value)
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

/// The font object of [toFont] (helpers.options.ts:130-137): a
/// [CanvasFontSpec] with the line height in pixels.
///
/// Upstream builds a plain object and keeps each value as it is. Here the
/// members have the types of [CanvasFontSpec]
/// (differences.md row `adapt-options-typed-results`):
/// - [family] and [style]: `ToString` of a value that is not a string.
/// - [size]: `ToNumber` of a value that is not a number.
/// - Dart `null` stands for JS `null` and for `undefined` in these three
///   members, as in [CanvasFontSpec].
/// - [style] is also Dart `null` for a falsy value that is not a string
///   (`0`, `-0`, `NaN` and `false`). Upstream keeps the value. The string
///   leaves out the style in both cases.
/// - [weight] keeps its value: a `String`, a `num`, Dart `null` (JS `null`)
///   or the [undefined] sentinel.
final class ParsedFont implements CanvasFontSpec {
  /// The font object `{family, lineHeight, size, style, weight, string}`.
  ParsedFont({
    required this.family,
    required this.lineHeight,
    required this.size,
    required this.style,
    required this.weight,
    required this.string,
  });

  /// helpers.options.ts:131 `family`.
  @override
  final String? family;

  /// helpers.options.ts:132 `lineHeight`, in pixels ([toLineHeight]).
  @override
  final double lineHeight;

  /// helpers.options.ts:133 `size`.
  @override
  final double? size;

  /// helpers.options.ts:134 `style`.
  @override
  final String? style;

  /// helpers.options.ts:135 `weight`.
  @override
  final Object? weight;

  /// helpers.options.ts:136 `string`: the CSS font string of
  /// `toFontString` (helpers.options.ts:139), or `null` when [size] or
  /// [family] is empty.
  @override
  String? string;
}

/// The global `parseInt(string, 10)` (ECMAScript `parseInt`) of a string:
/// the optional sign and the decimal digits after leading white space, or
/// NaN.
///
/// `\s` of a Dart [RegExp] is the `\s` of JavaScript: the white space and
/// line terminators that `parseInt` skips. `double.parse` rounds the digits
/// correctly, as V8 does. `'-0'` gives -0.
double _parseInt(String string) {
  final match = _decimalInteger.firstMatch(string);
  if (match == null) return double.nan;
  return double.parse(match[1]!);
}

/// The prefix that `parseInt(string, 10)` reads.
final RegExp _decimalInteger = RegExp(r'^\s*([+-]?[0-9]+)');

/// The [CanvasFontSpec] form of a `family` or `style` value: Dart `null` for
/// JS `null` and `undefined`, else `ToString` of the value.
String? _fontMemberString(Object? value) =>
    isNullOrUndef(value) ? null : jsToString(value);

/// helpers.options.ts:115 `toFont`.
///
/// Parses font options and returns the font object.
/// @param options - A object that contains font options to be parsed.
/// @param fallback - A object that contains fallback font options.
/// @return The font object.
/// @private
///
/// [options] and [fallback] are option objects: Maps, also resolvers. A
/// falsy value is no object, and Dart `null` stands for a missing
/// [fallback]. The fallback is then `defaults.font`.
///
/// `console.warn` is [print]: the Dart console output on every platform.
ParsedFont toFont(Object? options, [Object? fallback]) {
  // Upstream reassigns its parameters.
  // ignore: parameter_assignments
  options = jsTruthy(options) ? options : <String, Object?>{};
  // Upstream reassigns its parameters.
  // ignore: parameter_assignments
  fallback = jsTruthy(fallback) ? fallback : defaults['font'];

  var size = valueOrDefault(
    jsGet(options, 'size'),
    jsGet(fallback, 'size'),
  );

  if (size is String) {
    size = _parseInt(size);
  }
  var style = valueOrDefault(
    jsGet(options, 'style'),
    jsGet(fallback, 'style'),
  );
  if (jsTruthy(style) && !_fontStyle.hasMatch(jsToString(style))) {
    // console.warn has no other counterpart in the pure layers.
    // ignore: avoid_print
    print('Invalid font style specified: "${jsToString(style)}"');
    style = undefined;
  }

  // DIVERGES(chartjs): adapt-options-typed-results, typed font members.
  final font = ParsedFont(
    family: _fontMemberString(
      valueOrDefault(
        jsGet(options, 'family'),
        jsGet(fallback, 'family'),
      ),
    ),
    // `size * 1.2` and `size * value` convert size with ToNumber.
    lineHeight: toLineHeight(
      valueOrDefault(
        jsGet(options, 'lineHeight'),
        jsGet(fallback, 'lineHeight'),
      ),
      jsToNumber(size),
    ),
    size: isNullOrUndef(size) ? null : jsToNumber(size),
    // A falsy style that is not a string stays falsy: `toFontString` leaves
    // it out.
    style: !jsTruthy(style) && style is! String
        ? null
        : _fontMemberString(style),
    weight: valueOrDefault(
      jsGet(options, 'weight'),
      jsGet(fallback, 'weight'),
    ),
    string: '',
  );

  font.string = toFontString(font);
  return font;
}

/// The element `array[index]` of a JavaScript array for a number [index]:
/// the element at an integer index from 0 to `length - 1`, else
/// [undefined]. A fractional, negative or NaN index names a property that
/// the array does not have.
Object? _arrayElement(List<Object?> array, double index) {
  if (index >= 0 && index < array.length && index == index.floorToDouble()) {
    return array[index.toInt()];
  }
  return undefined;
}

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
/// `undefined`. A function value is called through [jsCall]. The result is
/// [undefined] when no input gives a defined value.
Object? resolve(
  List<Object?> inputs, [
  Object? context = undefined,
  double? index,
  AnyObject? info,
]) {
  var cacheable = true;
  Object? value;

  for (var i = 0, ilen = inputs.length; i < ilen; ++i) {
    value = inputs[i];
    if (identical(value, undefined)) {
      continue;
    }
    if (!identical(context, undefined) && jsIsFunction(value)) {
      value = jsCall(value, [context]);
      cacheable = false;
    }
    if (index != null && isArray(value)) {
      final array = value! as List<Object?>;
      value = _arrayElement(array, index.remainder(array.length));
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
({double min, double max}) addGrace(
  ({double min, double max}) minmax,
  Object? grace,
  // Upstream takes beginAtZero as a positional parameter.
  // ignore: avoid_positional_boolean_parameters
  bool beginAtZero,
) {
  final (:min, :max) = minmax;
  final change = toDimension(grace, (max - min) / 2);
  double keepZero(double value, double add) =>
      beginAtZero && value == 0 ? 0 : value + add;
  return (min: keepZero(min, -change.abs()), max: keepZero(max, change));
}

/// helpers.options.ts:205 the object `Object.create(parentContext)` of
/// `createContext` ([createContext]): a context object with a prototype.
///
/// The typed contexts of Chart.js ADR 0054 §11 extend it. Each member of
/// the `index.d.ts` context of its `type` that the context owns is a typed
/// field: [ScriptableChartContext], [ScriptableContext],
/// [ScriptableScaleContext], [ScriptableScalePointLabelContext],
/// [ScriptableTooltipContext] and [ScriptableLineSegmentContext]. Any other
/// own key is an extra. A [ContextObject] of another type keeps each own
/// key as an extra (differences.md row `adapt-typed-contexts`).
///
/// A Map has no prototype. A [ContextObject] keeps its own properties and
/// reads the [prototype] for the other keys
/// (differences.md row `adapt-create-context-prototype`). It implements
/// [JsObjectFace], the face by name. During the migration it is also a
/// `MapBase` (the scaffolding of Chart.js ADR 0054 §5):
/// - `operator []` is `[[Get]]`: the own value, also the [undefined]
///   sentinel, else the value of the [prototype], else Dart `null` as for an
///   absent key of a Map.
/// - [containsKey] is the `in` operator (`[[HasProperty]]`): an own key or
///   a key of the [prototype] chain. Thus a read that gives [undefined] for
///   an absent key (`containsKey(key) ? map[key] : undefined`) also finds
///   the inherited values.
/// - [hasOwnProperty] is `Object.prototype.hasOwnProperty`.
/// - [keys], [length] and the iteration are the own keys only, in their
///   insertion order. [jsKeys] is `Object.keys`.
/// - `operator []=`, [remove] and [clear] change the own properties only,
///   as a property assignment and `delete` do.
// DIVERGES(chartjs): adapt-create-context-prototype, a Map with a prototype.
base class ContextObject extends MapBase<String, Object?>
    implements JsObjectFace {
  /// `Object.create(prototype)`: an object without own properties. Dart
  /// `null` is the `null` prototype.
  ContextObject(this.prototype);

  /// `Object.getPrototypeOf(this)`: the parent context, or Dart `null`.
  final AnyObject? prototype;

  /// The own keys, in insertion order.
  final List<String> _names = <String>[];

  /// The own keys that are not typed fields, and their values.
  List<String>? _extraNames;
  List<Object?>? _extraValues;

  /// The value of the typed field [name] of a subclass. A field that the
  /// context does not own, or a name that is not a field of the subclass,
  /// gives a private marker.
  @protected
  Object? fieldGet(String name) => _unset;

  /// Writes the typed field [name] of a subclass (the private marker clears
  /// it). Returns false for a name that is not a field of the subclass.
  @protected
  bool fieldSet(String name, Object? value) => false;

  /// `this[name]` (`[[Get]]`) for a typed field: the own [field], else the
  /// value of the prototype chain.
  Object? _fieldRead(Object? field, String name) =>
      identical(field, _unset) ? jsRead(name) : field;

  /// `type`.
  Object? get type => jsRead('type');

  /// The own value of [name], or [_unset].
  Object? _own(String name) {
    if (!_names.contains(name)) return _unset;
    final field = fieldGet(name);
    if (!identical(field, _unset)) return field;
    final index = _extraNames?.indexOf(name) ?? -1;
    return index < 0 ? _unset : _extraValues![index];
  }

  @override
  Object? operator [](Object? key) {
    if (key is! String) return null;
    final own = _own(key);
    if (!identical(own, _unset)) return own;
    return prototype?[key];
  }

  @override
  void operator []=(String key, Object? value) {
    if (!_names.contains(key)) _names.add(key);
    if (fieldSet(key, value)) return;
    final names = _extraNames ??= <String>[];
    final values = _extraValues ??= <Object?>[];
    final index = names.indexOf(key);
    if (index < 0) {
      names.add(key);
      values.add(value);
    } else {
      values[index] = value;
    }
  }

  @override
  bool containsKey(Object? key) =>
      (key is String && _names.contains(key)) ||
      (prototype?.containsKey(key) ?? false);

  /// `Object.prototype.hasOwnProperty.call(this, key)`.
  bool hasOwnProperty(Object? key) => key is String && _names.contains(key);

  @override
  Iterable<String> get keys => List<String>.of(_names);

  @override
  int get length => _names.length;

  @override
  Object? remove(Object? key) {
    if (key is! String || !_names.contains(key)) return null;
    final value = _own(key);
    _names.remove(key);
    if (!fieldSet(key, _unset)) {
      final index = _extraNames!.indexOf(key);
      _extraNames!.removeAt(index);
      _extraValues!.removeAt(index);
    }
    return value;
  }

  @override
  void clear() => List<String>.of(_names).forEach(remove);

  // The face of Chart.js ADR 0054 §5.

  @override
  Object? jsRead(String name) {
    final own = _own(name);
    if (!identical(own, _unset)) return own;
    final parent = prototype;
    if (parent == null) return undefined;
    if (parent case final JsObjectFace face) return face.jsRead(name);
    return parent.containsKey(name) ? parent[name] : undefined;
  }

  @override
  void jsWrite(String name, Object? value) => this[name] = value;

  @override
  List<String> jsKeys() {
    if (!_names.any((name) => jsArrayIndex(name) != null)) {
      return List<String>.of(_names);
    }
    // The indices are distinct integers: an unstable sort gives one order.
    final indices =
        [
            for (final name in _names)
              if (jsArrayIndex(name) case final int index) (index, name),
          ]
          // js-ok: distinct keys, as jsObjectKeys sorts them
          ..sort((a, b) => a.$1.compareTo(b.$1));
    return [
      for (final (_, name) in indices) name,
      for (final name in _names)
        if (jsArrayIndex(name) == null) name,
    ];
  }

  @override
  bool jsHas(String name) => _names.contains(name);

  @override
  bool jsDelete(String name) {
    if (!_names.contains(name)) return false;
    remove(name);
    return true;
  }
}

/// The value of a typed field of a [ContextObject] that the context does
/// not own.
const Object _unset = _Unset();

/// The type of [_unset].
final class _Unset {
  const _Unset();
}

/// index.d.ts:3252 `ScriptableChartContext`: the chart context `{chart,
/// type: 'chart'}` (core.controller.js:856).
final class ScriptableChartContext extends ContextObject {
  /// A chart context with the parent [prototype].
  ScriptableChartContext(super.prototype);

  Object? _chart = _unset;
  Object? _type = _unset;

  /// `chart`.
  Object? get chart => _fieldRead(_chart, 'chart');

  @override
  Object? fieldGet(String name) => switch (name) {
    'chart' => _chart,
    'type' => _type,
    _ => _unset,
  };

  @override
  bool fieldSet(String name, Object? value) {
    switch (name) {
      case 'chart':
        _chart = value;
      case 'type':
        _type = value;
      default:
        return false;
    }
    return true;
  }
}

/// index.d.ts:23 `ScriptableContext`: the dataset context `{active,
/// dataset, datasetIndex, index, mode, type: 'dataset'}` and the data
/// context `{active, dataIndex, parsed, raw, element, index, mode, type:
/// 'data'}` (core.datasetController.js:182-205).
final class ScriptableContext extends ContextObject {
  /// A dataset or data context with the parent [prototype].
  ScriptableContext(super.prototype);

  Object? _active = _unset;
  Object? _dataset = _unset;
  Object? _datasetIndex = _unset;
  Object? _dataIndex = _unset;
  Object? _parsed = _unset;
  Object? _raw = _unset;
  Object? _element = _unset;
  Object? _index = _unset;
  Object? _mode = _unset;
  Object? _type = _unset;

  /// `active`.
  Object? get active => _fieldRead(_active, 'active');

  /// `dataset`.
  Object? get dataset => _fieldRead(_dataset, 'dataset');

  /// `datasetIndex`.
  Object? get datasetIndex => _fieldRead(_datasetIndex, 'datasetIndex');

  /// `dataIndex`.
  Object? get dataIndex => _fieldRead(_dataIndex, 'dataIndex');

  /// `parsed`.
  Object? get parsed => _fieldRead(_parsed, 'parsed');

  /// `raw`.
  Object? get raw => _fieldRead(_raw, 'raw');

  /// `element`.
  Object? get element => _fieldRead(_element, 'element');

  /// `index`.
  Object? get index => _fieldRead(_index, 'index');

  /// `mode`.
  Object? get mode => _fieldRead(_mode, 'mode');

  @override
  Object? fieldGet(String name) => switch (name) {
    'active' => _active,
    'dataset' => _dataset,
    'datasetIndex' => _datasetIndex,
    'dataIndex' => _dataIndex,
    'parsed' => _parsed,
    'raw' => _raw,
    'element' => _element,
    'index' => _index,
    'mode' => _mode,
    'type' => _type,
    _ => _unset,
  };

  @override
  bool fieldSet(String name, Object? value) {
    switch (name) {
      case 'active':
        _active = value;
      case 'dataset':
        _dataset = value;
      case 'datasetIndex':
        _datasetIndex = value;
      case 'dataIndex':
        _dataIndex = value;
      case 'parsed':
        _parsed = value;
      case 'raw':
        _raw = value;
      case 'element':
        _element = value;
      case 'index':
        _index = value;
      case 'mode':
        _mode = value;
      case 'type':
        _type = value;
      default:
        return false;
    }
    return true;
  }
}

/// index.d.ts:1419 `ScriptableScaleContext`: the scale context `{scale,
/// type: 'scale'}` and the tick context `{tick, index, type: 'tick'}`
/// (core.scale.js:107-119).
final class ScriptableScaleContext extends ContextObject {
  /// A scale or tick context with the parent [prototype].
  ScriptableScaleContext(super.prototype);

  Object? _scale = _unset;
  Object? _tick = _unset;
  Object? _index = _unset;
  Object? _type = _unset;

  /// `scale`.
  Object? get scale => _fieldRead(_scale, 'scale');

  /// `tick`.
  Object? get tick => _fieldRead(_tick, 'tick');

  /// `index`.
  Object? get index => _fieldRead(_index, 'index');

  @override
  Object? fieldGet(String name) => switch (name) {
    'scale' => _scale,
    'tick' => _tick,
    'index' => _index,
    'type' => _type,
    _ => _unset,
  };

  @override
  bool fieldSet(String name, Object? value) {
    switch (name) {
      case 'scale':
        _scale = value;
      case 'tick':
        _tick = value;
      case 'index':
        _index = value;
      case 'type':
        _type = value;
      default:
        return false;
    }
    return true;
  }
}

/// index.d.ts:1426 `ScriptableScalePointLabelContext`: `{label, index,
/// type: 'pointLabel'}` (scale.radialLinear.js:330-336).
final class ScriptableScalePointLabelContext extends ContextObject {
  /// A point label context with the parent [prototype].
  ScriptableScalePointLabelContext(super.prototype);

  Object? _label = _unset;
  Object? _index = _unset;
  Object? _type = _unset;

  /// `label`.
  Object? get label => _fieldRead(_label, 'label');

  /// `index`.
  Object? get index => _fieldRead(_index, 'index');

  @override
  Object? fieldGet(String name) => switch (name) {
    'label' => _label,
    'index' => _index,
    'type' => _type,
    _ => _unset,
  };

  @override
  bool fieldSet(String name, Object? value) {
    switch (name) {
      case 'label':
        _label = value;
      case 'index':
        _index = value;
      case 'type':
        _type = value;
      default:
        return false;
    }
    return true;
  }
}

/// index.d.ts:2789 `ScriptableTooltipContext`: `{tooltip, tooltipItems,
/// type: 'tooltip'}` (plugin.tooltip.js:348-354).
final class ScriptableTooltipContext extends ContextObject {
  /// A tooltip context with the parent [prototype].
  ScriptableTooltipContext(super.prototype);

  Object? _tooltip = _unset;
  Object? _tooltipItems = _unset;
  Object? _type = _unset;

  /// `tooltip`.
  Object? get tooltip => _fieldRead(_tooltip, 'tooltip');

  /// `tooltipItems`.
  Object? get tooltipItems => _fieldRead(_tooltipItems, 'tooltipItems');

  @override
  Object? fieldGet(String name) => switch (name) {
    'tooltip' => _tooltip,
    'tooltipItems' => _tooltipItems,
    'type' => _type,
    _ => _unset,
  };

  @override
  bool fieldSet(String name, Object? value) {
    switch (name) {
      case 'tooltip':
        _tooltip = value;
      case 'tooltipItems':
        _tooltipItems = value;
      case 'type':
        _type = value;
      default:
        return false;
    }
    return true;
  }
}

/// index.d.ts:35 `ScriptableLineSegmentContext`: `{type: 'segment', p0, p1,
/// p0DataIndex, p1DataIndex, datasetIndex}` (helpers.segment.js:315).
final class ScriptableLineSegmentContext extends ContextObject {
  /// A segment context with the parent [prototype].
  ScriptableLineSegmentContext(super.prototype);

  Object? _type = _unset;
  Object? _p0 = _unset;
  Object? _p1 = _unset;
  Object? _p0DataIndex = _unset;
  Object? _p1DataIndex = _unset;
  Object? _datasetIndex = _unset;

  /// `p0`.
  Object? get p0 => _fieldRead(_p0, 'p0');

  /// `p1`.
  Object? get p1 => _fieldRead(_p1, 'p1');

  /// `p0DataIndex`.
  Object? get p0DataIndex => _fieldRead(_p0DataIndex, 'p0DataIndex');

  /// `p1DataIndex`.
  Object? get p1DataIndex => _fieldRead(_p1DataIndex, 'p1DataIndex');

  /// `datasetIndex`.
  Object? get datasetIndex => _fieldRead(_datasetIndex, 'datasetIndex');

  @override
  Object? fieldGet(String name) => switch (name) {
    'type' => _type,
    'p0' => _p0,
    'p1' => _p1,
    'p0DataIndex' => _p0DataIndex,
    'p1DataIndex' => _p1DataIndex,
    'datasetIndex' => _datasetIndex,
    _ => _unset,
  };

  @override
  bool fieldSet(String name, Object? value) {
    switch (name) {
      case 'type':
        _type = value;
      case 'p0':
        _p0 = value;
      case 'p1':
        _p1 = value;
      case 'p0DataIndex':
        _p0DataIndex = value;
      case 'p1DataIndex':
        _p1DataIndex = value;
      case 'datasetIndex':
        _datasetIndex = value;
      default:
        return false;
    }
    return true;
  }
}

/// helpers.options.ts:204 `createContext`.
///
/// Create a context inheriting parentContext
/// @param parentContext
/// @param context
/// @returns
///
/// `Object.assign(Object.create(parentContext), context)`. Dart `null` is
/// the JS `null` of the overload at helpers.options.ts:202. `Object.assign`
/// copies the own keys of [context] in the order of `Object.keys`
/// ([jsObjectKeys]), and reads each value with `[[Get]]`. The context is
/// the typed class of its `type` (Chart.js ADR 0054 §11): `chart`,
/// `dataset` and `data`, `scale` and `tick`, `pointLabel`, `tooltip` and
/// `segment`. Another type gives a [ContextObject].
// DIVERGES(chartjs): adapt-typed-contexts, the typed class of the type.
ContextObject createContext(AnyObject? parentContext, AnyObject context) {
  final target = switch (context['type']) {
    'chart' => ScriptableChartContext(parentContext),
    'dataset' || 'data' => ScriptableContext(parentContext),
    'scale' || 'tick' => ScriptableScaleContext(parentContext),
    'pointLabel' => ScriptableScalePointLabelContext(parentContext),
    'tooltip' => ScriptableTooltipContext(parentContext),
    'segment' => ScriptableLineSegmentContext(parentContext),
    _ => ContextObject(parentContext),
  };
  for (final key in jsObjectKeys(context)) {
    target[key] = context[key];
  }
  return target;
}
