// Ported from Chart.js v4.6.1 src/controllers/controller.bar.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-typed-parsed, the typed data of Chart.js ADR 0054.

/// Port of `src/controllers/controller.bar.js`.
///
/// [BarController] is the dataset controller of the `bar` charts. It parses
/// the float bars (`[start, end]`), computes the pixels of each bar from the
/// index scale and the value scale, and writes the properties of each
/// `BarElement` through `updateElement`.
///
/// - The parsed data is typed (Chart.js ADR 0054 §8): a parsed item is a
///   [ParsedItem], its `_custom` of a float bar a [FloatingBar], and its
///   stack object a [StackEntry]. The reads of a parsed value are
///   [parsedValueOf], and the reads of the stacks [stacksOf] and
///   [axisStackOf]. A parsed item of `parsing: false` is a data item of the
///   user: it and its `_custom` and `_stacks` objects read by name
///   ([jsGetKey], Chart.js ADR 0036).
/// - The dataset options read typed ([OptionView.readKey]), and so do the
///   [BarOptions] of an element. The options of a user element type read
///   by name. The properties of a bar are a [BarProperties] (Chart.js ADR
///   0054 §9).
/// - A raw option value stays `Object?` until its upstream operator. Then
///   the port applies the runtime form of that operator: [jsToNumber],
///   [jsTruthy], [jsAdd] or the Dart `==` for `===` (Chart.js ADR 0036,
///   section 7). Where both operands of `===` can be a `Date`, the port
///   compares with `_strictEquals`: Dart `==` compares two `DateTime`
///   values by their time, `===` by identity.
/// - The controller reads the members of other modules through
///   `lib/src/types/` and imports no concrete scale, element or chart
///   module (Chart.js ADR 0028, section 1). The draw casts each bar to
///   `types.VisualElement`, as `DatasetController.draw` does.
/// - [BarController.jsClass] is the class as a value with the statics `id`,
///   `defaults` and `overrides` (Chart.js ADR 0020, section 3).
/// - The memo of `_getAxis`, `getFirstScaleIdForIndexAxis` and `_getStacks`
///   for each bar, the `skipNull` find and the empty object of
///   `(parsed._stacks || {})` are ported literally (Chart.js ADR 0036,
///   section 8: the step 7 list).
///
/// This library imports `core.datasetController.dart`, which imports
/// `core.animations.dart`. Thus it is not a pure layer.
library;

import 'dart:typed_data';

import 'package:flutter_chartjs_port/src/core/bar_bulk_update.dart';
import 'package:flutter_chartjs_port/src/core/bar_index_layout.dart';
import 'package:flutter_chartjs_port/src/core/bar_sorted_values.dart';
import 'package:flutter_chartjs_port/src/core/core.config.dart' show Config;

import 'package:flutter_chartjs_port/src/core/core.datasetController.dart'
    show
        DatasetController,
        DatasetStack,
        axisStackOf,
        controllerArgs,
        dataItemValue,
        parsedValueOf,
        setStackValue,
        stacksOf,
        visualValuesOf;
import 'package:flutter_chartjs_port/src/core/data_update.dart'
    show nativeDataUpdateList;
import 'package:flutter_chartjs_port/src/core/point_option_preparation.dart'
    show prepareNativePointContexts;
import 'package:flutter_chartjs_port/src/core/primitive_parse.dart';
import 'package:flutter_chartjs_port/src/elements/element_options.dart'
    show BarOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show arrayUnique;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show OptionView, readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show defined, isArray, isNullOrUndef, valueOrDefault;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show MinMax, sign;
import 'package:flutter_chartjs_port/src/js/js_array.dart'
    show jsObjectKeys, jsSort;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsMin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex, jsGetKey;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/parsed.dart'
    show AxisKey, FloatingBar, ParsedItem, StackEntry;
import 'package:flutter_chartjs_port/src/options/props.dart'
    show BarProperties, BorderSkipped;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show
        AnimationOptionsScope,
        AnimationsSpecScope,
        BarControllerDatasetOptionsScope,
        ChartOptionsScope,
        GridLineOptionsScope,
        ScaleOptionsByIdScope,
        ScaleOptionsScope;
import 'package:flutter_chartjs_port/src/types/bar_option_enums.dart'
    show BorderSkippedEdge;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// controller.bar.js:546-556 the object of `_getRuler` (Chart.js ADR 0003).
///
/// - `min` is `barThickness || computeMinSampleSize(meta)`: the raw option
///   value or a number (Chart.js ADR 0036, section 7).
/// - `grouped` is the raw `grouped` option.
typedef _Ruler = ({
  Object? min,
  List<double> pixels,
  double start,
  double end,
  double stackCount,
  types.Scale scale,
  Object? grouped,
  double ratio,
});

/// controller.bar.js:76-80 and :110-114 the object `{chunk, ratio, start}`
/// of `computeFitCategoryTraits` and `computeFlexCategoryTraits`.
///
/// `ratio` is the raw `barPercentage` option or 1. Its only reader applies
/// `ToNumber` (:652).
typedef _CategoryTraits = ({double chunk, Object? ratio, double start});

/// controller.bar.js:625-630 and :660-665 the object `{size, base, head,
/// center}` of `_calculateBarValuePixels` and `_calculateBarIndexPixels`.
typedef _BarPixels = ({double size, double base, double head, double center});

/// controller.bar.js:7 `getAllScaleValues(scale, type)`.
///
/// `scale._cache.$bar` holds the sorted unique values: the typed field
/// `ScaleCache.bar` (Chart.js ADR 0054 §4). Only this function writes it. An
/// array is truthy in JavaScript, thus `!scale._cache.$bar` is true only for
/// an absent entry, Dart `null`.
List<double> _getAllScaleValues(types.Scale scale, String type) {
  final cached = scale.cache.bar;
  if (cached != null) {
    return cached;
  }
  final visibleMetas = scale.getMatchingVisibleMetas(type);
  var values = <double>[];

  for (var i = 0, ilen = visibleMetas.length; i < ilen; i++) {
    // `values.concat(...)`: a new List.
    values = values + visibleMetas[i].controller!.getAllParsedValues(scale);
  }
  // DIVERGES(chartjs): adapt-sorted-bar-values, owned numeric sorted input.
  // Concatenation owns this list; no user getters or comparator are omitted.
  final unique =
      uniqueSortedBarValues(values) ??
      arrayUnique(jsSort(values, (a, b) => a - b));
  scale.cache.bar = unique;
  return unique;
}

/// controller.bar.js:24 `computeMinSampleSize(meta)`.
///
/// Computes the "optimal" sample size to maintain bars equally sized while
/// preventing overlap.
/// @private
///
/// `curr` is Dart `null` for the JS `null` of `getPixelForTick`. `prev`
/// starts as [undefined]. `curr - prev` applies `ToNumber` to both.
double _computeMinSampleSize(types.ChartMeta meta) {
  final scale = meta.iScale!;
  final values = _getAllScaleValues(scale, meta.type);
  var min = scale.length;
  double? curr;
  Object? prev = undefined;
  void updateMinAndPrev() {
    if (curr == 32767 || curr == -32768) {
      // Ignore truncated pixels
      return;
    }
    if (defined(prev)) {
      // curr - prev === 0 is ignored
      final difference = (jsToNumber(curr) - jsToNumber(prev)).abs();
      min = jsMin(min, jsTruthy(difference) ? difference : min);
    }
    prev = curr;
  }

  for (var i = 0, ilen = values.length; i < ilen; ++i) {
    curr = scale.getPixelForValue(values[i]);
    updateMinAndPrev();
  }

  prev = undefined;
  for (var i = 0, ilen = scale.ticks!.length; i < ilen; ++i) {
    curr = scale.getPixelForTick(i);
    updateMinAndPrev();
  }

  return min;
}

/// controller.bar.js:61 `computeFitCategoryTraits(index, ruler, options,
/// stackCount)`.
///
/// Computes an "ideal" category based on the absolute bar thickness or, if
/// undefined or null, uses the smallest interval (see computeMinSampleSize)
/// that prevents bar overlapping. This mode currently always generates bars
/// equally sized (until we introduce scriptable options?).
/// @private
///
/// `ruler.pixels` has one pixel for each data element. Thus [index] is in
/// its range.
_CategoryTraits _computeFitCategoryTraits(
  double index,
  _Ruler ruler,
  OptionView options,
  double stackCount,
) {
  final thickness = options.readKey(OptionKey.barThickness);
  double size;
  Object? ratio;

  if (isNullOrUndef(thickness)) {
    size =
        jsToNumber(ruler.min) *
        jsToNumber(options.readKey(OptionKey.categoryPercentage));
    ratio = options.readKey(OptionKey.barPercentage);
  } else {
    // When bar thickness is enforced, category and bar percentages are
    // ignored.
    // Note(SB): we could add support for relative bar thickness (e.g.
    // barThickness: '50%') and deprecate barPercentage since this value is
    // ignored when thickness is absolute.
    size = jsToNumber(thickness) * stackCount;
    ratio = 1.0;
  }

  return (
    chunk: size / stackCount,
    ratio: ratio,
    start: ruler.pixels[index.toInt()] - (size / 2),
  );
}

/// controller.bar.js:89 `computeFlexCategoryTraits(index, ruler, options,
/// stackCount)`.
///
/// Computes an "optimal" category that globally arranges bars side by side
/// (no gap when percentage options are 1), based on the previous and
/// following categories. This mode generates bars with different widths
/// when data are not evenly spaced.
/// @private
///
/// Dart `null` for `prev` and `next` is the JS `null` of :92-93.
_CategoryTraits _computeFlexCategoryTraits(
  double index,
  _Ruler ruler,
  OptionView options,
  double stackCount,
) {
  final pixels = ruler.pixels;
  final curr = pixels[index.toInt()];
  var prev = index > 0 ? pixels[index.toInt() - 1] : null;
  var next = index < pixels.length - 1 ? pixels[index.toInt() + 1] : null;
  final percent = options.readKey(OptionKey.categoryPercentage);

  // :96 `if (prev === null)`.
  // first data: its size is double based on the next point or,
  // if it's also the last data, we use the scale size.
  prev ??= curr - (next == null ? ruler.end - ruler.start : next - curr);

  // :102 `if (next === null)`.
  // last data: its size is also double based on the previous point.
  next ??= curr + curr - prev;

  final start = curr - (curr - jsMin(prev, next)) / 2 * jsToNumber(percent);
  final size = (next - prev).abs() / 2 * jsToNumber(percent);

  return (
    chunk: size / stackCount,
    ratio: options.readKey(OptionKey.barPercentage),
    start: start,
  );
}

/// controller.bar.js:117 `parseFloatBar(entry, item, vScale, i)`.
///
/// [entry] is a List (`isArray`, :145). `Math.min` and `Math.max` apply
/// `ToNumber` to the parsed values. `_custom` is a [FloatingBar]: it keeps
/// the parsed values as they are in `start` and `end`. [vKey] is the key of
/// the axis of [vScale].
void _parseFloatBar(
  Object? entry,
  ParsedItem item,
  types.Scale vScale,
  AxisKey vKey,
  double i,
) {
  final startValue = vScale.parse(jsGetIndex(entry, 0), i);
  final endValue = vScale.parse(jsGetIndex(entry, 1), i);
  final min = jsMin(jsToNumber(startValue), jsToNumber(endValue));
  final max = jsMax(jsToNumber(startValue), jsToNumber(endValue));
  var barStart = min;
  var barEnd = max;

  if (min.abs() > max.abs()) {
    barStart = max;
    barEnd = min;
  }

  // Store `barEnd` (furthest away from origin) as parsed value,
  // to make stacking straight forward
  item
    ..setValue(vKey, vScale.axis, barEnd)
    ..custom = FloatingBar(
      barStart: barStart,
      barEnd: barEnd,
      start: startValue,
      end: endValue,
      min: min,
      max: max,
    );
}

/// controller.bar.js:144 `parseValue(entry, item, vScale, i)`. [vKey] is
/// the key of the axis of [vScale].
ParsedItem _parseValue(
  Object? entry,
  ParsedItem item,
  types.Scale vScale,
  AxisKey vKey,
  double i,
) {
  if (isArray(entry)) {
    _parseFloatBar(entry, item, vScale, vKey, i);
  } else {
    item.setValue(vKey, vScale.axis, vScale.parse(entry, i));
  }
  return item;
}

/// controller.bar.js:153 `parseArrayOrPrimitive(meta, data, start, count)`.
///
/// Each item is a [ParsedItem]: the key of the index axis first, then the
/// key of the value axis and `_custom` (Chart.js ADR 0054 §8).
List<ParsedItem> _parseArrayOrPrimitive(
  types.ChartMeta meta,
  List<Object?> data,
  double start,
  double count,
) {
  final iScale = meta.iScale;
  final vScale = meta.vScale;
  final labels = iScale!.getLabels();
  // DIVERGES(chartjs): adapt-numeric-category-parse, guarded native range.
  final numeric = tryParseNumericCategories(
    iScale,
    vScale,
    labels,
    data,
    start,
    count,
  );
  if (numeric != null) return numeric;
  final singleScale = identical(iScale, vScale);
  final iKey = AxisKey.of(iScale.axis);
  // Upstream reads `vScale.axis` in the loop: no read for no item.
  final vKey = vScale == null ? AxisKey.other : AxisKey.of(vScale.axis);
  final parsed = <ParsedItem>[];

  for (var i = start, ilen = start + count; i < ilen; ++i) {
    final entry = jsGetIndex(data, i);
    // :164 `singleScale || iScale.parse(labels[i], i)`: the value of `||`,
    // `true` for a single scale.
    final item = ParsedItem()
      ..setValue(
        iKey,
        iScale.axis,
        singleScale ? true : iScale.parse(jsGetIndex(labels, i), i),
      );
    parsed.add(_parseValue(entry, item, vScale!, vKey, i));
  }
  return parsed;
}

/// `parsed._custom` of a parsed item: the typed field of a [ParsedItem],
/// else the read by name of a data item of `parsing: false`.
Object? _customOf(Object? parsed) =>
    parsed is ParsedItem ? parsed.custom : jsGetKey(parsed, '_custom');

/// `custom[key]` of the `_custom` object of a data item of `parsing: false`
/// (a user object), or of a [FloatingBar] that holds a value that user code
/// wrote by name: the raw value, read by name. A [FloatingBar] of the
/// parse reads typed at each site.
Object? _userCustomValue(Object? custom, String key) => jsGetKey(custom, key);

/// controller.bar.js:170 `isFloatBar(custom)`.
///
/// Upstream returns the value of `&&`. Each caller tests it as a boolean
/// (:410, :568), so a `bool` result keeps the behavior.
///
/// A [FloatingBar] has numbers in `barStart` and `barEnd`. A key that user
/// code deleted or wrote by name with another value gives NaN in the typed
/// field: then the face gives the JS value.
bool _isFloatBar(Object? custom) {
  if (custom is FloatingBar) {
    return (!custom.barStart.isNaN ||
            !identical(custom.jsRead('barStart'), undefined)) &&
        (!custom.barEnd.isNaN ||
            !identical(custom.jsRead('barEnd'), undefined));
  }
  return jsTruthy(custom) &&
      !identical(_userCustomValue(custom, 'barStart'), undefined) &&
      !identical(_userCustomValue(custom, 'barEnd'), undefined);
}

/// `stack._top` of the stack object of a bar (:220, :410): the typed field
/// of a [StackEntry], else the read by name of a `_stacks` object that user
/// code gave a data item of `parsing: false`. A value of another class that
/// user code wrote into a [StackEntry] reads through the face.
Object? _stackTop(Object? stack) => stack is StackEntry
    ? stack.top ?? stack.jsRead('_top')
    : jsGetKey(stack, '_top');

/// `stack._bottom` of the stack object of a bar (:222, :410), as
/// [_stackTop].
Object? _stackBottom(Object? stack) => stack is StackEntry
    ? stack.bottom ?? stack.jsRead('_bottom')
    : jsGetKey(stack, '_bottom');

/// controller.bar.js:174 `barSign(size, vScale, actualBase)`.
///
/// `vScale.min >= actualBase` compares the number `min` with the
/// `ToNumber` of [actualBase], as the JavaScript `>=` does for a number
/// operand.
double _barSign(double size, types.Scale vScale, Object? actualBase) {
  if (size != 0) {
    return sign(size);
  }
  return (vScale.isHorizontal() ? 1 : -1) *
      (vScale.min >= jsToNumber(actualBase) ? 1 : -1);
}

/// controller.bar.js:181 `borderProps(properties)`.
///
/// `base`, `x` and `y` are numbers: `a > b` compares two `double` values.
// DIVERGES(chartjs): adapt-border-skipped-enum, the enum values.
({
  BorderSkippedEdge start,
  BorderSkippedEdge end,
  bool reverse,
  BorderSkippedEdge top,
  BorderSkippedEdge bottom,
})
_borderProps(BarProperties properties) {
  bool reverse;
  BorderSkippedEdge start;
  BorderSkippedEdge end;
  BorderSkippedEdge top;
  BorderSkippedEdge bottom;
  if (properties.horizontal) {
    reverse = properties.base > properties.x;
    start = BorderSkippedEdge.left;
    end = BorderSkippedEdge.right;
  } else {
    reverse = properties.base < properties.y;
    start = BorderSkippedEdge.bottom;
    end = BorderSkippedEdge.top;
  }
  if (reverse) {
    top = BorderSkippedEdge.end;
    bottom = BorderSkippedEdge.start;
  } else {
    top = BorderSkippedEdge.start;
    bottom = BorderSkippedEdge.end;
  }
  return (start: start, end: end, reverse: reverse, top: top, bottom: bottom);
}

/// The strict equality `a === b` of JavaScript.
///
/// Numbers compare by value: `0 === -0` is true and `NaN === NaN` is false,
/// as Dart `==` on `num` gives. Strings compare by value. Every other value
/// compares by identity: `true`, `false`, `null` and [undefined] are single
/// instances, and objects compare by reference. A number and a string are
/// never equal.
///
/// Dart `==` is not `===` for each value: a `DateTime` stands for a JS
/// `Date` (Chart.js ADR 0024), and Dart `==` compares two `DateTime`
/// values by their time. `===` compares two Dates by identity. Thus the
/// sites where both operands can be a data value or an option value use
/// this function: the stack names (`:462`, `:521`), the `skipNull` find
/// (`:444`), `value === actualBase` (`:603`) and `(stack._top || 0) ===
/// index` (`:220`, `:222`).
bool _strictEquals(Object? a, Object? b) {
  if (a is num && b is num) return a == b;
  if (a is String && b is String) return a == b;
  return identical(a, b);
}

/// The JS `value || 0` without `ToNumber`: a truthy value stays as it is.
Object? _orZero(Object? value) => jsTruthy(value) ? value : 0.0;

/// `res[edge] = true` of `setBorderSkipped` (:222, :226): the typed field of
/// the edge `top`, `right`, `bottom` or `left`, else an extra with the name
/// of the edge (the property key `ToString(edge)` of upstream: `start`,
/// `end` or `middle` of a [BorderSkippedEdge], or another value of the
/// user).
// DIVERGES(chartjs): adapt-border-skipped-enum, the enum values.
void _skipEdge(BorderSkipped res, Object? edge) {
  switch (edge) {
    case BorderSkippedEdge.top:
      res.top = true;
    case BorderSkippedEdge.right:
      res.right = true;
    case BorderSkippedEdge.bottom:
      res.bottom = true;
    case BorderSkippedEdge.left:
      res.left = true;
    case final BorderSkippedEdge other:
      res.jsWrite(other.name, true);
    default:
      res.jsWrite(jsToString(edge), true);
  }
}

/// controller.bar.js:202 `setBorderSkipped(properties, options, stack,
/// index)`.
///
/// `res` is a [BorderSkipped] (Chart.js ADR 0054 §9). The property key of
/// `res[edge]` is the `ToString` of the edge ([_skipEdge]). The options are
/// `properties.options || bars[i].options`: a [BarOptions] reads typed
/// ([readOption]), and the options of a user element type read by name.
///
/// `(stack._top || 0) === index` keeps a truthy `_top` as it is and
/// compares it with `===` ([_strictEquals]). No arithmetic follows, thus
/// the port does not apply `ToNumber`: a `_top` of `'0'` or `true` is not
/// the dataset index 0 or 1. Only a user `_stacks` object in a `parsing:
/// false` item can hold such a value.
void _setBorderSkipped(
  BarProperties properties,
  Object? options,
  Object? stack,
  double index,
) {
  var edge = readOption(options, OptionKey.borderSkipped);
  final res = BorderSkipped();

  if (!jsTruthy(edge)) {
    properties.borderSkipped = res;
    return;
  }

  if (edge == true) {
    properties.borderSkipped = BorderSkipped.all();
    return;
  }

  final (:start, :end, :reverse, :top, :bottom) = _borderProps(properties);

  // DIVERGES(chartjs): adapt-border-skipped-enum, the enum value.
  if (edge == BorderSkippedEdge.middle && jsTruthy(stack)) {
    properties.enableBorderRadius = true;
    if (_strictEquals(_orZero(_stackTop(stack)), index)) {
      edge = top;
    } else if (_strictEquals(_orZero(_stackBottom(stack)), index)) {
      edge = bottom;
    } else {
      _skipEdge(res, _parseEdge(bottom, start, end, reverse));
      edge = top;
    }
  }

  _skipEdge(res, _parseEdge(edge, start, end, reverse));
  properties.borderSkipped = res;
}

/// controller.bar.js:234 `parseEdge(edge, a, b, reverse)`.
Object? _parseEdge(
  Object? edge,
  BorderSkippedEdge a,
  BorderSkippedEdge b,
  bool reverse,
) {
  var result = edge;
  if (reverse) {
    result = _swap(result, a, b);
    result = _startEnd(result, b, a);
  } else {
    result = _startEnd(result, a, b);
  }
  return result;
}

/// controller.bar.js:244 `swap(orig, v1, v2)`.
Object? _swap(Object? orig, BorderSkippedEdge v1, BorderSkippedEdge v2) {
  return orig == v1
      ? v2
      : orig == v2
      ? v1
      : orig;
}

/// controller.bar.js:248 `startEnd(v, start, end)`.
Object? _startEnd(Object? v, BorderSkippedEdge start, BorderSkippedEdge end) {
  return v == BorderSkippedEdge.start
      ? start
      : v == BorderSkippedEdge.end
      ? end
      : v;
}

/// controller.bar.js:252 `setInflateAmount(properties, {inflateAmount},
/// ratio)`.
///
/// The element takes a number (Chart.js ADR 0017, section 5). Its only
/// reader applies ToNumber (element.bar.js:127-140, :179-196). An absent
/// option gives the property `undefined`, through the face of the props.
void _setInflateAmount(
  BarProperties properties,
  Object? options,
  double ratio,
) {
  final inflateAmount = readOption(options, OptionKey.inflateAmount);
  if (inflateAmount == 'auto') {
    properties.inflateAmount = ratio == 1 ? 0.33 : 0.0;
  } else if (identical(inflateAmount, undefined)) {
    properties.jsWrite('inflateAmount', undefined);
  } else {
    properties.inflateAmount = jsToNumber(inflateAmount);
  }
}

/// controller.bar.js:258 `BarController extends DatasetController`.
class BarController extends DatasetController implements NativeBarIndexReads {
  /// `new BarController(chart, datasetIndex)`. Upstream declares no
  /// constructor in this class. [newTarget] is `new.target` (Chart.js ADR
  /// 0020, section 4).
  BarController(super.chart, super.datasetIndex, [super.newTarget]);

  /// Native support for the explicit data-only lifecycle.
  @override
  // DIVERGES(chartjs): adapt-incremental-data-update, native opt-in.
  bool get supportsDataUpdates => super.runtimeType == BarController;

  /// controller.bar.js:260 `static id = 'bar'`.

  static const String id = 'bar';

  /// controller.bar.js:265 `static defaults`, a typed scope of the kind
  /// `BarControllerDatasetOptions` (Chart.js ADR 0054 §3).
  static final BarControllerDatasetOptionsScope defaults =
      BarControllerDatasetOptionsScope()
        ..datasetElementType = false
        ..dataElementType = 'bar'
        ..categoryPercentage = 0.8
        ..barPercentage = 0.9
        ..grouped = true
        ..animations = (AnimationsSpecScope()
          ..numbers = (AnimationOptionsScope()
            ..type = 'number'
            ..properties = <String>['x', 'y', 'base', 'width', 'height']));

  /// controller.bar.js:284 `static overrides`, a typed scope of the kind
  /// `ChartOptions` (Chart.js ADR 0054 §3).
  static final ChartOptionsScope overrides = ChartOptionsScope()
    ..scales = (ScaleOptionsByIdScope()
      ..jsWrite(
        '_index_',
        ScaleOptionsScope()
          ..type = 'category'
          ..offset = true
          ..grid = (GridLineOptionsScope()..offset = true),
      )
      ..jsWrite(
        '_value_',
        ScaleOptionsScope()
          ..type = 'linear'
          ..beginAtZero = true,
      ));

  /// controller.bar.js:258 `class BarController extends DatasetController`
  /// as a value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [DatasetController.jsClass]. Its statics are `id`
  /// (`'bar'`), [defaults] and [overrides], in the upstream order of
  /// declaration (:260-298). Its `construct` calls `BarController(chart,
  /// datasetIndex, newTarget)` with the arguments of [controllerArgs].
  static final JsClass jsClass = JsClass(
    'BarController',
    superclass: DatasetController.jsClass,
    statics: {'id': id, 'defaults': defaults, 'overrides': overrides},
    construct: (newTarget, args) {
      final (:chart, :datasetIndex) = controllerArgs(args);
      return BarController(chart, datasetIndex, newTarget);
    },
  );

  late final bool _nativeBarIndexReads = runtimeType == BarController;

  /// Unknown subclasses retain their getDataset/getParsed/stack overrides.
  @override
  @internal
  bool get supportsNativeBarIndexReads => _nativeBarIndexReads;

  /// controller.bar.js:306 `parsePrimitiveData(meta, data, start, count)`.
  ///
  /// Overriding primitive data parsing since we support mixed
  /// primitive/array data for float bars
  /// @protected
  @override
  List<ParsedItem> parsePrimitiveData(
    types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    return _parseArrayOrPrimitive(meta, data, start, count);
  }

  /// controller.bar.js:315 `parseArrayData(meta, data, start, count)`.
  ///
  /// Overriding array data parsing since we support mixed primitive/array
  /// data for float bars
  /// @protected
  @override
  List<ParsedItem> parseArrayData(
    types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    return _parseArrayOrPrimitive(meta, data, start, count);
  }

  /// controller.bar.js:324 `parseObjectData(meta, data, start, count)`.
  ///
  /// Overriding object data parsing since we support mixed primitive/array
  /// value-scale data for float bars
  /// @protected
  ///
  /// The destructuring defaults `{xAxisKey = 'x', yAxisKey = 'y'}` are
  /// [valueOrDefault]. A key that is not a string throws a [TypeError] at
  /// the cast inside the loop (Chart.js ADR 0036, section 4). A parse of no
  /// item does not throw.
  ///
  /// Upstream throws at that call only when its resolver cache has no
  /// entry for the `ToString` of the key: then `key.split` throws. The
  /// cache holds `''`, `'x'`, `'y'` and each string key of an earlier
  /// call. Thus the key `[]` (the string `''`) and the key `[['y']]` (the
  /// option resolver gives `['y']`, the string `'y'`) do not throw upstream,
  /// but throw here. The cache of `resolveObjectKey` is private to
  /// `helpers.core.dart`, and the cast is the form of Chart.js ADR 0036,
  /// section 4.
  ///
  /// Each item is a [ParsedItem]. A `TypedDataItem` data item gives its
  /// typed field for the default key ([dataItemValue]).
  @override
  List<ParsedItem> parseObjectData(
    types.ChartMeta meta,
    List<Object?> data,
    double start,
    double count,
  ) {
    final iScale = meta.iScale;
    final vScale = meta.vScale;
    final xAxisKey = valueOrDefault(
      readOption(parsing, OptionKey.xAxisKey),
      'x',
    );
    final yAxisKey = valueOrDefault(
      readOption(parsing, OptionKey.yAxisKey),
      'y',
    );
    final iAxisKey = iScale!.axis == 'x' ? xAxisKey : yAxisKey;
    final vAxisKey = vScale!.axis == 'x' ? xAxisKey : yAxisKey;
    final iKey = AxisKey.of(iScale.axis);
    final vKey = AxisKey.of(vScale.axis);
    final parsed = <ParsedItem>[];
    for (var i = start, ilen = start + count; i < ilen; ++i) {
      final obj = jsGetIndex(data, i);
      final item = ParsedItem()
        ..setValue(
          iKey,
          iScale.axis,
          iScale.parse(dataItemValue(obj, iAxisKey! as String), i),
        );
      parsed.add(
        _parseValue(
          dataItemValue(obj, vAxisKey! as String),
          item,
          vScale,
          vKey,
          i,
        ),
      );
    }
    return parsed;
  }

  /// controller.bar.js:343 `updateRangeFromParsed(range, scale, parsed,
  /// stack)`.
  /// @protected
  ///
  /// `Math.min` and `Math.max` apply `ToNumber` to `custom.min` and
  /// `custom.max`.
  @override
  void updateRangeFromParsed(
    MinMax range,
    types.Scale scale,
    Object? parsed,
    DatasetStack? stack,
  ) {
    super.updateRangeFromParsed(range, scale, parsed, stack);
    final custom = _customOf(parsed);
    if (jsTruthy(custom) && identical(scale, cachedMeta.vScale)) {
      // float bar: only one end of the bar is considered by `super`
      if (custom is FloatingBar) {
        range
          ..min = jsMin(range.min, custom.min)
          ..max = jsMax(range.max, custom.max);
      } else {
        range
          ..min = jsMin(range.min, jsToNumber(_userCustomValue(custom, 'min')))
          ..max = jsMax(range.max, jsToNumber(_userCustomValue(custom, 'max')));
      }
    }
  }

  /// controller.bar.js:357 `getMaxOverflow()`.
  ///
  /// @return {number|boolean}
  /// @protected
  @override
  Object? getMaxOverflow() {
    return 0.0;
  }

  /// controller.bar.js:364 `getLabelAndValue(index)`.
  /// @protected
  ///
  /// `'' + value` and `'[' + custom.start + ...` are [jsToString]. Thus the
  /// label is a `String` (Chart.js ADR 0028, section 2).
  @override
  ({Object? label, String value}) getLabelAndValue(double index) {
    final meta = cachedMeta;
    final iScale = meta.iScale;
    final vScale = meta.vScale;
    final parsed = getParsed(index);
    final custom = _customOf(parsed);
    final String value;
    if (_isFloatBar(custom)) {
      final (start, end) = custom is FloatingBar
          ? (custom.start, custom.end)
          : (
              _userCustomValue(custom, 'start'),
              _userCustomValue(custom, 'end'),
            );
      value = '[${jsToString(start)}, ${jsToString(end)}]';
    } else {
      value = jsToString(
        vScale!.getLabelForValue(_axisValueOf(parsed, vScale)),
      );
    }

    return (
      label: jsToString(iScale!.getLabelForValue(_axisValueOf(parsed, iScale))),
      value: value,
    );
  }

  /// `parsed[scale.axis]`: [parsedValueOf] with the key of the axis of
  /// [scale].
  static Object? _axisValueOf(Object? parsed, types.Scale scale) {
    final axis = scale.axis;
    return parsedValueOf(parsed, AxisKey.of(axis), axis);
  }

  /// controller.bar.js:379 `initialize()`.
  @override
  void initialize() {
    enableOptionSharing = true;

    super.initialize();

    // `const meta = this._cachedMeta; meta.stack = ...`: the dataset object
    // of the user.
    cachedMeta.stack = jsGet(getDataset(), 'stack');
  }

  /// controller.bar.js:388 `update(mode)`.
  @override
  void update(String mode) {
    final meta = cachedMeta;
    updateElements(meta.data, 0, meta.data.length.toDouble(), mode);
  }

  /// controller.bar.js:393 `updateElements(bars, start, count, mode)`.
  ///
  /// [index] is the dataset index (`const {index} = this`). The object
  /// `{base, head: base}` of :403 has no `size` and no `center`:
  /// `Math.abs(vpixels.size)` (:413-414) is NaN. The record gives NaN for
  /// both. No code reads `center`.
  @override
  void updateElements(
    List<types.Element> bars,
    double start,
    double count,
    String mode,
  ) {
    final reset = mode == 'reset';
    final index = this.index;
    final vScale = cachedMeta.vScale;
    final base = vScale!.getBasePixel();
    final horizontal = vScale.isHorizontal();
    final ruler = _getRuler();
    final (:sharedOptions, :includeOptions) = getSharedOptions_(start, mode);
    final vAxis = vScale.axis;
    final vKey = AxisKey.of(vAxis);

    for (var i = start; i < start + count; i++) {
      final parsed = getParsed(i);
      final vpixels = reset || isNullOrUndef(parsedValueOf(parsed, vKey, vAxis))
          ? (size: double.nan, base: base, head: base, center: double.nan)
          : _calculateBarValuePixels(i);
      final ipixels = _calculateBarIndexPixels(i, ruler);
      final itemStacks = stacksOf(parsed);
      // `(parsed._stacks || {})[vScale.axis]`: the read of the empty object
      // gives `undefined` (Chart.js ADR 0036, section 8).
      final stack = jsTruthy(itemStacks)
          ? axisStackOf(itemStacks, vKey, vAxis)
          : undefined;

      final properties = BarProperties.geometry(
        horizontal: horizontal,
        base: vpixels.base,
        // :410 `!stack || isFloatBar(parsed._custom) || (index ===
        // stack._top || index === stack._bottom)`.
        enableBorderRadius:
            !jsTruthy(stack) ||
            _isFloatBar(_customOf(parsed)) ||
            (index == _stackTop(stack) || index == _stackBottom(stack)),
        x: horizontal ? vpixels.head : ipixels.center,
        y: horizontal ? ipixels.center : vpixels.head,
        height: horizontal ? ipixels.size : vpixels.size.abs(),
        width: horizontal ? vpixels.size.abs() : ipixels.size,
      );

      if (includeOptions) {
        // `sharedOptions || ...`: Dart `null` is the JS `undefined` of no
        // shared options.
        properties.options =
            sharedOptions ??
            resolveDataElementOptions(
              i,
              bars[i.toInt()].active ? 'active' : mode,
            );
      }
      // `properties.options || bars[i].options`: the value is an options
      // object or absent.
      final options = properties.options ?? bars[i.toInt()].options;
      _setBorderSkipped(properties, options, stack, index);
      _setInflateAmount(properties, options, ruler.ratio);
      updateElement(bars[i.toInt()], i, properties, mode);
      // The first ordinary item resolves options at their original points.
      // Qualification for the remainder runs no user code and writes nothing.
      // DIVERGES(chartjs): adapt-bulk-bar-update, guarded numeric remainder.
      if (i == start &&
          mode == 'none' &&
          includeOptions &&
          sharedOptions is BarOptions &&
          _updateBulk(
            bars,
            i + 1,
            start + count,
            ruler,
            vScale,
            vAxis,
            horizontal,
            sharedOptions,
          )) {
        return;
      }
      // DIVERGES(chartjs): adapt-prepared-indexed-options, varying colors do
      // not prevent native geometry when every remaining read is effect-free.
      if (i == start &&
          mode == 'none' &&
          includeOptions &&
          sharedOptions == null &&
          options is BarOptions &&
          _updateBulk(
            bars,
            i + 1,
            start + count,
            ruler,
            vScale,
            vAxis,
            horizontal,
            options,
            individualOptions: true,
          )) {
        return;
      }
    }
  }

  /// Preflight the entire remaining range before direct native writes. There
  /// can be no callback between the captured settings and the final element.
  bool _updateBulk(
    List<types.Element> bars,
    double first,
    double end,
    _Ruler ruler,
    types.Scale valueScale,
    String valueAxis,
    bool horizontal,
    BarOptions shared, {
    bool individualOptions = false,
  }) {
    if (super.runtimeType != BarController) return false;
    final elementClass = dataElementType;
    if (individualOptions &&
        (type != 'bar' ||
            elementClass is! JsClass ||
            elementClass.id is! String ||
            elementClass.id != 'bar')) {
      return false;
    }
    final owner = chart;
    if (owner is! BulkBarChart ||
        !(owner as BulkBarChart).supportsBulkBarUpdate ||
        owner is! SingleBarIndexSource ||
        valueScale is! BulkBarScale ||
        !(valueScale as BulkBarScale).supportsBulkBarUpdate ||
        !identical(valueScale.chart, owner) ||
        !identical(cachedMeta.vScale, valueScale) ||
        valueScale.axis != valueAxis ||
        !(valueAxis == 'x' || valueAxis == 'y') ||
        !identical(cachedMeta.stacked, false) ||
        !identical(ruler.grouped, true) ||
        !(owner as SingleBarIndexSource).hasSingleBarIndexLayout(
          this,
          ruler.scale,
        )) {
      return false;
    }
    final settings = options.cachedBulkBarOptions;
    if (settings == null ||
        !(valueScale as BulkBarScale).hasStaticBulkBarGrid) {
      return false;
    }
    final resolveColors = individualOptions
        ? (chart.config as Config).prepareIndexedBarColors()
        : null;
    if (individualOptions && resolveColors == null) return false;
    final representative = resolveColors?.call(0) ?? shared;
    final edge = representative.borderSkippedValue;
    if (!(edge == null ||
        identical(edge, undefined) ||
        edge is bool ||
        // DIVERGES(chartjs): adapt-border-skipped-enum, the enum value.
        edge is BorderSkippedEdge)) {
      return false;
    }
    final amount = representative.inflateAmountValue;
    final double inflate;
    if (amount is String && amount == 'auto') {
      inflate = ruler.ratio == 1 ? 0.33 : 0;
    } else if (amount is num && amount.isFinite) {
      inflate = amount.toDouble();
    } else {
      return false;
    }
    final parsed = cachedMeta.parsed;
    if ((!nativeBulkBarLists(bars, parsed) &&
            !(updatingData &&
                nativeBulkBarElements(bars) &&
                nativeDataUpdateList(parsed))) ||
        !first.isFinite ||
        !end.isFinite ||
        first < 0 ||
        end <= first ||
        first != first.truncateToDouble() ||
        end != end.truncateToDouble() ||
        end > bars.length ||
        end > parsed.length ||
        end > ruler.pixels.length) {
      return false;
    }
    final begin = first.toInt();
    final stop = end.toInt();
    final values = Float64List(stop - begin);
    final key = AxisKey.of(valueAxis);
    for (var i = begin; i < stop; i++) {
      final element = bars[i];
      final item = parsed[i];
      if (element is! BulkBarElement ||
          !(element as BulkBarElement).supportsBulkBarWrites) {
        return false;
      }
      if (individualOptions && element.active) return false;
      if (item is ParsedItem) {
        if (item.hasForeign || item.hasSlot(3) || item.hasSlot(4)) return false;
      } else if (!updatingData ||
          jsTruthy(_customOf(item)) ||
          jsTruthy(stacksOf(item))) {
        return false;
      }
      // Data-only updates preflight native prepared values before these reads.
      final value = parsedValueOf(item, key, valueAxis);
      // The type tests come first: `isFinite` and `toDouble()` on a num are
      // calls in an AOT build (performance.md §72).
      if (value is double) {
        if (!value.isFinite) return false;
        values[i - begin] = value;
        continue;
      }
      // js-ok: only the VM and dart2wasm get here with a number, an int.
      if (value is! int) return false;
      values[i - begin] = value * 1.0;
    }
    final stacks = ruler.stackCount;
    if (!stacks.isFinite || stacks <= 0) return false;
    final double size;
    final double ratio;
    if (settings.thickness case final thickness?) {
      size = thickness * stacks;
      ratio = 1;
    } else {
      final minimum = ruler.min;
      if (minimum is! num || !minimum.isFinite) return false;
      size = minimum.toDouble() * settings.categoryPercentage;
      ratio = settings.barPercentage;
    }
    final chunk = size / stacks;
    final breadth = jsMin(settings.maxThickness, chunk * ratio);
    if (!size.isFinite || !chunk.isFinite || !breadth.isFinite) return false;
    final basePixel = valueScale.getPixelForValue(settings.base);
    final actualBase = settings.base == 0 ? 0.0 : settings.base;
    final actualBasePixel = valueScale.getPixelForValue(actualBase);
    if (!basePixel.isFinite || !actualBasePixel.isFinite) return false;
    double? gridWidth;
    // DIVERGES(chartjs): adapt-context-bulk-refresh, the data chain read once.
    final contexts = resolveColors == null || !identical(bars, cachedMeta.data)
        ? null
        : prepareNativePointContexts(this, 'none');
    for (var i = begin; i < stop; i++) {
      var base = basePixel;
      final head = chart.getDataVisibility(i)
          ? valueScale.getPixelForValue(0.0 + values[i - begin])
          : base;
      var length = head - base;
      if (base == actualBasePixel) {
        // Preserve the first tick-context creation at the original point.
        gridWidth ??= valueScale.getLineWidthForValue(actualBase);
        final halfGrid = sign(length) * gridWidth / 2;
        base += halfGrid;
        length -= halfGrid;
      }
      // Keep upstream operation order, including the zero stack-index term.
      final rangeStart = ruler.pixels[i] - size / 2;
      final center = rangeStart + chunk * 0.0 + chunk / 2;
      // Context refresh remains after geometry and before the option stores.
      // Eligibility proved native config/data/element reads and no callbacks.
      final BarOptions elementOptions;
      if (resolveColors != null) {
        // The preflight of this loop read the capability of each bar.
        if (contexts?.readQualified(bars[i], i) == null) {
          getContext(i * 1.0, false, 'none');
        }
        elementOptions = resolveColors(i);
      } else {
        elementOptions = shared;
      }
      final BorderSkipped skipped;
      if (identical(edge, true)) {
        skipped = BorderSkipped.all();
      } else {
        skipped = BorderSkipped();
        if (edge is BorderSkippedEdge) {
          _skipEdge(
            skipped,
            _parseEdge(
              edge,
              horizontal ? BorderSkippedEdge.left : BorderSkippedEdge.bottom,
              horizontal ? BorderSkippedEdge.right : BorderSkippedEdge.top,
              horizontal ? base > head : base < head,
            ),
          );
        }
      }
      (bars[i] as BulkBarElement).writeBulkBar(
        horizontal: horizontal,
        base: base,
        x: horizontal ? head : center,
        y: horizontal ? center : head,
        height: horizontal ? breadth : length.abs(),
        width: horizontal ? length.abs() : breadth,
        options: elementOptions,
        skipped: skipped,
        inflate: inflate,
      );
    }
    return true;
  }

  /// controller.bar.js:434 `_getStacks(last, dataIndex)`.
  ///
  /// Returns the stacks based on groups and bar visibility.
  /// @param {number} [last] - The dataset index
  /// @param {number} [dataIndex] - The data index of the ruler
  /// @returns {string[]} The list of stack IDs
  /// @private
  ///
  /// Dart `null` for [last] and [dataIndex] stands for JS `undefined`.
  /// `getParsed(undefined)` reads the key `'undefined'` of the parsed items
  /// and gives `undefined`: `getParsed(NaN)` gives the same. `find` and
  /// `indexOf` compare with `===` ([_strictEquals]): two separate `Date`
  /// stacks with the same time are two stacks.
  List<Object?> _getStacks([double? last, double? dataIndex]) {
    final iScale = cachedMeta.iScale;
    final metasets = iScale!
        .getMatchingVisibleMetas(type)
        .where(
          (meta) => jsTruthy(
            readOption(meta.controller!.options, OptionKey.grouped),
          ),
        )
        .toList();
    final stacked = readOption(iScale.options, OptionKey.stacked);
    final stacks = <Object?>[];
    final currentParsed = cachedMeta.controller!.getParsed(
      dataIndex ?? double.nan,
    );
    final iAxis = iScale.axis;
    final iKey = AxisKey.of(iAxis);
    final iScaleValue = jsTruthy(currentParsed)
        ? parsedValueOf(currentParsed, iKey, iAxis)
        : currentParsed;

    // :443-450: `true`, or Dart `null` for the JS `undefined` of no return.
    bool? skipNull(types.ChartMeta meta) {
      // `Array.prototype.find` gives `undefined` when no item matches.
      final parsed = meta.parsed.firstWhere(
        (item) => _strictEquals(parsedValueOf(item, iKey, iAxis), iScaleValue),
        orElse: () => undefined,
      );
      final val = jsTruthy(parsed)
          ? _axisValueOf(parsed, meta.vScale!)
          : parsed;

      if (isNullOrUndef(val) || jsIsNaN(val)) {
        return true;
      }
      return null;
    }

    for (final meta in metasets) {
      if (dataIndex != null && (skipNull(meta) ?? false)) {
        continue;
      }

      // stacked   | meta.stack
      //           | found | not found | undefined
      // false     |   x   |     x     |     x
      // true      |       |     x     |
      // undefined |       |     x     |     x
      if (stacked == false ||
          !stacks.any((stack) => _strictEquals(stack, meta.stack)) ||
          (identical(stacked, undefined) && identical(meta.stack, undefined))) {
        stacks.add(meta.stack);
      }
      if (meta.index == last) {
        break;
      }
    }

    // No stacks? that means there is no visible data. Let's still
    // initialize an `undefined` stack where possible invisible bars will be
    // located.
    // https://github.com/chartjs/Chart.js/issues/6368
    if (stacks.isEmpty) {
      stacks.add(undefined);
    }

    return stacks;
  }

  /// controller.bar.js:485 `_getStackCount(index)`.
  ///
  /// Returns the effective number of stacks based on groups and bar
  /// visibility.
  /// @private
  ///
  /// Dart `null` for [index] stands for JS `undefined`. The spec reads it
  /// (controller.bar.tests.js:85, :1803). Thus it drops the underscore
  /// (Chart.js ADR 0012).
  @internal
  double getStackCount([double? index]) {
    return _getStacks(null, index).length.toDouble();
  }

  /// controller.bar.js:489 `_getAxisCount()`.
  double _getAxisCount() {
    return _getAxis().length.toDouble();
  }

  /// controller.bar.js:493 `getFirstScaleIdForIndexAxis()`.
  ///
  /// The first key of `chart.scales` whose scale has the axis of the
  /// `indexAxis` option. Dart `null` stands for the JS `undefined` of
  /// `shift()` on an empty array.
  String? getFirstScaleIdForIndexAxis() {
    final scales = chart.scales;
    final indexScaleId = readOption(chart.options, OptionKey.indexAxis);
    // The `Object.keys` order of the scale ids of the user.
    return jsObjectKeys(
      scales,
    ).where((key) => scales[key]!.axis == indexScaleId).firstOrNull;
  }

  /// `indexAxis === 'x' ? dataset.xAxisID : dataset.yAxisID` (:503-504,
  /// :642): the axis id of the dataset object [dataset] of the user, read
  /// by name.
  Object? _indexAxisIdOf(Object? dataset) => jsGet(
    dataset,
    readOption(chart.options, OptionKey.indexAxis) == 'x'
        ? 'xAxisID'
        : 'yAxisID',
  );

  /// controller.bar.js:499 `_getAxis()`.
  ///
  /// The property key of `axis[...]` is the `ToString` of the axis id.
  ///
  /// `chart.data.datasets` is a List here: `mergeScaleConfig` of each
  /// `initOptions` call (core.config.js:93) calls `datasets.forEach` before
  /// any controller update, and a value that is not an array throws there.
  /// JS `for...of` also iterates a String, but a String fails that
  /// `forEach` first. The port tests for a List and needs no cast (IV
  /// §4.8). It throws a [TypeError] for another value, as `for...of` does
  /// for a value that is not iterable.
  List<String> _getAxis() {
    final axis = <String, Object?>{};
    final firstScaleAxisId = getFirstScaleIdForIndexAxis();
    // The data object of the user.
    final datasets = jsGet(chart.data, 'datasets');
    if (datasets is! List) {
      throw TypeError();
    }
    for (final dataset in datasets) {
      axis[jsToString(
            valueOrDefault(
              _indexAxisIdOf(dataset),
              firstScaleAxisId ?? undefined,
            ),
          )] =
          true;
    }
    // `Object.keys(axis)`: the JS order of the axis ids.
    return jsObjectKeys(axis);
  }

  /// controller.bar.js:518 `_getStackIndex(datasetIndex, name, dataIndex)`.
  ///
  /// Returns the stack index for the given dataset based on groups and bar
  /// visibility.
  /// @param {number} [datasetIndex] - The dataset index
  /// @param {string} [name] - The stack name to find
  /// @param {number} [dataIndex]
  /// @returns {number} The stack index
  /// @private
  ///
  /// Dart `null` for [dataIndex] stands for JS `undefined`. [name] is the
  /// [undefined] sentinel when the caller gives no name. `indexOf` compares
  /// with `===` ([_strictEquals]). The spec reads it with one argument
  /// (controller.bar.tests.js:325). Thus it drops the underscore (Chart.js
  /// ADR 0012).
  @internal
  double getStackIndex(
    double datasetIndex, [
    Object? name = undefined,
    double? dataIndex,
  ]) {
    final stacks = _getStacks(datasetIndex, dataIndex);
    final index = !identical(name, undefined)
        ? stacks.indexWhere((stack) => _strictEquals(stack, name))
        : -1; // indexOf returns -1 if element is not present

    return (index == -1 ? stacks.length - 1 : index).toDouble();
  }

  /// controller.bar.js:532 `_getRuler()`.
  /// @private
  ///
  /// `pixels` is a [Float64List]: an internal array of numbers that no user
  /// code reaches (Chart.js ADR 0054 §8).
  _Ruler? _dataUpdateRuler;

  _Ruler _getRuler() {
    if (!updatingData) _dataUpdateRuler = null;
    final cached = _dataUpdateRuler;
    if (updatingData &&
        reuseDataLayout &&
        primitiveDataUpdate &&
        parsing != false &&
        cached != null &&
        cached.scale.type == 'category' &&
        !jsTruthy(options.readKey(OptionKey.skipNull))) {
      return cached;
    }

    final opts = options;
    final meta = cachedMeta;
    final iScale = meta.iScale;
    final ilen = meta.data.length;
    final pixels = Float64List(ilen);
    // Upstream reads `iScale.axis` in the loop: no read for no element.
    final iKey = iScale == null ? AxisKey.other : AxisKey.of(iScale.axis);

    for (var i = 0; i < ilen; ++i) {
      pixels[i] = iScale!.getPixelForValue(
        parsedValueOf(getParsed(i * 1.0), iKey, iScale.axis),
        i * 1.0,
      );
    }

    final barThickness = opts.readKey(OptionKey.barThickness);
    final min = jsTruthy(barThickness)
        ? barThickness
        : _computeMinSampleSize(meta);

    final ruler = (
      min: min,
      pixels: pixels,
      start: iScale!.startPixel,
      end: iScale.endPixel,
      stackCount: getStackCount(),
      scale: iScale,
      grouped: opts.readKey(OptionKey.grouped),
      // bar thickness ratio used for non-grouped bars
      ratio: jsTruthy(barThickness)
          ? 1.0
          : jsToNumber(opts.readKey(OptionKey.categoryPercentage)) *
                jsToNumber(opts.readKey(OptionKey.barPercentage)),
    );
    _dataUpdateRuler =
        updatingData &&
            reuseDataLayout &&
            primitiveDataUpdate &&
            parsing != false &&
            ruler.scale.type == 'category'
        ? ruler
        : null;
    return ruler;
  }

  /// controller.bar.js:563 `_calculateBarValuePixels(index)`.
  ///
  /// Note: pixel values are not clamped to the scale area.
  /// @private
  ///
  /// The `base` option, the parsed value and the float bar values stay raw
  /// values until their operators (Chart.js ADR 0036, section 7):
  /// - `baseValue || 0` keeps a truthy option value: `'0' || 0` is `'0'`.
  /// - `start + length` is [jsAdd]. `length - value` applies `ToNumber`.
  /// - `value === actualBase` is [_strictEquals]: `5 === '5'` is false, and
  ///   two separate `Date` values with the same time are not equal.
  /// - `minBarLength` gets its `ToNumber` once, at the read: both of its
  ///   uses apply `ToNumber`.
  ///
  /// `getValueForPixel` gives Dart `null` for the JS `undefined` of the
  /// base scale: the subtraction gives NaN.
  _BarPixels _calculateBarValuePixels(double index) {
    final vScale = cachedMeta.vScale;
    final stacked = cachedMeta.stacked;
    final datasetIndex = cachedMeta.index;
    final baseValue = options.readKey(OptionKey.base);
    final minBarLength = jsToNumber(options.readKey(OptionKey.minBarLength));
    final actualBase = jsTruthy(baseValue) ? baseValue : 0.0;
    final parsed = getParsed(index);
    final custom = _customOf(parsed);
    final floating = _isFloatBar(custom);
    final vAxis = vScale!.axis;
    final vKey = AxisKey.of(vAxis);
    var value = parsedValueOf(parsed, vKey, vAxis);
    Object? start = 0.0;
    var length = jsTruthy(stacked)
        ? applyStack(vScale, parsed, stacked)
        : value;
    double head;
    double size;

    if (length != value) {
      start = jsToNumber(length) - jsToNumber(value);
      length = value;
    }

    if (floating) {
      // `custom.barStart` and `custom.barEnd`, each read once: the reads of
      // an object have no side effect.
      // A FloatingBar with a value that user code wrote by name reads its
      // raw values, as a user object does.
      final Object? barStart;
      final Object? barEnd;
      if (custom is FloatingBar && !custom.hasForeign) {
        barStart = custom.barStart;
        barEnd = custom.barEnd;
      } else {
        barStart = _userCustomValue(custom, 'barStart');
        barEnd = _userCustomValue(custom, 'barEnd');
      }
      value = barStart;
      length = jsToNumber(barEnd) - jsToNumber(barStart);
      // bars crossing origin are not stacked
      if (value != 0 && sign(jsToNumber(value)) != sign(jsToNumber(barEnd))) {
        start = 0.0;
      }
      start = jsAdd(start, value);
    }

    final startValue = !isNullOrUndef(baseValue) && !floating
        ? baseValue
        : start;
    var base = vScale.getPixelForValue(startValue);

    if (chart.getDataVisibility(index)) {
      head = vScale.getPixelForValue(jsAdd(start, length));
    } else {
      // When not visible, no height
      head = base;
    }

    size = head - base;

    if (size.abs() < minBarLength) {
      size = _barSign(size, vScale, actualBase) * minBarLength;
      if (_strictEquals(value, actualBase)) {
        base -= size / 2;
      }
      final startPixel = vScale.getPixelForDecimal(0);
      final endPixel = vScale.getPixelForDecimal(1);
      final min = jsMin(startPixel, endPixel);
      final max = jsMax(startPixel, endPixel);
      base = jsMax(jsMin(base, max), min);
      head = base + size;

      if (jsTruthy(stacked) && !floating) {
        // visual data coordinates after applying minBarLength
        // :615 `parsed._stacks[vScale.axis]._visualValues[datasetIndex] =
        // ...`. DC writes `_visualValues` as an IndexValues
        // (core.datasetController.js:170-173). Another value is a user
        // object: a Map takes the write, and another value throws a
        // TypeError, as the JS write into a primitive does.
        setStackValue(
          visualValuesOf(axisStackOf(stacksOf(parsed), vKey, vAxis)),
          datasetIndex,
          (vScale.getValueForPixel(head) ?? double.nan) -
              (vScale.getValueForPixel(base) ?? double.nan),
        );
      }
    }

    if (base == vScale.getPixelForValue(actualBase)) {
      final halfGrid = sign(size) * vScale.getLineWidthForValue(actualBase) / 2;
      base += halfGrid;
      size -= halfGrid;
    }

    return (size: size, base: base, head: head, center: head + size / 2);
  }

  /// controller.bar.js:636 `_calculateBarIndexPixels(index, ruler)`.
  /// @private
  ///
  /// `valueOrDefault(options.maxBarThickness, Infinity)` gets its
  /// `ToNumber` once, at the read: both `Math.min` calls apply it. `indexOf`
  /// on the axis keys compares with `===`: a key equals only the same
  /// string.
  _BarPixels _calculateBarIndexPixels(double index, _Ruler ruler) {
    final scale = ruler.scale;
    final options = this.options;
    final skipNull = options.readKey(OptionKey.skipNull);
    final maxBarThickness = jsToNumber(
      valueOrDefault(
        options.readKey(OptionKey.maxBarThickness),
        double.infinity,
      ),
    );
    double center;
    double size;
    // DIVERGES(chartjs): adapt-live-bar-layout, check live state twice.
    final source = supportsNativeBarIndexReads && chart is SingleBarIndexSource
        ? chart as SingleBarIndexSource
        : null;
    final direct =
        !jsTruthy(skipNull) &&
        source != null &&
        source.hasSingleBarIndexLayout(this, scale);
    final axisCount = direct ? 1.0 : _getAxisCount();
    final pureTraits =
        direct &&
        options.runtimeType == OptionView &&
        options.hasCachedStaticBarTraits;
    if (jsTruthy(ruler.grouped)) {
      final stackCount = jsTruthy(skipNull)
          ? getStackCount(index)
          : ruler.stackCount;
      final range = options.readKey(OptionKey.barThickness) == 'flex'
          ? _computeFlexCategoryTraits(
              index,
              ruler,
              options,
              stackCount * axisCount,
            )
          : _computeFitCategoryTraits(
              index,
              ruler,
              options,
              stackCount * axisCount,
            );
      final double stackIndex;
      // Range options may run user callbacks and mutate axes or datasets.
      // Observe the topology again exactly where the original does.
      if (!jsTruthy(skipNull) &&
          source != null &&
          (pureTraits || source.hasSingleBarIndexLayout(this, scale))) {
        stackIndex = 0;
      } else {
        final axisID = _indexAxisIdOf(getDataset());
        final axes = _getAxis();
        final axisKey = valueOrDefault(
          axisID,
          getFirstScaleIdForIndexAxis() ?? undefined,
        );
        final axisNumber = axes.indexWhere((key) => key == axisKey);
        stackIndex =
            getStackIndex(
              this.index,
              cachedMeta.stack,
              jsTruthy(skipNull) ? index : null,
            ) +
            axisNumber;
      }
      center = range.start + (range.chunk * stackIndex) + (range.chunk / 2);
      size = jsMin(maxBarThickness, range.chunk * jsToNumber(range.ratio));
    } else {
      // For non-grouped bar charts, exact pixel values are used
      center = scale.getPixelForValue(
        _axisValueOf(getParsed(index), scale),
        index,
      );
      size = jsMin(maxBarThickness, jsToNumber(ruler.min) * ruler.ratio);
    }

    return (
      base: center - size / 2,
      head: center + size / 2,
      center: center,
      size: size,
    );
  }

  /// controller.bar.js:668 `draw()`.
  ///
  /// `!== null`: the [undefined] sentinel is not `null`, so a bar with an
  /// absent value key draws, as upstream. The draw reads [ctx] for each bar
  /// (:677, Chart.js ADR 0030, section 1).
  @override
  void draw() {
    final meta = cachedMeta;
    final vScale = meta.vScale;
    final rects = meta.data;
    final ilen = rects.length;
    var i = 0;
    // Upstream reads `vScale.axis` in the loop: no read for no element.
    final vKey = vScale == null ? AxisKey.other : AxisKey.of(vScale.axis);

    for (; i < ilen; ++i) {
      if (parsedValueOf(getParsed(i * 1.0), vKey, vScale!.axis) != null &&
          !jsTruthy(rects[i].hidden)) {
        (rects[i] as types.VisualElement).draw(ctx!);
      }
    }
  }
}
