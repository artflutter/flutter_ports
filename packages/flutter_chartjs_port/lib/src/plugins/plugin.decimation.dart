// Ported from Chart.js v4.6.1 src/plugins/plugin.decimation.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.decimation.js`.
///
/// [decimation] is the plugin object, the default export of the upstream
/// file and `Decimation` of `src/plugins/index.js:2` (Chart.js ADR 0038,
/// section 1). It is a mutable Map with the upstream keys in the upstream
/// order: `id`, `defaults`, `beforeElementsUpdate` and `destroy`. Each hook
/// is a closure with the upstream parameter count (Chart.js ADR 0038,
/// section 3).
///
/// The data of a dataset: upstream replaces the own property `data` of a
/// decimated dataset with an accessor (`plugin.decimation.js:249-265`). A
/// Dart `Map` has no accessor for one key. Thus `data` stays a plain entry
/// that holds the value of the upstream getter, and an `Expando` marks the
/// datasets that have the accessor. A sync turns a user write of `data`
/// into the setter write (Chart.js ADR 0038, section 8; differences.md row
/// `adapt-decimation-data-accessor`).
///
/// The two algorithms read the data items with the JavaScript operators:
/// `+=` with [jsAdd], the arithmetic through [jsToNumber], `|` through
/// [jsToInt32], and the compare of the raw `y` values through [jsLessThan]
/// (Chart.js ADRs 0036 and 0045). For number items, these are the `double`
/// operations.
///
/// A pure layer (Chart.js ADR 0038, section 9): it imports only pure
/// helpers, the JS runtime and the type interfaces.
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show lookupByKey;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show limitValue;
import 'package:flutter_chartjs_port/src/helpers/helpers.options.dart'
    show resolve;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsObjectKeys;
import 'package:flutter_chartjs_port/src/js/js_math.dart'
    show jsMax, jsMin, jsToInt32;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsAdd, jsLessThan, jsToNumber, jsToString, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex, jsGetKey;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;
import 'package:meta/meta.dart';

/// plugin.decimation.js:3 `lttbDecimation(data, start, count,
/// availableWidth, options)`.
///
/// Implementation of the Largest Triangle Three Buckets algorithm.
///
/// This implementation is based on the original implementation by Sveinn
/// Steinarsson in
/// https://github.com/sveinn-steinarsson/flot-downsample/blob/master/jquery.flot.downsample.js
///
/// The original implementation is MIT licensed.
///
/// Upstream does not export the function. It is public here with
/// `@internal` for the tests of the algorithm (Chart.js ADR 0012).
///
/// [data] is the raw data of the dataset. [options] is the option object
/// of the plugin: the function reads `options.samples`. An index past the
/// end, a `null` or an `undefined` item throws a [TypeError] at the read of
/// its `x`, as the destructuring of `:50` and the reads of `:40-41` and
/// `:61-62` do.
@internal
List<Object?> lttbDecimation(
  List<Object?> data,
  double start,
  double count,
  double availableWidth,
  Object? options,
) {
  final samplesOption = jsGet(options, 'samples');
  // `samples` reaches only numeric operators (`>=`, `-`, `/`, `<`), which
  // apply ToNumber to it.
  final samples = jsToNumber(
    jsTruthy(samplesOption) ? samplesOption : availableWidth,
  );
  // There are less points than the threshold, returning the whole array
  if (samples >= count) {
    return _slice(data, start, start + count);
  }

  final decimated = <Object?>[];

  final bucketWidth = (count - 2) / (samples - 2);
  final endIndex = start + count - 1;
  // Starting from offset
  // `a` and `nextA` are indices. Dart `null` stands for the `undefined` of
  // a `nextA` that the loop of :59-70 never sets.
  double? a = start;
  double? nextA;
  Object? maxAreaPoint = undefined;
  double maxArea;
  double area;

  decimated.add(jsGetIndex(data, a));

  for (var i = 0.0; i < samples - 2; i++) {
    Object? avgX = 0.0;
    Object? avgY = 0.0;

    // Adding offset
    final avgRangeStart = ((i + 1) * bucketWidth).floorToDouble() + 1 + start;
    final avgRangeEnd =
        jsMin(((i + 2) * bucketWidth).floorToDouble() + 1, count) + start;
    final avgRangeLength = avgRangeEnd - avgRangeStart;

    for (var j = avgRangeStart; j < avgRangeEnd; j++) {
      avgX = jsAdd(avgX, jsGetKey(jsGetIndex(data, j), 'x'));
      avgY = jsAdd(avgY, jsGetKey(jsGetIndex(data, j), 'y'));
    }

    final avgXValue = jsToNumber(avgX) / avgRangeLength;
    final avgYValue = jsToNumber(avgY) / avgRangeLength;

    // Adding offset
    final rangeOffs = (i * bucketWidth).floorToDouble() + 1 + start;
    final rangeTo =
        jsMin(((i + 1) * bucketWidth).floorToDouble() + 1, count) + start;
    // `const {x: pointAx, y: pointAy} = data[a]`: an `undefined` a reads
    // `data[undefined]`.
    final pointA = jsGetIndex(data, a ?? double.nan);
    final pointAx = jsToNumber(jsGetKey(pointA, 'x'));
    final pointAy = jsToNumber(jsGetKey(pointA, 'y'));

    // Note that this is changed from the original algorithm which
    // initializes these values to 1. The reason for this change is that if
    // the area is small, nextA would never be set and thus a crash would
    // occur in the next loop as `a` would become `undefined`. Since the area
    // is always positive, but could be 0 in the case of a flat trace,
    // initializing with a negative number is the correct solution.
    maxArea = area = -1;

    for (var j = rangeOffs; j < rangeTo; j++) {
      final point = jsGetIndex(data, j);
      area =
          0.5 *
          ((pointAx - avgXValue) *
                      (jsToNumber(jsGetKey(point, 'y')) - pointAy) -
                  (pointAx - jsToNumber(jsGetKey(point, 'x'))) *
                      (avgYValue - pointAy))
              .abs();

      if (area > maxArea) {
        maxArea = area;
        maxAreaPoint = point;
        nextA = j;
      }
    }

    decimated.add(maxAreaPoint);
    a = nextA;
  }

  // Include the last point
  decimated.add(jsGetIndex(data, endIndex));

  return decimated;
}

/// plugin.decimation.js:82 `minMaxDecimation(data, start, count,
/// availableWidth)`.
///
/// Upstream does not export the function. It is public here with
/// `@internal` for the tests of the algorithm (Chart.js ADR 0012).
///
/// The `y` values stay raw until the compare of `:101` and `:104`, which
/// compares two strings by their code units ([jsLessThan]). A new item of
/// `:124-133` is a new Map with the own keys of the item and `x` ([_withX]).
@internal
List<Object?> minMaxDecimation(
  List<Object?> data,
  double start,
  double count,
  double availableWidth,
) {
  var avgX = 0.0;
  var countX = 0.0;
  // Dart `null` stands for the `undefined` start values of :85.
  double? prevX;
  double? minIndex;
  double? maxIndex;
  double? startIndex;
  Object? minY;
  Object? maxY;
  final decimated = <Object?>[];
  final endIndex = start + count - 1;

  final xMin = jsGetKey(jsGetIndex(data, start), 'x');
  final xMax = jsGetKey(jsGetIndex(data, endIndex), 'x');
  final dx = jsToNumber(xMax) - jsToNumber(xMin);

  for (var i = start; i < start + count; ++i) {
    final point = jsGetIndex(data, i);
    final pointX = jsGetKey(point, 'x');
    final x = (jsToNumber(pointX) - jsToNumber(xMin)) / dx * availableWidth;
    final y = jsGetKey(point, 'y');
    final truncX = jsToInt32(x);

    if (truncX == prevX) {
      // Determine `minY` / `maxY` and `avgX` while we stay within same
      // x-position
      if (jsLessThan(y, minY)) {
        minY = y;
        minIndex = i;
      } else if (jsLessThan(maxY, y)) {
        maxY = y;
        maxIndex = i;
      }
      // For first point in group, countX is `0`, so average will be `x` / 1.
      // Use point.x here because we're computing the average data `x` value
      avgX = jsToNumber(jsAdd(countX * avgX, pointX)) / ++countX;
    } else {
      // Push up to 4 points, 3 for the last interval and the first point for
      // this interval
      final lastIndex = i - 1;

      if (!isNullOrUndef(minIndex) && !isNullOrUndef(maxIndex)) {
        // The interval is defined by 4 points: start, min, max, end.
        // The starting point is already considered at this point, so we need
        // to determine which of the other points to add. We need to sort
        // these points to ensure the decimated data is still sorted and then
        // ensure there are no duplicates.
        final intermediateIndex1 = jsMin(minIndex!, maxIndex!);
        final intermediateIndex2 = jsMax(minIndex, maxIndex);

        if (intermediateIndex1 != startIndex &&
            intermediateIndex1 != lastIndex) {
          decimated.add(_withX(jsGetIndex(data, intermediateIndex1), avgX));
        }
        if (intermediateIndex2 != startIndex &&
            intermediateIndex2 != lastIndex) {
          decimated.add(_withX(jsGetIndex(data, intermediateIndex2), avgX));
        }
      }

      // lastIndex === startIndex will occur when a range has only 1 point
      // which could happen with very uneven data
      if (i > 0 && lastIndex != startIndex) {
        // Last point in the previous interval
        decimated.add(jsGetIndex(data, lastIndex));
      }

      // Start of the new interval
      decimated.add(point);
      prevX = truncX;
      countX = 0;
      minY = maxY = y;
      minIndex = maxIndex = startIndex = i;
    }
  }

  return decimated;
}

/// The object literal `{...item, x: avgX}` of plugin.decimation.js:124-133:
/// the own enumerable keys of [item] in the order of `Object.keys`, then
/// `x`. A key `x` of [item] keeps its place and gets [x].
///
/// Only an item with a `y` value that compares (`:101`, `:104`) becomes a
/// min or max item. An array, a string, a number, `null` and `undefined`
/// have no own `y`, so [item] is always a Map here. A Map gives its String
/// keys, as the spread gives the own keys. This is also true for a Map with
/// other type arguments, for example the `Map<dynamic, dynamic>` of an
/// untyped literal, which [jsGet] and [jsGetKey] also read. A key that is
/// not a String is not a property: [jsGet] never reads it, so the copy
/// leaves it out.
AnyObject _withX(Object? item, double x) {
  final own = switch (item) {
    final Map<String, Object?> map => map,
    final Map<dynamic, dynamic> map => <String, Object?>{
      for (final MapEntry(:key, :value) in map.entries)
        if (key is String) key: value,
    },
    _ => const <String, Object?>{},
  };
  return <String, Object?>{
    for (final key in jsObjectKeys(own)) key: jsGet(own, key),
    'x': x,
  };
}

/// `array.slice(begin, end)` (ECMAScript 23.1.3.28) for the whole-number
/// bounds of plugin.decimation.js:15: a new List.
List<Object?> _slice(List<Object?> list, double begin, double end) {
  final length = list.length.toDouble();
  double bound(double value) =>
      value < 0 ? jsMax(length + value, 0) : jsMin(value, length);
  final from = bound(begin).toInt();
  final to = bound(end).toInt();
  return from < to ? list.sublist(from, to) : <Object?>[];
}

/// The accessor of plugin.decimation.js:255-264 on one dataset: [written] is
/// the last value that the plugin wrote into the plain entry `data`.
final class _DataAccessor {
  _DataAccessor(this.written);

  /// The last getter value that the plugin wrote into `data`.
  Object? written;
}

/// The accessor state of plugin.decimation.js:255-264: present while `data`
/// of the dataset is the accessor property.
final Expando<_DataAccessor> _dataAccessor = Expando<_DataAccessor>(
  'decimation data accessor',
);

// DIVERGES(chartjs): adapt-decimation-data-accessor, a Map has no accessor.
/// The setter of plugin.decimation.js:261-263, applied before each use of
/// the dataset.
///
/// A `data` value that is not identical to the last value that the plugin
/// wrote is a user write since the last hook: it goes to `_data`. Then
/// `data` gets the getter value (`_decimated`, :258-260). Thus a user write
/// or delete of `_decimated` changes `data` and not `_data`, as the getter
/// does. The getter value comes from [jsGet], so an absent `_decimated`
/// gives [undefined]. A `delete dataset.data` of the user removes the
/// accessor upstream: an absent key `data` clears the mark. A dataset that
/// is not a Map never has the accessor.
void _syncDataAccessor(Object? dataset) {
  if (dataset is! AnyObject) return;
  final accessor = _dataAccessor[dataset];
  if (accessor == null) return;
  if (!dataset.containsKey('data')) {
    _dataAccessor[dataset] = null;
    return;
  }
  final data = dataset['data'];
  if (!identical(data, accessor.written)) {
    // DIVERGES(chartjs): js-semantics-narrow-datasets, a narrow or fixed Map.
    dataset['_data'] = data;
  }
  final getterValue = jsGet(dataset, '_decimated');
  if (!identical(data, getterValue)) {
    dataset['data'] = getterValue;
  }
  accessor.written = getterValue;
}

/// plugin.decimation.js:156 `cleanDecimatedDataset(dataset)`.
///
/// The sync of the accessor runs first ([_syncDataAccessor]). The write of
/// `data` keeps the place of the key, as `Object.defineProperty` on an own
/// key does, and adds the key at the end when the user removed it.
void _cleanDecimatedDataset(Object? dataset) {
  _syncDataAccessor(dataset);
  if (jsTruthy(jsGet(dataset, '_decimated'))) {
    final target = dataset! as AnyObject;
    final data = jsGet(target, '_data');
    // DIVERGES(chartjs): js-semantics-narrow-datasets, a narrow or fixed Map.
    target
      ..remove('_decimated')
      ..remove('_data')
      ..['data'] = data;
    _dataAccessor[target] = null;
  }
}

/// plugin.decimation.js:170 `cleanDecimatedData(chart)`.
///
/// `forEach` visits the indices below the length at its start.
void _cleanDecimatedData(types.Chart chart) {
  final datasets = _datasets(chart);
  for (var k = 0, length = datasets.length; k < length; k++) {
    _cleanDecimatedDataset(datasets[k]);
  }
}

/// `chart.data.datasets`: a value that is not an array throws a
/// [TypeError] at the call of `forEach`.
List<Object?> _datasets(types.Chart chart) =>
    jsGet(chart.data, 'datasets')! as List<Object?>;

// DIVERGES(chartjs): js-semantics-decimation-data, the data is an array.
/// plugin.decimation.js:176 `getStartAndCountOfVisiblePointsSimplified(meta,
/// points)`.
///
/// `start` and `count` are JS numbers: `double` values. The `lo` and `hi`
/// of [lookupByKey] are `int` values, which the port converts. [points] is
/// the raw data of the dataset. Data that is not an array throws a
/// [TypeError] here (differences.md row `js-semantics-decimation-data`).
({double start, double count}) _getStartAndCountOfVisiblePointsSimplified(
  types.ChartMeta meta,
  Object? points,
) {
  final table = points! as List<Object?>;
  final pointCount = table.length.toDouble();

  var start = 0.0;
  double count;

  final iScale = meta.iScale!;
  final (:min, :max, :minDefined, :maxDefined) = iScale.getUserBounds();

  if (minDefined) {
    start = limitValue(
      lookupByKey(table, iScale.axis, min).lo.toDouble(),
      0,
      pointCount - 1,
    );
  }
  if (maxDefined) {
    count =
        limitValue(
          lookupByKey(table, iScale.axis, max).hi + 1.0,
          start,
          pointCount,
        ) -
        start;
  } else {
    count = pointCount - start;
  }

  return (start: start, count: count);
}

/// plugin.decimation.js:205 `beforeElementsUpdate(chart, args, options)`.
void _beforeElementsUpdate(
  types.Chart chart,
  AnyObject args,
  AnyObject options,
) {
  if (!jsTruthy(jsGet(options, 'enabled'))) {
    // The decimation plugin may have been previously enabled. Need to remove
    // old `dataset._data` handlers
    _cleanDecimatedData(chart);
    return;
  }

  // Assume the entire chart is available to show a few more points than
  // needed
  final availableWidth = chart.width;

  final datasets = _datasets(chart);
  for (
    var datasetIndex = 0, length = datasets.length;
    datasetIndex < length;
    datasetIndex++
  ) {
    final dataset = datasets[datasetIndex];
    // DIVERGES(chartjs): adapt-decimation-data-accessor, the setter first.
    _syncDataAccessor(dataset);
    final dataOwn = jsGet(dataset, '_data');
    final indexAxis = jsGet(dataset, 'indexAxis');
    final meta = chart.getDatasetMeta(datasetIndex.toDouble());
    final data = jsTruthy(dataOwn) ? dataOwn : jsGet(dataset, 'data');

    if (resolve([indexAxis, jsGet(chart.options, 'indexAxis')]) == 'y') {
      // Decimation is only supported for lines that have an X indexAxis
      continue;
    }

    if (!meta.controller!.supportsDecimation) {
      // Only line datasets are supported
      continue;
    }

    final xAxis = chart.scales[jsToString(meta.xAxisID)]!;
    if (xAxis.type != 'linear' && xAxis.type != 'time') {
      // Only linear interpolation is supported
      continue;
    }

    if (jsTruthy(jsGet(chart.options, 'parsing'))) {
      // Plugin only supports data that does not need parsing
      continue;
    }

    final (:start, :count) = _getStartAndCountOfVisiblePointsSimplified(
      meta,
      data,
    );
    final threshold = jsGet(options, 'threshold');
    // `count <= threshold` applies ToNumber to the threshold, because
    // `count` is a number.
    if (count <=
        jsToNumber(jsTruthy(threshold) ? threshold : 4 * availableWidth)) {
      // No decimation is required until we are above this threshold
      _cleanDecimatedDataset(dataset);
      continue;
    }

    final target = dataset! as AnyObject;
    if (isNullOrUndef(dataOwn)) {
      // First time we are seeing this dataset
      // We override the 'data' property with a setter that stores the
      // raw data in _data, but reads the decimated data from _decimated
      // DIVERGES(chartjs): js-semantics-narrow-datasets, a narrow or fixed Map.
      target['_data'] = data;
      target.remove('data');
      // DIVERGES(chartjs): adapt-decimation-data-accessor, the getter value.
      final getterValue = jsGet(target, '_decimated');
      target['data'] = getterValue;
      _dataAccessor[target] = _DataAccessor(getterValue);
    }

    // Point the chart to the decimated data
    final List<Object?> decimated;
    final algorithm = jsGet(options, 'algorithm');
    switch (algorithm) {
      case 'lttb':
        decimated = lttbDecimation(
          data! as List<Object?>,
          start,
          count,
          availableWidth,
          options,
        );
      case 'min-max':
        decimated = minMaxDecimation(
          data! as List<Object?>,
          start,
          count,
          availableWidth,
        );
      default:
        // A JavaScript Error.
        throw StateError(
          "Unsupported decimation algorithm '${jsToString(algorithm)}'",
        );
    }

    // DIVERGES(chartjs): js-semantics-narrow-datasets, a narrow or fixed Map.
    target['_decimated'] = decimated;
    final accessor = _dataAccessor[target];
    if (accessor != null) {
      // DIVERGES(chartjs): adapt-decimation-data-accessor, the getter value.
      target['data'] = decimated;
      accessor.written = decimated;
    }
  }
}

/// plugin.decimation.js:197 the default export, `Decimation` of
/// src/plugins/index.js:2.
final AnyObject decimation = <String, Object?>{
  'id': 'decimation',

  'defaults': <String, Object?>{
    'algorithm': 'min-max',
    'enabled': false,
  },

  /// plugin.decimation.js:205 `beforeElementsUpdate(chart, args, options)`.
  'beforeElementsUpdate': _beforeElementsUpdate,

  /// plugin.decimation.js:284 `destroy(chart)`: the body is the call of
  /// `cleanDecimatedData(chart)`, and both take one parameter.
  'destroy': _cleanDecimatedData,
};
