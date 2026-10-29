// Ported from Chart.js v4.5.1+7169e651 src/scales/scale.category.js (MIT, Chart.js Contributors).

/// Port of `src/scales/scale.category.js`.
///
/// [CategoryScale] maps the labels of the chart to the indexes 0, 1, 2 and
/// so on. The labels are the List of `options.labels`, of `data.xLabels` or
/// `data.yLabels`, or of `data.labels` ([Scale.getLabels]). It is the live
/// List, not a copy. [CategoryScale.parse] adds a string that is not a
/// label to that List, and [CategoryScale.init] removes the added strings
/// again at the next update (scale.category.js:4-12, :56-68).
///
/// - Numbers are `double` (Chart.js ADR 0045). A label index is a `double`
///   too. A read of the labels at a value that is not an integer index in
///   the range gives the [undefined] sentinel, as JavaScript does.
/// - The value methods take any JS value (Chart.js ADR 0025).
///   [CategoryScale.getPixelForValue] starts with the port-only fast path
///   for a `double` of Chart.js ADR 0025, section 3.
/// - The upstream `_` members that only this file reads keep the
///   underscore (Chart.js ADR 0012, Chart.js ADR 0025, section 6):
///   `_startValue`, `_valueRange` and `_addedLabels`.
///
/// `core.scale.dart` imports `helpers.extras`, which is not a pure layer.
/// Thus this library is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show limitValue;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsSplice;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show JsFunction;
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsMax, jsRound;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:meta/meta.dart';

/// An item of `_addedLabels`: the object literal `{index, label}` of
/// scale.category.js:7. `index` is the index of the label that
/// `addIfString` added, and `label` is the label.
typedef _AddedLabel = ({double index, String label});

/// scale.category.js:4 `addIfString`.
///
/// [index] is the index that `parse` gives, or the raw value
/// (scale.category.js:76). A string [raw] goes to the end of [labels], and
/// its index goes to the start of [addedLabels]. Another [raw] that is NaN
/// after `ToNumber` gives Dart `null` (JS `null`). Else the function gives
/// [index].
///
/// [labels] is the `List` of the configuration. A `List` with a narrow
/// element type, for example `List<int>`, throws a [TypeError] at the add
/// of a string. A `List` that cannot grow (a const, an unmodifiable or a
/// fixed-length `List`) throws an [UnsupportedError]. JavaScript pushes the
/// string in both cases (differences.md row `js-semantics-narrow-labels`).
Object? _addIfString(
  List<Object?> labels,
  Object? raw,
  Object? index,
  List<_AddedLabel> addedLabels,
) {
  if (raw is String) {
    // DIVERGES(chartjs): js-semantics-narrow-labels, a narrow or fixed List.
    labels.add(raw);
    final added = (labels.length - 1).toDouble();
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    index = added;
    addedLabels.insert(0, (index: added, label: raw));
  } else if (jsIsNaN(raw)) {
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    index = null;
  }
  return index;
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
/// values by their time. `===` compares two Dates by identity.
bool _strictEquals(Object? a, Object? b) {
  if (a is num && b is num) return a == b;
  if (a is String && b is String) return a == b;
  return identical(a, b);
}

/// `labels.indexOf(raw)` of JavaScript: the first index of [labels] whose
/// label is `===` [raw] ([_strictEquals]), or -1.
int _indexOf(List<Object?> labels, Object? raw) {
  for (var i = 0; i < labels.length; i++) {
    if (_strictEquals(labels[i], raw)) return i;
  }
  return -1;
}

/// `labels.lastIndexOf(raw)` of JavaScript: the last index of [labels]
/// whose label is `===` [raw] ([_strictEquals]), or -1.
int _lastIndexOf(List<Object?> labels, Object? raw) {
  for (var i = labels.length - 1; i >= 0; i--) {
    if (_strictEquals(labels[i], raw)) return i;
  }
  return -1;
}

/// scale.category.js:14 `findOrAddLabel`.
///
/// `indexOf` and `lastIndexOf` of JavaScript compare with `===`. Thus
/// [_indexOf] and [_lastIndexOf] compare with [_strictEquals], and not with
/// Dart `==`: a copy of a label Date is not the label.
Object? _findOrAddLabel(
  List<Object?> labels,
  Object? raw,
  Object? index,
  List<_AddedLabel> addedLabels,
) {
  final first = _indexOf(labels, raw);
  if (first == -1) {
    return _addIfString(labels, raw, index, addedLabels);
  }
  final last = _lastIndexOf(labels, raw);
  return first != last ? index : first.toDouble();
}

/// scale.category.js:23 `validIndex`.
///
/// `Math.round(index)` applies `ToNumber` to [index], which can be the raw
/// value of `findOrAddLabel`.
double? _validIndex(Object? index, double max) =>
    index == null ? null : limitValue(jsRound(jsToNumber(index)), 0, max);

/// The JavaScript read `labels[index]`.
///
/// A `double` [index] reads the label at an integer index in the range, or
/// gives [undefined], as the property key `ToString(index)` does (-0 reads
/// the index 0). Another [index] goes through [jsGet].
Object? _labelAt(List<Object?> labels, Object? index) {
  if (index is double) {
    return index >= 0 &&
            index < labels.length &&
            index == index.truncateToDouble()
        ? labels[index.toInt()]
        : undefined;
  }
  return jsGet(labels, index);
}

/// scale.category.js:25 `_getLabelForValue(value)`.
///
/// The function reads `this`. Here [self] is `this`: the closure of a
/// [JsFunction] gets `this` as its first parameter. A [self] that is not a
/// [Scale] throws a [TypeError], as the call `this.getLabels()` throws for
/// a value without that method.
///
/// `value >= 0` and `value < labels.length` apply `ToNumber` to [value].
Object? _getLabelForValue(Object? self, Object? value) {
  final labels = (self! as Scale).getLabels();

  if (jsToNumber(value) >= 0 && jsToNumber(value) < labels.length) {
    return _labelAt(labels, value);
  }
  return value;
}

/// The JavaScript `array.slice(start, end)` (ECMAScript 23.1.3.28): a new
/// List with the elements of [list] from [start] up to [end], not
/// inclusive.
///
/// [start] and [end] go through `ToIntegerOrInfinity`: NaN gives 0, and a
/// fraction truncates toward zero. A negative value counts from the end of
/// [list]. Both values clamp to the range of [list]. The port has no other
/// call of `slice`. Thus the function is private to this library.
List<T> _slice<T>(List<T> list, double start, double end) {
  final from = _relativeIndex(start, list.length);
  final to = _relativeIndex(end, list.length);
  return from < to ? list.sublist(from, to) : <T>[];
}

/// The index of the `slice` argument [value] in a List of [length]: the
/// steps 3 to 5 and 7 to 9 of ECMAScript 23.1.3.28.
int _relativeIndex(double value, int length) {
  final relative = value.isNaN ? 0.0 : value.truncateToDouble();
  if (relative < 0) {
    final fromEnd = length + relative;
    return fromEnd > 0 ? fromEnd.toInt() : 0;
  }
  return relative < length ? relative.toInt() : length;
}

/// scale.category.js:34 `CategoryScale`.
///
/// The scale of the labels: the value of a label is its index.
class CategoryScale extends Scale {
  /// scale.category.js:47 `constructor(cfg)`.
  ///
  /// The fields `_startValue`, `_valueRange` and `_addedLabels` get their
  /// start values in their declarations (scale.category.js:51-53).
  CategoryScale(super.cfg);

  // scale.category.js:36 `static id = 'category'`. Scale has the instance
  // field `id`. Thus the value is only in the statics of jsClass.

  /// scale.category.js:41 `static defaults`.
  ///
  /// The tick callback is `_getLabelForValue` (scale.category.js:25), a
  /// function that reads `this`.
  static final AnyObject defaults = {
    'ticks': <String, Object?>{
      'callback': const JsFunction(_getLabelForValue),
    },
  };

  /// scale.category.js:34 `class CategoryScale extends Scale` as a value
  /// (Chart.js ADR 0020, section 3).
  ///
  /// It extends [Scale.jsClass]. Its statics are `id` (`'category'`) and
  /// [defaults], in the upstream order of declaration
  /// (scale.category.js:36-45). Its `construct` calls `CategoryScale(cfg)`
  /// with the `cfg` of [scaleCfgArg].
  static final JsClass jsClass = JsClass(
    'CategoryScale',
    superclass: Scale.jsClass,
    statics: {'id': 'category', 'defaults': defaults},
    construct: (newTarget, args) => CategoryScale(scaleCfgArg(args)),
  );

  /// scale.category.js:51 `_startValue`, the value at the start of the
  /// range. NaN stands for JS `undefined`. [buildTicks] sets it.
  double _startValue = double.nan;

  /// scale.category.js:52 `_valueRange`, the length of the value range.
  /// [buildTicks] sets it.
  double _valueRange = 0;

  /// scale.category.js:53 `_addedLabels`, the labels that [parse] added, the
  /// last one first.
  List<_AddedLabel> _addedLabels = [];

  /// scale.category.js:56 `init(scaleOptions)`.
  ///
  /// It removes the labels that [parse] added since the last [init]. Then
  /// it calls `super.init` with [options] only, as upstream does: [opts]
  /// has no effect.
  @override
  void init(AnyObject options, [AnyObject? opts]) {
    final added = _addedLabels;
    if (added.isNotEmpty) {
      final labels = getLabels();
      for (final (:index, :label) in added) {
        if (_strictEquals(_labelAt(labels, index), label)) {
          jsSplice(labels, index, 1);
        }
      }
      _addedLabels = [];
    }
    super.init(options);
  }

  /// scale.category.js:70 `parse(raw, index)`.
  ///
  /// It gives the index of the label [raw], or Dart `null` (JS `null`) for
  /// `null`, [undefined] and a value that has no index. For a repeated label
  /// without [index], `findOrAddLabel` gives [raw] itself, and `validIndex`
  /// applies `Math.round` to it: a string that is not a number gives NaN
  /// (scale.category.js:19-23). Dart `null` for [index] stands for JS
  /// `undefined`. `isFinite(index)` is the global function: it is false for
  /// `undefined`.
  ///
  /// A string that is not a label goes to the end of the labels
  /// (scale.category.js:4-12). `labels[index] === raw` is [_strictEquals]:
  /// a copy of a label Date is not the label.
  @override
  double? parse(Object? raw, [double? index]) {
    if (isNullOrUndef(raw)) {
      return null;
    }
    final labels = getLabels();
    // Upstream assigns the result to its parameter `index`, which is a
    // `double?` here.
    final found =
        index != null &&
            index.isFinite &&
            _strictEquals(_labelAt(labels, index), raw)
        ? index
        : _findOrAddLabel(labels, raw, index ?? raw, _addedLabels);
    return _validIndex(found, (labels.length - 1).toDouble());
  }

  /// scale.category.js:80 `determineDataLimits()`.
  @override
  void determineDataLimits() {
    final (:minDefined, :maxDefined, min: _, max: _) = getUserBounds();
    var (:min, :max) = getMinMax(true);

    if (options['bounds'] == 'ticks') {
      if (!minDefined) {
        min = 0;
      }
      if (!maxDefined) {
        max = (getLabels().length - 1).toDouble();
      }
    }

    this.min = min;
    this.max = max;
  }

  /// scale.category.js:97 `buildTicks()`.
  ///
  /// The ticks have the values from [min] to [max], in steps of 1.
  @override
  List<Tick> buildTicks() {
    final min = this.min;
    final max = this.max;
    final offset = options['offset'];
    final ticks = <Tick>[];
    var labels = getLabels();

    // If we are viewing some subset of labels, slice the original array
    labels = (min == 0 && max == labels.length - 1)
        ? labels
        : _slice(labels, min, max + 1);

    _valueRange = jsMax(
      labels.length - (jsTruthy(offset) ? 0.0 : 1.0),
      1,
    );
    _startValue = this.min - (jsTruthy(offset) ? 0.5 : 0);

    for (var value = min; value <= max; value++) {
      ticks.add(Tick(value: value));
    }
    return ticks;
  }

  /// scale.category.js:116 `getLabelForValue(value)`.
  ///
  /// The label at the index [value], or [value] when no label has that
  /// index.
  @override
  Object? getLabelForValue(Object? value) {
    return _getLabelForValue(this, value);
  }

  /// scale.category.js:123 `configure()`.
  ///
  /// @protected
  @override
  @protected
  void configure() {
    super.configure();

    if (!isHorizontal()) {
      // For backward compatibility, vertical category scale reverse is
      // inverted.
      reversePixels = !reversePixels;
    }
  }

  /// scale.category.js:133 `getPixelForValue(value)`.
  ///
  /// Used to get data value locations. Value can either be an index or a
  /// numerical value
  ///
  /// [value] is any JS value. A value that is not a number gets the index of
  /// its label through [parse] (Chart.js ADR 0025).
  @override
  double getPixelForValue(Object? value, [double? index]) {
    if (value is double) {
      // Port-only fast path for a number (Chart.js ADR 0025, section 3).
      return getPixelForDecimal((value - _startValue) / _valueRange);
    }
    if (value is! num) {
      // Upstream reassigns its parameter.
      // ignore: parameter_assignments
      value = parse(value);
    }

    return value == null
        ? double.nan
        : getPixelForDecimal((jsToNumber(value) - _startValue) / _valueRange);
  }

  /// scale.category.js:143 `getPixelForTick(index)`.
  ///
  /// Must override base implementation because it calls getPixelForValue
  /// and category scale can have duplicate values
  ///
  /// Dart `null` stands for the JS `null` of an index out of the range.
  @override
  double? getPixelForTick(int index) {
    final ticks = this.ticks!;
    if (index < 0 || index > ticks.length - 1) {
      return null;
    }
    return getPixelForValue(ticks[index].value);
  }

  /// scale.category.js:151 `getValueForPixel(pixel)`.
  @override
  double getValueForPixel(double pixel) {
    return jsRound(_startValue + getDecimalForPixel(pixel) * _valueRange);
  }

  /// scale.category.js:155 `getBasePixel()`.
  @override
  double getBasePixel() {
    return bottom;
  }
}
