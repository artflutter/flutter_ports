// Ported from Chart.js v4.6.1 src/scales/scale.time.js (MIT, Chart.js Contributors).

/// Port of `src/scales/scale.time.js`.
///
/// [TimeScale] maps dates to the axis. It reads each date through the date
/// adapter of `core.adapters.dart`: `new adapters._date(...)` gives a
/// [DateAdapterBase], whose prototype starts with the default members of
/// `date_adapter.dart` (Chart.js ADR 0024). A time is a number of
/// milliseconds since the epoch.
///
/// - Options are the resolvers of `helpers.config` (Chart.js ADR 0043). The
///   scale reads an option with `options[key]` or [jsGet], tests it with
///   [jsTruthy], and applies [jsToNumber] before arithmetic. The adapter
///   gets the raw option values, as upstream gives them.
/// - Numbers are `double` (Chart.js ADR 0045). `+value` of an adapter
///   result is [jsToNumber]. `Date.now()` is [jsDateNow].
/// - The value methods take any JS value (Chart.js ADR 0025).
///   [TimeScale.getDecimalForValue] starts with the port-only fast path for
///   a `double` of Chart.js ADR 0025, section 3.
/// - The `_` members that other modules read drop the underscore and carry
///   `@internal` (Chart.js ADR 0012, Chart.js ADR 0025, section 6):
///   [TimeScale.unit], [TimeScale.adapter], [TimeScale.offsets] and
///   [TimeScale.generate]. The other `_` members keep the underscore.
/// - A label that the adapter cannot parse gives the timestamp JS `null`.
///   The label timestamps keep it as Dart `null`. `Tick.value`, `Scale.min`
///   and `Scale.max` are `double`. Thus such a tick value is NaN, and such a
///   bound is 0 (differences.md row `adapt-time-null-timestamp`). The
///   readers of this library read the tick value with [_tickValue], which
///   gives the `null` back: [TimeScale.getPixelForTick], the tick labels,
///   the major ticks and [TimeScale.afterAutoSkip].
/// - A step of `_generate` that does not advance throws a [StateError].
///   Upstream loops without end (differences.md row
///   `adapt-time-generate-no-advance`).
///
/// `core.scale.dart` imports `helpers.extras`, which is not a pure layer.
/// Thus this library is not a pure layer.
library;

import 'package:flutter_chartjs_port/src/core/core.adapters.dart';
import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show arrayUnique, filterBetween, lookup;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show callback, isFinite, isNullOrUndef, mergeIf, valueOrDefault;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show isNumber, limitValue, toRadians;
import 'package:flutter_chartjs_port/src/js/js_array.dart' show jsSort;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_date.dart' show jsDateNow;
import 'package:flutter_chartjs_port/src/js/js_function.dart'
    show jsCall, jsIsFunction;
import 'package:flutter_chartjs_port/src/js/js_math.dart'
    show jsCos, jsMax, jsMin, jsSin;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart' show jsGet;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:meta/meta.dart';

/// scale.time.js:9 `Interval`: `{common: boolean, size: number, steps?:
/// number}`. Dart `null` for `steps` stands for the absent key.
typedef _Interval = ({bool common, double size, double? steps});

/// scale.time.js:16 `INTERVALS`.
const Map<String, _Interval> _intervals = {
  'millisecond': (common: true, size: 1, steps: 1000),
  'second': (common: true, size: 1000, steps: 60),
  'minute': (common: true, size: 60000, steps: 60),
  'hour': (common: true, size: 3600000, steps: 24),
  'day': (common: true, size: 86400000, steps: 30),
  'week': (common: false, size: 604800000, steps: 4),
  'month': (common: true, size: 2.628e9, steps: 12),
  'quarter': (common: false, size: 7.884e9, steps: 4),
  'year': (common: true, size: 3.154e10, steps: null),
};

/// scale.time.js:31 `UNITS`: the keys of [_intervals], in their order.
const List<String> _units = [
  'millisecond',
  'second',
  'minute',
  'hour',
  'day',
  'week',
  'month',
  'quarter',
  'year',
];

/// `Number.MAX_SAFE_INTEGER` (ECMAScript 21.1.2.6).
const double _maxSafeInteger = 9007199254740991;

/// `UNITS[i]`: the unit at the index [i], or [undefined] for an index
/// outside [_units], as JavaScript reads it.
Object? _unitAt(int i) => i >= 0 && i < _units.length ? _units[i] : undefined;

/// `UNITS.indexOf(unit)`: -1 for a value that is not a unit name. The
/// strict compare of `indexOf` matches no value that is not a string.
int _indexOfUnit(Object? unit) => unit is String ? _units.indexOf(unit) : -1;

/// `INTERVALS[unit]` for a member read. A [unit] that is not a key of
/// [_intervals] reads `undefined`, and a member read of `undefined` throws
/// a [TypeError], as JavaScript throws.
_Interval _intervalOf(Object? unit) => _intervals[unit] ?? (throw TypeError());

/// scale.time.js:37 `sorter(a, b)`.
///
/// `a - b` applies `ToNumber` to each value. A JS `null` timestamp of a
/// label thus sorts as 0.
double _sorter(double? a, double? b) {
  return jsToNumber(a) - jsToNumber(b);
}

/// scale.time.js:46 `parse(scale, input)`.
///
/// The method [TimeScale.parse] has the name `parse` too. Thus the Dart
/// name of this function has an underscore.
///
/// It gives the timestamp of [input], or Dart `null` for JS `null`.
/// `typeof parser === 'function'` is [jsIsFunction], and the call
/// `parser(value)` is [jsCall] with no `this`. A [DateTime] value is a JS
/// `Date`: it is not a finite number, so the adapter parses it.
double? _parse(TimeScale scale, Object? input) {
  if (isNullOrUndef(input)) {
    return null;
  }

  final adapter = scale.adapter;
  final (:parser, :round, :isoWeekday) = scale._parseOpts;
  var value = input;

  if (jsIsFunction(parser)) {
    value = jsCall(parser, [value]);
  }

  // Only parse if it's not a timestamp already
  if (!isFinite(value)) {
    value = parser is String
        ? adapter.parse(value, parser)
        : adapter.parse(value);
  }

  if (value == null) {
    return null;
  }

  if (jsTruthy(round)) {
    value = round == 'week' && (isNumber(isoWeekday) || isoWeekday == true)
        ? adapter.startOf(value, 'isoWeek', isoWeekday)
        : adapter.startOf(value, round);
  }

  return jsToNumber(value);
}

/// scale.time.js:87 `determineUnitForAutoTicks(minUnit, min, max,
/// capacity)`.
///
/// Figures out what unit results in an appropriate number of
/// auto-generated ticks
///
/// A [minUnit] that is not a unit gives the index -1. Upstream then reads
/// `INTERVALS[undefined].steps`, which throws a [TypeError].
Object? _determineUnitForAutoTicks(
  Object? minUnit,
  double min,
  double max,
  double capacity,
) {
  final ilen = _units.length;

  for (var i = _indexOfUnit(minUnit); i < ilen - 1; ++i) {
    final interval = _intervalOf(_unitAt(i));
    final steps = interval.steps;
    final factor = jsTruthy(steps) ? steps! : _maxSafeInteger;

    if (interval.common &&
        ((max - min) / (factor * interval.size)).ceilToDouble() <= capacity) {
      return _units[i];
    }
  }

  return _units[ilen - 1];
}

/// scale.time.js:111 `determineUnitForFormatting(scale, numTicks, minUnit,
/// min, max)`.
///
/// Figures out what unit to format a set of ticks with
///
/// `>=` applies `ToNumber` to the result of `diff`. A [minUnit] that is not
/// a unit runs the loop down to the index -1, where `INTERVALS[undefined]`
/// throws a [TypeError], as upstream.
Object? _determineUnitForFormatting(
  TimeScale scale,
  int numTicks,
  Object? minUnit,
  double min,
  double max,
) {
  for (var i = _units.length - 1; i >= _indexOfUnit(minUnit); i--) {
    final unit = _unitAt(i);
    if (_intervalOf(unit).common &&
        jsToNumber(scale.adapter.diff(max, min, unit)) >= numTicks - 1) {
      return unit;
    }
  }

  return _unitAt(jsTruthy(minUnit) ? _indexOfUnit(minUnit) : 0);
}

/// scale.time.js:126 `determineMajorUnit(unit)`.
///
/// Dart `null` stands for the `undefined` of a unit without a larger common
/// unit.
String? _determineMajorUnit(Object? unit) {
  for (var i = _indexOfUnit(unit) + 1, ilen = _units.length; i < ilen; ++i) {
    if (_intervals[_units[i]]!.common) {
      return _units[i];
    }
  }
  return null;
}

/// scale.time.js:139 `addTick(ticks, time, timestamps)`.
///
/// [timestamps] - if defined, snap to these timestamps. Dart `null` stands
/// for the `false` of `ticks.source !== 'data'`.
///
/// Upstream sets the key `ToString(time)` of an object. [ticks] is a Map of
/// the times instead (see [TimeScale.generate]).
void _addTick(Map<double, bool> ticks, double time, List<double>? timestamps) {
  if (timestamps == null) {
    ticks[time] = true;
  } else if (timestamps.isNotEmpty) {
    final (:lo, :hi) = lookup(timestamps, time);
    final timestamp = timestamps[lo] >= time ? timestamps[lo] : timestamps[hi];
    ticks[timestamp] = true;
  }
}

/// The ticks of [_ticksFromTimestamps] whose value is JS `null`: the ticks
/// of the labels that the adapter cannot parse. `Tick.value` is a
/// `double`, and such a tick holds NaN (row `adapt-time-null-timestamp`).
/// The marks stay with the [Tick] objects: `autoSkip` and `reverse` keep
/// the objects.
final Expando<bool> _nullValueTicks = Expando<bool>('null tick value');

/// `tick.value` as upstream holds it: Dart `null` (JS `null`) for a tick of
/// [_nullValueTicks] that still holds NaN, else [Tick.value].
double? _tickValue(Tick tick) {
  final value = tick.value;
  // DIVERGES(chartjs): adapt-time-null-timestamp, the null tick value.
  return value.isNaN && (_nullValueTicks[tick] ?? false) ? null : value;
}

/// scale.time.js:156 `setMajorTicks(scale, ticks, map, majorUnit)`.
///
/// `map[major]` reads the key `ToString(major)` upstream. [map] has the
/// tick values as keys instead (see [_ticksFromTimestamps]).
///
/// The tick values are the values of [_tickValue]. `major <= last` applies
/// `ToNumber` to a `null` last value: it compares with 0.
List<Tick> _setMajorTicks(
  TimeScale scale,
  List<Tick> ticks,
  Map<double?, int> map,
  String majorUnit,
) {
  final adapter = scale.adapter;
  final first = jsToNumber(adapter.startOf(_tickValue(ticks[0]), majorUnit));
  final last = jsToNumber(_tickValue(ticks[ticks.length - 1]));
  double major;
  int? index;

  for (
    major = first;
    major <= last;
    major = jsToNumber(adapter.add(major, 1.0, majorUnit))
  ) {
    index = map[major];
    if (index != null && index >= 0) {
      ticks[index].major = true;
    }
  }
  return ticks;
}

/// scale.time.js:177 `ticksFromTimestamps(scale, values, majorUnit)`.
///
/// Upstream keys the object `map` by `ToString(value)`. Here the keys of
/// the Map `map` are the values. Two numbers have the same key string
/// exactly when they are equal numbers, also 0 and -0. Thus each read of
/// [_setMajorTicks], which reads a number that is not NaN, finds the same
/// index.
///
/// A JS `null` value (a label that the adapter cannot parse) gives a tick
/// with the value NaN, in [_nullValueTicks] (row
/// `adapt-time-null-timestamp`).
List<Tick> _ticksFromTimestamps(
  TimeScale scale,
  List<double?> values,
  String? majorUnit,
) {
  final ticks = <Tick>[];
  final map = <double?, int>{};
  final ilen = values.length;

  for (var i = 0; i < ilen; ++i) {
    final value = values[i];
    map[value] = i;

    // DIVERGES(chartjs): adapt-time-null-timestamp, a null tick value is NaN.
    final tick = Tick(value: value ?? double.nan, major: false);
    if (value == null) _nullValueTicks[tick] = true;
    ticks.add(tick);
  }

  // We set the major ticks separately from the above loop because calling
  // startOf for every tick is expensive when there is a large number of
  // ticks
  return (ilen == 0 || !jsTruthy(majorUnit))
      ? ticks
      : _setMajorTicks(scale, ticks, map, majorUnit!);
}

/// helpers.collection.ts:84 `_filterBetween(values, min, max)` for the
/// timestamps of [TimeScale.buildTicks].
///
/// A `List<double>` goes to [filterBetween]. The label timestamps can hold
/// JS `null`: then the same loop compares `null` as 0, as the JavaScript
/// `<` and `>` do. The result is [values] itself when no value is outside
/// the range, as upstream.
List<double?> _filterBetween(List<double?> values, double min, double max) {
  if (values is List<double>) {
    return filterBetween(values, min, max);
  }
  var start = 0;
  var end = values.length;

  while (start < end && jsToNumber(values[start]) < min) {
    start++;
  }
  while (end > start && jsToNumber(values[end - 1]) > max) {
    end--;
  }

  return start > 0 || end < values.length ? values.sublist(start, end) : values;
}

/// `Array.prototype.reverse()` (ECMAScript 23.1.3.26): it reverses [list] in
/// place and keeps the List object. `List.reversed` of Dart is a copy.
void _reverse<T>(List<T> list) {
  for (var lo = 0, hi = list.length - 1; lo < hi; lo++, hi--) {
    final item = list[lo];
    list[lo] = list[hi];
    list[hi] = item;
  }
}

/// The start value of `_cache` (scale.time.js:251-255, :304-308): the data
/// timestamps, the label timestamps and the timestamps of the lookup table
/// of the timeseries scale. A label timestamp can be Dart `null` (JS
/// `null`).
AnyObject _newCache() => <String, Object?>{
  'data': <double>[],
  'labels': <double?>[],
  'all': <double?>[],
};

/// scale.time.js:199 `TimeScale extends Scale`.
class TimeScale extends Scale {
  /// scale.time.js:247 `constructor(props)`.
  ///
  /// [cfg] is the object `{id, type, ctx, chart}` of [Scale.new]. The
  /// fields get their start values in their declarations
  /// (scale.time.js:251-263), and the constructor sets `_cache`.
  TimeScale(super.cfg) {
    cache = _newCache();
  }

  // scale.time.js:201 `static id = 'time'`. Scale has the instance field
  // `id`. Thus the value is only in the statics of jsClass.

  /// scale.time.js:206 `static defaults`.
  ///
  /// `TimeSeriesScale.defaults` is the same Map (scale.timeseries.js:41).
  static final AnyObject defaults = {
    // Scale boundary strategy (bypassed by min/max time options)
    // - `data`: make sure data are fully visible, ticks outside are removed
    // - `ticks`: make sure ticks are fully visible, data outside are
    //   truncated
    // @see https://github.com/chartjs/Chart.js/pull/4556
    // @since 2.7.0
    'bounds': 'data',

    'adapters': <String, Object?>{},
    'time': <String, Object?>{
      // false == a pattern string from or a custom callback that converts
      // its argument to a timestamp
      'parser': false,
      // false == automatic or override with week, month, year, etc.
      'unit': false,
      // none, or override with week, month, year, etc.
      'round': false,
      // override week start day
      'isoWeekday': false,
      'minUnit': 'millisecond',
      'displayFormats': <String, Object?>{},
    },
    'ticks': <String, Object?>{
      // Ticks generation input values:
      // - 'auto': generates "optimal" ticks based on scale size and time
      //   options.
      // - 'data': generates ticks from data (including labels from data
      //   {t|x|y} objects).
      // - 'labels': generates ticks from user given `data.labels` values
      //   ONLY.
      // @see https://github.com/chartjs/Chart.js/pull/4507
      // @since 2.7.0
      'source': 'auto',

      'callback': false,

      'major': <String, Object?>{'enabled': false},
    },
  };

  /// scale.time.js:199 `class TimeScale extends Scale` as a value (Chart.js
  /// ADR 0020, section 3).
  ///
  /// It extends [Scale.jsClass]. Its statics are `id` (`'time'`) and
  /// [defaults], in the upstream order of declaration
  /// (scale.time.js:201-245). Its `construct` calls `TimeScale(cfg)` with
  /// the `cfg` of [scaleCfgArg].
  static final JsClass jsClass = JsClass(
    'TimeScale',
    superclass: Scale.jsClass,
    statics: {'id': 'time', 'defaults': defaults},
    construct: (newTarget, args) => TimeScale(scaleCfgArg(args)),
  );

  /// scale.time.js:258 `_unit`. The spec reads it (scale.time.tests.js:115).
  ///
  /// The unit of the labels: a unit name, or the raw value of a truthy
  /// `time.unit` option (scale.time.js:387).
  @internal
  Object? unit = 'day';

  /// scale.time.js:260 `_majorUnit`. Dart `null` stands for JS `undefined`.
  String? _majorUnit;

  /// scale.time.js:261 `_offsets`. scale.timeseries.js:171 reads it.
  ///
  /// The start value `{}` reads `undefined` for each member, thus NaN.
  @internal
  ({double start, double end, double factor}) offsets = (
    start: double.nan,
    end: double.nan,
    factor: double.nan,
  );

  /// scale.time.js:262 `_normalized`, the `normalized` option of the chart.
  /// The readers test only its truthiness.
  bool _normalized = false;

  /// scale.time.js:263 `_parseOpts`: the `parser`, `round` and `isoWeekday`
  /// options. [init] sets it. A read before [init] throws, as the
  /// destructuring of `undefined` throws upstream.
  late ({Object? parser, Object? round, Object? isoWeekday}) _parseOpts;

  /// scale.time.js:269 `_adapter`. The spec reads it (scale.time.tests.js:448,
  /// :453). Chart.js ADR 0024 decides its type. [init] sets it.
  @internal
  late DateAdapter adapter;

  /// scale.time.js:266 `init(scaleOpts, opts = {})`.
  ///
  /// [options] is the resolver of the scale options. [opts] is the chart
  /// options. Dart `null` stands for JS `undefined`, which takes the
  /// default `{}`.
  ///
  /// The adapter is new in each update, and gets the chart options. The
  /// display formats of the adapter fill the formats that the options do
  /// not give.
  @override
  void init(AnyObject options, [AnyObject? opts]) {
    final chartOptions = opts ?? <String, Object?>{};
    final currentTime = options['time'];
    final time = jsTruthy(currentTime)
        ? currentTime
        : (options['time'] = <String, Object?>{});
    // scale.time.js:271 `adapter.init(opts)` is the cascade.
    final adapter = this.adapter = (jsConstruct(adapters['_date'], [
      jsGet(options['adapters'], 'date'),
    ]) as DateAdapter)..init(chartOptions);

    // Backward compatibility: before introducing adapter, `displayFormats`
    // was supposed to contain *all* unit/string pairs but this can't be
    // resolved when loading the scale (adapters are loaded afterward), so
    // let's populate missing formats on update
    mergeIf(jsGet(time, 'displayFormats'), adapter.formats());

    _parseOpts = (
      parser: jsGet(time, 'parser'),
      round: jsGet(time, 'round'),
      isoWeekday: jsGet(time, 'isoWeekday'),
    );

    super.init(options);

    _normalized = jsTruthy(jsGet(chartOptions, 'normalized'));
  }

  /// scale.time.js:295 `parse(raw, index)`.
  ///
  /// It gives the timestamp of [raw], or Dart `null` (JS `null`) for
  /// [undefined], `null` and a value that the adapter cannot parse.
  @override
  double? parse(Object? raw, [double? index]) {
    // eslint-disable-line no-unused-vars
    if (identical(raw, undefined)) {
      return null;
    }
    return _parse(this, raw);
  }

  /// scale.time.js:302 `beforeLayout()`.
  @override
  void beforeLayout() {
    super.beforeLayout();
    cache = _newCache();
  }

  /// scale.time.js:311 `determineDataLimits()`.
  ///
  /// Without data and bounds, the limits are the start and the end of the
  /// current `time.unit` (or day), from `Date.now()` ([jsDateNow]).
  @override
  void determineDataLimits() {
    final options = this.options;
    final adapter = this.adapter;
    final timeUnit = jsGet(options['time'], 'unit');
    final unit = jsTruthy(timeUnit) ? timeUnit : 'day';
    // eslint-disable-next-line prefer-const
    var (:min, :max, :minDefined, :maxDefined) = getUserBounds();

    /// scale.time.js:321 `_applyBounds(bounds)`.
    ///
    /// `isNaN` and `Math.min` apply `ToNumber`: a JS `null` bound of the
    /// labels acts as 0.
    void applyBounds(({double? min, double? max}) bounds) {
      if (!minDefined && !jsIsNaN(bounds.min)) {
        min = jsMin(min, jsToNumber(bounds.min));
      }
      if (!maxDefined && !jsIsNaN(bounds.max)) {
        max = jsMax(max, jsToNumber(bounds.max));
      }
    }

    // If we have user provided `min` and `max` labels / data bounds can be
    // ignored
    if (!minDefined || !maxDefined) {
      // Labels are always considered, when user did not force bounds
      applyBounds(_getLabelBounds());

      // If `bounds` is `'ticks'` and `ticks.source` is `'labels'`,
      // data bounds are ignored (and don't need to be determined)
      if (options['bounds'] != 'ticks' ||
          jsGet(options['ticks'], 'source') != 'labels') {
        applyBounds(getMinMax(false));
      }
    }

    min = isFinite(min) && !jsIsNaN(min)
        ? min
        : jsToNumber(adapter.startOf(jsDateNow(), unit));
    max = isFinite(max) && !jsIsNaN(max)
        ? max
        : jsToNumber(adapter.endOf(jsDateNow(), unit)) + 1;

    // Make sure that max is strictly higher than min (required by the
    // timeseries lookup table)
    this.min = jsMin(min, max - 1);
    this.max = jsMax(min + 1, max);
  }

  /// scale.time.js:353 `_getLabelBounds()`.
  ///
  /// The first and the last label timestamp. Dart `null` stands for a JS
  /// `null` timestamp.
  ({double? min, double? max}) _getLabelBounds() {
    final arr = getLabelTimestamps();
    double? min = double.infinity;
    double? max = double.negativeInfinity;

    if (arr.isNotEmpty) {
      min = arr[0];
      max = arr[arr.length - 1];
    }
    return (min: min, max: max);
  }

  /// scale.time.js:368 `buildTicks()`.
  ///
  /// It also sets [unit], `_majorUnit` and [offsets]. With `reverse`, it
  /// reverses the List of the timestamps in place, as upstream: that List
  /// can be the List of the label timestamps.
  @override
  List<Tick> buildTicks() {
    final options = this.options;
    final timeOpts = options['time'];
    final tickOpts = options['ticks'];
    final timestamps = jsGet(tickOpts, 'source') == 'labels'
        ? getLabelTimestamps()
        : generate();

    if (options['bounds'] == 'ticks' && timestamps.isNotEmpty) {
      // DIVERGES(chartjs): adapt-time-null-timestamp, a null bound is 0.
      this.min = jsToNumber(jsTruthy(userMin) ? userMin : timestamps[0]);
      this.max = jsToNumber(
        jsTruthy(userMax) ? userMax : timestamps[timestamps.length - 1],
      );
    }

    final min = this.min;
    final max = this.max;

    final ticks = _filterBetween(timestamps, min, max);

    // PRIVATE
    // determineUnitForFormatting relies on the number of ticks so we don't
    // use it when autoSkip is enabled because we don't yet know what the
    // final number of ticks will be
    final timeUnit = jsGet(timeOpts, 'unit');
    unit = jsTruthy(timeUnit)
        ? timeUnit
        : (jsTruthy(jsGet(tickOpts, 'autoSkip'))
              ? _determineUnitForAutoTicks(
                  jsGet(timeOpts, 'minUnit'),
                  this.min,
                  this.max,
                  _getLabelCapacity(min),
                )
              : _determineUnitForFormatting(
                  this,
                  ticks.length,
                  jsGet(timeOpts, 'minUnit'),
                  this.min,
                  this.max,
                ));
    _majorUnit =
        !jsTruthy(jsGet(jsGet(tickOpts, 'major'), 'enabled')) || unit == 'year'
        ? null
        : _determineMajorUnit(unit);
    initOffsets(timestamps);

    if (jsTruthy(options['reverse'])) {
      _reverse(ticks);
    }

    return _ticksFromTimestamps(this, ticks, _majorUnit);
  }

  /// scale.time.js:401 `afterAutoSkip()`.
  ///
  /// `+tick.value` is [jsToNumber] of [_tickValue]: a `null` tick value
  /// gives 0.
  @override
  void afterAutoSkip() {
    // Offsets for bar charts need to be handled with the auto skipped
    // ticks. Once ticks have been skipped, we re-compute the offsets.
    if (jsTruthy(options['offsetAfterAutoskip'])) {
      initOffsets([for (final tick in ticks!) jsToNumber(_tickValue(tick))]);
    }
  }

  /// scale.time.js:417 `initOffsets(timestamps = [])`.
  ///
  /// Returns the start and end offsets from edges in the form of {start,
  /// end} where each value is a relative width to the scale and ranges
  /// between 0 and 1. They add extra margins on the both sides by scaling
  /// down the original scale. Offsets are added when the `offset` option is
  /// true.
  ///
  /// It sets [offsets]. A Dart `null` timestamp (JS `null`) gives NaN in
  /// [getDecimalForValue], as upstream.
  @protected
  void initOffsets([List<double?> timestamps = const []]) {
    var start = 0.0;
    var end = 0.0;
    double first;
    double last;

    if (jsTruthy(options['offset']) && timestamps.isNotEmpty) {
      first = getDecimalForValue(timestamps[0]);
      if (timestamps.length == 1) {
        start = 1 - first;
      } else {
        start = (getDecimalForValue(timestamps[1]) - first) / 2;
      }
      last = getDecimalForValue(timestamps[timestamps.length - 1]);
      if (timestamps.length == 1) {
        end = last;
      } else {
        end =
            (last - getDecimalForValue(timestamps[timestamps.length - 2])) / 2;
      }
    }
    final limit = timestamps.length < 3 ? 0.5 : 0.25;
    start = limitValue(start, 0, limit);
    end = limitValue(end, 0, limit);

    offsets = (start: start, end: end, factor: 1 / (start + 1 + end));
  }

  /// scale.time.js:450 `_generate()`. scale.timeseries.js:119 overrides it.
  ///
  /// Generates a maximum of `capacity` timestamps between min and max,
  /// rounded to the `minor` unit using the given scale time `options`.
  /// Important: this method can return ticks outside the min and max range,
  /// it's the responsibility of the calling code to clamp values if needed.
  ///
  /// Upstream keeps the times as the keys `ToString(time)` of an object,
  /// then sorts the keys with `sorter` and converts them back with `+x`.
  /// Two times have the same key exactly when they are equal numbers. Thus
  /// a Map of the times keeps the same times, and [jsSort] with the same
  /// comparator gives the same order. `+x` of the key `'0'` of -0 gives 0:
  /// the result gives 0 for a zero time too. The order of the keys before
  /// the sort can differ only for an index key (a time from 0 to 2^32 - 2
  /// ms). It changes the result only together with a NaN time, which
  /// compares equal to each number.
  ///
  /// The loop throws a [StateError] when a step does not advance (row
  /// `adapt-time-generate-no-advance`).
  @internal
  @protected
  List<double> generate() {
    final adapter = this.adapter;
    final min = this.min;
    final max = this.max;
    final options = this.options;
    final timeOpts = options['time'];
    final timeUnit = jsGet(timeOpts, 'unit');
    // @ts-ignore
    final minor = jsTruthy(timeUnit)
        ? timeUnit
        : _determineUnitForAutoTicks(
            jsGet(timeOpts, 'minUnit'),
            min,
            max,
            _getLabelCapacity(min),
          );
    final stepSize = valueOrDefault<Object?>(
      jsGet(options['ticks'], 'stepSize'),
      1.0,
    );
    final weekday = minor == 'week' ? jsGet(timeOpts, 'isoWeekday') : false;
    final hasWeekday = isNumber(weekday) || weekday == true;
    final ticks = <double, bool>{};
    var first = min;
    double time;
    var count = 0;

    // For 'week' unit, handle the first day of week option
    if (hasWeekday) {
      first = jsToNumber(adapter.startOf(first, 'isoWeek', weekday));
    }

    // Align first ticks on unit
    first = jsToNumber(adapter.startOf(first, hasWeekday ? 'day' : minor));

    // Prevent browser from freezing in case user options request millions
    // of milliseconds
    if (jsToNumber(adapter.diff(max, min, minor)) >
        100000 * jsToNumber(stepSize)) {
      throw StateError(
        '${jsNumberToString(min)} and ${jsNumberToString(max)} are too far '
        'apart with stepSize of ${jsToString(stepSize)} ${jsToString(minor)}',
      );
    }

    final timestamps = jsGet(options['ticks'], 'source') == 'data'
        ? getDataTimestamps()
        : null;
    for (time = first; time < max; count++) {
      _addTick(ticks, time, timestamps);
      final next = jsToNumber(adapter.add(time, stepSize, minor));
      // DIVERGES(chartjs): adapt-time-generate-no-advance, a stuck step.
      if (next <= time) {
        throw StateError(
          '${jsNumberToString(min)} and ${jsNumberToString(max)}: the step '
          'of ${jsToString(stepSize)} ${jsToString(minor)} does not advance',
        );
      }
      time = next;
    }

    if (time == max || options['bounds'] == 'ticks' || count == 1) {
      _addTick(ticks, time, timestamps);
    }

    // @ts-ignore
    return [
      for (final x in jsSort(ticks.keys.toList(), _sorter))
        if (x == 0) 0.0 else x,
    ];
  }

  /// scale.time.js:495 `getLabelForValue(value)`.
  ///
  /// The text of `time.tooltipFormat`, or of the `datetime` display format.
  @override
  Object? getLabelForValue(Object? value) {
    final adapter = this.adapter;
    final timeOpts = options['time'];
    final tooltipFormat = jsGet(timeOpts, 'tooltipFormat');

    if (jsTruthy(tooltipFormat)) {
      return adapter.format(value, tooltipFormat);
    }
    return adapter.format(
      value,
      jsGet(jsGet(timeOpts, 'displayFormats'), 'datetime'),
    );
  }

  /// scale.time.js:510 `format(value, format)`.
  ///
  /// The text of [value] in [format], or in the display format of [unit].
  /// Dart `null` for [format] stands for JS `undefined`.
  Object? format(Object? value, [Object? format]) {
    final options = this.options;
    final formats = jsGet(options['time'], 'displayFormats');
    final unit = this.unit;
    final fmt = jsTruthy(format) ? format : jsGet(formats, unit);
    return adapter.format(value, fmt);
  }

  /// scale.time.js:527 `_tickFormatFunction(time, index, ticks, format)`.
  ///
  /// Function to format an individual tick mark
  ///
  /// The tick `callback` gets the time, the index as a number and the
  /// ticks, with the scale as `this`. Dart `null` for [time] is the JS
  /// `null` value of a tick ([_tickValue]). Dart `null` for [format] stands
  /// for JS `undefined`.
  Object? _tickFormatFunction(
    double? time,
    int index,
    List<Tick> ticks, [
    Object? format,
  ]) {
    final options = this.options;
    final formatter = jsGet(options['ticks'], 'callback');

    if (jsTruthy(formatter)) {
      return callback(formatter, [time, index.toDouble(), ticks], this);
    }

    final formats = jsGet(options['time'], 'displayFormats');
    final unit = this.unit;
    final majorUnit = _majorUnit;
    final minorFormat = jsTruthy(unit) ? jsGet(formats, unit) : unit;
    final majorFormat = jsTruthy(majorUnit)
        ? jsGet(formats, majorUnit)
        : majorUnit;
    final tick = index >= 0 && index < ticks.length ? ticks[index] : null;
    final major =
        jsTruthy(majorUnit) &&
        jsTruthy(majorFormat) &&
        tick != null &&
        jsTruthy(tick.major);

    return adapter.format(
      time,
      jsTruthy(format) ? format : (major ? majorFormat : minorFormat),
    );
  }

  /// scale.time.js:549 `generateTickLabels(ticks)`.
  ///
  /// `tick.value` is [_tickValue]: the callback and the adapter get `null`
  /// for a `null` tick value, as upstream.
  @override
  void generateTickLabels(List<Tick> ticks) {
    for (var i = 0, ilen = ticks.length; i < ilen; ++i) {
      final tick = ticks[i];
      tick.label = _tickFormatFunction(_tickValue(tick), i, ticks);
    }
  }

  /// scale.time.js:562 `getDecimalForValue(value)`.
  ///
  /// [value] - Milliseconds since epoch (1 January 1970 00:00:00 UTC)
  ///
  /// [value] is any JS value (Chart.js ADR 0025). `null` gives NaN. The `-`
  /// operator applies `ToNumber` to another value.
  double getDecimalForValue(Object? value) {
    if (value is double) {
      // Port-only fast path for a number (Chart.js ADR 0025, section 3).
      return (value - min) / (max - min);
    }
    return value == null ? double.nan : (jsToNumber(value) - min) / (max - min);
  }

  /// scale.time.js:570 `getPixelForValue(value)`.
  ///
  /// [value] - Milliseconds since epoch (1 January 1970 00:00:00 UTC)
  ///
  /// [value] is any JS value (Chart.js ADR 0025). The method gives it
  /// unchanged to [getDecimalForValue].
  @override
  double getPixelForValue(Object? value, [double? index]) {
    final offsets = this.offsets;
    final pos = getDecimalForValue(value);
    return getPixelForDecimal((offsets.start + pos) * offsets.factor);
  }

  /// scale.time.js:580 `getValueForPixel(pixel)`.
  @override
  double getValueForPixel(double pixel) {
    final offsets = this.offsets;
    final pos = getDecimalForPixel(pixel) / offsets.factor - offsets.end;
    return min + pos * (max - min);
  }

  /// core.scale.js:906 `getPixelForTick(index)`, for the ticks of this
  /// library. Upstream has no override.
  ///
  /// `ticks[index].value` is [_tickValue]: [getPixelForValue] gets `null`
  /// for a `null` tick value, as upstream. The time scale gives NaN for it,
  /// and the timeseries scale reads it as 0 (row
  /// `adapt-time-null-timestamp`). Dart `null` stands for the JS `null` of
  /// an index out of the range.
  @override
  double? getPixelForTick(int index) {
    final ticks = this.ticks!;
    if (index < 0 || index > ticks.length - 1) {
      return null;
    }
    // DIVERGES(chartjs): adapt-time-null-timestamp, the null tick value.
    return getPixelForValue(_tickValue(ticks[index]));
  }

  /// scale.time.js:591 `_getLabelSize(label)`.
  ///
  /// The canvas measures the `ToString` of [label] in its current font, as
  /// upstream: the scale sets no font before the measure.
  ({double w, double h}) _getLabelSize(Object? label) {
    final ticksOpts = options['ticks'];
    final tickLabelWidth = ctx!.measureText(jsToString(label)).width;
    final angle = toRadians(
      jsToNumber(
        isHorizontal()
            ? jsGet(ticksOpts, 'maxRotation')
            : jsGet(ticksOpts, 'minRotation'),
      ),
    );
    final cosRotation = jsCos(angle);
    final sinRotation = jsSin(angle);
    final tickFontSize = resolveTickFontOptions(0).size ?? double.nan;

    return (
      w: (tickLabelWidth * cosRotation) + (tickFontSize * sinRotation),
      h: (tickLabelWidth * sinRotation) + (tickFontSize * cosRotation),
    );
  }

  /// scale.time.js:610 `_getLabelCapacity(exampleTime)`.
  ///
  /// The number of labels of the format of `time.unit` (or of the
  /// `millisecond` format) that the axis can hold, at least 1.
  double _getLabelCapacity(double exampleTime) {
    final timeOpts = options['time'];
    final displayFormats = jsGet(timeOpts, 'displayFormats');

    // pick the longest format (milliseconds) for guesstimation
    final unitFormat = jsGet(displayFormats, jsGet(timeOpts, 'unit'));
    final format = jsTruthy(unitFormat)
        ? unitFormat
        : jsGet(displayFormats, 'millisecond');
    final exampleLabel = _tickFormatFunction(
      exampleTime,
      0,
      _ticksFromTimestamps(this, [exampleTime], _majorUnit),
      format,
    );
    final size = _getLabelSize(exampleLabel);
    // subtract 1 - if offset then there's one less label than tick
    // if not offset then one half label padding is added to each end leaving
    // room for one less label
    final capacity =
        (isHorizontal() ? width / size.w : height / size.h).floorToDouble() - 1;
    return capacity > 0 ? capacity : 1;
  }

  /// scale.time.js:627 `getDataTimestamps()`.
  ///
  /// The parsed values of the visible datasets of the scale, sorted and
  /// unique, or the values of the first dataset with the `normalized`
  /// option. The result is the List of the cache: the timeseries scale
  /// changes it in place (scale.timeseries.js:119-130).
  @protected
  List<double> getDataTimestamps() {
    var timestamps = cache['data'] as List<double>? ?? <double>[];

    if (timestamps.isNotEmpty) {
      return timestamps;
    }

    final metas = getMatchingVisibleMetas();

    if (_normalized && metas.isNotEmpty) {
      return cache['data'] = metas[0].controller!.getAllParsedValues(this);
    }

    for (var i = 0, ilen = metas.length; i < ilen; ++i) {
      timestamps = [
        ...timestamps,
        ...metas[i].controller!.getAllParsedValues(this),
      ];
    }

    return cache['data'] = normalize(timestamps);
  }

  /// scale.time.js:651 `getLabelTimestamps()`.
  ///
  /// The timestamps of the labels, sorted and unique unless the chart has
  /// the `normalized` option. Dart `null` stands for the JS `null` of a
  /// label that the adapter cannot parse.
  @protected
  List<double?> getLabelTimestamps() {
    final timestamps = cache['labels'] as List<double?>? ?? <double?>[];

    if (timestamps.isNotEmpty) {
      return timestamps;
    }

    final labels = getLabels();
    for (var i = 0, ilen = labels.length; i < ilen; ++i) {
      timestamps.add(_parse(this, labels[i]));
    }

    return cache['labels'] = _normalized ? timestamps : normalize(timestamps);
  }

  /// scale.time.js:671 `normalize(values)`.
  ///
  /// It sorts [values] in place, then removes the repeated values. The
  /// result is [values] itself when no value repeats.
  @protected
  List<T> normalize<T extends double?>(List<T> values) {
    // It seems to be somewhat faster to do sorting first
    return arrayUnique(jsSort(values, _sorter));
  }
}
