// Ported from Chart.js v4.5.1+7169e651 src/scales/scale.timeseries.js (MIT, Chart.js Contributors).

/// Port of `src/scales/scale.timeseries.js`.
///
/// [TimeSeriesScale] is a [TimeScale] that puts the data timestamps at
/// equal distances. A lookup table of `{time, pos}` entries maps a time to
/// a position, and a position back to a time, by linear interpolation
/// between the entries.
///
/// - Numbers are `double` (Chart.js ADR 0045).
/// - An entry of the lookup table is a Map `{'time': time, 'pos': pos}`
///   (Chart.js ADR 0043): [lookupByKey] reads the entries by key. `time` can
///   be Dart `null`, the JS `null` timestamp of a label that the adapter
///   cannot parse. The arithmetic reads it with `ToNumber`, as upstream.
/// - The value methods take any JS value (Chart.js ADR 0025).
///   [TimeSeriesScale.getDecimalForValue] applies one `ToNumber` at the
///   entry of `interpolate`. Thus `null` acts as 0.
/// - The `_` members of this file have readers only in this file. They keep
///   the underscore (Chart.js ADR 0012, Chart.js ADR 0025, section 6).
///
/// `core.scale.dart` imports `helpers.extras`, which is not a pure layer.
/// Thus this library is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show lookupByKey;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsSort;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart' show jsRound;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/scales/scale.time.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:meta/meta.dart';

/// An entry of the lookup table: `{time, pos}` (scale.timeseries.js:95-96,
/// :107).
typedef _TableEntry = Map<String, Object?>;

/// The `ToNumber` of the member [key] of [entry]: `time` or `pos`.
double _read(_TableEntry entry, String key) => jsToNumber(entry[key]);

/// scale.timeseries.js:12 `interpolate(table, val, reverse)`.
///
/// Linearly interpolates the given source `val` using the table. If value
/// is out of bounds, values at edges are used for the interpolation.
/// [reverse] - lookup time based on position instead of vice versa
///
/// [val] is the `ToNumber` of the value: interpolate uses it only in
/// compares and in arithmetic, so one `ToNumber` at the entry gives the
/// result of the `ToNumber` of each operator (Chart.js ADR 0025, section
/// 3).
double _interpolate(
  List<_TableEntry> table,
  double val, [
  bool reverse = false,
]) {
  var lo = 0;
  var hi = table.length - 1;
  double prevSource;
  double nextSource;
  double prevTarget;
  double nextTarget;
  if (reverse) {
    if (val >= _read(table[lo], 'pos') && val <= _read(table[hi], 'pos')) {
      (:lo, :hi) = lookupByKey(table, 'pos', val);
    }
    // ({pos: prevSource, time: prevTarget} = table[lo]);
    prevSource = _read(table[lo], 'pos');
    prevTarget = _read(table[lo], 'time');
    // ({pos: nextSource, time: nextTarget} = table[hi]);
    nextSource = _read(table[hi], 'pos');
    nextTarget = _read(table[hi], 'time');
  } else {
    if (val >= _read(table[lo], 'time') && val <= _read(table[hi], 'time')) {
      (:lo, :hi) = lookupByKey(table, 'time', val);
    }
    // ({time: prevSource, pos: prevTarget} = table[lo]);
    prevSource = _read(table[lo], 'time');
    prevTarget = _read(table[lo], 'pos');
    // ({time: nextSource, pos: nextTarget} = table[hi]);
    nextSource = _read(table[hi], 'time');
    nextTarget = _read(table[hi], 'pos');
  }

  final span = nextSource - prevSource;
  return jsTruthy(span)
      ? prevTarget + (nextTarget - prevTarget) * (val - prevSource) / span
      : prevTarget;
}

/// The JS read `items[index]` of a List of timestamps: NaN (the `ToNumber`
/// of `undefined`) for an index out of the range, 0 for a JS `null`
/// timestamp.
double _itemAt(List<double?> items, int index) =>
    index >= 0 && index < items.length ? jsToNumber(items[index]) : double.nan;

/// scale.timeseries.js:34 `TimeSeriesScale extends TimeScale`.
class TimeSeriesScale extends TimeScale {
  /// scale.timeseries.js:46 `constructor(props)`.
  ///
  /// The fields get their start values in their declarations
  /// (scale.timeseries.js:50-54).
  TimeSeriesScale(super.cfg);

  // scale.timeseries.js:36 `static id = 'timeseries'`. Scale has the
  // instance field `id`. Thus the value is only in the statics of jsClass.

  /// scale.timeseries.js:41 `static defaults = TimeScale.defaults`: the same
  /// Map as [TimeScale.defaults].
  static final AnyObject defaults = TimeScale.defaults;

  /// scale.timeseries.js:34 `class TimeSeriesScale extends TimeScale` as a
  /// value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [TimeScale.jsClass]. Its statics are `id` (`'timeseries'`)
  /// and [defaults], in the upstream order of declaration
  /// (scale.timeseries.js:36-41). Its `construct` calls
  /// `TimeSeriesScale(cfg)` with the `cfg` of [scaleCfgArg]. The registry
  /// registers [TimeScale.jsClass] first, because it has an `id` and
  /// `defaults` (core.typedRegistry.js:30-32).
  static final JsClass jsClass = JsClass(
    'TimeSeriesScale',
    superclass: TimeScale.jsClass,
    statics: {'id': 'timeseries', 'defaults': defaults},
    construct: (newTarget, args) => TimeSeriesScale(scaleCfgArg(args)),
  );

  /// scale.timeseries.js:50 `_table`, the lookup table.
  List<_TableEntry> _table = [];

  /// scale.timeseries.js:52 `_minPos`. NaN stands for JS `undefined`.
  double _minPos = double.nan;

  /// scale.timeseries.js:54 `_tableRange`. NaN stands for JS `undefined`.
  double _tableRange = double.nan;

  /// scale.timeseries.js:60 `initOffsets()`.
  ///
  /// Upstream declares no parameter. [TimeScale.buildTicks] and
  /// [TimeScale.afterAutoSkip] give timestamps, and the method ignores
  /// them: it builds the lookup table from the timestamps of the data and
  /// of the labels.
  @override
  @protected
  void initOffsets([List<double?> _ = const []]) {
    final timestamps = _getTimestampsForTable();
    final table = _table = buildLookupTable(timestamps);
    _minPos = _interpolate(table, min);
    _tableRange = _interpolate(table, max) - _minPos;
    super.initOffsets(timestamps);
  }

  /// scale.timeseries.js:79 `buildLookupTable(timestamps)`.
  ///
  /// Returns an array of {time, pos} objects used to interpolate a specific
  /// `time` or position (`pos`) on the scale, by searching entries before
  /// and after the requested value. `pos` is a decimal between 0 and 1: 0
  /// being the start of the scale (left or top) and 1 the other extremity
  /// (left + width or top + height). Note that it would be more optimized to
  /// directly store pre-computed pixels, but the scale dimensions are not
  /// guaranteed at the time we need to create the lookup table. The table
  /// ALWAYS contains at least two items: min and max.
  ///
  /// The compares and the sum apply `ToNumber` to a JS `null` timestamp.
  /// `Math.round(...) !== curr` is true for a `null` `curr`. An entry is a
  /// Map `{'time': time, 'pos': pos}`.
  @protected
  List<Map<String, Object?>> buildLookupTable(List<double?> timestamps) {
    final min = this.min;
    final max = this.max;
    final items = <double?>[];
    final table = <_TableEntry>[];

    for (var i = 0, ilen = timestamps.length; i < ilen; ++i) {
      final curr = timestamps[i];
      if (jsToNumber(curr) >= min && jsToNumber(curr) <= max) {
        items.add(curr);
      }
    }

    if (items.length < 2) {
      // In case there is less that 2 timestamps between min and max, the
      // scale is defined by min and max
      return [
        {'time': min, 'pos': 0.0},
        {'time': max, 'pos': 1.0},
      ];
    }

    for (var i = 0, ilen = items.length; i < ilen; ++i) {
      final next = _itemAt(items, i + 1);
      final prev = _itemAt(items, i - 1);
      final curr = items[i];

      // only add points that breaks the scale linearity
      if (jsRound((next + prev) / 2) != curr) {
        table.add({'time': curr, 'pos': i / (ilen - 1)});
      }
    }
    return table;
  }

  /// scale.timeseries.js:119 `_generate()`.
  ///
  /// Generates all timestamps defined in the data.
  /// Important: this method can return ticks outside the min and max range,
  /// it's the responsibility of the calling code to clamp values if needed.
  ///
  /// The result is the List of the data timestamps of the cache: the method
  /// adds [min] and [max] to it and sorts it in place, as upstream.
  @internal
  @protected
  @override
  List<double> generate() {
    final min = this.min;
    final max = this.max;
    final timestamps = super.getDataTimestamps();
    if (!timestamps.contains(min) || timestamps.isEmpty) {
      timestamps.insert(0, min);
    }
    if (!timestamps.contains(max) || timestamps.length == 1) {
      timestamps.add(max);
    }
    return jsSort(timestamps, (a, b) => a - b);
  }

  /// scale.timeseries.js:137 `_getTimestampsForTable()`.
  ///
  /// Returns all timestamps
  List<double?> _getTimestampsForTable() {
    var timestamps = cache['all'] as List<double?>? ?? <double?>[];

    if (timestamps.isNotEmpty) {
      return timestamps;
    }

    final data = getDataTimestamps();
    final label = getLabelTimestamps();
    if (data.isNotEmpty && label.isNotEmpty) {
      // If combining labels and data (data might not contain all labels),
      // we need to recheck uniqueness and sort
      timestamps = normalize(<double?>[...data, ...label]);
    } else {
      timestamps = data.isNotEmpty ? data : label;
    }
    // timestamps = this._cache.all = timestamps;
    return cache['all'] = timestamps;
  }

  /// scale.timeseries.js:162 `getDecimalForValue(value)`.
  ///
  /// [value] - Milliseconds since epoch (1 January 1970 00:00:00 UTC)
  ///
  /// [value] is any JS value. `null` acts as 0 (Chart.js ADR 0025, probe
  /// P5).
  @override
  double getDecimalForValue(Object? value) {
    return (_interpolate(_table, jsToNumber(value)) - _minPos) / _tableRange;
  }

  /// scale.timeseries.js:170 `getValueForPixel(pixel)`.
  @override
  double getValueForPixel(double pixel) {
    final offsets = this.offsets;
    final decimal = getDecimalForPixel(pixel) / offsets.factor - offsets.end;
    return _interpolate(_table, decimal * _tableRange + _minPos, true);
  }
}
