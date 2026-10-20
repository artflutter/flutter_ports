// Ported from Chart.js v4.5.1 src/core/core.datasetController.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.datasetController.js`.
///
/// [DatasetController] is the base class of the dataset controllers of
/// phase 7. It implements `types.DatasetController`, the interface that
/// `core.interaction`, `core.scale` and `helpers.config` read.
///
/// - The chart is a `types.Chart`, the meta a `types.ChartMeta` and a scale
///   a `types.Scale` (Chart.js ADR 0003). The JSDoc typedefs of :7-10 name
///   the concrete classes. `chart.config` is the `Config` of
///   `core.config.dart`.
/// - A JS plain object is a Map (Chart.js ADR 0006): the parsed items, the
///   stacks and the contexts. The work objects `{keys, values}` of the stacks
///   and `{min, max}` of `getMinMax` are classes.
/// - [DatasetController.jsClass] is the class as a value with the statics
///   `defaults`, `datasetElementType` and `dataElementType` (Chart.js ADR
///   0020, section 3). The constructor takes `new.target` as an optional
///   last parameter (section 4).
/// - The `_` members that other modules or the controllers of phase 7 read
///   drop the underscore and carry `@internal` (Chart.js ADR 0012). Two of
///   them then have the name of a public member: `_update` is
///   [DatasetController.update_], and `_getSharedOptions` is
///   [DatasetController.getSharedOptions_] (Chart.js ADR 0023).
/// - The array listener members `_onData*` are the `onData*` members of the
///   `ArrayListener` mixin of `helpers.collection.dart`. The code that
///   changes a data `List` calls `notifyArrayListeners` (differences.md
///   `platform-array-events`).
/// - The options of an element are the typed classes of
///   `element_options.dart` (Chart.js ADR 0021).
///
/// This file imports `core.animations.dart`, which imports
/// `core.animator.dart`. Thus it is not a pure layer.
library;

import 'package:flutter_chartjs/src/canvas/canvas.dart'
    show CanvasRenderingContext2D;
import 'package:flutter_chartjs/src/core/core.animations.dart';
import 'package:flutter_chartjs/src/core/core.config.dart';
// DatasetController has a static `defaults`. Inside the class, upstream
// `defaults` is the import of core.defaults.js.
import 'package:flutter_chartjs/src/core/core.defaults.dart' as core_defaults;
import 'package:flutter_chartjs/src/core/core.element.dart';
import 'package:flutter_chartjs/src/elements/element_options.dart'
    show copyOptions, createElementOptions;
import 'package:flutter_chartjs/src/helpers/helpers.collection.dart'
    show ArrayListener, listenArrayEvents, unlistenArrayEvents;
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isArray, isFinite, isObject, resolveObjectKey, valueOrDefault;
import 'package:flutter_chartjs/src/helpers/helpers.math.dart'
    show MinMax, sign;
import 'package:flutter_chartjs/src/helpers/helpers.options.dart'
    show createContext;
import 'package:flutter_chartjs/src/js/js_array.dart'
    show jsObjectKeys, jsSplice;
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart'
    show jsGet, jsObjectFreeze;
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/basic.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// core.datasetController.js:12 `scaleClip`.
///
/// `scale && scale.options || {}`: the options of a scale are always an
/// object. The edges are [allowedOverflow] or 0.
({Object? start, Object? end}) _scaleClip(
  types.Scale? scale,
  Object? allowedOverflow,
) {
  final opts = scale?.options ?? const <String, Object?>{};
  final reverse = jsGet(opts, 'reverse');
  final min = identical(jsGet(opts, 'min'), undefined) ? allowedOverflow : 0.0;
  final max = identical(jsGet(opts, 'max'), undefined) ? allowedOverflow : 0.0;
  return (
    start: jsTruthy(reverse) ? max : min,
    end: jsTruthy(reverse) ? min : max,
  );
}

/// core.datasetController.js:23 `defaultClip`.
///
/// The result is `false` or the plain object `{top, right, bottom, left}`.
Object? _defaultClip(
  types.Scale? xScale,
  types.Scale? yScale,
  Object? allowedOverflow,
) {
  if (allowedOverflow == false) {
    return false;
  }
  final x = _scaleClip(xScale, allowedOverflow);
  final y = _scaleClip(yScale, allowedOverflow);

  return <String, Object?>{
    'top': y.end,
    'right': x.end,
    'bottom': y.start,
    'left': x.start,
  };
}

/// core.datasetController.js:38 `toClip`.
///
/// An absent key of an object [value] gives the [undefined] sentinel, as the
/// property read of upstream does.
types.ChartMetaClip _toClip(Object? value) {
  Object? t;
  Object? r;
  Object? b;
  Object? l;

  if (isObject(value)) {
    t = jsGet(value, 'top');
    r = jsGet(value, 'right');
    b = jsGet(value, 'bottom');
    l = jsGet(value, 'left');
  } else {
    t = r = b = l = value;
  }

  return _Clip(top: t, right: r, bottom: b, left: l, disabled: value == false);
}

/// core.datasetController.js:50 the object `{top, right, bottom, left,
/// disabled}` of `toClip`.
final class _Clip implements types.ChartMetaClip {
  _Clip({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
    required this.disabled,
  });

  @override
  final Object? top;

  @override
  final Object? right;

  @override
  final Object? bottom;

  @override
  final Object? left;

  @override
  final bool disabled;
}

/// core.datasetController.js:59 `getSortedDatasetIndices`.
List<double> _getSortedDatasetIndices(
  types.Chart chart,
  bool filterVisible,
) {
  final keys = <double>[];
  final metasets = chart.getSortedDatasetMetas(filterVisible);

  for (var i = 0, ilen = metasets.length; i < ilen; ++i) {
    keys.add(metasets[i].index);
  }
  return keys;
}

/// core.datasetController.js:70 `applyStack(stack, value, dsIndex, options
/// = {})`.
///
/// [mode] and [all] are the keys of `options`. Dart `null` for [mode] stands
/// for JS `undefined`.
///
/// The result is the upstream result: [undefined] for a `null` [value], 0
/// when the stack does not contain [dsIndex], else the sum. The sum keeps
/// the JavaScript `+`: a string value appends text. A number result is a
/// `double`.
Object? _applyStack(
  DatasetStack stack,
  Object? value,
  double dsIndex, {
  Object? mode,
  bool all = false,
}) {
  final keys = stack.keys;
  final singleMode = mode == 'single';
  double datasetIndex;
  Object? otherValue;

  if (value == null) {
    return undefined;
  }

  var sum = value;
  var found = false;
  for (var i = 0, ilen = keys.length; i < ilen; ++i) {
    datasetIndex = keys[i];
    if (datasetIndex == dsIndex) {
      found = true;
      if (all) {
        continue;
      }
      break;
    }
    otherValue = jsGet(stack.values, _indexKey(datasetIndex));
    if (isFinite(otherValue) &&
        (singleMode ||
            (sum == 0 ||
                sign(jsToNumber(sum)) == sign(jsToNumber(otherValue))))) {
      sum = _plus(sum, otherValue! as num);
    }
  }

  if (!found && !all) {
    return 0.0;
  }

  return sum;
}

/// The JavaScript `value + other` for a finite number [other]: a number sum,
/// or the text of [value] with the text of [other] when [value] is a string
/// or an object.
Object _plus(Object? value, num other) => switch (value) {
  final double number => number + other,
  null || Undefined() || bool() || num() => jsToNumber(value) + other,
  _ => jsToString(value) + jsNumberToString(other),
};

/// core.datasetController.js:102 `convertObjectDataToArray`.
List<Object?> _convertObjectDataToArray(AnyObject data, types.ChartMeta meta) {
  final iScale = meta.iScale!;
  final vScale = meta.vScale!;
  final iAxisKey = iScale.axis == 'x' ? 'x' : 'y';
  final vAxisKey = vScale.axis == 'x' ? 'x' : 'y';
  final keys = jsObjectKeys(data);
  final adata = <Object?>[];
  String key;
  for (var i = 0, ilen = keys.length; i < ilen; ++i) {
    key = keys[i];
    adata.add(<String, Object?>{iAxisKey: key, vAxisKey: data[key]});
  }
  return adata;
}

/// core.datasetController.js:119 `isStacked`.
///
/// The result is the `stacked` option when it is truthy, else a `bool`.
Object? _isStacked(types.Scale? scale, types.ChartMeta meta) {
  final stacked = scale == null ? undefined : jsGet(scale.options, 'stacked');
  return jsTruthy(stacked)
      ? stacked
      : (identical(stacked, undefined) && !identical(meta.stack, undefined));
}

/// core.datasetController.js:124 `getStackKey`.
String _getStackKey(
  types.Scale indexScale,
  types.Scale valueScale,
  types.ChartMeta meta,
) {
  final stack = jsTruthy(meta.stack) ? meta.stack : meta.type;
  return '${indexScale.id}.${valueScale.id}.${jsToString(stack)}';
}

/// core.datasetController.js:128 `getUserBounds`.
({double min, double max}) _getUserBounds(types.Scale scale) {
  final (:min, :max, :minDefined, :maxDefined) = scale.getUserBounds();
  return (
    min: minDefined ? min : double.negativeInfinity,
    max: maxDefined ? max : double.infinity,
  );
}

/// core.datasetController.js:136 `getOrCreateStack`.
///
/// The key of [indexValue] is its `ToString`, as the property key of
/// `subStack[indexValue]`.
AnyObject _getOrCreateStack(
  AnyObject stacks,
  String stackKey,
  Object? indexValue,
) {
  var subStack = stacks[stackKey];
  if (!jsTruthy(subStack)) {
    stacks[stackKey] = subStack = <String, Object?>{};
  }
  final sub = subStack! as AnyObject;
  final key = jsToString(indexValue);
  var stack = sub[key];
  if (!jsTruthy(stack)) {
    sub[key] = stack = <String, Object?>{};
  }
  return stack! as AnyObject;
}

/// core.datasetController.js:141 `getLastIndexInStack`.
///
/// `value > 0` and `value < 0` compare the `ToNumber` of the stack value
/// with 0, as the JavaScript relational operators do for a number operand.
/// Dart `null` stands for the JS `null` result.
double? _getLastIndexInStack(
  AnyObject stack,
  types.Scale vScale,
  bool positive,
  String type,
) {
  for (final meta in vScale.getMatchingVisibleMetas(type).reversed) {
    final value = jsToNumber(jsGet(stack, _indexKey(meta.index)));
    if ((positive && value > 0) || (!positive && value < 0)) {
      return meta.index;
    }
  }

  return null;
}

/// core.datasetController.js:152 `updateStacks`.
///
/// The map structure of `chart._stacks` is `{stackKey: {datasetIndex:
/// value}}`. A key of a stack is the `ToString` of the dataset index.
///
/// A parsed item is any value (`unknown[]`, index.d.ts:473). With `parsing:
/// false`, the items are the data items. `item._stacks = {}` writes into the
/// item. A write into a primitive throws a `TypeError` in the strict code of
/// an ES module, and so does the port. A write into a Map of a narrower
/// value type than `Object?` throws a [TypeError] too, where upstream writes
/// into the plain object (differences.md row `js-semantics-resolver-objects`).
void _updateStacks(DatasetController controller, List<Object?> parsed) {
  final chart = controller.chart;
  final meta = controller.cachedMeta;
  // map structure is {stackKey: {datasetIndex: value}}
  final stacks = chart.stacks ??= <String, Object?>{};
  final iScale = meta.iScale!;
  final vScale = meta.vScale!;
  final datasetIndex = meta.index;
  final iAxis = iScale.axis;
  final vAxis = vScale.axis;
  final key = _getStackKey(iScale, vScale, meta);
  final ilen = parsed.length;
  // The property key of `stack[datasetIndex]`.
  final datasetKey = _indexKey(datasetIndex);
  AnyObject stack;

  for (var i = 0; i < ilen; ++i) {
    final item = parsed[i];
    final index = jsGet(item, iAxis);
    final value = jsGet(item, vAxis);
    var itemStacks = _parsedValue(item, '_stacks');
    if (!jsTruthy(itemStacks)) {
      // A JavaScript TypeError: a property write into a primitive.
      if (item is! Map<dynamic, dynamic>) throw TypeError();
      // DIVERGES(chartjs): js-semantics-resolver-objects, a narrow Map throws.
      item['_stacks'] = itemStacks = <String, Object?>{};
    }
    stack = (itemStacks! as AnyObject)[vAxis] = _getOrCreateStack(
      stacks,
      key,
      index,
    );
    stack[datasetKey] = value;

    stack['_top'] = _getLastIndexInStack(stack, vScale, true, meta.type);
    stack['_bottom'] = _getLastIndexInStack(stack, vScale, false, meta.type);

    var visualValues = stack['_visualValues'];
    if (!jsTruthy(visualValues)) {
      stack['_visualValues'] = visualValues = <String, Object?>{};
    }
    (visualValues! as AnyObject)[datasetKey] = value;
  }
}

/// core.datasetController.js:177 `getFirstScaleId`: the first key of
/// `chart.scales` whose scale has [axis], or Dart `null` for `undefined`.
String? _getFirstScaleId(types.Chart chart, String axis) {
  final scales = chart.scales;
  return jsObjectKeys(
    scales,
  ).where((key) => scales[key]!.axis == axis).firstOrNull;
}

/// core.datasetController.js:182 `createDatasetContext`.
AnyObject _createDatasetContext(AnyObject parent, double index) {
  return createContext(parent, <String, Object?>{
    'active': false,
    'dataset': undefined,
    'datasetIndex': index,
    'index': index,
    'mode': 'default',
    'type': 'dataset',
  });
}

/// core.datasetController.js:195 `createDataContext`.
AnyObject _createDataContext(AnyObject parent, double index, Element element) {
  return createContext(parent, <String, Object?>{
    'active': false,
    'dataIndex': index,
    'parsed': undefined,
    'raw': undefined,
    'element': element,
    'index': index,
    'mode': 'default',
    'type': 'data',
  });
}

/// core.datasetController.js:208 `clearStacks(meta, items)`.
///
/// The loop returns at the first parsed item without a value of the dataset
/// in its stack, as v4.5.1 does (:220). Upstream `master` continues there
/// (ledger row #12155). The commit pin after phase 5 brings that change.
void _clearStacks(types.ChartMeta meta, [List<Object?>? items]) {
  // Not using meta.index here, because it might be already updated if the
  // dataset changed location
  final datasetIndex = meta.controller!.index;
  final axis = meta.vScale?.axis;
  if (axis == null || axis.isEmpty) {
    return;
  }

  final parsedItems = items ?? meta.parsed;
  // The property key of `stacks[axis][datasetIndex]`.
  final datasetKey = _indexKey(datasetIndex);
  for (final parsed in parsedItems) {
    final stacks = _parsedValue(parsed, '_stacks');
    if (!jsTruthy(stacks) ||
        identical(jsGet(stacks, axis), undefined) ||
        identical(jsGet(jsGet(stacks, axis), datasetKey), undefined)) {
      return;
    }
    final axisStacks = jsGet(stacks, axis)! as AnyObject..remove(datasetKey);
    final visualValues = jsGet(axisStacks, '_visualValues');
    if (!identical(visualValues, undefined) &&
        !identical(jsGet(visualValues, datasetKey), undefined)) {
      (visualValues! as AnyObject).remove(datasetKey);
    }
  }
}

/// core.datasetController.js:229 `isDirectUpdateMode`.
bool _isDirectUpdateMode(Object? mode) => mode == 'reset' || mode == 'none';

/// core.datasetController.js:230 `cloneIfNotShared`.
///
/// The copy is [copyOptions]: it keeps the class of the options (Chart.js
/// ADR 0021, section 3).
// DIVERGES(chartjs): adapt-typed-element-options, the copy keeps the class.
AnyObject _cloneIfNotShared(AnyObject cached, bool shared) =>
    shared ? cached : copyOptions(cached);

/// core.datasetController.js:231 `createStack`.
///
/// Dart `null` stands for each falsy result of the `&&` chain.
DatasetStack? _createStack(
  Object? canStack,
  types.ChartMeta meta,
  types.Chart chart,
) => jsTruthy(canStack) && !jsTruthy(meta.hidden) && jsTruthy(meta.stacked)
    ? DatasetStack(_getSortedDatasetIndices(chart, true), null)
    : null;

/// core.datasetController.js:231-232 and :597-600 the object `{keys,
/// values}` of `createStack` and of the method `applyStack`.
///
/// `updateRangeFromParsed` writes [values] (:612).
final class DatasetStack {
  /// The object `{keys, values}`.
  DatasetStack(this.keys, this.values);

  /// `keys`: the indices of the visible datasets in the drawing order
  /// (`getSortedDatasetIndices`).
  final List<double> keys;

  /// `values`: the values of the stack by the `ToString` of the dataset
  /// index. Dart `null` stands for the JS `null` of `createStack`. The
  /// [undefined] sentinel stands for an absent `_visualValues`.
  Object? values;
}

/// core.datasetController.js:629 the object `{min, max}` of `getMinMax`.
final class _Range implements MinMax {
  _Range(this.min, this.max);

  @override
  double min;

  @override
  double max;
}

/// The value of the data elements at [DatasetController._insertElements]
/// between the move of the elements and the new elements. The new elements
/// replace it at once.
final Element _hole = Element();

/// The JS read `list[index]` of a list of objects: Dart `null` for an index
/// that names no item, JS `undefined`.
T? _at<T extends Object>(List<T> list, double index) {
  if (index >= 0 && index < list.length) {
    final i = index.toInt();
    if (i == index) return list[i];
  }
  return null;
}

/// The JS read `data[index]` of a data array: [undefined] for an index that
/// names no item.
Object? _item(List<Object?> data, double index) {
  if (index >= 0 && index < data.length) {
    final i = index.toInt();
    if (i == index) return data[i];
  }
  return undefined;
}

/// The JS read `object[index]` for a number [index]: the item of a List
/// without the `ToString` of the key, else [jsGet].
Object? _getIndex(Object? object, double index) =>
    object is List<Object?> ? _item(object, index) : jsGet(object, index);

/// The property keys `'0'` to `'63'`.
final List<String> _indexKeys = [
  for (var i = 0; i < 64; i++) jsNumberToString(i),
];

/// The property key of the number [index], the `ToPropertyKey` of
/// `object[index]`: a cached key for a small dataset index, else
/// [jsNumberToString].
String _indexKey(double index) {
  if (index >= 0 && index < _indexKeys.length) {
    final i = index.toInt();
    if (i == index) return _indexKeys[i];
  }
  return jsNumberToString(index);
}

/// The JS write `list[index] = value`: a write at the length appends.
///
/// Upstream leaves a hole for an index after the length. Dart throws a
/// [RangeError]. `parse` writes the items in order from its start.
/// `_resyncElements` gives a start at most the length. `_insertElements`
/// gives the start of the caller of `onDataSplice`, which can be past the
/// length (differences.md row `platform-array-events`).
void _setAt<T>(List<T> list, int index, T value) {
  if (index == list.length) {
    list.add(value);
  } else {
    list[index] = value;
  }
}

/// The JS read `item[key]` of a parsed item: the Map read for a Map, else
/// [jsGet].
///
/// A parsed item is any value (index.d.ts:473). [jsGet] gives [undefined]
/// for a number or a boolean, and throws a [TypeError] for `null` and
/// [undefined]. The Map read gives Dart `null` for an absent key, where
/// JavaScript gives `undefined`. The callers test the value with
/// `isFinite`, `isNullOrUndef` or the truthiness, which give the same
/// result for both. The Map read is the fast path of the hot loops.
Object? _parsedValue(Object? item, String key) =>
    item is Map<dynamic, dynamic> ? item[key] : jsGet(item, key);

/// The JavaScript relational comparison `a < b` (ECMAScript 7.2.13).
///
/// Two numbers compare as numbers, two strings by their code units, and
/// other values by their `ToNumber` after `ToPrimitive`.
bool _lessThan(Object? a, Object? b) {
  if (a is num && b is num) return a < b;
  final pa = _toPrimitive(a);
  final pb = _toPrimitive(b);
  if (pa is String && pb is String) return pa.compareTo(pb) < 0;
  return jsToNumber(pa) < jsToNumber(pb);
}

/// `ToPrimitive(value)` of a value without `valueOf`: an object gives its
/// `ToString`.
Object? _toPrimitive(Object? value) => switch (value) {
  null || Undefined() || bool() || num() || String() => value,
  _ => jsToString(value),
};

/// `this.datasetElementType.id` and `this.dataElementType.id`
/// (core.datasetController.js:789, :798, Chart.js ADR 0020, section 4).
///
/// A class value gives its typed `id`. Another value gives its property
/// `id`. Dart `null` (JS `null`) throws a [TypeError], as in JavaScript.
Object? _idOf(Object? elementType) =>
    elementType is JsClass ? elementType.id : jsGet(elementType, 'id');

/// `console.warn(message)`.
void _consoleWarn(String message) {
  // console.warn has no other counterpart in this layer.
  // ignore: avoid_print
  print(message);
}

/// The `chart` and `datasetIndex` of `new ControllerClass(chart,
/// datasetIndex)` from the arguments [args] of the `construct` closure of a
/// controller class value (Chart.js ADR 0020, sections 3 and 4).
///
/// The first argument must be a `types.Chart`. Another value throws a
/// [TypeError]. Upstream reads `chart.ctx` and calls
/// `chart.getDatasetMeta`: an object with these members also works there.
/// The second argument gives its `ToNumber`, NaN for an absent argument.
// DIVERGES(chartjs): adapt-component-class-role, a non-Chart chart throws.
@internal
({types.Chart chart, double datasetIndex}) controllerArgs(List<Object?> args) {
  final chart = args.isEmpty ? undefined : args[0];
  final datasetIndex = args.length < 2 ? undefined : args[1];
  return switch (chart) {
    final types.Chart value => (
      chart: value,
      datasetIndex: jsToNumber(datasetIndex),
    ),
    // A JavaScript TypeError: a property read of a value without the
    // members of a chart.
    _ => throw TypeError(),
  };
}

/// core.datasetController.js:234 `DatasetController`.
class DatasetController
    with ArrayListener<Object?>
    implements types.DatasetController {
  /// core.datasetController.js:255 `constructor(chart, datasetIndex)`.
  ///
  /// @param {Chart} chart
  /// @param {number} datasetIndex
  ///
  /// [newTarget] is `new.target` (Chart.js ADR 0020, section 4). A direct
  /// Dart call without it stands for `new DatasetController(chart,
  /// datasetIndex)`. The instance fields `datasetElementType` and
  /// `dataElementType` copy the statics of `new.target`.
  ///
  /// The fields with a start value get it before the body, and the body
  /// reads the meta. A subclass that overrides [getMeta] thus sees the start
  /// values of upstream.
  DatasetController(this.chart, double datasetIndex, [JsClass? newTarget])
    : ctx = chart.ctx,
      index = datasetIndex {
    cachedMeta = getMeta();
    type = cachedMeta.type;
    final target = newTarget ?? jsClass;
    datasetElementType = target['datasetElementType'];
    dataElementType = target['dataElementType'];

    initialize();
  }

  /// core.datasetController.js:239 `static defaults = {}`.
  static final AnyObject defaults = {};

  /// core.datasetController.js:234 `class DatasetController` as a value
  /// (Chart.js ADR 0020, section 3).
  ///
  /// Its statics are [defaults], `datasetElementType` and `dataElementType`,
  /// in that order (:239-249). The last two are JS `null`: the element types
  /// that generate a meta dataset (e.g. `Chart.element.LineElement`) and a
  /// meta data (e.g. `Chart.element.PointElement`). They are only properties
  /// of the class value, because the instance has members of the same names
  /// (Chart.js ADR 0020, section 3). Its `construct` gives `newTarget` to the
  /// constructor. Thus a registered subclass value without a Dart class
  /// constructs a [DatasetController] with its own class value as
  /// `new.target`.
  static final JsClass jsClass = JsClass(
    'DatasetController',
    statics: {
      'defaults': defaults,
      'datasetElementType': null,
      'dataElementType': null,
    },
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return DatasetController(chart, datasetIndex, newTarget);
    },
  );

  /// core.datasetController.js:256 `chart` (index.d.ts:600).
  final types.Chart chart;

  /// core.datasetController.js:257 `_ctx`, the context of the chart.
  /// controller.bar.js:677 reads it. Dart `null` stands for the JS `null` of
  /// a chart without a context.
  @internal
  final CanvasRenderingContext2D? ctx;

  /// core.datasetController.js:258 `index`, the dataset index
  /// (index.d.ts:601). [updateIndex] writes it.
  @override
  double index;

  /// core.datasetController.js:259 `_cachedDataOpts`: the cached element
  /// options by `elementType-mode` and the cached animations by
  /// `animation-transition`.
  AnyObject _cachedDataOpts = {};

  /// core.datasetController.js:260 `_cachedMeta`, the meta of the dataset
  /// (index.d.ts:602).
  @internal
  @override
  late final types.ChartMeta cachedMeta;

  /// core.datasetController.js:261 `_type`, the dataset type of the meta.
  /// controller.bar.js:436 and controller.doughnut.js:189 read it.
  @internal
  late final String type;

  /// core.datasetController.js:262 `options`, the resolver of the dataset
  /// options. [configure] assigns it.
  ///
  /// The constructor calls [initialize], which calls [configure] first.
  /// Thus no reader finds the `undefined` start value.
  late AnyObject options;

  /// core.datasetController.js:264 `_parsing`, the `parsing` option: `false`
  /// or an object of the parsing keys. `@type {boolean | object}`.
  @internal
  @override
  Object? parsing = false;

  /// core.datasetController.js:265 `_data`: the data array, or the array of
  /// `convertObjectDataToArray` for object data. Dart `null` stands for JS
  /// `undefined`.
  List<Object?>? _data;

  // core.datasetController.js:266 `this._objectData = undefined`: no
  // upstream code reads `_objectData`. Thus the port has no field.

  /// core.datasetController.js:267 `_sharedOptions`, the options that all
  /// data elements share (Chart.js ADR 0021, section 3).
  /// `core.interaction.js:49` reads it. Dart `null` stands for JS
  /// `undefined`, the start value.
  @internal
  @override
  AnyObject? sharedOptions;

  /// core.datasetController.js:268 `_drawStart`: the first data element of
  /// [draw]. controller.line.js:48 writes it. Dart `null` stands for JS
  /// `undefined`.
  @internal
  double? drawStart;

  /// core.datasetController.js:269 `_drawCount`: the count of data elements
  /// of [draw]. controller.line.js:49 writes it. Dart `null` stands for JS
  /// `undefined`.
  @internal
  double? drawCount;

  /// core.datasetController.js:270 `enableOptionSharing`.
  bool enableOptionSharing = false;

  /// core.datasetController.js:271 `supportsDecimation`.
  bool supportsDecimation = false;

  /// core.datasetController.js:272 `$context`, the dataset context of
  /// [getContext]. Dart `null` stands for JS `undefined`.
  AnyObject? $context;

  /// core.datasetController.js:273 `_syncList`: the array changes
  /// `[method, start, count]` until the next [_resyncElements].
  List<List<Object?>> _syncList = [];

  /// core.datasetController.js:274 `datasetElementType`: the class value of
  /// the dataset element, `false`, or Dart `null` for JS `null` (Chart.js
  /// ADR 0020, section 4). controller.scatter.js:94 and :105 write it.
  Object? datasetElementType;

  /// core.datasetController.js:275 `dataElementType`: the class value of
  /// the data elements, or Dart `null` for JS `null`.
  Object? dataElementType;

  /// core.datasetController.js:280 `initialize()`.
  void initialize() {
    final meta = cachedMeta;
    configure();
    linkScales();
    meta.stacked = _isStacked(meta.vScale, meta);
    addElements();

    if (jsTruthy(jsGet(options, 'fill')) && !chart.isPluginEnabled('filler')) {
      _consoleWarn(
        "Tried to use the 'fill' option without the 'Filler' plugin enabled. "
        "Please import and register the 'Filler' plugin and make sure it is "
        'not disabled in the options',
      );
    }
  }

  /// core.datasetController.js:292 `updateIndex(datasetIndex)`.
  void updateIndex(double datasetIndex) {
    if (index != datasetIndex) {
      _clearStacks(cachedMeta);
    }
    index = datasetIndex;
  }

  /// core.datasetController.js:299 `linkScales()`.
  ///
  /// An axis id is a string (index.d.ts:459-463). An id of another type is
  /// outside the upstream type contract: the write throws an
  /// [ArgumentError].
  void linkScales() {
    final chart = this.chart;
    final meta = cachedMeta;
    final dataset = getDataset();

    String? chooseId(String? axis, String? x, String? y, String? r) =>
        axis == 'x'
        ? x
        : axis == 'r'
        ? r
        : y;

    final xid = meta.xAxisID = _axisId(
      valueOrDefault(
        jsGet(dataset, 'xAxisID'),
        _getFirstScaleId(chart, 'x') ?? undefined,
      ),
    );
    final yid = meta.yAxisID = _axisId(
      valueOrDefault(
        jsGet(dataset, 'yAxisID'),
        _getFirstScaleId(chart, 'y') ?? undefined,
      ),
    );
    final rid = meta.rAxisID = _axisId(
      valueOrDefault(
        jsGet(dataset, 'rAxisID'),
        _getFirstScaleId(chart, 'r') ?? undefined,
      ),
    );
    final indexAxis = meta.indexAxis;
    final iid = meta.iAxisID = chooseId(indexAxis, xid, yid, rid);
    final vid = meta.vAxisID = chooseId(indexAxis, yid, xid, rid);
    meta
      ..xScale = getScaleForId(xid)
      ..yScale = getScaleForId(yid)
      ..rScale = getScaleForId(rid)
      ..iScale = getScaleForId(iid)
      ..vScale = getScaleForId(vid);
  }

  /// The axis id [value] of [linkScales] as the `String?` of the meta: Dart
  /// `null` for JS `undefined` and `null`.
  String? _axisId(Object? value) => switch (value) {
    null || Undefined() => null,
    final String id => id,
    _ => throw ArgumentError.value(value, 'axisID', 'Not a string'),
  };

  /// core.datasetController.js:319 `getDataset()`.
  ///
  /// The dataset `chart.data.datasets[index]`: a Map, or [undefined] for an
  /// index that names no dataset.
  Object? getDataset() {
    return _getIndex(jsGet(chart.data, 'datasets'), index);
  }

  /// core.datasetController.js:323 `getMeta()`.
  types.ChartMeta getMeta() {
    return chart.getDatasetMeta(index);
  }

  /// core.datasetController.js:331 `getScaleForId(scaleID)`.
  ///
  /// @param {string} scaleID
  /// @return {Scale}
  ///
  /// Dart `null` for [scaleID] and for the result stands for JS
  /// `undefined`.
  types.Scale? getScaleForId(String? scaleID) {
    return chart.scales[scaleID];
  }

  /// core.datasetController.js:338 `_getOtherScale(scale)`.
  /// @private
  types.Scale? _getOtherScale(types.Scale scale) {
    final meta = cachedMeta;
    return identical(scale, meta.iScale) ? meta.vScale : meta.iScale;
  }

  /// core.datasetController.js:345 `reset()`.
  void reset() {
    update_('reset');
  }

  /// core.datasetController.js:352 `_destroy()`. core.controller.js:922
  /// calls it.
  /// @private
  @internal
  void destroy() {
    final meta = cachedMeta;
    final data = _data;
    if (data != null) {
      unlistenArrayEvents(data, this);
    }
    if (jsTruthy(meta.stacked)) {
      _clearStacks(meta);
    }
  }

  /// core.datasetController.js:365 `_dataCheck()`.
  /// @private
  ///
  /// A truthy `data` that is neither a Map nor a `List` is outside the
  /// upstream type contract: the cast throws a [TypeError].
  void _dataCheck() {
    final dataset = getDataset();
    var data = jsGet(dataset, 'data');
    if (!jsTruthy(data)) {
      (dataset! as AnyObject)['data'] = data = <Object?>[];
    }
    final oldData = _data;

    // In order to correctly handle data addition/deletion animation (and
    // thus simulate real-time charts), we need to monitor these data
    // modifications and synchronize the internal metadata accordingly.

    if (isObject(data)) {
      final meta = cachedMeta;
      _data = _convertObjectDataToArray(data! as AnyObject, meta);
    } else if (!identical(oldData, data)) {
      if (oldData != null) {
        // This case happens when the user replaced the data array instance.
        unlistenArrayEvents(oldData, this);
        // Discard old parsed data and stacks
        final meta = cachedMeta;
        _clearStacks(meta);
        meta.parsed = <Object?>[];
      }
      final array = data! as List<Object?>;
      // A Dart List has no extensibility state: `Object.isExtensible(data)`
      // is true for each data List.
      // DIVERGES(chartjs): platform-array-events, each List is extensible.
      listenArrayEvents(array, this);
      _syncList = [];
      _data = array;
    }
  }

  /// core.datasetController.js:394 `addElements()`.
  void addElements() {
    final meta = cachedMeta;

    _dataCheck();

    final datasetElementType = this.datasetElementType;
    if (jsTruthy(datasetElementType)) {
      // DIVERGES(chartjs): adapt-component-class-role, the cast throws earlier.
      meta.dataset = jsConstruct(datasetElementType, const []) as Element;
    }
  }

  /// core.datasetController.js:404 `buildOrUpdateElements(resetNewElements)`.
  ///
  /// Dart `null` for [resetNewElements] stands for JS `undefined`.
  void buildOrUpdateElements([
    // The upstream signature has a positional `resetNewElements`.
    // ignore: avoid_positional_boolean_parameters
    bool? resetNewElements,
  ]) {
    final meta = cachedMeta;
    final dataset = getDataset();
    var stackChanged = false;

    _dataCheck();

    // make sure cached _stacked status is current
    final oldStacked = meta.stacked;
    meta.stacked = _isStacked(meta.vScale, meta);

    // detect change in stack option
    // `!==`: Dart `!=` gives its result for the JS values of the option.
    if (meta.stack != jsGet(dataset, 'stack')) {
      stackChanged = true;
      // remove values from old stack
      _clearStacks(meta);
      meta.stack = jsGet(dataset, 'stack');
    }

    // Re-sync meta data in case the user replaced the data array or if we
    // missed any updates and so make sure that we handle number of
    // datapoints changing.
    _resyncElements(resetNewElements);

    // if stack changed, update stack values for the whole dataset
    if (stackChanged || oldStacked != meta.stacked) {
      _updateStacks(this, meta.parsed);
      meta.stacked = _isStacked(meta.vScale, meta);
    }
  }

  /// core.datasetController.js:438 `configure()`.
  ///
  /// Merges user-supplied and default dataset-level options
  /// @private
  void configure() {
    final config = chart.config as Config;
    final scopeKeys = config.datasetScopeKeys(type);
    final scopes = config.getOptionScopes(getDataset(), scopeKeys, true);
    options = config.createResolver(scopes, getContext());
    parsing = jsGet(options, 'parsing');
    _cachedDataOpts = {};
  }

  /// core.datasetController.js:451 `parse(start, count)`.
  ///
  /// @param {number} start
  /// @param {number} count
  ///
  /// [start] and [count] are integers: [start] is at most the count of the
  /// parsed items.
  void parse(double start, double count) {
    final meta = cachedMeta;
    final data = _data!;
    final iScale = meta.iScale!;
    final stacked = meta.stacked;
    final iAxis = iScale.axis;

    var sorted = (start == 0 && count == data.length) || meta.sorted;
    // `start > 0 && meta._parsed[start - 1]`.
    var prev = start > 0 ? _item(meta.parsed, start - 1) : false;
    int i;
    Object? cur;
    List<Object?> parsed;

    if (parsing == false) {
      // The data items are the parsed items, of any type (index.d.ts:473).
      meta
        ..parsed = parsed = data
        ..sorted = true;
    } else {
      final first = _item(data, start);
      if (isArray(first)) {
        parsed = parseArrayData(meta, data, start, count);
      } else if (isObject(first)) {
        parsed = parseObjectData(meta, data, start, count);
      } else {
        parsed = parsePrimitiveData(meta, data, start, count);
      }

      bool isNotInOrderComparedToPrev() =>
          jsGet(cur, iAxis) == null ||
          (jsTruthy(prev) && _lessThan(jsGet(cur, iAxis), jsGet(prev, iAxis)));
      final parsedItems = meta.parsed;
      final offset = start.toInt();
      for (i = 0; i < count; ++i) {
        _setAt(parsedItems, i + offset, cur = parsed[i]);
        if (sorted) {
          if (isNotInOrderComparedToPrev()) {
            sorted = false;
          }
          prev = cur;
        }
      }
      meta.sorted = sorted;
    }

    if (jsTruthy(stacked)) {
      _updateStacks(this, parsed);
    }
  }

  /// core.datasetController.js:502 `parsePrimitiveData(meta, data, start,
  /// count)`.
  ///
  /// Parse array of primitive values
  /// @param {object} meta - dataset meta
  /// @param {array} data - data array. Example [1,3,4]
  /// @param {number} start - start index
  /// @param {number} count - number of items to parse
  /// @returns {object} parsed item - item containing index and a parsed
  /// value for each scale id.
  /// Example: {xScale0: 0, yScale0: 1}
  /// @protected
  ///
  /// With one scale for both axes, the item has one key: the second key of
  /// the object literal replaces the first.
  List<AnyObject> parsePrimitiveData(
    types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    final iScale = meta.iScale!;
    final vScale = meta.vScale!;
    final iAxis = iScale.axis;
    final vAxis = vScale.axis;
    final labels = iScale.getLabels();
    final singleScale = identical(iScale, vScale);
    final parsed = <AnyObject>[];
    double index;

    for (var i = 0, ilen = count.toInt(); i < ilen; ++i) {
      index = i + start;
      parsed.add(<String, Object?>{
        // `singleScale || iScale.parse(...)`.
        iAxis: singleScale
            ? singleScale
            : iScale.parse(_item(labels, index), index),
        vAxis: vScale.parse(_item(data, index), index),
      });
    }
    return parsed;
  }

  /// core.datasetController.js:532 `parseArrayData(meta, data, start,
  /// count)`.
  ///
  /// Parse array of arrays
  /// @param {object} meta - dataset meta
  /// @param {array} data - data array. Example [[1,2],[3,4]]
  /// @param {number} start - start index
  /// @param {number} count - number of items to parse
  /// @returns {object} parsed item - item containing index and a parsed
  /// value for each scale id.
  /// Example: {x: 0, y: 1}
  /// @protected
  List<AnyObject> parseArrayData(
    types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    final xScale = meta.xScale!;
    final yScale = meta.yScale!;
    final parsed = <AnyObject>[];
    double index;
    Object? item;

    for (var i = 0, ilen = count.toInt(); i < ilen; ++i) {
      index = i + start;
      item = _item(data, index);
      parsed.add(<String, Object?>{
        'x': xScale.parse(jsGet(item, '0'), index),
        'y': yScale.parse(jsGet(item, '1'), index),
      });
    }
    return parsed;
  }

  /// core.datasetController.js:559 `parseObjectData(meta, data, start,
  /// count)`.
  ///
  /// Parse array of objects
  /// @param {object} meta - dataset meta
  /// @param {array} data - data array. Example [{x:1, y:5}, {x:2, y:10}]
  /// @param {number} start - start index
  /// @param {number} count - number of items to parse
  /// @returns {object} parsed item - item containing index and a parsed
  /// value for each scale id. _custom is optional
  /// Example: {xScale0: 0, yScale0: 1, _custom: {r: 10, foo: 'bar'}}
  /// @protected
  ///
  /// The keys `xAxisKey` and `yAxisKey` of [parsing] default to `'x'` and
  /// `'y'`. A key that is not a string throws a [TypeError].
  List<AnyObject> parseObjectData(
    types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    final xScale = meta.xScale!;
    final yScale = meta.yScale!;
    final xAxisKey = _keyOr(jsGet(parsing, 'xAxisKey'), 'x');
    final yAxisKey = _keyOr(jsGet(parsing, 'yAxisKey'), 'y');
    final parsed = <AnyObject>[];
    double index;
    Object? item;

    for (var i = 0, ilen = count.toInt(); i < ilen; ++i) {
      index = i + start;
      item = _item(data, index);
      parsed.add(<String, Object?>{
        'x': xScale.parse(resolveObjectKey(item, xAxisKey), index),
        'y': yScale.parse(resolveObjectKey(item, yAxisKey), index),
      });
    }
    return parsed;
  }

  /// The parsing key [value] of the destructuring `{xAxisKey = 'x'}`:
  /// [fallback] for [undefined].
  String _keyOr(Object? value, String fallback) =>
      identical(value, undefined) ? fallback : value! as String;

  /// core.datasetController.js:579 `getParsed(index)`.
  /// @protected
  ///
  /// A parsed item is any value (`unknown[]`, index.d.ts:473): a Map of the
  /// `parse*Data` methods, a data item with `parsing: false`, or a number of
  /// a controller that writes numbers (controller.doughnut.js:150, :161).
  /// An index that names no parsed item gives [undefined]. Dart `null` is a
  /// JS `null` item.
  Object? getParsed(double index) {
    return _item(cachedMeta.parsed, index);
  }

  /// core.datasetController.js:586 `getDataElement(index)`.
  /// @protected
  ///
  /// Dart `null` stands for the JS `undefined` of an index that names no
  /// element.
  types.Element? getDataElement(double index) {
    return _at(cachedMeta.data, index);
  }

  /// core.datasetController.js:593 `applyStack(scale, parsed, mode)`.
  /// @protected
  ///
  /// [mode] is the `_stacked` value of the meta, for example `'single'`. The
  /// result is the upstream result: [undefined] for a `null` value, else a
  /// number, or a string for a string value.
  Object? applyStack(types.Scale scale, Object? parsed, [Object? mode]) {
    final chart = this.chart;
    final meta = cachedMeta;
    final value = jsGet(parsed, scale.axis);
    final stack = DatasetStack(
      _getSortedDatasetIndices(chart, true),
      jsGet(jsGet(jsGet(parsed, '_stacks'), scale.axis), '_visualValues'),
    );
    return _applyStack(stack, value, meta.index, mode: mode);
  }

  /// core.datasetController.js:607 `updateRangeFromParsed(range, scale,
  /// parsed, stack)`.
  /// @protected
  ///
  /// Dart `null` for [stack] stands for the falsy values of `createStack`.
  void updateRangeFromParsed(
    MinMax range,
    types.Scale scale,
    Object? parsed,
    DatasetStack? stack,
  ) {
    final parsedValue = jsGet(parsed, scale.axis);
    // `parsedValue === null ? NaN : parsedValue`.
    Object? value = parsedValue ?? double.nan;
    final values = stack == null
        ? null
        : jsGet(jsGet(parsed, '_stacks'), scale.axis);
    if (stack != null && jsTruthy(values)) {
      stack.values = values;
      value = _applyStack(stack, parsedValue, cachedMeta.index);
    }
    // Math.min and Math.max read the value with ToNumber.
    final number = jsToNumber(value);
    range
      ..min = jsMin(range.min, number)
      ..max = jsMax(range.max, number);
  }

  /// core.datasetController.js:622 `getMinMax(scale, canStack)`.
  /// @protected
  ///
  /// Dart `null` for [canStack] stands for JS `undefined`. The result is a
  /// record of the object `{min, max}`. A parsed value of the other scale
  /// compares with the user bounds through `ToNumber`, as the JavaScript
  /// `>` and `<` do.
  @override
  ({double min, double max}) getMinMax(types.Scale scale, [bool? canStack]) {
    final meta = cachedMeta;
    final parsedItems = meta.parsed;
    final sorted = meta.sorted && identical(scale, meta.iScale);
    final ilen = parsedItems.length;
    final otherScale = _getOtherScale(scale)!;
    final stack = _createStack(canStack, meta, chart);
    final range = _Range(double.infinity, double.negativeInfinity);
    final (min: otherMin, max: otherMax) = _getUserBounds(otherScale);
    var i = 0;
    Object? parsed;

    bool skip() {
      parsed = parsedItems[i];
      final otherValue = jsToNumber(jsGet(parsed, otherScale.axis));
      return !isFinite(_parsedValue(parsed, scale.axis)) ||
          otherMin > otherValue ||
          otherMax < otherValue;
    }

    for (i = 0; i < ilen; ++i) {
      if (skip()) {
        continue;
      }
      updateRangeFromParsed(range, scale, parsed, stack);
      if (sorted) {
        // if the data is sorted, we don't need to check further from this
        // end of array
        break;
      }
    }
    if (sorted) {
      // in the sorted case, find first non-skipped value from other end of
      // array
      for (i = ilen - 1; i >= 0; --i) {
        if (skip()) {
          continue;
        }
        updateRangeFromParsed(range, scale, parsed, stack);
        break;
      }
    }
    return (min: range.min, max: range.max);
  }

  /// core.datasetController.js:662 `getAllParsedValues(scale)`.
  List<double> getAllParsedValues(types.Scale scale) {
    final parsed = cachedMeta.parsed;
    final values = <double>[];
    Object? value;

    for (var i = 0, ilen = parsed.length; i < ilen; ++i) {
      value = _parsedValue(parsed[i], scale.axis);
      if (isFinite(value)) {
        values.add((value! as num).toDouble());
      }
    }
    return values;
  }

  /// core.datasetController.js:680 `getMaxOverflow()`.
  ///
  /// @return {number|boolean}
  /// @protected
  Object? getMaxOverflow() {
    return false;
  }

  /// core.datasetController.js:687 `getLabelAndValue(index)`.
  /// @protected
  ///
  /// The result is a record of the object `{label, value}`. `'' + value` is
  /// [jsToString].
  ({String label, String value}) getLabelAndValue(double index) {
    final meta = cachedMeta;
    final iScale = meta.iScale;
    final vScale = meta.vScale;
    final parsed = getParsed(index);
    return (
      label: iScale != null
          ? jsToString(iScale.getLabelForValue(jsGet(parsed, iScale.axis)))
          : '',
      value: vScale != null
          ? jsToString(vScale.getLabelForValue(jsGet(parsed, vScale.axis)))
          : '',
    );
  }

  /// core.datasetController.js:701 `_update(mode)`. core.controller.js:677
  /// calls it. The name has a trailing underscore, because [update] has the
  /// name without the leading underscore (Chart.js ADR 0023).
  /// @private
  ///
  /// Dart `null` for [mode] stands for JS `undefined`.
  @internal
  void update_([String? mode]) {
    final meta = cachedMeta;
    update(mode == null || mode.isEmpty ? 'default' : mode);
    meta.clip = _toClip(
      valueOrDefault(
        jsGet(options, 'clip'),
        _defaultClip(meta.xScale, meta.yScale, getMaxOverflow()),
      ),
    );
  }

  /// core.datasetController.js:710 `update(mode)`.
  ///
  /// @param {string} mode
  void update(String mode) {} // eslint-disable-line no-unused-vars

  /// core.datasetController.js:712 `draw()`.
  ///
  /// The dataset element gets `start` and `count` through [jsCall]: a line
  /// element takes them, and another element ignores them, as a JavaScript
  /// call ignores an extra argument. The port casts the elements to
  /// `types.VisualElement` for their `draw`.
  void draw() {
    final ctx = this.ctx;
    final chart = this.chart;
    final meta = cachedMeta;
    final elements = meta.data;
    final area = chart.chartArea;
    final active = <Element>[];
    final start = jsOrZero(drawStart);
    final count = jsTruthy(drawCount) ? drawCount! : elements.length - start;
    final drawActiveElementsOnTop = jsTruthy(
      jsGet(options, 'drawActiveElementsOnTop'),
    );
    double i;

    final dataset = meta.dataset;
    if (dataset != null) {
      jsCall((dataset as types.VisualElement).draw, [ctx, area, start, count]);
    }

    for (i = start; i < start + count; ++i) {
      final element = _at(elements, i)! as Element;
      if (jsTruthy(element['hidden'])) {
        continue;
      }
      if (element.active && drawActiveElementsOnTop) {
        active.add(element);
      } else {
        (element as types.VisualElement).draw(ctx!, area);
      }
    }

    for (var k = 0; k < active.length; ++k) {
      (active[k] as types.VisualElement).draw(ctx!, area);
    }
  }

  /// core.datasetController.js:752 `getStyle(index, active)`.
  ///
  /// Returns a set of predefined style properties that should be used to
  /// represent the dataset or the data if the index is specified
  /// @param {number} index - data index
  /// @param {boolean} [active] - true if hover
  /// @return {object} style object
  ///
  /// Dart `null` for [index] and [active] stands for JS `undefined`.
  AnyObject getStyle(
    double? index, [
    // The upstream signature has a positional `active`.
    // ignore: avoid_positional_boolean_parameters
    bool? active,
  ]) {
    final mode = jsTruthy(active) ? 'active' : 'default';
    return index == null && cachedMeta.dataset != null
        ? resolveDatasetElementOptions(mode)
        : resolveDataElementOptions(jsOrZero(index), mode);
  }

  /// core.datasetController.js:762 `getContext(index, active, mode)`.
  /// @protected
  ///
  /// Dart `null` for [index], [active] and [mode] stands for JS `undefined`.
  /// An [index] of a data element gives the context of that element. It is
  /// an extra property `$context` of the element (Chart.js ADR 0017,
  /// section 5).
  AnyObject getContext([
    double? index,
    // The upstream signature has a positional `active`.
    // ignore: avoid_positional_boolean_parameters
    bool? active,
    String? mode,
  ]) {
    final dataset = getDataset();
    AnyObject context;
    if (index != null && index >= 0 && index < cachedMeta.data.length) {
      final element = _at(cachedMeta.data, index)! as Element;
      var elementContext = element[r'$context'];
      if (!jsTruthy(elementContext)) {
        element[r'$context'] = elementContext = _createDataContext(
          getContext(),
          index,
          element,
        );
      }
      context = elementContext! as AnyObject;
      context['parsed'] = getParsed(index);
      context['raw'] = _getIndex(jsGet(dataset, 'data'), index);
      context['index'] = context['dataIndex'] = index;
    } else {
      context = $context ??= _createDatasetContext(
        chart.getContext(),
        this.index,
      );
      context['dataset'] = dataset;
      context['index'] = context['datasetIndex'] = this.index;
    }

    context['active'] = jsTruthy(active);
    context['mode'] = mode ?? undefined;
    return context;
  }

  /// core.datasetController.js:788 `resolveDatasetElementOptions(mode)`.
  ///
  /// @param {string} [mode]
  /// @protected
  ///
  /// Dart `null` for [mode] stands for JS `undefined`.
  AnyObject resolveDatasetElementOptions([String? mode]) {
    return _resolveElementOptions(_idOf(datasetElementType), mode);
  }

  /// core.datasetController.js:797 `resolveDataElementOptions(index, mode)`.
  ///
  /// @param {number} index
  /// @param {string} [mode]
  /// @protected
  ///
  /// Dart `null` for [mode] stands for JS `undefined`.
  AnyObject resolveDataElementOptions(double index, [String? mode]) {
    return _resolveElementOptions(_idOf(dataElementType), mode, index);
  }

  /// core.datasetController.js:804 `_resolveElementOptions(elementType, mode
  /// = 'default', index)`.
  /// @private
  ///
  /// [elementType] is the `id` of the element class value: any value. Dart
  /// `null` for [mode] gives `'default'`. Dart `null` for [index] stands for
  /// JS `undefined`.
  ///
  /// The result object is the typed options class of [elementType]
  /// (`createElementOptions`, Chart.js ADR 0021, section 1).
  AnyObject _resolveElementOptions(
    Object? elementType, [
    String? mode,
    double? index,
  ]) {
    final resolvedMode = mode ?? 'default';
    final active = resolvedMode == 'active';
    final cache = _cachedDataOpts;
    final typeName = jsToString(elementType);
    final cacheKey = '$typeName-$resolvedMode';
    final cached = cache[cacheKey];
    final sharing = enableOptionSharing && index != null;
    if (cached != null) {
      return _cloneIfNotShared(cached as AnyObject, sharing);
    }
    final config = chart.config as Config;
    final scopeKeys = config.datasetElementScopeKeys(type, elementType);
    final prefixes = active
        ? ['${typeName}Hover', 'hover', typeName, '']
        : [typeName, ''];
    final scopes = config.getOptionScopes(getDataset(), scopeKeys);
    final names = jsObjectKeys(
      jsGet(core_defaults.defaults['elements'], elementType)! as AnyObject,
    );
    // context is provided as a function, and is called only if needed,
    // so we don't create a context for each element if not needed.
    AnyObject context() => getContext(index, active, resolvedMode);
    // DIVERGES(chartjs): adapt-typed-element-options, a typed result object.
    final values = config.resolveNamedOptions(
      scopes,
      names,
      context,
      prefixes,
      createElementOptions(elementType),
    );

    if (jsTruthy(values[r'$shared'])) {
      // `$shared` indicates this set of options can be shared between
      // multiple elements. Sharing is used to reduce number of properties
      // to change during animation.
      values[r'$shared'] = sharing;

      // We cache options by `mode`, which can be 'active' for example. This
      // enables us to have the 'active' element options and 'default'
      // options to switch between when interacting.
      cache[cacheKey] = jsObjectFreeze(_cloneIfNotShared(values, sharing));
    }

    return values;
  }

  /// core.datasetController.js:841 `_resolveAnimations(index, transition,
  /// active)`. core.controller.js:895 calls it.
  /// @private
  ///
  /// Dart `null` for each parameter stands for JS `undefined`.
  /// `Object.freeze` of the cached animations is [jsObjectFreeze]. It
  /// leaves an `Animations` as it is (differences.md
  /// `js-semantics-object-freeze`).
  @internal
  Animations resolveAnimations([
    double? index,
    String? transition,
    // The upstream signature has a positional `active`.
    // ignore: avoid_positional_boolean_parameters
    bool? active,
  ]) {
    final chart = this.chart;
    final cache = _cachedDataOpts;
    final cacheKey = 'animation-${transition ?? 'undefined'}';
    final cached = cache[cacheKey];
    if (cached != null) {
      return cached as Animations;
    }
    AnyObject? options;
    if (jsGet(chart.options, 'animation') != false) {
      final config = this.chart.config as Config;
      final scopeKeys = config.datasetAnimationScopeKeys(
        type,
        transition ?? undefined,
      );
      final scopes = config.getOptionScopes(getDataset(), scopeKeys);
      options = config.createResolver(
        scopes,
        getContext(index, active, transition),
      );
    }
    final animations = Animations(
      chart,
      options == null ? undefined : jsGet(options, 'animations'),
    );
    if (options != null && jsTruthy(jsGet(options, '_cacheable'))) {
      cache[cacheKey] = jsObjectFreeze(animations);
    }
    return animations;
  }

  /// core.datasetController.js:867 `getSharedOptions(options)`.
  ///
  /// Utility for getting the options object shared between elements
  /// @protected
  ///
  /// Dart `null` stands for the JS `undefined` result. The copy keeps the
  /// class of the options (Chart.js ADR 0021, section 3).
  AnyObject? getSharedOptions(AnyObject options) {
    if (!jsTruthy(options[r'$shared'])) {
      return null;
    }
    // DIVERGES(chartjs): adapt-typed-element-options, the copy keeps the class.
    return sharedOptions ??= copyOptions(options);
  }

  /// core.datasetController.js:878 `includeOptions(mode, sharedOptions)`.
  ///
  /// Utility for determining if `options` should be included in the updated
  /// properties
  /// @protected
  ///
  /// Dart `null` for [sharedOptions] stands for JS `undefined`.
  bool includeOptions(String mode, AnyObject? sharedOptions) {
    return sharedOptions == null ||
        _isDirectUpdateMode(mode) ||
        jsTruthy(chart.animationsDisabled);
  }

  /// core.datasetController.js:885 `_getSharedOptions(start, mode)`.
  /// controller.line.js:79 and the other controllers call it. The name has a
  /// trailing underscore, because [getSharedOptions] has the name without
  /// the leading underscore (Chart.js ADR 0023).
  ///
  /// @todo v4, rename to getSharedOptions and remove excess functions
  ///
  /// The result is a record of the object `{sharedOptions,
  /// includeOptions}`.
  @internal
  ({AnyObject? sharedOptions, bool includeOptions}) getSharedOptions_(
    double start,
    String mode,
  ) {
    final firstOpts = resolveDataElementOptions(start, mode);
    final previouslySharedOptions = this.sharedOptions;
    final sharedOptions = getSharedOptions(firstOpts);
    final includeOptions =
        this.includeOptions(mode, sharedOptions) ||
        !identical(sharedOptions, previouslySharedOptions);
    updateSharedOptions(sharedOptions, mode, firstOpts);
    return (sharedOptions: sharedOptions, includeOptions: includeOptions);
  }

  /// core.datasetController.js:898 `updateElement(element, index,
  /// properties, mode)`.
  ///
  /// Utility for updating an element with new properties, using animations
  /// when appropriate.
  /// @protected
  ///
  /// `Object.assign(element, properties)` is [Element.assign] (Chart.js ADR
  /// 0017, section 6). Dart `null` for [index] stands for JS `undefined`.
  void updateElement(
    Element element,
    double? index,
    AnyObject properties,
    String mode,
  ) {
    if (_isDirectUpdateMode(mode)) {
      element.assign(properties);
    } else {
      resolveAnimations(index, mode).update(element, properties);
    }
  }

  /// core.datasetController.js:910 `updateSharedOptions(sharedOptions, mode,
  /// newOptions)`.
  ///
  /// Utility to animate the shared options, that are potentially affecting
  /// multiple elements.
  /// @protected
  ///
  /// Dart `null` for [sharedOptions] stands for JS `undefined`.
  void updateSharedOptions(
    AnyObject? sharedOptions,
    String mode,
    AnyObject newOptions,
  ) {
    if (sharedOptions != null && !_isDirectUpdateMode(mode)) {
      resolveAnimations(null, mode).update(sharedOptions, newOptions);
    }
  }

  /// core.datasetController.js:919 `_setStyle(element, index, mode,
  /// active)`.
  /// @private
  void _setStyle(
    Element element,
    double? index,
    String mode,
    bool active,
  ) {
    element.active = active;
    final options = getStyle(index, active);
    resolveAnimations(index, mode, active).update(element, <String, Object?>{
      // When going from active to inactive, we need to update to the shared
      // options. This way the once hovered element will end up with the
      // same original shared options instance, after animation.
      'options': (!active ? getSharedOptions(options) : null) ?? options,
    });
  }

  /// core.datasetController.js:929 `removeHoverStyle(element, datasetIndex,
  /// index)`.
  void removeHoverStyle(Element element, double datasetIndex, double index) {
    _setStyle(element, index, 'active', false);
  }

  /// core.datasetController.js:933 `setHoverStyle(element, datasetIndex,
  /// index)`.
  void setHoverStyle(Element element, double datasetIndex, double index) {
    _setStyle(element, index, 'active', true);
  }

  /// core.datasetController.js:940 `_removeDatasetHoverStyle()`.
  /// core.controller.js:1072 calls it by name.
  /// @private
  @internal
  void removeDatasetHoverStyle() {
    final element = cachedMeta.dataset;

    if (element != null) {
      _setStyle(element as Element, null, 'active', false);
    }
  }

  /// core.datasetController.js:951 `_setDatasetHoverStyle()`.
  /// core.controller.js:1072 calls it by name.
  /// @private
  @internal
  void setDatasetHoverStyle() {
    final element = cachedMeta.dataset;

    if (element != null) {
      _setStyle(element as Element, null, 'active', true);
    }
  }

  /// core.datasetController.js:962 `_resyncElements(resetNewElements)`.
  /// @private
  ///
  /// Dart `null` for [resetNewElements] stands for JS `undefined`.
  void _resyncElements([bool? resetNewElements]) {
    final data = _data!;
    final elements = cachedMeta.data;

    // Apply changes detected through array listeners
    final syncList = _syncList;
    for (var k = 0; k < syncList.length; k++) {
      final args = syncList[k];
      _call(args[0], args[1], args[2]);
    }
    _syncList = [];

    final numMeta = elements.length;
    final numData = data.length;
    final count = jsMin(numData.toDouble(), numMeta.toDouble());

    if (count != 0) {
      // It is not optimal to always parse the old data
      // This is done because we are not detecting direct assignments:
      // chart.data.datasets[0].data[5] = 10;
      // chart.data.datasets[0].data[5].y = 10;
      parse(0, count);
    }

    if (numData > numMeta) {
      _insertElements(
        numMeta.toDouble(),
        (numData - numMeta).toDouble(),
        resetNewElements,
      );
    } else if (numData < numMeta) {
      _removeElements(numData.toDouble(), (numMeta - numData).toDouble());
    }
  }

  /// core.datasetController.js:994 `_insertElements(start, count,
  /// resetNewElements = true)`.
  /// @private
  ///
  /// Dart `null` for [resetNewElements] gives `true`. [onDataSplice] passes
  /// the start of its caller unchanged, as upstream does (:1064-1071), and
  /// the other callers compute [start] from the lengths. A [start] past the
  /// length throws a [RangeError] at the move, where upstream leaves holes
  /// (differences.md row `platform-array-events`).
  void _insertElements(
    double start,
    double count, [
    bool? resetNewElements,
  ]) {
    final meta = cachedMeta;
    final data = meta.data;
    final end = start + count;
    double i;

    // `arr.length += count` and the move of the items from `start` to
    // `end`. The items in `start..end` are replaced next.
    void move<T>(List<T> arr, T filler) {
      arr.insertAll(start.toInt(), List<T>.filled(count.toInt(), filler));
    }

    move<types.Element>(data, _hole);

    for (i = start; i < end; ++i) {
      // DIVERGES(chartjs): adapt-component-class-role, the cast throws earlier.
      data[i.toInt()] = jsConstruct(dataElementType, const []) as Element;
    }

    if (jsTruthy(parsing)) {
      // `arr.length += count` leaves holes, JS `undefined`.
      move<Object?>(meta.parsed, undefined);
    }
    parse(start, count);

    if (resetNewElements ?? true) {
      updateElements(data, start, count, 'reset');
    }
  }

  /// core.datasetController.js:1022 `updateElements(element, start, count,
  /// mode)`.
  void updateElements(
    List<types.Element> elements,
    double start,
    double count,
    String mode,
  ) {} // eslint-disable-line no-unused-vars

  /// core.datasetController.js:1027 `_removeElements(start, count)`.
  /// @private
  void _removeElements(double start, double count) {
    final meta = cachedMeta;
    if (jsTruthy(parsing)) {
      final removed = jsSplice(meta.parsed, start, count);
      if (jsTruthy(meta.stacked)) {
        _clearStacks(meta, removed);
      }
    }
    jsSplice(meta.data, start, count);
  }

  /// core.datasetController.js:1041 `_sync(args)`.
  /// @private
  ///
  /// [args] is `[method, start, count]`.
  void _sync(List<Object?> args) {
    if (jsTruthy(parsing)) {
      _syncList.add(args);
    } else {
      _call(args[0], args[1], args[2]);
    }
    chart.dataChanges.add([index, ...args]);
  }

  /// `this[method](arg1, arg2)` (core.datasetController.js:968, :1046): the
  /// call of `_insertElements` or `_removeElements` by its name. The two
  /// methods are private. No controller of upstream overrides them.
  void _call(Object? method, Object? arg1, Object? arg2) {
    switch (method) {
      case '_insertElements':
        _insertElements(jsToNumber(arg1), jsToNumber(arg2));
      case '_removeElements':
        _removeElements(jsToNumber(arg1), jsToNumber(arg2));
      default:
        // A JavaScript TypeError: this[method] is not a function.
        throw TypeError();
    }
  }

  /// core.datasetController.js:1051 `_onDataPush()`. `arguments.length` is
  /// the count of [items].
  @internal
  @override
  void onDataPush(List<Object?> items) {
    final count = items.length.toDouble();
    _sync([
      '_insertElements',
      jsToNumber(jsGet(jsGet(getDataset(), 'data'), 'length')) - count,
      count,
    ]);
  }

  /// core.datasetController.js:1056 `_onDataPop()`.
  @internal
  @override
  void onDataPop() {
    _sync(['_removeElements', cachedMeta.data.length - 1.0, 1.0]);
  }

  /// core.datasetController.js:1060 `_onDataShift()`.
  @internal
  @override
  void onDataShift() {
    _sync(['_removeElements', 0.0, 1.0]);
  }

  /// core.datasetController.js:1064 `_onDataSplice(start, count)`.
  ///
  /// [index] is `start`, [deleteCount] is `count`, and `arguments.length -
  /// 2` is the count of [items].
  @internal
  @override
  void onDataSplice(double index, double deleteCount, List<Object?> items) {
    if (jsTruthy(deleteCount)) {
      _sync(['_removeElements', index, deleteCount]);
    }
    final newCount = items.length;
    if (newCount != 0) {
      _sync(['_insertElements', index, newCount.toDouble()]);
    }
  }

  /// core.datasetController.js:1074 `_onDataUnshift()`. `arguments.length`
  /// is the count of [items].
  @internal
  @override
  void onDataUnshift(List<Object?> items) {
    _sync(['_insertElements', 0.0, items.length.toDouble()]);
  }
}
