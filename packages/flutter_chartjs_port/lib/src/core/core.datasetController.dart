// Ported from Chart.js v4.6.1 src/core/core.datasetController.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-parsed, the typed data of Chart.js ADR 0054.

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
/// - The parsed data is typed (Chart.js ADR 0054 §8): the parse functions
///   give a [ParsedItem] for each item, `item._stacks` is an [ItemStacks],
///   the stack objects of `getOrCreateStack` are [StackEntry] objects and
///   their `_visualValues` are [IndexValues]. The hot read of a parsed value
///   is [parsedValueOf] with the [ScaleAxis] of the scale. A parsed item of
///   another class (a data item of `parsing: false`) and a `_stacks` object
///   that user code gave read by name. The work objects `{keys, values}` of
///   the stacks and `{min, max}` of `getMinMax` are classes.
/// - The dataset options ([DatasetController.options]) are an [OptionView]
///   with typed reads ([readOption], Chart.js ADR 0054 §4). The options
///   of an element are the typed classes of `element_options.dart`
///   ([ElementOptions]).
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
///
/// This file imports `core.animations.dart`, which imports
/// `core.animator.dart`. Thus it is not a pure layer.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/chartjs.dart';
// The static defaults of DatasetController has the name of the module value.
import 'package:flutter_chartjs_port/chartjs.dart' as chartjs;
// DatasetController has a static `defaults`. Inside the class, upstream
// `defaults` is the import of core.defaults.js.
import 'package:meta/meta.dart';

/// core.datasetController.js:12 `scaleClip`.
///
/// `scale && scale.options || {}`: the options of a scale are always an
/// object. The edges are [allowedOverflow] or 0.
({double start, double end}) _scaleClip(IScale? scale, double allowedOverflow) {
  final opts = scale?.options ?? const <String, Object?>{};
  final reverse = readOption(opts, OptionKey.reverse);
  final min = identical(readOption(opts, OptionKey.min), undefined)
      ? allowedOverflow
      : 0.0;
  final max = identical(readOption(opts, OptionKey.max), undefined)
      ? allowedOverflow
      : 0.0;
  return (
    start: jsTruthy(reverse) ? max : min,
    end: jsTruthy(reverse) ? min : max,
  );
}

/// core.datasetController.js:23 `defaultClip`, with the `toClip` of its
/// result.
///
/// No overflow (Dart `null`, the JS `false`) gives [ChartClip.none].
// DIVERGES(chartjs): adapt-chart-clip-option, the edges are a ChartClip.
ChartClip _defaultClip(
  IScale? xScale,
  IScale? yScale,
  double? allowedOverflow,
) {
  if (allowedOverflow == null) {
    return ChartClip.none;
  }
  final x = _scaleClip(xScale, allowedOverflow);
  final y = _scaleClip(yScale, allowedOverflow);

  return ChartClip(top: y.end, right: x.end, bottom: y.start, left: x.start);
}

/// core.datasetController.js:59 `getSortedDatasetIndices`.
List<int> _getSortedDatasetIndices(IChart chart, bool filterVisible) {
  final keys = <int>[];
  final metasets = chart.getSortedDatasetMetas(filterVisible);

  for (var i = 0, ilen = metasets.length; i < ilen; ++i) {
    keys.add(metasets[i].index);
  }
  return keys;
}

/// core.datasetController.js:70 `applyStack(stack, value, dsIndex, options
/// = {})`.
///
/// [mode] and [all] are the keys of `options`: [mode] is the `_stacked`
/// value of the meta, and Dart `null` stands for JS `undefined`.
///
/// The result is the upstream result: Dart `null` for a `null` [value]
/// (the JS `undefined`), 0 when the stack does not contain [dsIndex], else
/// the sum. A value that is not a number adds its `ToNumber`, where upstream
/// appends the text of a string value (row `adapt-apply-stack-number`).
// DIVERGES(chartjs): adapt-apply-stack-number, the sum is a number.
double? _applyStack(
  DatasetStack stack,
  Object? value,
  int dsIndex, {
  StackMode? mode,
  bool all = false,
}) {
  final keys = stack.keys;
  final singleMode = mode == StackMode.single;
  int datasetIndex;
  Object? otherValue;

  if (value == null) {
    return null;
  }

  var sum = value is double ? value : jsToNumber(value);
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
    otherValue = _stackValueOf(stack.values, datasetIndex);
    if (isFinite(otherValue) &&
        (singleMode ||
            (sum == 0 || sign(sum) == sign(jsToNumber(otherValue))))) {
      // An add of a double and a num is a call in an AOT build (performance.md
      // §72). The sum is the same number.
      sum += otherValue is double ? otherValue : (otherValue! as int) * 1.0;
    }
  }

  if (!found && !all) {
    return 0;
  }

  return sum;
}

/// core.datasetController.js:102 `convertObjectDataToArray`.
///
/// [data] is the object `data` of the user: a Map, or an object with a face
/// (an object for `isObject`) that is not a Map, which reads its keys and
/// values through its face. `Object.keys` gives the JS key order. Each item
/// is a plain object of the data, as upstream: with `parsing: false` it is
/// the parsed item.
List<Object?> _convertObjectDataToArray(Object data, ChartMeta meta) {
  final iScale = meta.iScale!;
  final vScale = meta.vScale!;
  // `iScale.axis === 'x' ? 'x' : 'y'`: the keys of the plain data objects.
  final iAxisKey = iScale.axis is XAxis ? 'x' : 'y';
  final vAxisKey = vScale.axis is XAxis ? 'x' : 'y';
  final map = data is AnyObject ? data : null;
  final face = map == null ? data as JsObjectFace : null;
  final keys = map != null ? jsObjectKeys(map) : face!.jsKeys();
  final adata = <Object?>[];
  String key;
  for (var i = 0, ilen = keys.length; i < ilen; ++i) {
    key = keys[i];
    adata.add(<String, Object?>{
      iAxisKey: key,
      vAxisKey: map != null ? map[key] : face!.jsRead(key),
    });
  }
  return adata;
}

/// core.datasetController.js:119 `isStacked`.
///
/// `stacked || (stacked === undefined && meta.stack !== undefined)`.
// DIVERGES(chartjs): adapt-stacked-option-enum, the option is a
// [StackMode], and Dart `null` is `undefined`.
StackMode _isStacked(IScale? scale, ChartMeta meta) {
  final stacked = scale?.options.stacked;
  return stacked ?? (meta.stack != null ? StackMode.on : StackMode.off);
}

/// A `stack` or an axis id of a dataset as the value of the meta: Dart
/// `null` for JS `undefined` and `null`, else the string. The schema shape of
/// both is `string`: another value stops a debug build, and a release build
/// takes no id (row `adapt-native-chart-meta`, Chart.js ADR 0176).
String? metaStringOf(Object? value, String option) {
  if (value is String) return value;
  if (value == null || value is Undefined) return null;
  assert(false, 'The dataset option $option takes a String, not $value.');
  return null;
}

/// core.datasetController.js:124 `getStackKey`.
String _getStackKey(IScale indexScale, IScale valueScale, ChartMeta meta) {
  final stack = meta.stack;
  return '${indexScale.id}.${valueScale.id}.'
      '${stack != null && stack.isNotEmpty ? stack : meta.type}';
}

/// core.datasetController.js:128 `getUserBounds`.
({double min, double max}) _getUserBounds(IScale scale) {
  final (:min, :max, :minDefined, :maxDefined) = scale.getUserBounds();
  return (
    min: minDefined ? min : double.negativeInfinity,
    max: maxDefined ? max : double.infinity,
  );
}

/// core.datasetController.js:136 `getOrCreateStack`.
///
/// A value of `chart._stacks` is the sub-stack of a stack key: the stack
/// object ([StackEntry]) of each index value, by the property key of the
/// index value, its `ToString`. Only this function writes `chart._stacks`.
StackEntry _getOrCreateStack(
  ChartStacks stacks,
  String stackKey,
  Object? indexValue,
) {
  final subStack = stacks[stackKey] ??= {};
  final key = indexValue is double
      ? _numberKey(indexValue)
      : jsToString(indexValue);
  return subStack[key] ??= StackEntry();
}

/// The sub-stack of [stackKey] in [stacks], as `getOrCreateStack` reads
/// it (core.datasetController.js:137-138).
Map<String, StackEntry> _subStackOf(ChartStacks stacks, String stackKey) =>
    stacks[stackKey] ??= {};

/// The stack object of [indexValue] in the sub-stack [subStack], as
/// `getOrCreateStack` makes it (core.datasetController.js:139-140).
StackEntry _getOrCreateSubStackEntry(
  Map<String, StackEntry> subStack,
  Object? indexValue,
) {
  final key = indexValue is double
      ? _numberKey(indexValue)
      : jsToString(indexValue);
  return subStack[key] ??= StackEntry();
}

/// The dataset indexes of `vScale.getMatchingVisibleMetas(type).reverse()`
/// of `getLastIndexInStack`.
List<int> _reversedVisibleIndices(IScale vScale, String type) => [
  for (final meta in vScale.getMatchingVisibleMetas(type).reversed) meta.index,
];

/// `getLastIndexInStack` over the dataset indexes [reversed] of
/// [_reversedVisibleIndices], read one time for the loop of `updateStacks`.
int? _lastIndexIn(StackEntry stack, List<int> reversed, bool positive) {
  for (var i = 0; i < reversed.length; i++) {
    final index = reversed[i];
    final value = jsToNumber(_indexValueOf(stack.datasetValues, index));
    if ((positive && value > 0) || (!positive && value < 0)) {
      return index;
    }
  }
  return null;
}

/// core.datasetController.js:141 `getLastIndexInStack`.
///
/// `value > 0` and `value < 0` compare the `ToNumber` of the stack value
/// with 0, as the JavaScript relational operators do for a number operand.
/// Dart `null` stands for the JS `null` result.
int? _getLastIndexInStack(
  StackEntry stack,
  IScale vScale,
  bool positive,
  String type,
) {
  for (final meta in vScale.getMatchingVisibleMetas(type).reversed) {
    final value = jsToNumber(_indexValueOf(stack.datasetValues, meta.index));
    if ((positive && value > 0) || (!positive && value < 0)) {
      return meta.index;
    }
  }

  return null;
}

/// The array index of the dataset index [index], or -1 for a number that is
/// not an array index (Chart.js ADR 0054 §8: [IndexValues] keeps the
/// values by array index).
int _arrayIndex(int index) => index >= 0 ? index : -1;

/// `values[index]` of the values by dataset index [values]: [undefined]
/// for an absent index.
Object? _indexValueOf(IndexValues values, int index) {
  final i = _arrayIndex(index);
  return i >= 0 ? values.valueAt(i) : values.jsRead(_indexKey(index));
}

/// `values[index] = value` of the values by dataset index [values].
void _setIndexValue(IndexValues values, int index, Object? value) {
  final i = _arrayIndex(index);
  if (i >= 0) {
    values.setAt(i, value);
  } else {
    values.jsWrite(_indexKey(index), value);
  }
}

/// `delete values[index]` of the values by dataset index [values].
void _deleteIndexValue(IndexValues values, int index) {
  final i = _arrayIndex(index);
  if (i >= 0) {
    values.removeAt(i);
  } else {
    values.jsDelete(_indexKey(index));
  }
}

/// `stack[datasetIndex]` of a stack object or of its `_visualValues`
/// (core.datasetController.js:91, :143, :218-223).
///
/// A [StackEntry] and an [IndexValues] read typed. Another value is a
/// `_stacks` object that user code wrote into a parsed item by name: it
/// reads by name, and Dart `null` and [undefined] throw a [TypeError].
Object? _stackValueOf(Object? stack, int datasetIndex) => switch (stack) {
  final StackEntry entry => _indexValueOf(entry.datasetValues, datasetIndex),
  final IndexValues values => _indexValueOf(values, datasetIndex),
  _ => jsGetKey(stack, _indexKey(datasetIndex)),
};

/// `stack[datasetIndex] = value` of a stack object or of its
/// `_visualValues` (controller.bar.js:615). Another value is a `_stacks`
/// object that user code wrote into a parsed item: a Map, else the cast
/// throws a [TypeError], as the JS write into a primitive does.
void setStackValue(Object? stack, int datasetIndex, Object? value) {
  switch (stack) {
    case final StackEntry entry:
      _setIndexValue(entry.datasetValues, datasetIndex, value);
    case final IndexValues values:
      _setIndexValue(values, datasetIndex, value);
    default:
      (stack! as AnyObject)[_indexKey(datasetIndex)] = value;
  }
}

/// `delete stack[datasetIndex]` (core.datasetController.js:221, :223) of a
/// stack object or of its `_visualValues`. Another value is a `_stacks`
/// object that user code wrote into a parsed item: a Map, else the cast
/// throws a [TypeError].
void _deleteStackValue(Object? stack, int datasetIndex) {
  switch (stack) {
    case final StackEntry entry:
      _deleteIndexValue(entry.datasetValues, datasetIndex);
    case final IndexValues values:
      _deleteIndexValue(values, datasetIndex);
    default:
      (stack! as AnyObject).remove(_indexKey(datasetIndex));
  }
}

/// `stack._visualValues` of a stack object (core.datasetController.js:599,
/// :222; controller.bar.js:615). A [StackEntry] reads typed; a value of
/// another class that user code wrote reads through the face. Another stack
/// object is a `_stacks` object that user code wrote into a parsed item: it
/// reads by name.
Object? visualValuesOf(Object? stack) => stack is StackEntry
    ? stack.visualValues ?? stack.jsRead('_visualValues')
    : jsGetKey(stack, '_visualValues');

/// `itemStacks[axis]` of the `_stacks` object of a parsed item
/// (core.datasetController.js:218, :599, :610; controller.bar.js:405,
/// :615). An [ItemStacks] reads typed; a value of another class that user
/// code wrote reads through the face. Another object is a `_stacks` object
/// that user code wrote into a parsed item: it reads by the key of the axis
/// ([axisDataKey]), and Dart `null` and [undefined] throw a [TypeError]. An
/// axis of another class has no key: [undefined].
Object? axisStackOf(Object? itemStacks, ScaleAxis axis) {
  final key = axisDataKey(axis);
  if (itemStacks is ItemStacks) {
    return itemStacks.entryOf(axis) ??
        (key == null ? undefined : itemStacks.jsRead(key));
  }
  return key == null ? undefined : jsGetKey(itemStacks, key);
}

/// `item._stacks || (item._stacks = {})` (core.datasetController.js:165).
///
/// The new object is an [ItemStacks] in the typed field of the item. A
/// Dart `null` item (a JS `null` in the data List of `parsing: false`)
/// throws a [TypeError], as the JS read of a property of `null` does.
Object _itemStacksOf(ParsedItem? item) {
  final current = stacksOf(item);
  if (jsTruthy(current)) {
    return current!;
  }
  final created = ItemStacks();
  item!.stacks = created;
  return created;
}

/// core.datasetController.js:152 `updateStacks`.
///
/// The map structure of `chart._stacks` is `{stackKey: {datasetIndex:
/// value}}`: a Map of sub-stacks by stack key, and a sub-stack of
/// [StackEntry] objects by index value ([_getOrCreateStack]).
///
/// A parsed item is a [ParsedItem]: an item of the parse functions, or a
/// data item of `parsing: false` (row `adapt-parsed-data-items`).
/// `item._stacks = {}` is [_itemStacksOf]. A `_stacks` object that user
/// code wrote into a parsed item by name takes the stack by name, and so
/// does a truthy `stack._visualValues` of another class that user code
/// wrote (Chart.js ADR 0054 §8).
void _updateStacks(DatasetController controller, List<ParsedItem?> parsed) {
  final chart = controller.chart;
  final meta = controller.cachedMeta;
  // map structure is {stackKey: {datasetIndex: value}}
  final stacks = chart.stacks ??= {};
  final iScale = meta.iScale!;
  final vScale = meta.vScale!;
  final datasetIndex = meta.index;
  final iAxis = iScale.axis;
  final vAxis = vScale.axis;
  final key = _getStackKey(iScale, vScale, meta);
  final ilen = parsed.length;
  // DIVERGES(chartjs): adapt-dense-index-values, one read of the visible
  // metas and of the sub-stack when no user code runs in the loop. A branch
  // that can run user code drops both: the next item reads them again.
  var visible = ilen > 0 && fastStackLoopIsNative(controller, parsed)
      ? _reversedVisibleIndices(vScale, meta.type)
      : null;
  // The sub-stack is read at the first item, as `getOrCreateStack` does:
  // a dataset with no item makes no sub-stack.
  Map<String, StackEntry>? subStack;

  for (var i = 0; i < ilen; ++i) {
    final item = parsed[i];
    final index = parsedValueOf(item, iAxis);
    final value = parsedValueOf(item, vAxis);
    final itemStacks = _itemStacksOf(item);
    final stack = visible != null
        ? _getOrCreateSubStackEntry(
            subStack ??= _subStackOf(stacks, key),
            index,
          )
        : _getOrCreateStack(stacks, key, index);
    if (itemStacks is ItemStacks) {
      itemStacks.setEntry(vAxis, stack);
    } else {
      // A `_stacks` object that user code wrote: a Map, else the cast
      // throws a TypeError, as the JS write into a primitive does. The key
      // is the key of the axis ([axisDataKey]).
      final vKey = axisDataKey(vAxis);
      if (vKey != null) (itemStacks as AnyObject)[vKey] = stack;
    }
    _setIndexValue(stack.datasetValues, datasetIndex, value);

    if (visible != null) {
      stack
        ..top = _lastIndexIn(stack, visible, true)
        ..bottom = _lastIndexIn(stack, visible, false);
    } else {
      stack
        ..top = _getLastIndexInStack(stack, vScale, true, meta.type)
        ..bottom = _getLastIndexInStack(stack, vScale, false, meta.type);
    }

    // `stack._visualValues || (stack._visualValues = {})`.
    final visualValues = stack.visualValues;
    if (visualValues != null) {
      _setIndexValue(visualValues, datasetIndex, value);
    } else {
      // A truthy value of another class that user code wrote takes the
      // write by name, as upstream.
      final other = stack.jsRead('_visualValues');
      if (jsTruthy(other)) {
        // The write into an object of the user can run user code.
        visible = null;
        subStack = null;
        setStackValue(other, datasetIndex, value);
      } else {
        _setIndexValue(stack.visualValues = IndexValues(), datasetIndex, value);
      }
    }
  }
}

/// core.datasetController.js:177 `getFirstScaleId`: the first key of
/// `chart.scales` whose scale has [axis] ([sameAxis]), or Dart `null` for
/// `undefined`.
String? _getFirstScaleId(IChart chart, ScaleAxis axis) {
  final scales = chart.scales;
  return jsObjectKeys(scales)
      .where((key) => sameAxis(scales[key]!.axis, axis))
      .firstOrNull;
}

/// core.datasetController.js:182 `createDatasetContext`.
///
/// `createContext(parent, {active, dataset, datasetIndex, index, mode,
/// type})` is the typed context of the type `dataset`, with the keys of the
/// literal in their order (Chart.js ADR 0054 §11).
// DIVERGES(chartjs): adapt-typed-contexts, the typed class of the type.
ScriptableContext _createDatasetContext(ContextObject parent, int index) {
  return ScriptableContext.dataset(parent, index);
}

/// core.datasetController.js:195 `createDataContext`.
///
/// `createContext(parent, {active, dataIndex, parsed, raw, element, index,
/// mode, type})` is the typed context of the type `data`, with the keys of
/// the literal in their order (Chart.js ADR 0054 §11).
// DIVERGES(chartjs): adapt-typed-contexts, the typed class of the type.
ScriptableContext _createDataContext(
  ContextObject parent,
  int index,
  Element element,
) {
  return ScriptableContext.data(parent, index, element);
}

/// core.datasetController.js:208 `clearStacks(meta, items)`.
///
/// The loop continues after a parsed item without a value of the dataset in
/// its stack (:220, ledger row #12155). v4.5.1 returns there.
void _clearStacks(ChartMeta meta, [List<ParsedItem?>? items]) {
  // Not using meta.index here, because it might be already updated if the
  // dataset changed location
  final datasetIndex = meta.controller!.index;
  final axis = meta.vScale?.axis;
  if (axis == null) {
    return;
  }

  final parsedItems = items ?? meta.parsed;
  for (final parsed in parsedItems) {
    final stacks = stacksOf(parsed);
    if (!jsTruthy(stacks)) {
      continue;
    }
    final axisStack = axisStackOf(stacks, axis);
    if (identical(axisStack, undefined) ||
        identical(_stackValueOf(axisStack, datasetIndex), undefined)) {
      continue;
    }
    _deleteStackValue(axisStack, datasetIndex);
    final visualValues = visualValuesOf(axisStack);
    if (!identical(visualValues, undefined) &&
        !identical(_stackValueOf(visualValues, datasetIndex), undefined)) {
      _deleteStackValue(visualValues, datasetIndex);
    }
  }
}

/// The cache entry of the element options that the last call of one loop
/// read, for [DatasetController.resolveHeldDataElementOptions] (Chart.js ADR
/// 0165). A loop makes one and drops it at its end.
// DIVERGES(chartjs): adapt-held-element-options, it lives inside one loop.
final class HeldElementOptions._() {
  /// A hold for one loop, or Dart `null` when [heldElementOptionsEnabled] is
  /// off.
  static HeldElementOptions? forLoop() =>
      heldElementOptionsEnabled ? HeldElementOptions._() : null;

  /// The `id` of the data element type of the read, a string.
  String? _id;

  /// The mode of the read.
  String _mode = '';

  /// The cache key of the read.
  String _key = '';

  /// The entry of the read, or Dart `null` for none.
  ElementOptions? _entry;

  /// The count of the writes and the clears of the cache after the read.
  int _generation = -1;

  /// Whether the last call took the entry and ran no code of the app: the
  /// data element type is a class value and the entry a `PointOptions`.
  bool native = false;

  int _taken = 0;

  /// Whether the hold has an entry.
  bool get holds => _entry != null;

  /// Adds the count of the calls that took the entry to
  /// [heldElementOptionsTaken].
  void finish() => heldElementOptionsTaken += _taken;
}

/// Differential test switch of Chart.js ADR 0165; not a chart option. With it
/// off, a loop makes no [HeldElementOptions].
@visibleForTesting
bool heldElementOptionsEnabled = true;

/// The calls that took a held entry, for differential tests. A loop adds its
/// count when it ends.
@visibleForTesting
int heldElementOptionsTaken = 0;

/// core.datasetController.js:229 `isDirectUpdateMode`.
bool _isDirectUpdateMode(Object? mode) => mode == 'reset' || mode == 'none';

/// core.datasetController.js:230 `cloneIfNotShared`.
///
/// The copy is [ElementOptions.clone]: it keeps the class of the options
/// (Chart.js ADR 0021, section 3).
// DIVERGES(chartjs): adapt-typed-element-options, the copy keeps the class.
ElementOptions _cloneIfNotShared(ElementOptions cached, bool shared) =>
    shared ? cached : cached.clone();

/// core.datasetController.js:231 `createStack`.
///
/// Dart `null` stands for each falsy result of the `&&` chain.
DatasetStack? _createStack(Object? canStack, ChartMeta meta, IChart chart) =>
    jsTruthy(canStack) &&
        !(meta.hidden ?? false) &&
        meta.stacked != StackMode.off
    ? DatasetStack(_getSortedDatasetIndices(chart, true), null)
    : null;

/// core.datasetController.js:231-232 and :597-600 the object `{keys,
/// values}` of `createStack` and of the method `applyStack`.
///
/// `updateRangeFromParsed` writes [values] (:612).
final class DatasetStack(
  /// `keys`: the indices of the visible datasets in the drawing order
  /// (`getSortedDatasetIndices`).
  final List<int> keys,

  /// `values`: the values of the stack by dataset index: a [StackEntry]
  /// (`updateRangeFromParsed`, :612), its [IndexValues] `_visualValues`
  /// (`applyStack`, :599), or a stack object that user code gave a data
  /// item. Dart `null` stands for the JS `null` of `createStack`. The
  /// [undefined] sentinel stands for an absent `_visualValues`.
  var Object? values,
) {
  /// The object `{keys, values}`.
  this;
}

/// core.datasetController.js:629 the object `{min, max}` of `getMinMax`.
final class _Range(@override var double min, @override var double max)
    implements MinMax;

/// The value of the data elements at [DatasetController._insertElements]
/// between the move of the elements and the new elements. The new elements
/// replace it at once.
final Element _hole = Element();

/// The JS read `list[index]` of a list of objects: Dart `null` for an index
/// that names no item, JS `undefined`.
T? _at<T extends Object>(List<T> list, int index) =>
    index >= 0 && index < list.length ? list[index] : null;

/// [jsGetIndex] of a receiver that is a List by its static type: the same
/// result, with no type test (Chart.js ADR 0096).
Object? _itemAt(List<Object?> list, int index) =>
    index >= 0 && index < list.length ? list[index] : undefined;

/// `meta._parsed[index]`: Dart `null` for an index that names no parsed item
/// and for a hole, the JS `undefined`.
ParsedItem? _parsedAt(List<ParsedItem?> list, int index) =>
    index >= 0 && index < list.length ? list[index] : null;

/// `dataset.data[index]` of `getContext`, the data of the dataset object of
/// the user.
Object? _rawOf(Object? dataset, int index) =>
    jsGetIndex(readOption(dataset, OptionKey.data), index);

/// `new Array(count)` of the parse functions, as the bound of their loop:
/// a count below 0 is an empty range.
int _itemCount(int count) => count < 0 ? 0 : count;

/// The class of the plain List that `_dataCheck` gives `meta._parsed`.
final Type _plainParsedList = <ParsedItem?>[].runtimeType;

/// Gives the empty plain List [items] the length of the [count] items of a
/// parse from index 0 that copies the native List [source], and that then
/// writes [items] by index. Returns whether it did.
///
/// Upstream grows `meta._parsed` by one for each item. The length is
/// observable only by user code that runs between the writes. The callers
/// keep that out: [DatasetController.parse] gives the list its upstream
/// length before a value that can run user code, and
/// [presizeParsedNumbers] takes only numbers (Chart.js ADR 0096).
// DIVERGES(chartjs): adapt-parse-presize, one growth of the plain List.
bool _presizeParsed(
  List<ParsedItem?> items,
  int start,
  int count,
  List<Object?> source,
) {
  if (start == 0 &&
      count > 0 &&
      items.runtimeType == _plainParsedList &&
      items.isEmpty &&
      nativeDataUpdateList(source) &&
      count <= source.length) {
    items.length = count;
    return true;
  }
  return false;
}

/// [_presizeParsed] for a parse that writes the numbers of the native List
/// [data] in a loop with no user code (controller.doughnut.js:153-165).
/// Another [data] keeps the growth by one.
void presizeParsedNumbers(
  List<ParsedItem?> items,
  Object? data,
  int start,
  int count,
) {
  if (data is List<num?>) _presizeParsed(items, start, count, data);
}

/// The property keys `'0'` to `'63'`.
final List<String> _indexKeys = [for (var i = 0; i < 64; i++) '$i'];

/// The property key of the number [index], the `ToPropertyKey` of
/// `object[index]`: a cached key for a small dataset index, else
/// its text.
String _indexKey(int index) =>
    index >= 0 && index < _indexKeys.length ? _indexKeys[index] : '$index';

/// The property key of the index value [value] of a stack, its `ToString`:
/// a cached key for a small whole number, else [jsToString].
String _numberKey(double value) {
  if (value >= 0 && value < _indexKeys.length) {
    final i = value.toInt();
    if (i == value) return _indexKeys[i];
  }
  return jsToString(value);
}

/// The JS read `item[axis]` of a parsed item: the hot read of Chart.js ADR
/// 0054 §8.
///
/// A parsed item is a [ParsedItem]: an item of the parse functions, or a
/// data item of `parsing: false` (row `adapt-parsed-data-items`). It reads
/// the typed field of the axis [axis] ([ParsedItem.valueOf]). A Dart `null`
/// item (an index that names no parsed item, the JS `undefined`) throws a
/// [TypeError], as the JS read of a property of `undefined` does. An axis of
/// another class has no field: [undefined] (row `adapt-axis-objects`).
@pragma('vm:prefer-inline')
@pragma('dart2js:prefer-inline')
@pragma('wasm:prefer-inline')
Object? parsedValueOf(ParsedItem? item, ScaleAxis axis) => item!.valueOf(axis);

/// `properties[axis] = value` of the properties of a point (for example
/// controller.line.js:100-101, controller.bubble.js:127-128): the typed
/// setter for [XAxis] or [YAxis], else the write by the key of the axis
/// ([axisDataKey]) of the face. An axis of another class has no key: no
/// write.
void setPointAxis(PointProperties properties, ScaleAxis axis, double value) {
  switch (axis) {
    case XAxis():
      properties.x = value;
    case YAxis():
      properties.y = value;
    default:
      final key = axisDataKey(axis);
      if (key != null) properties.jsWrite(key, value);
  }
}

/// `resolveObjectKey(item, key)` of a data item in the object parse
/// (core.datasetController.js:571-572, controller.bar.js:333-334).
///
/// A [ParsedItem] (for example a `DataPoint` of the typed API) gives its
/// typed field for the parsing key `x` or `y` (Chart.js ADR 0054 §7).
/// Another key, and an item of another class, read by the key path of
/// [resolveObjectKey].
Object? dataItemValue(Object? item, String key) => item is ParsedItem
    ? switch (key) {
        'x' => item.x,
        'y' => item.y,
        _ => resolveObjectKey(item, key),
      }
    : resolveObjectKey(item, key);

/// The read `item._stacks` of a parsed item (core.datasetController.js:165,
/// :218, :599, :610; controller.bar.js:405, :615).
///
/// A [ParsedItem] gives its typed [ItemStacks]; a value of another class
/// that user code wrote reads through the face, and an absent key gives
/// [undefined]. A Dart `null` item throws a [TypeError], as the JS read of a
/// property of `null` does.
Object? stacksOf(ParsedItem? item) {
  final parsed = item!;
  return parsed.hasSlot(4)
      ? parsed.stacks ?? parsed.jsRead('_stacks')
      : undefined;
}

/// `this.datasetElementType.id` and `this.dataElementType.id`
/// (core.datasetController.js:789, :798, Chart.js ADR 0020, section 4).
///
/// Dart `null` (the JS `null` or `false`) throws a [TypeError], as in
/// JavaScript.
Object? _idOf(JsClass? elementType) =>
    elementType == null ? throw TypeError() : elementType.id;

/// The element class of the static `datasetElementType` or `dataElementType`
/// [value] of a controller class value: a class value, or Dart `null` for the
/// JS `null` and `false`. Another value stops a debug build, and a release
/// build takes no class.
// DIVERGES(chartjs): adapt-element-type-classes, a class value or null.
JsClass? _elementClassOf(Object? value) {
  if (value is JsClass) return value;
  assert(
    value == null || value == false || value is Undefined,
    'An element type is a JsClass, not $value.',
  );
  return null;
}

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
///
/// `chartjs.dart` exports it: the class value of a controller of another
/// package reads its arguments with it (Chart.js ADR 0133).
// DIVERGES(chartjs): adapt-component-class-role, a non-Chart chart throws.
({IChart chart, int datasetIndex}) controllerArgs(List<Object?> args) {
  final chart = args.isEmpty ? undefined : args[0];
  final datasetIndex = args.length < 2 ? undefined : args[1];
  return switch (chart) {
    final IChart value => (
      chart: value,
      // An absent or another argument is no dataset index, -1.
      datasetIndex: datasetIndex is num && datasetIndex.isFinite
          ? datasetIndex.toInt()
          : -1,
    ),
    // A JavaScript TypeError: a property read of a value without the
    // members of a chart.
    _ => throw TypeError(),
  };
}

/// core.datasetController.js:234 `DatasetController`.
class DatasetController(
  /// core.datasetController.js:256 `chart` (index.d.ts:630).
  final IChart chart,
  int datasetIndex, [
  JsClass? newTarget,
]) with ArrayListener<Object?> implements IDatasetController {
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
  this {
    cachedMeta = getMeta();
    type = cachedMeta.type;
    final target = newTarget ?? jsClass;
    datasetElementType = _elementClassOf(target['datasetElementType']);
    dataElementType = _elementClassOf(target['dataElementType']);

    initialize();
  }

  /// core.datasetController.js:239 `static defaults = {}`, an empty typed
  /// scope of the kind `GenericDatasetOptions` (Chart.js ADR 0054 §3).
  static final GenericDatasetOptionsScope defaults =
      GenericDatasetOptionsScope();

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

  /// core.datasetController.js:257 `_ctx`, the context of the chart.
  /// controller.bar.js:677 reads it. Dart `null` stands for the JS `null` of
  /// a chart without a context. It is writable, as the JS property: the
  /// reference tests put a recording context here.
  CanvasRenderingContext2D? ctx = chart.ctx;

  /// core.datasetController.js:258 `index`, the dataset index
  /// (index.d.ts:631). [updateIndex] writes it.
  @override
  int index = datasetIndex;

  /// core.datasetController.js:259 `_cachedDataOpts`, the part of the
  /// element options: the frozen options of `_resolveElementOptions` by the
  /// key `elementType-mode` (:807).
  ///
  /// Upstream keeps them with the animations of `_resolveAnimations` in
  /// one object. The two typed Maps have the same keys. [configure] clears
  /// both, as `this._cachedDataOpts = {}` (:445) does.
  final Map<String, ElementOptions> _cachedElementOptions = {};

  // DIVERGES(chartjs): adapt-held-element-options, a count of the writes and
  // the clears of [_cachedElementOptions]. It keeps no value.
  int _elementOptionsGeneration = 0;

  // DIVERGES(chartjs): adapt-element-option-cache-key, reuse only the last
  // joined string. The option cache and its invalidation stay unchanged.
  String? _lastElementTypeName;
  String? _lastElementMode;
  String _lastElementCacheKey = '';

  // Container implementation is immutable; keys and option values stay live.
  Object? _lastElementDefaults;
  bool _nativeElementDefaultKeys = false;
  bool _nativeSnapshotKeys = false;
  String? _nativePrefixType;
  bool _nativePrefixActive = false;
  late List<String> _nativePrefixes;

  /// core.datasetController.js:259 `_cachedDataOpts`, the part of the
  /// animations: the frozen [Animations] of [resolveAnimations] by the
  /// transition of the key `animation-transition` (:844).
  final Map<String, Animations> _cachedAnimations = {};

  /// core.datasetController.js:260 `_cachedMeta`, the meta of the dataset
  /// (index.d.ts:632). It is public: a controller of another package reads
  /// it, as upstream subclasses read the protected `_cachedMeta` (Chart.js
  /// ADR 0133).
  @override
  late final ChartMeta cachedMeta;

  /// core.datasetController.js:261 `_type`, the dataset type of the meta.
  /// controller.bar.js:436 and controller.doughnut.js:192 read it.
  late final String type;

  /// core.datasetController.js:262 `options`, the resolver of the dataset
  /// options. [configure] assigns it: the view of `createResolver` with the
  /// dataset context, an [OptionView]. The reads are typed
  /// ([OptionView.readKey]).
  ///
  /// The constructor calls [initialize], which calls [configure] first.
  /// Thus no reader finds the `undefined` start value.
  @override
  late OptionView options;

  /// core.datasetController.js:264 `_parsing`, the `parsing` option: the
  /// keys of the data items, or Dart `null` for `false`, the start value.
  // DIVERGES(chartjs): adapt-parsing-keys, the keys of the option.
  @override
  ParsingKeys? parsing;

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
  @override
  ElementOptions? sharedOptions;

  /// core.datasetController.js:268 `_drawStart`: the first data element of
  /// [draw]. controller.line.js:48 writes it. Dart `null` stands for JS
  /// `undefined`.
  int? drawStart;

  /// core.datasetController.js:269 `_drawCount`: the count of data elements
  /// of [draw]. controller.line.js:49 writes it. Dart `null` stands for JS
  /// `undefined`.
  int? drawCount;

  /// core.datasetController.js:270 `enableOptionSharing`.
  bool enableOptionSharing = false;

  /// Unknown controllers keep the full lifecycle.
  bool get supportsDataUpdates => false;

  /// Default native point fields used by the incremental input preflight.
  DataUpdateShape get dataUpdateShape => DataUpdateShape.cartesian;

  /// True only while the chart runs its explicit data-only lifecycle.
  bool updatingData = false;

  /// A stable layout and primitive index sequence permit controller reuse.
  bool reuseDataLayout = false;

  /// The current source is an ordinary numeric array.
  bool primitiveDataUpdate = false;

  /// Whether the ordinary full update resolved context-independent styles.
  /// The cache records this even for controllers that do not share options.
  bool get hasStaticDataUpdateOptions =>
      _hasCachedEntry(dataElementType) &&
      (cachedMeta.dataset == null || _hasCachedEntry(datasetElementType));

  /// Whether the cache has an entry of the element type [type], in another mode
  /// than `active`.
  bool _hasCachedEntry(JsClass? type) {
    final prefix = '${jsToString(_idOf(type))}-';
    return _cachedElementOptions.keys.any(
      (key) => key.startsWith(prefix) && key != '${prefix}active',
    );
  }

  /// Whether a data-only update of this controller gives the options of a full
  /// update with no user code (Chart.js ADR 0100): each resolve of a data
  /// element is a cached entry or a native indexed plan, the dataset element
  /// has a cached entry, and no dataset option that a view read is a function.
  ///
  /// A proof holds for its cache generation of the config: each clear of the
  /// scopes or of the resolvers changes it. `updateData` states that the
  /// options stay unchanged, so the items of the indexed lists are read once
  /// for each generation.
  // DIVERGES(chartjs): adapt-data-update-indexed-plan, the proof of the path.
  bool get hasDataUpdateOptions {
    final config = chart.config;
    if (config is! Config) return false;
    final generation = config.resolutionGeneration;
    if (_dataUpdateProofGeneration == generation) return true;
    if (!options.readsNoFunctionValue ||
        !(hasStaticDataUpdateOptions || _hasIndexedDataOptions(config))) {
      return false;
    }
    _dataUpdateProofGeneration = generation;
    return true;
  }

  // The cache generation of the last proof of [hasDataUpdateOptions].
  int _dataUpdateProofGeneration = -1;

  /// Whether each resolve of a data element takes a native indexed plan. A
  /// dataset element has no such plan: its cached entry stays the proof.
  bool _hasIndexedDataOptions(Config config) {
    final elementType = _idOf(dataElementType);
    if (elementType is! String ||
        !nativePointDatasetIndex(index) ||
        (cachedMeta.dataset != null && !_hasCachedEntry(datasetElementType))) {
      return false;
    }
    return config.hasStaticIndexedElementOptions(
      index,
      controllerType: type,
      elementType: elementType,
    );
  }

  /// The built-in `generateLabels` of this exact class, or Dart `null`: the
  /// doughnut, pie and polar area controllers name theirs (Chart.js ADR 0092).
  /// A subclass and another controller keep the ordinary legend builds.
  // DIVERGES(chartjs): adapt-hidden-legend-items, the built-in generator.
  Object? get nativeLegendGenerator => null;

  /// The source of [getStyle] while a hidden legend builds its items at a read
  /// (Chart.js ADR 0099), with the count of the arcs at the mark of that build:
  /// an update can rebuild the arcs before its own mark. That build runs no
  /// user code, and a read writes no context, as a read of the snapshot of
  /// upstream writes none. Dart `null` at each other time.
  // DIVERGES(chartjs): adapt-hidden-legend-items, a later build, no writes.
  ({IndexedElementStyles styles, int arcCount})? legendStyles;

  /// Whether `getStyle(index)` of a data element reads a cached `default`
  /// entry of [_resolveElementOptions]: the read then runs no context and no
  /// option function (Chart.js ADR 0092).
  // DIVERGES(chartjs): adapt-hidden-legend-items, the proof of a legend build.
  bool get hasCachedDefaultDataOptions => _cachedElementOptions.containsKey(
    '${jsToString(_idOf(dataElementType))}-default',
  );

  /// Whether the next `getStyle(index)` of a data element needs no context, and
  /// thus calls no option function and writes the `default` entry: an entry of
  /// another mode came from this resolver and this `needContext` result, and no
  /// clear of the caches came after it. The entry of the mode `active` has
  /// other prefixes (Chart.js ADR 0092).
  // DIVERGES(chartjs): adapt-hidden-legend-items, the proof with no call.
  bool get defaultDataOptionsNeedNoContext =>
      hasStaticDataUpdateOptions &&
      _staticEntryGeneration == (chart.config as Config).resolutionGeneration;

  // The cache generation of the last entry of the element options, Chart.js
  // ADR 0092.
  int _staticEntryGeneration = -1;

  /// core.datasetController.js:271 `supportsDecimation`.
  @override
  bool supportsDecimation = false;

  /// core.datasetController.js:272 `$context`, the dataset context of
  /// [getContext], a typed [ScriptableContext]. Dart `null` stands for JS
  /// `undefined`.
  ScriptableContext? $context;

  /// core.datasetController.js:273 `_syncList`: the array changes
  /// `[method, start, count]` until the next [_resyncElements].
  List<List<Object?>> _syncList = [];

  /// core.datasetController.js:274 `datasetElementType`: the class value of
  /// the dataset element, or Dart `null` for the JS `null` and `false`
  /// (Chart.js ADR 0020, section 4). controller.scatter.js:94 and :105 write
  /// it.
  JsClass? datasetElementType;

  /// core.datasetController.js:275 `dataElementType`: the class value of
  /// the data elements, or Dart `null` for JS `null`.
  JsClass? dataElementType;

  /// core.datasetController.js:280 `initialize()`.
  void initialize() {
    final meta = cachedMeta;
    configure();
    linkScales();
    meta.stacked = _isStacked(meta.vScale, meta);
    addElements();

    // DIVERGES(chartjs): adapt-fill-target-objects, the truthiness of a class.
    if (_fillTruthy(options.readKey(OptionKey.fill)) &&
        !chart.isPluginEnabled('filler')) {
      _consoleWarn(
        "Tried to use the 'fill' option without the 'Filler' plugin enabled. "
        "Please import and register the 'Filler' plugin and make sure it is "
        'not disabled in the options',
      );
    }
  }

  /// core.datasetController.js:292 `updateIndex(datasetIndex)`.
  void updateIndex(int datasetIndex) {
    if (index != datasetIndex) {
      _clearStacks(cachedMeta);
    }
    index = datasetIndex;
  }

  /// core.datasetController.js:299 `linkScales()`.
  ///
  /// An axis id is a `String?` of the meta (row `adapt-native-chart-meta`):
  /// Dart `null` stands for JS `undefined` and `null`.
  void linkScales() {
    final chart = this.chart;
    final meta = cachedMeta;
    final dataset = getDataset();

    // `axis === 'x' ? x : axis === 'r' ? r : y`.
    String? chooseId(ScaleAxis? axis, String? x, String? y, String? r) =>
        switch (axis) {
          XAxis() => x,
          RAxis() => r,
          _ => y,
        };

    final xid = meta.xAxisID = metaStringOf(
      valueOrDefault(
        jsGet(dataset, 'xAxisID'),
        _getFirstScaleId(chart, const XAxis()) ?? undefined,
      ),
      'xAxisID',
    );
    final yid = meta.yAxisID = metaStringOf(
      valueOrDefault(
        jsGet(dataset, 'yAxisID'),
        _getFirstScaleId(chart, const YAxis()) ?? undefined,
      ),
      'yAxisID',
    );
    final rid = meta.rAxisID = metaStringOf(
      valueOrDefault(
        jsGet(dataset, 'rAxisID'),
        _getFirstScaleId(chart, const RAxis()) ?? undefined,
      ),
      'rAxisID',
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

  /// core.datasetController.js:319 `getDataset()`.
  ///
  /// The dataset `chart.data.datasets[index]`: a Map, or [undefined] for an
  /// index that names no dataset.
  @override
  Object? getDataset() {
    return jsGetIndex(readOption(chart.data, OptionKey.datasets), index);
  }

  /// core.datasetController.js:323 `getMeta()`.
  ChartMeta getMeta() {
    return chart.getDatasetMeta(index);
  }

  /// core.datasetController.js:331 `getScaleForId(scaleID)`.
  ///
  /// @param {string} scaleID
  /// @return {Scale}
  ///
  /// Dart `null` for [scaleID] and for the result stands for JS
  /// `undefined`. A scale id is a `String` (Chart.js ADR 0176).
  // DIVERGES(chartjs): adapt-string-ids, a String id only.
  IScale? getScaleForId(String? scaleID) => chart.scales[scaleID];

  /// core.datasetController.js:338 `_getOtherScale(scale)`.
  /// @private
  IScale? _getOtherScale(IScale scale) {
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
  void destroy() {
    final meta = cachedMeta;
    final data = _data;
    if (data != null) {
      unlistenArrayEvents(data, this);
    }
    if (meta.stacked != StackMode.off) {
      _clearStacks(meta);
    }
  }

  /// core.datasetController.js:365 `_dataCheck()`.
  /// @private
  ///
  /// A string `data` becomes a [JsStringList], the reads `data[i]` and
  /// `data.length` of the string. A string is not extensible, so it gets no
  /// listener (:386). `_data !== data` compares two strings by value: an
  /// equal string keeps [_data], the parsed items and the stacks. Any other
  /// truthy `data` that is neither a Map nor a `List` is outside the upstream
  /// type contract: the cast throws a [TypeError].
  void _dataCheck() {
    final dataset = getDataset();
    var data = jsGet(dataset, 'data');
    if (!jsTruthy(data)) {
      jsSet(dataset, 'data', data = <Object?>[]);
    }
    final oldData = _data;

    // In order to correctly handle data addition/deletion animation (and
    // thus simulate real-time charts), we need to monitor these data
    // modifications and synchronize the internal metadata accordingly.

    if (isObject(data)) {
      final meta = cachedMeta;
      _data = _convertObjectDataToArray(data!, meta);
    } else if (oldData is JsStringList
        ? oldData.string != data
        : !identical(oldData, data)) {
      if (oldData != null) {
        // This case happens when the user replaced the data array instance.
        unlistenArrayEvents(oldData, this);
        // Discard old parsed data and stacks
        final meta = cachedMeta;
        _clearStacks(meta);
        meta.parsed = <ParsedItem?>[];
      }
      final List<Object?> array;
      if (data is String) {
        // `Object.isExtensible(data)` is false for a string.
        array = JsStringList(data);
      } else {
        array = data! as List<Object?>;
        // A Dart List has no extensibility state: `Object.isExtensible(data)`
        // is true for each data List.
        // DIVERGES(chartjs): platform-array-events, each List is extensible.
        listenArrayEvents(array, this);
      }
      _syncList = [];
      _data = array;
    }
  }

  /// core.datasetController.js:394 `addElements()`.
  void addElements() {
    final meta = cachedMeta;

    _dataCheck();

    final datasetElementType = this.datasetElementType;
    if (datasetElementType != null) {
      // DIVERGES(chartjs): adapt-component-class-role, the cast throws earlier.
      meta.dataset = jsConstruct(datasetElementType, const []) as Element;
    }
  }

  /// core.datasetController.js:404 `buildOrUpdateElements(resetNewElements)`.
  ///
  /// Dart `null` for [resetNewElements] stands for JS `undefined`.
  void buildOrUpdateElements([bool? resetNewElements]) {
    final meta = cachedMeta;
    final dataset = getDataset();
    var stackChanged = false;

    _dataCheck();

    // make sure cached _stacked status is current
    final oldStacked = meta.stacked;
    meta.stacked = _isStacked(meta.vScale, meta);

    // detect change in stack option
    // `!==`: Dart `!=` gives its result for the JS values of the option.
    // Upstream reads `dataset.stack` twice, with `clearStacks` between the
    // reads. No user code runs there: one read gives the same value.
    final stack = metaStringOf(jsGet(dataset, 'stack'), 'stack');
    if (meta.stack != stack) {
      stackChanged = true;
      // remove values from old stack
      _clearStacks(meta);
      meta.stack = stack;
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
    // The dataset context is an object: the result is a view.
    options = config.createResolver(scopes, getContext()) as OptionView;
    parsing = ParsingKeys.of(options.readKey(OptionKey.parsing));
    _cachedElementOptions.clear();
    // DIVERGES(chartjs): adapt-held-element-options, the clear ends a hold.
    _elementOptionsGeneration++;
    _cachedAnimations.clear();
  }

  /// [configure] in a range update of the chart (Chart.js ADR 0111): the
  /// resolver of the last full update stays, with a new context view over it
  /// where [configure] makes a new scope list and a new resolver. The reads
  /// and the clears of [configure] stay: the dataset context, `parsing` and
  /// the two caches of the resolved options and the animations. Under the
  /// contract of `Chart.updateRanges` no option of the scopes changed, so
  /// the kept resolver gives the values of a new one, and each scriptable
  /// option runs again through the new view.
  // DIVERGES(chartjs): adapt-range-updates, configure with a kept resolver.
  void configureKeptResolver() {
    options = attachContext(options.resolver, getContext());
    parsing = ParsingKeys.of(options.readKey(OptionKey.parsing));
    _cachedElementOptions.clear();
    // DIVERGES(chartjs): adapt-held-element-options, the clear ends a hold.
    _elementOptionsGeneration++;
    _cachedAnimations.clear();
  }

  /// core.datasetController.js:451 `parse(start, count)`.
  ///
  /// @param {number} start
  /// @param {number} count
  ///
  /// [start] and [count] are integers: [start] is at most the count of the
  /// parsed items.
  void parse(int start, int count) {
    final meta = cachedMeta;
    final data = _data!;
    final iScale = meta.iScale!;
    final stacked = meta.stacked;
    final iAxis = iScale.axis;

    var sorted = (start == 0 && count == data.length) || meta.sorted;
    // `start > 0 && meta._parsed[start - 1]`: Dart `null` is the falsy
    // `false` and a hole.
    var prev = start > 0 ? _parsedAt(meta.parsed, start - 1) : null;
    int i;
    ParsedItem? cur;
    List<ParsedItem?> parsed;

    if (parsing == null) {
      // DIVERGES(chartjs): adapt-parsed-data-items, the data items are typed.
      meta
        ..parsed = parsed = parsedDataItems(data)
        ..sorted = true;
    } else {
      final first = jsGetIndex(data, start);
      if (isArray(first)) {
        parsed = parseArrayData(meta, data, start, count);
      } else if (isObject(first)) {
        parsed = parseObjectData(meta, data, start, count);
      } else {
        parsed = parsePrimitiveData(meta, data, start, count);
      }

      bool isNotInOrderComparedToPrev() =>
          parsedValueOf(cur, iAxis) == null ||
          (prev != null &&
              jsLessThan(
                parsedValueOf(cur, iAxis),
                parsedValueOf(prev, iAxis),
              ));
      final parsedItems = meta.parsed;
      final offset = start;
      // DIVERGES(chartjs): adapt-parse-presize, one growth of the plain List.
      var presized = _presizeParsed(parsedItems, start, count, parsed);
      for (i = 0; i < count; ++i) {
        cur = parsed[i];
        // `parsed[i + offset] = cur`: a write at the length appends.
        if (i + offset == parsedItems.length) {
          parsedItems.add(cur);
        } else {
          parsedItems[i + offset] = cur;
        }
        if (sorted) {
          // The comparison runs the `toString` of a value that is not a
          // number. That user code sees the list of upstream.
          if (presized && parsedValueOf(cur, iAxis) is! num?) {
            parsedItems.length = i + offset + 1;
            presized = false;
          }
          if (isNotInOrderComparedToPrev()) {
            sorted = false;
          }
          prev = cur;
        }
      }
      meta.sorted = sorted;
    }

    if (stacked != StackMode.off) {
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
  /// Each item is a [ParsedItem] with the keys of the literal in their
  /// order (Chart.js ADR 0054 §8). With one scale for both axes, the item
  /// has one key: the second key of the object literal replaces the first.
  List<ParsedItem> parsePrimitiveData(
    ChartMeta meta,
    List<Object?> data,
    int start,
    int count,
  ) {
    final iScale = meta.iScale!;
    final vScale = meta.vScale!;
    final iAxis = iScale.axis;
    final vAxis = vScale.axis;
    final labels = iScale.getLabels();
    final singleScale = identical(iScale, vScale);
    // DIVERGES(chartjs): adapt-radial-numeric-parse, one scale on both axes.
    if (singleScale) {
      final single = tryParseNumericSingleScale(vScale, data, start, count);
      if (single != null) return single;
    }
    // DIVERGES(chartjs): adapt-numeric-category-parse, shared primitive path.
    final numeric = tryParseNumericCategories(
      iScale,
      vScale,
      labels,
      data,
      start,
      count,
    );
    if (numeric != null) return numeric;

    return List<ParsedItem>.generate(_itemCount(count), (i) {
      final index = i + start;
      return ParsedItem.of(
        iAxis,
        // `singleScale || iScale.parse(...)`.
        singleScale ? singleScale : iScale.parse(_itemAt(labels, index), index),
        vAxis,
        vScale.parse(_itemAt(data, index), index),
      );
    });
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
  ///
  /// Each item is a [ParsedItem] `{x, y}`. `item[0]` and `item[1]` are
  /// [jsGetIndex]: the item of a List, else the property `'0'` or `'1'`.
  List<ParsedItem> parseArrayData(
    ChartMeta meta,
    List<Object?> data,
    int start,
    int count,
  ) {
    final xScale = meta.xScale!;
    final yScale = meta.yScale!;

    return List<ParsedItem>.generate(_itemCount(count), (i) {
      final index = i + start;
      final item = _itemAt(data, index);
      return ParsedItem.of(
        const XAxis(),
        xScale.parse(jsGetIndex(item, 0), index),
        const YAxis(),
        yScale.parse(jsGetIndex(item, 1), index),
      );
    });
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
  /// `'y'` for Dart `null`.
  ///
  /// Each item is a [ParsedItem] `{x, y}`. A data item that is a
  /// [ParsedItem] (a [DataPoint]) gives its typed field for the default key
  /// ([dataItemValue]).
  List<ParsedItem> parseObjectData(
    ChartMeta meta,
    List<Object?> data,
    int start,
    int count,
  ) {
    final xScale = meta.xScale!;
    final yScale = meta.yScale!;
    final xAxisKey = parsing?.xAxisKey ?? 'x';
    final yAxisKey = parsing?.yAxisKey ?? 'y';

    return List<ParsedItem>.generate(_itemCount(count), (i) {
      final index = i + start;
      final item = _itemAt(data, index);
      return ParsedItem.of(
        const XAxis(),
        xScale.parse(dataItemValue(item, xAxisKey), index),
        const YAxis(),
        yScale.parse(dataItemValue(item, yAxisKey), index),
      );
    });
  }

  /// core.datasetController.js:579 `getParsed(index)`.
  /// @protected
  ///
  /// A parsed item is any value (`unknown[]`, index.d.ts:503): a
  /// [ParsedItem] of the `parse*Data` methods, a data item with `parsing:
  /// false`, or a number of a controller that writes numbers
  /// (controller.doughnut.js:153, :164).
  /// An index that names no parsed item gives [undefined]. Dart `null` is a
  /// JS `null` item.
  @override
  ParsedItem? getParsed(int index) {
    return _parsedAt(cachedMeta.parsed, index);
  }

  /// core.datasetController.js:586 `getDataElement(index)`.
  /// @protected
  ///
  /// Dart `null` stands for the JS `undefined` of an index that names no
  /// element.
  IElement? getDataElement(int index) {
    return _at(cachedMeta.data, index);
  }

  /// core.datasetController.js:593 `applyStack(scale, parsed, mode)`.
  /// @protected
  ///
  /// [mode] is the `_stacked` value of the meta. The result is the upstream
  /// result: Dart `null` for a `null` value (the JS `undefined`), else a
  /// number (row `adapt-apply-stack-number`).
  double? applyStack(IScale scale, ParsedItem parsed, [StackMode? mode]) {
    final chart = this.chart;
    final meta = cachedMeta;
    final axis = scale.axis;
    final value = parsedValueOf(parsed, axis);
    final stack = DatasetStack(
      _getSortedDatasetIndices(chart, true),
      visualValuesOf(axisStackOf(stacksOf(parsed), axis)),
    );
    return _applyStack(stack, value, meta.index, mode: mode);
  }

  /// The dataset indexes of the visible metas in their sorted order: the
  /// `getSortedDatasetIndices(chart, true)` of [applyStack].
  List<int> sortedVisibleDatasetIndices() =>
      _getSortedDatasetIndices(chart, true);

  /// [applyStack] with the dataset indexes [indexes] of
  /// [sortedVisibleDatasetIndices], read one time for a loop that runs no
  /// user code (Chart.js ADR 0152). The result is the result of
  /// [applyStack].
  // DIVERGES(chartjs): adapt-bulk-bar-update, the sorted indexes read once.
  double? applyStackWith(
    IScale scale,
    ParsedItem parsed,
    StackMode? mode,
    List<int> indexes,
  ) {
    final axis = scale.axis;
    final value = parsedValueOf(parsed, axis);
    final stack = DatasetStack(
      indexes,
      visualValuesOf(axisStackOf(stacksOf(parsed), axis)),
    );
    return _applyStack(stack, value, cachedMeta.index, mode: mode);
  }

  /// core.datasetController.js:607 `updateRangeFromParsed(range, scale,
  /// parsed, stack)`.
  /// @protected
  ///
  /// Dart `null` for [stack] stands for the falsy values of `createStack`.
  void updateRangeFromParsed(
    MinMax range,
    IScale scale,
    ParsedItem? parsed,
    DatasetStack? stack,
  ) {
    final axis = scale.axis;
    final parsedValue = parsedValueOf(parsed, axis);
    // `parsedValue === null ? NaN : parsedValue`.
    Object? value = parsedValue ?? double.nan;
    final values = stack == null ? null : axisStackOf(stacksOf(parsed), axis);
    if (stack != null && jsTruthy(values)) {
      stack.values = values;
      // The JS `undefined` of a `null` value gives NaN below.
      value = _applyStack(stack, parsedValue, cachedMeta.index) ?? double.nan;
    }
    // Math.min and Math.max read the value with ToNumber.
    final number = jsToNumber(value);
    range
      ..min = math.min(range.min, number)
      ..max = math.max(range.max, number);
  }

  /// core.datasetController.js:622 `getMinMax(scale, canStack)`.
  /// @protected
  ///
  /// Dart `null` for [canStack] stands for JS `undefined`. The result is a
  /// record of the object `{min, max}`. A parsed value of the other scale
  /// compares with the user bounds through `ToNumber`, as the JavaScript
  /// `>` and `<` do.
  @override
  ({double min, double max}) getMinMax(IScale scale, [bool? canStack]) {
    final meta = cachedMeta;
    final parsedItems = meta.parsed;
    final sorted = meta.sorted && identical(scale, meta.iScale);
    final ilen = parsedItems.length;
    final otherScale = _getOtherScale(scale)!;
    final stack = _createStack(canStack, meta, chart);
    final range = _Range(double.infinity, double.negativeInfinity);
    final (min: otherMin, max: otherMax) = _getUserBounds(otherScale);
    final axis = scale.axis;
    final otherAxis = otherScale.axis;
    var i = 0;
    ParsedItem? parsed;

    bool skip() {
      parsed = parsedItems[i];
      final otherValue = jsToNumber(parsedValueOf(parsed, otherAxis));
      return !isFinite(parsedValueOf(parsed, axis)) ||
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
  @override
  List<double> getAllParsedValues(IScale scale) {
    final parsed = cachedMeta.parsed;
    final values = <double>[];
    final axis = scale.axis;
    Object? value;

    for (var i = 0, ilen = parsed.length; i < ilen; ++i) {
      value = parsedValueOf(parsed[i], axis);
      if (isFinite(value)) {
        values.add((value! as num).toDouble());
      }
    }
    return values;
  }

  /// core.datasetController.js:680 `getMaxOverflow()`.
  ///
  /// The pixels that the elements of the dataset can draw outside the chart
  /// area. Dart `null` is the JS `false`: no overflow, and the default clip
  /// of the dataset is [ChartClip.none] (row `adapt-max-overflow`).
  /// @protected
  // DIVERGES(chartjs): adapt-max-overflow, a double or null.
  double? getMaxOverflow() {
    return null;
  }

  /// core.datasetController.js:687 `getLabelAndValue(index)`.
  /// @protected
  ///
  /// The result is a record of the object `{label, value}`. `'' + value` is
  /// [jsToString].
  ///
  /// index.d.ts:641 declares a string label. The overrides of other
  /// controllers do not convert their label to a string. Scatter, bubble,
  /// doughnut, pie and polar area return `labels[index] || ''` of
  /// `chart.data.labels` (for example controller.scatter.js:51). Radar
  /// returns `vScale.getLabels()[index]` (controller.radar.js:44), and
  /// core.scale.js:358-361 reads the scale option `labels` first, then
  /// `xLabels` or `yLabels`, and `chart.data.labels` last. Thus the label
  /// can be any value: Dart `null` for JS `null`, or the [undefined]
  /// sentinel (Chart.js ADR 0028, section 2). The `value` is always a
  /// string.
  @override
  ({List<String> label, String value}) getLabelAndValue(int index) {
    final meta = cachedMeta;
    final iScale = meta.iScale;
    final vScale = meta.vScale;
    final parsed = getParsed(index);
    return (
      label: iScale != null
          ? dataLabelLinesOf(scaleLabelOf(iScale, _axisValueOf(parsed, iScale)))
          : const [],
      value: vScale != null
          ? scaleLabelOf(vScale, _axisValueOf(parsed, vScale))
          : '',
    );
  }

  /// `parsed[scale.axis]`: [parsedValueOf] with the axis of [scale].
  static Object? _axisValueOf(ParsedItem? parsed, IScale scale) {
    return parsedValueOf(parsed, scale.axis);
  }

  /// core.datasetController.js:701 `_update(mode)`. core.controller.js:677
  /// calls it. The name has a trailing underscore, because [update] has the
  /// name without the leading underscore (Chart.js ADR 0023).
  /// @private
  ///
  /// Dart `null` for [mode] stands for JS `undefined`.
  void update_([String? mode]) {
    final meta = cachedMeta;
    // DIVERGES(chartjs): adapt-scatter-overflow-refresh, names this caller.
    overflowFollowsUpdate = true;
    update(mode == null || mode.isEmpty ? 'default' : mode);
    overflowFollowsUpdate = false;
    // DIVERGES(chartjs): adapt-chart-clip-option, the option holds the
    // ChartClip of `toClip`. The default runs at each update, as upstream.
    final clip = options.readKey(OptionKey.clip);
    final orElse = _defaultClip(meta.xScale, meta.yScale, getMaxOverflow());
    assert(
      clip is ChartClip || identical(clip, undefined) || clip == null,
      'The option clip takes a ChartClip, not $clip.',
    );
    meta.clip = clip is ChartClip ? clip : orElse;
  }

  /// Whether the [update] that starts now has the [getMaxOverflow] of
  /// [update_] after it. A public call of [update] finds it false. An exact
  /// native controller takes it at its first statement (Chart.js ADR 0101).
  // DIVERGES(chartjs): adapt-scatter-overflow-refresh, the caller of `update`.
  bool overflowFollowsUpdate = false;

  /// core.datasetController.js:710 `update(mode)`.
  ///
  /// @param {string} mode
  void update(String mode) {} // eslint-disable-line no-unused-vars

  /// core.datasetController.js:712 `draw()`.
  ///
  /// The dataset element gets `start` and `count` when its `draw` takes
  /// them, as a line element does. Another element, also of a user element
  /// class, gets `ctx` and `area` only, as a JavaScript call ignores an extra
  /// argument (Chart.js ADR 0173). The port casts the elements to
  /// `types.VisualElement` for their `draw`.
  void draw() {
    final ctx = this.ctx;
    final chart = this.chart;
    final meta = cachedMeta;
    final elements = meta.data;
    final area = chart.chartArea;
    final active = <Element>[];
    final start = drawStart ?? 0;
    final drawCount = this.drawCount;
    final count = drawCount != null && drawCount != 0
        ? drawCount
        : elements.length - start;
    final drawActiveElementsOnTop = jsTruthy(
      options.readKey(OptionKey.drawActiveElementsOnTop),
    );
    int i;

    final dataset = meta.dataset;
    if (dataset != null) {
      final draw = (dataset as VisualElement).draw;
      // DIVERGES(chartjs): adapt-option-function-types, a typed draw call.
      // A null context throws a TypeError, as the JS call does.
      if (draw case final _RangeDraw rangeDraw) {
        rangeDraw(ctx!, area, start, count);
      } else {
        draw(ctx!, area);
      }
    }

    i = start;
    // DIVERGES(chartjs): adapt-point-circle-run, a run of markers, then the
    // ordinary loop from the first element that the run did not handle.
    final last = start + count;
    if (area != null &&
        ctx != null &&
        start >= 0 &&
        start < last &&
        last <= elements.length) {
      final head = elements[start];
      if (head is PointCircleRun) {
        i = (head as PointCircleRun).drawCircleRun(
          ctx,
          area,
          elements,
          start,
          last,
          active,
          activeOnTop: drawActiveElementsOnTop,
        );
      }
    }

    for (; i < start + count; ++i) {
      final element = _at(elements, i)! as Element;
      if (element.hidden) {
        continue;
      }
      if (element.active && drawActiveElementsOnTop) {
        active.add(element);
      } else {
        (element as VisualElement).draw(ctx!, area);
      }
    }

    for (var k = 0; k < active.length; ++k) {
      (active[k] as VisualElement).draw(ctx!, area);
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
  @override
  ElementOptions getStyle(int? index, [bool? active]) {
    // DIVERGES(chartjs): adapt-hidden-legend-items, a later build, no writes.
    final legend = legendStyles;
    if (legend != null) {
      return legend.styles.at(index! < legend.arcCount ? index : this.index);
    }
    final mode = (active ?? false) ? 'active' : 'default';
    return index == null && cachedMeta.dataset != null
        ? resolveDatasetElementOptions(mode)
        : resolveDataElementOptions(index ?? 0, mode);
  }

  /// core.datasetController.js:762 `getContext(index, active, mode)`.
  /// @protected
  ///
  /// Dart `null` for [index], [active] and [mode] stands for JS `undefined`.
  /// An [index] of a data element gives the context of that element: the
  /// typed member `$context` of the element ([Element.$context], Chart.js
  /// ADR 0054 §9).
  ///
  /// The contexts are typed [ScriptableContext] objects (Chart.js ADR 0054
  /// §11). A context of another class that user code put into `$context` of
  /// an element gives way to a new data context (row `adapt-typed-contexts`).
  ScriptableContext getContext([int? index, bool? active, String? mode]) {
    final dataset = getDataset();
    if (index != null && index >= 0 && index < cachedMeta.data.length) {
      final element = _at(cachedMeta.data, index)! as Element;
      // A context object is truthy: Dart `null` is the falsy `undefined`
      // start state.
      final current = element.$context;
      final elementContext = current is ScriptableContext
          ? current
          : (element.$context = _createDataContext(
              getContext(),
              index,
              element,
            ));
      // `raw` is read after the write of `parsed`, as upstream.
      return elementContext..refresh(
        getParsed(index),
        _rawOf(dataset, index),
        index,
        active ?? false,
        mode == null ? null : UpdateMode(mode),
      );
    }
    return ($context ??= _createDatasetContext(chart.getContext(), this.index))
      ..dataset = dataset
      ..datasetIndex = this.index
      ..index = this.index
      ..active = active ?? false
      ..mode = mode == null ? null : UpdateMode(mode);
  }

  /// core.datasetController.js:788 `resolveDatasetElementOptions(mode)`.
  ///
  /// @param {string} [mode]
  /// @protected
  ///
  /// Dart `null` for [mode] stands for JS `undefined`.
  ElementOptions resolveDatasetElementOptions([String? mode]) {
    return _resolveElementOptions(_idOf(datasetElementType), mode);
  }

  /// core.datasetController.js:797 `resolveDataElementOptions(index, mode)`.
  ///
  /// @param {number} index
  /// @param {string} [mode]
  /// @protected
  ///
  /// Dart `null` for [mode] stands for JS `undefined`.
  @override
  ElementOptions resolveDataElementOptions(int index, [String? mode]) {
    return _resolveElementOptions(_idOf(dataElementType), mode, index);
  }

  /// [resolveDataElementOptions] of a loop over the data elements, with the
  /// cache entry that the last call of the loop read (Chart.js ADR 0165).
  ///
  /// A hit of `_resolveElementOptions` (core.datasetController.js:804-811)
  /// gives `cloneIfNotShared(cache[elementType.id + '-' + mode], sharing)`.
  /// The call takes the entry of [hold] when the inputs of that read are
  /// those of the call that read it: the same `id` object of the data element
  /// type (a string, read with `_idOf` as each call does), an equal mode, and
  /// no write or clear of the cache since. Then the key is the same and the
  /// read gives the same entry. The call writes the last key as
  /// `_elementCacheKey` does. Each other call is the ordinary one, and holds
  /// its entry for the next call. [hold] lives inside one loop: no entry
  /// outlives the loop (Chart.js ADR 0054 section 4).
  // DIVERGES(chartjs): adapt-held-element-options, one cache read for a loop.
  ElementOptions resolveHeldDataElementOptions(
    HeldElementOptions hold,
    int index,
    String mode,
  ) {
    final elementType = dataElementType;
    final id = _idOf(elementType);
    final entry = hold._entry;
    if (entry != null &&
        identical(id, hold._id) &&
        mode == hold._mode &&
        hold._generation == _elementOptionsGeneration) {
      // The writes of `_elementCacheKey` for an equal key.
      _lastElementTypeName = hold._id;
      _lastElementMode = hold._mode;
      _lastElementCacheKey = hold._key;
      // A class value gives its `id` with no code of the app, and the clone of
      // the final class `PointOptions` is ours.
      hold
        ..native = elementType is JsClass && entry is PointOptions
        .._taken += 1;
      return _cloneIfNotShared(entry, enableOptionSharing);
    }
    hold
      ..native = false
      .._entry = null;
    final result = _resolveElementOptions(id, mode, index);
    // The key of this call, unless a call inside it wrote another one.
    if (id is String &&
        _lastElementTypeName == id &&
        _lastElementMode == mode) {
      final key = _lastElementCacheKey;
      final cached = _cachedElementOptions[key];
      if (cached != null) {
        hold
          .._id = id
          .._mode = mode
          .._key = key
          .._entry = cached
          .._generation = _elementOptionsGeneration;
      }
    }
    return result;
  }

  /// Existing per-mode cache entries must retain priority over a loop plan.
  // DIVERGES(chartjs): adapt-native-line-resolution, retain cache precedence.
  bool get hasCachedPointNoneOptions =>
      _cachedElementOptions.containsKey('point-none');

  /// The cached entry of the data element type and [mode], with no copy. An
  /// exact native controller reads a value of it. Dart `null` on a miss.
  // DIVERGES(chartjs): adapt-arc-native-options, a read needs no clone.
  ElementOptions? cachedDataElementOptions(String mode) =>
      _cachedElementOptions[_elementCacheKey(
        jsToString(_idOf(dataElementType)),
        mode,
      )];

  /// Whether [options], the result of the last data element call, is its
  /// frozen cached entry. For an exact native controller, each later call
  /// before [configure] is then a hit that gives the same object.
  // DIVERGES(chartjs): adapt-arc-native-options, the result that must repeat.
  bool isCachedElementOptions(ElementOptions options) =>
      identical(_cachedElementOptions[_lastElementCacheKey], options);

  /// [_lastElementCacheKey] for [typeName] and [mode].
  // DIVERGES(chartjs): adapt-element-option-cache-key, retain the original
  // string key (including collisions) and convert the element id every time.
  String _elementCacheKey(String typeName, String mode) {
    if (typeName == _lastElementTypeName && mode == _lastElementMode) {
      return _lastElementCacheKey;
    }
    _lastElementTypeName = typeName;
    _lastElementMode = mode;
    return _lastElementCacheKey = '$typeName-$mode';
  }

  /// The frozen `point-<mode>` entry of `_cachedDataOpts`, for native loops.
  // DIVERGES(chartjs): adapt-native-point-size, the entry a resolve copies.
  ElementOptions? cachedPointOptions(String mode) {
    final key = 'point-$mode';
    return _cachedElementOptions[key];
  }

  /// The entry that `_resolveElementOptions` gives for the type `point` in the
  /// mode `none`, without user code. Null before a shareable resolution.
  // DIVERGES(chartjs): adapt-radar-direct-updates, the existing cached entry.
  ElementOptions? get cachedPointNoneOptions =>
      _cachedElementOptions[_pointNoneCacheKey];

  /// The cache key of the options of the type `point` in the mode `none`.
  static const String _pointNoneCacheKey = 'point-none';

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
  ElementOptions _resolveElementOptions(
    Object? elementType, [
    String? mode,
    int? index,
  ]) {
    final resolvedMode = mode ?? 'default';
    final cache = _cachedElementOptions;
    final typeName = jsToString(elementType);
    final cacheKey = _elementCacheKey(typeName, resolvedMode);
    final cached = cache[cacheKey];
    final sharing = enableOptionSharing && index != null;
    if (cached != null) {
      return _cloneIfNotShared(cached, sharing);
    }
    return _resolveUncachedElementOptions(
      elementType,
      typeName,
      resolvedMode,
      index,
      cacheKey,
      sharing,
    );
  }

  /// The miss path of [_resolveElementOptions] (core.datasetController.js:
  /// 812-832).
  // DIVERGES(chartjs): adapt-element-option-cache-key, its own method: a hit
  // allocates no context for the closure of the context factory.
  ElementOptions _resolveUncachedElementOptions(
    Object? elementType,
    String typeName,
    String resolvedMode,
    int? index,
    String cacheKey,
    bool sharing,
  ) {
    final active = resolvedMode == 'active';
    final cache = _cachedElementOptions;
    final config = chart.config as Config;
    final scopeKeys = config.datasetElementScopeKeys(type, elementType);
    // DIVERGES(chartjs): adapt-option-resolution-setup, native prefixes.
    final List<String> prefixes;
    if (config.runtimeType == Config &&
        _nativePrefixType == typeName &&
        _nativePrefixActive == active) {
      prefixes = _nativePrefixes;
    } else {
      prefixes = active
          ? ['${typeName}Hover', 'hover', typeName, '']
          : [typeName, ''];
      if (config.runtimeType == Config) {
        _nativePrefixType = typeName;
        _nativePrefixActive = active;
        _nativePrefixes = prefixes;
      }
    }
    final scopes = config.getOptionScopes(getDataset(), scopeKeys);
    // The names are the own keys of the typed scope (Chart.js ADR 0054 §4):
    // `defaults.elements[elementType]`.
    final elements = chartjs.defaults.lookup(OptionKey.elements)?.raw;
    final elementDefaults = elements is OptionScope
        ? elements.jsRead(typeName)
        // A user object in the defaults reads by name.
        : jsGet(elements ?? undefined, elementType);
    final immutableKeys =
        config.runtimeType == Config &&
        identical(elementDefaults, _lastElementDefaults) &&
        _nativeSnapshotKeys;
    final keys = immutableKeys
        ? (elementDefaults! as OptionScope).nativeOwnKeySnapshot
        : elementDefaults is OptionScope
        ? elementDefaults.jsOwnKeys()
        // A user object in the defaults gives its keys.
        : <Object>[...jsObjectKeys(elementDefaults)];
    // DIVERGES(chartjs): adapt-indexed-element-options, classify only the
    // producer of the key list. Native immutable snapshots invalidate on key
    // changes; a custom producer retains its live virtual enumeration.
    if (!identical(elementDefaults, _lastElementDefaults)) {
      _lastElementDefaults = elementDefaults;
      _nativeElementDefaultKeys =
          elementDefaults is! OptionScope ||
          elementDefaults.runtimeType == PointOptionsScope ||
          elementDefaults.runtimeType == BarOptionsScope ||
          // DIVERGES(chartjs): adapt-arc-native-options, a third key producer.
          elementDefaults.runtimeType == ArcOptionsScope;
      _nativeSnapshotKeys =
          elementDefaults is OptionScope && _nativeElementDefaultKeys;
    }
    // context is provided as a function, and is called only if needed,
    // so we don't create a context for each element if not needed.
    ScriptableContext context() => getContext(index, active, resolvedMode);
    // DIVERGES(chartjs): adapt-typed-element-options, a typed result object.
    // DIVERGES(chartjs): adapt-owned-option-result, final results only.
    final values =
        _nativeElementDefaultKeys &&
            config.runtimeType == Config &&
            elementType is String &&
            (elementType == 'point' || elementType == 'bar')
        ? config.resolveOwnedElementNamedOptions(
            scopes,
            keys,
            context,
            prefixes,
            point: elementType == 'point',
            immutableKeys: immutableKeys,
          )
        : _nativeElementDefaultKeys &&
              config.runtimeType == Config &&
              elementType is String &&
              elementType == 'arc'
        ? config.resolveOwnedArcNamedOptions(
            scopes,
            keys,
            context,
            prefixes,
            immutableKeys: immutableKeys,
          )
        : _nativeElementDefaultKeys
        ? config.resolveNativeElementNamedOptions(
            scopes,
            keys,
            context,
            prefixes,
            createElementOptions(elementType),
            // DIVERGES(chartjs): adapt-prepared-indexed-options, this result
            // is owned here and cannot be observed by the context factory.
            allowReplacement: true,
          )
        : config.resolveElementNamedOptions(
            scopes,
            keys,
            context,
            prefixes,
            createElementOptions(elementType),
          );

    if (values.isShared) {
      // `$shared` indicates this set of options can be shared between
      // multiple elements. Sharing is used to reduce number of properties
      // to change during animation.
      values.storeKey(OptionKey.dollarShared, sharing);

      // We cache options by `mode`, which can be 'active' for example. This
      // enables us to have the 'active' element options and 'default'
      // options to switch between when interacting.
      cache[cacheKey] = jsObjectFreeze(_cloneIfNotShared(values, sharing));
      // DIVERGES(chartjs): adapt-held-element-options, the write ends a hold.
      _elementOptionsGeneration++;
      // DIVERGES(chartjs): adapt-hidden-legend-items, the cache of the entry.
      if (!active) _staticEntryGeneration = config.resolutionGeneration;
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
  Animations resolveAnimations([int? index, String? transition, bool? active]) {
    final chart = this.chart;
    final cache = _cachedAnimations;
    // The transition of the key `animation-${transition}`.
    final cacheKey = transition ?? 'undefined';
    final cached = cache[cacheKey];
    if (cached != null) {
      return cached;
    }
    OptionView? options;
    if (readOption(chart.options, OptionKey.animation) != false) {
      final config = this.chart.config as Config;
      final scopeKeys = config.datasetAnimationScopeKeys(
        type,
        transition ?? undefined,
      );
      final scopes = config.getOptionScopes(getDataset(), scopeKeys);
      // The context is an object: the result is a view.
      options = config.createResolver(
        scopes,
        getContext(index, active, transition),
      ) as OptionView;
    }
    // DIVERGES(chartjs): adapt-property-animations, the items of the app.
    // A chart with no item makes no read of `animation` here.
    final holder = options != null && chart is ChartAnimationItems
        ? chart as ChartAnimationItems
        : null;
    final items = holder?.propertyAnimations;
    final modeItems = transitionIn(
      holder?.chartTransitions,
      transition,
    )?.animations;
    final hasItems =
        (items != null && items.isNotEmpty) ||
        (modeItems != null && modeItems.isNotEmpty);
    final animations = Animations(
      chart,
      options == null ? undefined : options.readKey(OptionKey.animations),
      items: items,
      modeItems: modeItems,
      base: hasItems ? options!.readKey(OptionKey.animation) : null,
    );
    if (options != null && options.cacheable) {
      cache[cacheKey] = jsObjectFreeze(animations);
    }
    return animations;
  }

  /// Whether [resolveAnimations] holds no animations of [transition]. Then,
  /// with the chart option `animation` equal to `false`, it gives a new empty
  /// `Animations` at each call (Chart.js ADR 0152).
  bool hasNoCachedAnimations(String transition) =>
      !_cachedAnimations.containsKey(transition);

  /// core.datasetController.js:867 `getSharedOptions(options)`.
  ///
  /// Utility for getting the options object shared between elements
  /// @protected
  ///
  /// Dart `null` stands for the JS `undefined` result. The copy keeps the
  /// class of the options (Chart.js ADR 0021, section 3).
  ElementOptions? getSharedOptions(ElementOptions options) {
    if (!options.isShared) {
      return null;
    }
    // DIVERGES(chartjs): adapt-typed-element-options, the copy keeps the class.
    return sharedOptions ??= options.clone();
  }

  /// core.datasetController.js:878 `includeOptions(mode, sharedOptions)`.
  ///
  /// Utility for determining if `options` should be included in the updated
  /// properties
  /// @protected
  ///
  /// Dart `null` for [sharedOptions] stands for JS `undefined`.
  bool includeOptions(String mode, ElementOptions? sharedOptions) {
    return sharedOptions == null ||
        _isDirectUpdateMode(mode) ||
        (chart.animationsDisabled ?? false);
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
  ({ElementOptions? sharedOptions, bool includeOptions}) getSharedOptions_(
    int start,
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
  ///
  /// index.d.ts:674 types [element] as `TElement | TDatasetElement`. Thus the
  /// parameter is a `types.Element`, and a controller passes its elements
  /// without a cast (Chart.js ADR 0028, section 1).
  void updateElement(
    IElement element,
    int? index,
    Object properties,
    String mode,
  ) {
    if (_isDirectUpdateMode(mode)) {
      // Each data and dataset element is an Element: the casts of
      // addElements and _insertElements (row adapt-component-class-role).
      (element as Element).assign(properties);
    } else {
      // DIVERGES(chartjs): adapt-shared-bar-animations, one resolution for
      // the bars of one update, under the guard of animation_share.dart.
      final shared = sharedAnimations;
      if (shared != null && index != null && shared.mode == mode) {
        shared.updateElement(element, index, properties);
        return;
      }
      resolveAnimations(index, mode).update(element, properties);
    }
  }

  /// The kept animation options of the `BarController.update` or
  /// `ScatterController.update` call that runs now, or Dart `null` (Chart.js
  /// ADRs 0151 and 0160). Only these two methods write it, and each clears it
  /// at the end of its loop.
  // DIVERGES(chartjs): adapt-shared-bar-animations, it lives for one loop.
  SharedBarAnimations? sharedAnimations;

  /// core.datasetController.js:910 `updateSharedOptions(sharedOptions, mode,
  /// newOptions)`.
  ///
  /// Utility to animate the shared options, that are potentially affecting
  /// multiple elements.
  /// @protected
  ///
  /// Dart `null` for [sharedOptions] stands for JS `undefined`.
  void updateSharedOptions(
    ElementOptions? sharedOptions,
    String mode,
    ElementOptions newOptions,
  ) {
    if (sharedOptions != null && !_isDirectUpdateMode(mode)) {
      resolveAnimations(null, mode).update(sharedOptions, newOptions);
    }
  }

  /// core.datasetController.js:919 `_setStyle(element, index, mode,
  /// active)`.
  /// @private
  ///
  /// The element is of any class. Thus the object `{options}` stays a Map
  /// of one key, the key of each props class of Chart.js ADR 0054 §9.
  void _setStyle(Element element, int? index, String mode, bool active) {
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
  /// index)`. Dart `null` stands for an absent argument, JS `undefined`.
  void removeHoverStyle(Element element, [int? datasetIndex, int? index]) {
    _setStyle(element, index, 'active', false);
  }

  /// core.datasetController.js:933 `setHoverStyle(element, datasetIndex,
  /// index)`. Dart `null` stands for an absent argument, JS `undefined`.
  void setHoverStyle(Element element, [int? datasetIndex, int? index]) {
    _setStyle(element, index, 'active', true);
  }

  /// core.datasetController.js:940 `_removeDatasetHoverStyle()`.
  /// core.controller.js:1072 calls it by name.
  /// @private
  void removeDatasetHoverStyle() {
    final element = cachedMeta.dataset;

    if (element != null) {
      _setStyle(element as Element, null, 'active', false);
    }
  }

  /// core.datasetController.js:951 `_setDatasetHoverStyle()`.
  /// core.controller.js:1072 calls it by name.
  /// @private
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
    final count = math.min(numData, numMeta);

    if (count != 0) {
      // It is not optimal to always parse the old data
      // This is done because we are not detecting direct assignments:
      // chart.data.datasets[0].data[5] = 10;
      // chart.data.datasets[0].data[5].y = 10;
      parse(0, count);
    }

    if (numData > numMeta) {
      _insertElements(numMeta, numData - numMeta, resetNewElements);
    } else if (numData < numMeta) {
      _removeElements(numData, numMeta - numData);
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
  void _insertElements(int start, int count, [bool? resetNewElements]) {
    final meta = cachedMeta;
    final data = meta.data;
    final end = start + count;
    int i;

    // `arr.length += count` and the loop of :1001-1003: the items from
    // `start` move to `end`, and the indexes in `start..end` keep their old
    // items. An index in `start..end` at or past the old length is a hole,
    // [filler]. The new elements replace the items of `data` next. `parse`
    // reads the old parsed item of an index below the old length through
    // the context of an option, as upstream does.
    void move<T>(List<T> arr, T filler) {
      final from = start;
      final oldLength = arr.length;
      arr.insertAll(
        from,
        List<T>.generate(
          count,
          (k) => from + k < oldLength ? arr[from + k] : filler,
        ),
      );
    }

    move<IElement>(data, _hole);

    for (i = start; i < end; ++i) {
      // DIVERGES(chartjs): adapt-component-class-role, the cast throws earlier.
      data[i] = jsConstruct(dataElementType, const []) as Element;
    }

    if (parsing != null) {
      // `arr.length += count` leaves holes, JS `undefined`.
      move<ParsedItem?>(meta.parsed, null);
    }
    parse(start, count);

    if (resetNewElements ?? true) {
      updateElements(data, start, count, 'reset');
    }
  }

  /// core.datasetController.js:1022 `updateElements(element, start, count,
  /// mode)`.
  void updateElements(
    List<IElement> elements,
    int start,
    int count,
    String mode,
  ) {} // eslint-disable-line no-unused-vars

  /// core.datasetController.js:1027 `_removeElements(start, count)`.
  /// @private
  void _removeElements(int start, int count) {
    final meta = cachedMeta;
    if (parsing != null) {
      final removed = _removeRange(meta.parsed, start, count);
      if (meta.stacked != StackMode.off) {
        _clearStacks(meta, removed);
      }
    }
    _removeRange(meta.data, start, count);
  }

  /// core.datasetController.js:1041 `_sync(args)`.
  /// @private
  ///
  /// [args] is `[method, start, count]`.
  void _sync(List<Object?> args) {
    if (parsing != null) {
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
    // dart2wasm of Dart 3.14.0-315.3.beta traps on a String switch over a
    // value that is neither null nor a String. Such a value switches as null
    // and takes the default branch, as before.
    switch (method is String ? method : null) {
      case '_insertElements':
        _insertElements((arg1! as num).toInt(), (arg2! as num).toInt());
      case '_removeElements':
        _removeElements((arg1! as num).toInt(), (arg2! as num).toInt());
      default:
        // A JavaScript TypeError: this[method] is not a function.
        throw TypeError();
    }
  }

  /// core.datasetController.js:1051 `_onDataPush()`. `arguments.length` is
  /// the count of [items].
  @override
  void onDataPush(List<Object?> items) {
    final count = items.length;
    _sync([
      '_insertElements',
      jsToNumber(jsGet(jsGet(getDataset(), 'data'), 'length')).toInt() - count,
      count,
    ]);
  }

  /// core.datasetController.js:1056 `_onDataPop()`.
  @override
  void onDataPop() {
    _sync(['_removeElements', cachedMeta.data.length - 1, 1]);
  }

  /// core.datasetController.js:1060 `_onDataShift()`.
  @override
  void onDataShift() {
    _sync(['_removeElements', 0, 1]);
  }

  /// core.datasetController.js:1064 `_onDataSplice(start, count)`.
  ///
  /// [index] is `start`, [deleteCount] is `count`, and `arguments.length -
  /// 2` is the count of [items].
  @override
  void onDataSplice(int index, int deleteCount, List<Object?> items) {
    if (deleteCount != 0) {
      _sync(['_removeElements', index, deleteCount]);
    }
    final newCount = items.length;
    if (newCount != 0) {
      _sync(['_insertElements', index, newCount]);
    }
  }

  /// core.datasetController.js:1074 `_onDataUnshift()`. `arguments.length`
  /// is the count of [items].
  @override
  void onDataUnshift(List<Object?> items) {
    _sync(['_insertElements', 0, items.length]);
  }
}

/// `!!options.fill` (core.datasetController.js:287): the JS truthiness of
/// the value of the option `fill`, a [FillTarget] (row
/// `adapt-fill-target-objects`). `undefined` and `null` are falsy.
bool _fillTruthy(Object? fill) => switch (FillTarget.of(fill)) {
  final FillTarget target => fillTargetTruthy(target),
  null => false,
};

/// The `draw` of a dataset element that takes `start` and `count`, as
/// `LineElement.draw` does (element.line.js:427).
typedef _RangeDraw = void Function(
  CanvasRenderingContext2D ctx,
  ChartArea? area,
  int? start,
  int? count,
);

/// `list.splice(start, count)`: removes [count] items from [start] and gives
/// them. [start] and the end clamp to the List, as `splice` does.
List<T> _removeRange<T>(List<T> list, int start, int count) {
  final length = list.length;
  final from = start < 0 ? 0 : (start > length ? length : start);
  final end = from + count;
  final to = end > length ? length : (end < from ? from : end);
  final removed = list.sublist(from, to);
  list.removeRange(from, to);
  return removed;
}
