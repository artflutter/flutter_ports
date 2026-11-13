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
/// `adapt-text-style-fonts`). The
/// result of [createContext] is a [ContextObject]: an object with a prototype
/// (differences.md row `adapt-create-context-prototype`), of the typed
/// class of its `type` (Chart.js ADR 0054 §11, differences.md row
/// `adapt-typed-contexts`).
library;

import 'package:flutter/painting.dart' show TextStyle;
import 'package:flutter_chartjs_port/src/core/core.defaults.dart' show defaults;
import 'package:flutter_chartjs_port/src/helpers/grace_length.dart'
    show GraceLength;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isArray, isObject, valueOrDefault;
import 'package:flutter_chartjs_port/src/js/js_array.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/chart_text_style.dart';
import 'package:flutter_chartjs_port/src/types/geometric.dart';
import 'package:meta/meta.dart' show internal, protected;

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
/// `undefined`. A function value is called through [jsCall]. The result is
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
    if (!identical(context, undefined) && jsIsFunction(value)) {
      value = jsCall(value, [context]);
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
/// A [ContextObject] keeps its own properties and reads the [prototype] for
/// the other keys (differences.md row `adapt-create-context-prototype`). It
/// implements [JsObjectFace], the face by name, with the JS rules (Chart.js
/// ADR 0054 §5). It is not a `Map`:
/// - [jsRead] and `operator []` are `[[Get]]`: the own value, also the
///   [undefined] sentinel, else the value of the [prototype], else
///   [undefined].
/// - [hasProperty] is the `in` operator (`[[HasProperty]]`): an own key or
///   a key of the [prototype] chain.
/// - [jsHas] and [hasOwnProperty] are `Object.prototype.hasOwnProperty`.
/// - [jsKeys] is `Object.keys`: the own keys only, in their insertion order,
///   with the array-index keys first.
/// - [jsWrite], `operator []=` and [jsDelete] change the own properties
///   only, as a property assignment and `delete` do.
// DIVERGES(chartjs): adapt-create-context-prototype, a prototype chain.
base class ContextObject implements JsObjectFace {
  /// `Object.create(prototype)`: an object without own properties. Dart
  /// `null` is the `null` prototype.
  new(this.prototype) : _names = <String>[];

  new _withNames(this.prototype, this._names) {
    for (final name in _names) {
      _presentNames |= _nameBit(name);
    }
  }

  /// `Object.getPrototypeOf(this)`: the parent context, or Dart `null`. A
  /// parent is a [ContextObject] or a `Map` (a context object of user
  /// code).
  final Object? prototype;

  /// The own keys, in insertion order.
  final List<String> _names;

  // DIVERGES(chartjs): adapt-context-key-presence, a mask for frequent names.
  // The ordered list remains authoritative for enumeration and reinsertion.
  int _presentNames = 0;

  static int _nameBit(String name) => switch (name) {
    'active' => 1,
    'dataset' => 2,
    'datasetIndex' => 4,
    'dataIndex' => 8,
    'parsed' => 16,
    'raw' => 32,
    'element' => 64,
    'index' => 128,
    'mode' => 256,
    'type' => 512,
    _ => 0,
  };

  bool _hasName(String name) {
    final bit = _nameBit(name);
    return bit == 0 ? _names.contains(name) : _presentNames & bit != 0;
  }

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

  /// Makes [name] an own key: a new name goes to the end of the own-key
  /// order, as [jsWrite] does. A typed setter of a subclass calls it
  /// before it sets its field.
  void _claim(String name, [int bit = 0]) {
    final mask = bit == 0 ? _nameBit(name) : bit;
    if (mask == 0) {
      if (!_names.contains(name)) _names.add(name);
    } else if (_presentNames & mask == 0) {
      _names.add(name);
      _presentNames |= mask;
    }
  }

  /// `this[name]` (`[[Get]]`) for a typed field: the own [field], else the
  /// value of the prototype chain.
  Object? _fieldRead(Object? field, String name) =>
      identical(field, _unset) ? jsRead(name) : field;

  /// `type`.
  Object? get type => jsRead('type');

  /// The own value of [name], or [_unset].
  Object? _own(String name) {
    if (!_hasName(name)) return _unset;
    final field = fieldGet(name);
    if (!identical(field, _unset)) return field;
    final index = _extraNames?.indexOf(name) ?? -1;
    return index < 0 ? _unset : _extraValues![index];
  }

  /// `name in this` (`[[HasProperty]]`): an own key or a key of the
  /// [prototype] chain.
  bool hasProperty(String name) {
    if (_hasName(name)) return true;
    return switch (prototype) {
      final ContextObject parent => parent.hasProperty(name),
      final JsObjectFace parent => parent.jsHas(name),
      final Map<dynamic, dynamic> parent => parent.containsKey(name),
      _ => false,
    };
  }

  /// `Object.prototype.hasOwnProperty.call(this, key)`.
  bool hasOwnProperty(Object? key) => key is String && _hasName(key);

  /// The count of the own keys.
  int get ownKeyCount => _names.length;

  // The face of Chart.js ADR 0054 §5.

  @override
  Object? jsRead(String name) {
    final own = _own(name);
    if (!identical(own, _unset)) return own;
    return switch (prototype) {
      null => undefined,
      final JsObjectFace face => face.jsRead(name),
      final Map<dynamic, dynamic> map =>
        map.containsKey(name) ? map[name] : undefined,
      _ => undefined,
    };
  }

  @override
  void jsWrite(String name, Object? value) {
    _claim(name);
    if (fieldSet(name, value)) return;
    final names = _extraNames ??= <String>[];
    final values = _extraValues ??= <Object?>[];
    final index = names.indexOf(name);
    if (index < 0) {
      names.add(name);
      values.add(value);
    } else {
      values[index] = value;
    }
  }

  @override
  Object? operator [](String name) => jsRead(name);

  @override
  void operator []=(String name, Object? value) => jsWrite(name, value);

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
  bool jsHas(String name) => _hasName(name);

  @override
  bool jsDelete(String name) {
    if (!_hasName(name)) return false;
    _names.remove(name);
    _presentNames &= ~_nameBit(name);
    if (!fieldSet(name, _unset)) {
      final index = _extraNames!.indexOf(name);
      _extraNames!.removeAt(index);
      _extraValues!.removeAt(index);
    }
    return true;
  }
}

/// The value of a typed field of a [ContextObject] that the context does
/// not own.
const Object _unset = _Unset();

/// The type of [_unset].
final class const _Unset();

/// index.d.ts:3252 `ScriptableChartContext`: the chart context `{chart,
/// type: 'chart'}` (core.controller.js:856).
final class ScriptableChartContext(super.prototype) extends ContextObject {
  /// A chart context with the parent [prototype].
  this;

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
  new(super.prototype);

  /// core.datasetController.js:182 `createDatasetContext(parent, index)`:
  /// the keys `active` (false), `dataset` (undefined), `datasetIndex`,
  /// `index`, `mode` ('default') and `type` ('dataset'), in this order.
  new dataset(super.prototype, int index) {
    this
      ..active = false
      ..dataset = undefined
      ..datasetIndex = index
      ..index = index
      ..mode = 'default'
      .._setType('dataset');
  }

  /// core.datasetController.js:195 `createDataContext(parent, index,
  /// element)`: the keys `active` (false), `dataIndex`, `parsed`
  /// (undefined), `raw` (undefined), `element`, `index`, `mode`
  /// ('default') and `type` ('data'), in this order.
  new data(super.prototype, int index, Object? element) {
    this
      ..active = false
      ..dataIndex = index
      ..parsed = undefined
      ..raw = undefined
      .._setElement(element)
      ..index = index
      ..mode = 'default'
      .._setType('data');
  }

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

  // The typed writes of `getContext` (core.datasetController.js:762-786).
  // Each one makes its name an own key first, as `operator []=` does. The
  // mask test stands at the setter: `getContext` writes each key of each
  // element at each resolve, and only the first write claims it.

  set active(Object? value) {
    if (_presentNames & 1 == 0) _claim('active', 1);
    _active = value;
  }

  set dataset(Object? value) {
    if (_presentNames & 2 == 0) _claim('dataset', 2);
    _dataset = value;
  }

  set datasetIndex(Object? value) {
    if (_presentNames & 4 == 0) _claim('datasetIndex', 4);
    _datasetIndex = value;
  }

  set dataIndex(Object? value) {
    if (_presentNames & 8 == 0) _claim('dataIndex', 8);
    _dataIndex = value;
  }

  set parsed(Object? value) {
    if (_presentNames & 16 == 0) _claim('parsed', 16);
    _parsed = value;
  }

  set raw(Object? value) {
    if (_presentNames & 32 == 0) _claim('raw', 32);
    _raw = value;
  }

  set index(Object? value) {
    if (_presentNames & 128 == 0) _claim('index', 128);
    _index = value;
  }

  set mode(Object? value) {
    if (_presentNames & 256 == 0) _claim('mode', 256);
    _mode = value;
  }

  /// The bits in [_presentNames] of the six keys of the refresh of a data
  /// context: `active`, `dataIndex`, `parsed`, `raw`, `index` and `mode`.
  static const int _refreshKeys = 1 | 8 | 16 | 32 | 128 | 256;

  /// `hasOwnProperty('index')`, with no lookup of the name.
  // DIVERGES(chartjs): adapt-context-key-presence, the bit of one known name.
  @internal
  bool get hasIndexKey => _presentNames & 128 != 0;

  /// The six writes of `getContext` (core.datasetController.js:772-785) for a
  /// caller whose reads of [parsed] and [raw] run no user code: a native list.
  ///
  /// With the six keys present, a write adds no key, so that one test serves
  /// all of them. After a `delete` of user code, the setters reinsert the keys
  /// in the order of `getContext`, as each write of a JS object does.
  // DIVERGES(chartjs): adapt-context-bulk-refresh, one test for six writes.
  @internal
  void refresh(
    Object? parsed,
    Object? raw,
    int index,
    Object? active,
    Object? mode,
  ) {
    if (_presentNames & _refreshKeys != _refreshKeys) {
      this
        ..parsed = parsed
        ..raw = raw
        ..dataIndex = index
        ..index = index
        ..active = active
        ..mode = mode;
      return;
    }
    _parsed = parsed;
    _raw = raw;
    _writeIndexes(index);
    _active = active;
    _mode = mode;
  }

  /// The five writes of `getContext` after its write of `parsed`
  /// (core.datasetController.js:773), whose read of `raw` can run user code:
  /// [refresh] with the same rule. A `delete` of `parsed` in that read stays.
  // DIVERGES(chartjs): adapt-context-bulk-refresh, one test for five writes.
  @internal
  void refreshAfterParsed(
    Object? raw,
    int index,
    Object? active,
    Object? mode,
  ) {
    if (_presentNames & _refreshKeys != _refreshKeys) {
      this
        ..raw = raw
        ..dataIndex = index
        ..index = index
        ..active = active
        ..mode = mode;
      return;
    }
    _raw = raw;
    _writeIndexes(index);
    _active = active;
    _mode = mode;
  }

  /// `context.index = context.dataIndex = index` of two present keys. An index
  /// that does not change keeps its box: a live chart writes the same number
  /// into each context several times in each update. -0 is another number.
  void _writeIndexes(int index) {
    _dataIndex = index;
    _index = index;
  }

  void _setElement(Object? value) {
    _claim('element', 64);
    _element = value;
  }

  void _setType(Object? value) {
    _claim('type', 512);
    _type = value;
  }

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
  new(super.prototype);

  /// The fresh tick context, with the upstream literal's own-key order.
  // DIVERGES(chartjs): adapt-tick-context-construction, direct typed fields.
  new tick(Object? parent, Object tick, int index)
    : _tick = tick,
      _index = index,
      _type = 'tick',
      super._withNames(parent, ['tick', 'index', 'type']);

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
  new(super.prototype);

  /// The fresh point label context, with the upstream literal's own-key order.
  // DIVERGES(chartjs): adapt-point-label-context-construction, typed fields.
  new pointLabel(Object? parent, Object? label, int index)
    : _label = label,
      _index = index,
      _type = 'pointLabel',
      super._withNames(parent, ['label', 'index', 'type']);

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
final class ScriptableTooltipContext(super.prototype) extends ContextObject {
  /// A tooltip context with the parent [prototype].
  this;

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
final class ScriptableLineSegmentContext(super.prototype)
    extends ContextObject {
  /// A segment context with the parent [prototype].
  this;

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
/// the JS `null` of the overload at helpers.options.ts:202. The parent is a
/// [ContextObject] or a `Map`. `Object.assign` copies the own keys of
/// [context] in the order of `Object.keys` ([jsObjectKeys]), and reads each
/// value with `[[Get]]`. The context is
/// the typed class of its `type` (Chart.js ADR 0054 §11): `chart`,
/// `dataset` and `data`, `scale` and `tick`, `pointLabel`, `tooltip` and
/// `segment`. Another type gives a [ContextObject].
// DIVERGES(chartjs): adapt-typed-contexts, the typed class of the type.
ContextObject createContext(Object? parentContext, AnyObject context) {
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
    target.jsWrite(key, context[key]);
  }
  return target;
}
