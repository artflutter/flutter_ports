// Ported from Chart.js v4.6.1 src/scales/scale.logarithmic.js (MIT, Chart.js Contributors).

/// Port of `src/scales/scale.logarithmic.js`.
///
/// [LogarithmicScale] maps the values on a base-10 logarithmic axis.
/// `generateTicks` (scale.logarithmic.js:42-71) starts with the step 10^exp
/// of `startExp`. That exponent can be smaller than the exponent of the
/// minimum, which gives more steps near the start of the range. The
/// significand of a tick goes up by 1 to 10, and then to 15. At 20, the step
/// becomes ten times larger and the significand starts again at 2. Thus the
/// ticks from a minimum of 1 are 1, 2, ..., 9, 10, 15, 20, 30, ..., 90, 100,
/// 150, 200, ...: each power of ten after the first also has a tick at 1.5
/// times that power. A tick at a power of ten is a major tick.
///
/// - Options are the typed resolver views of `helpers.config` (Chart.js ADR
///   0054 §4), through the facade [LogarithmicScaleOptions]. The scale reads
///   an option with a getter of the facade (`options.ticks.format`), and tests
///   it with [jsTruthy].
/// - Numbers are `double` (Chart.js ADR 0146). A property that starts JS
///   `undefined` and holds a number starts as NaN. `log10` of helpers.math
///   gives the exponent of an exact power of ten (Chart.js ADR 0146 §3).
///   `Math.pow` is `dart:math` `pow` with `double` operands.
/// - [LogarithmicScale.parse] gives NaN for a 0, where upstream gives
///   `undefined`, and JS `null` (Dart `null`) for a value that is not a
///   positive finite number (scale.logarithmic.js:103-110). NaN is not
///   finite and compares false, as `undefined`, and the value methods read it
///   as 0 (row `adapt-native-scale-values`).
/// - `determineDataLimits` can store JS `null` in `this.min` and `this.max`
///   (scale.logarithmic.js:115-116), and `handleTickRangeOptions` reads that
///   `null` (:133-134). [Scale.min] and [Scale.max] are `double` fields.
///   Between the two methods, NaN in them stands for that JS `null`:
///   upstream stores no NaN there. `handleTickRangeOptions` reads NaN as
///   Dart `null` and applies `ToNumber` to it ([jsToNumber]) where
///   JavaScript does: in `<=` and in `log10`.
/// - The value methods take a `double` (row `adapt-native-scale-values`).
/// - The upstream `_` members that only this file reads keep the
///   underscore (Chart.js ADR 0012, Chart.js ADR 0025, section 6):
///   `_startValue`, `_valueRange` and `_zero`.
/// - `scale.logarithmic.js:104` calls the parse of `LinearScaleBase` with
///   `LinearScaleBase.prototype.parse.apply(this, [raw, index])`. This scale
///   does not extend `LinearScaleBase`. Thus it calls the static
///   [LinearScaleBase.prototypeParse], the body of that parse.
///
/// `core.scale.dart` imports `helpers.extras`, which is not a pure layer.
/// Thus this library is not a pure layer.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

import 'package:meta/meta.dart';

/// scale.logarithmic.js:8 `log10Floor`.
double _log10Floor(double v) => log10(v).floorToDouble();

/// scale.logarithmic.js:9 `changeExponent`.
///
/// Dart `null` for [v] is the JS `null` of `this.min` or `this.max`
/// (scale.logarithmic.js:115-116). `log10` applies `ToNumber` to it
/// ([jsToNumber]): `log10(0)` is -Infinity, and the result is 0.
double _changeExponent(double? v, double m) =>
    math.pow(10.0, _log10Floor(jsToNumber(v)) + m).toDouble();

/// scale.logarithmic.js:11 `isMajor`.
bool _isMajor(double tickVal) {
  final remain = tickVal / (math.pow(10.0, _log10Floor(tickVal)));
  return remain == 1;
}

/// scale.logarithmic.js:16 `steps`.
double _steps(double min, double max, double rangeExp) {
  final rangeStep = math.pow(10.0, rangeExp).toDouble();
  final start = (min / rangeStep).floorToDouble();
  final end = (max / rangeStep).ceilToDouble();
  return end - start;
}

/// scale.logarithmic.js:23 `startExp`.
double _startExp(double min, double max) {
  final range = max - min;
  var rangeExp = _log10Floor(range);
  while (_steps(min, max, rangeExp) > 10) {
    rangeExp++;
  }
  while (_steps(min, max, rangeExp) < 10) {
    rangeExp--;
  }
  return math.min(rangeExp, _log10Floor(min));
}

/// The object `generationOptions` of [_generateTicks]
/// (scale.logarithmic.js:163-166): `_userMin` and `_userMax`, the results of
/// [LogarithmicScale.parse] for the `min` and `max` options. Each one is a
/// number, Dart `null` (JS `null`) or NaN (JS `undefined`).
typedef _GenerationOptions = ({double? min, double? max});

/// scale.logarithmic.js:42 `generateTicks(generationOptions, {min, max})`.
///
/// Generate a set of logarithmic ticks
/// @param generationOptions the options used to generate the ticks
/// @param dataRange the range of the data
/// @returns {object[]} array of tick objects
///
/// The data range is the scale: upstream passes `this`
/// (scale.logarithmic.js:167). [MinMax] gives its `min` and `max`.
List<Tick> _generateTicks(
  _GenerationOptions generationOptions,
  MinMax dataRange,
) {
  final max = dataRange.max;
  final min = finiteOrDefault(generationOptions.min, dataRange.min);
  final ticks = <Tick>[];
  final minExp = _log10Floor(min);
  var exp = _startExp(min, max);
  var precision = exp < 0 ? math.pow(10.0, exp.abs()).toDouble() : 1.0;
  final stepSize = math.pow(10.0, exp).toDouble();
  final base = minExp > exp ? math.pow(10.0, minExp).toDouble() : 0.0;
  final start = ((min - base) * precision).roundToDouble() / precision;
  final offset = ((min - base) / stepSize / 10).floorToDouble() * stepSize * 10;
  var significand = ((start - offset) / math.pow(10.0, exp)).floorToDouble();
  var value = finiteOrDefault(
    generationOptions.min,
    ((base + offset + significand * math.pow(10.0, exp)) * precision)
            .roundToDouble() /
        precision,
  );
  while (value < max) {
    ticks.add(
      Tick(value: value, major: _isMajor(value), significand: significand),
    );
    if (significand >= 10) {
      significand = significand < 15 ? 15 : 20;
    } else {
      significand++;
    }
    if (significand >= 20) {
      exp++;
      significand = 2;
      precision = exp >= 0 ? 1 : precision;
    }
    value =
        ((base + offset + significand * math.pow(10.0, exp)) * precision)
            .roundToDouble() /
        precision;
  }
  final lastTick = finiteOrDefault(generationOptions.max, value);
  ticks.add(
    Tick(value: lastTick, major: _isMajor(lastTick), significand: significand),
  );

  return ticks;
}

/// The JS value of [Scale.min] or [Scale.max] in `determineDataLimits` and
/// `handleTickRangeOptions`: Dart `null` (JS `null`) for NaN
/// (scale.logarithmic.js:115-116).
double? _nullForNaN(double value) => value.isNaN ? null : value;

/// scale.logarithmic.js:74 `LogarithmicScale`.
class LogarithmicScale(super.cfg) extends Scale implements NullValueScale {
  /// scale.logarithmic.js:91 `constructor(cfg)`.
  ///
  /// `cfg` is the object `{id, type, ctx, chart}` of [Scale.new]. The
  /// fields `start`, `end`, `_startValue` and `_valueRange` get their start
  /// values in their declarations (scale.logarithmic.js:94-100).
  this;

  // scale.logarithmic.js:76 `static id = 'logarithmic'`. Scale has the
  // instance field `id`. Thus the value is only in [component].

  /// scale.logarithmic.js:81 `static defaults`.
  ///
  /// The tick callback is `Ticks.formatters.logarithmic` (core.ticks.js:71),
  /// a function that reads `this`. A Dart `static final` gets its value at
  /// the first read, not at the load of the library. Thus the callback is
  /// the value of `formatters['logarithmic']` at the first read of
  /// [defaults]. The object is a typed scope of the kind `ScaleOptions`
  /// (Chart.js ADR 0054 §3).
  static final ScaleOptionsScope defaults = ScaleOptionsScope()
    ..ticks = (TickOptionsScope()
      ..callback = formatters['logarithmic']!
      ..major = (MajorTickOptionsScope()..enabled = true));

  /// The class as a typed component (Chart.js ADR 0204): the statics
  /// `id`, `defaults`, and the constructor.
  static final ScaleType component = ScaleType(
    id: 'logarithmic',
    defaults: defaults,
    create: LogarithmicScale.new,
  );

  /// The options of the scale: the logarithmic scale options (index.d.ts:3405).
  @override
  LogarithmicScaleOptions get options =>
      super.options as LogarithmicScaleOptions;

  /// The logarithmic scale options of the view [view].
  @override
  @protected
  LogarithmicScaleOptions createOptions(OptionView view) =>
      LogarithmicScaleOptions(view);

  /// scale.logarithmic.js:95 `start`, the value at the start of the axis.
  /// NaN stands for JS `undefined`, the start value. [buildTicks] sets it.
  double start = double.nan;

  /// scale.logarithmic.js:97 `end`, the value at the end of the axis. NaN
  /// stands for JS `undefined`. [buildTicks] sets it.
  double end = double.nan;

  /// scale.logarithmic.js:99 `_startValue`, the `log10` of the value at the
  /// start of the range. NaN stands for JS `undefined`. [configure] sets it.
  double _startValue = double.nan;

  /// scale.logarithmic.js:100 `_valueRange`, the length of the range in
  /// `log10` units. [configure] sets it.
  double _valueRange = 0;

  /// `_zero`, whether [parse] got a 0 or the `beginAtZero` option is set
  /// (scale.logarithmic.js:106, :119). The constructor does not declare it,
  /// and the readers test its truthiness: false stands for the start value
  /// `undefined`. No method resets it.
  bool _zero = false;

  /// The number of a JS `null` value: `-Infinity`, which has no logarithm,
  /// so [getPixelForValue] gives NaN, as upstream gives for `null`. NaN is
  /// the parse of a 0 (row `adapt-native-scale-values`).
  @override
  double get nullValue => double.negativeInfinity;

  /// A value with no number gives `-Infinity`, as [nullValue]: upstream gives
  /// NaN for it, and NaN is the parse of a 0 here.
  @override
  double get nanValue => double.negativeInfinity;

  /// scale.logarithmic.js:103 `parse(raw, index)`.
  ///
  /// The parse of `LinearScaleBase` gives a number or JS `null`
  /// ([LinearScaleBase.prototypeParse]). A 0 sets `_zero` and gives NaN,
  /// where upstream gives `undefined` (row
  /// `adapt-native-scale-values`). A positive finite number gives that
  /// number. Another value gives Dart `null` (JS `null`).
  @override
  double? parse(Object? raw, [int? index]) {
    final value = LinearScaleBase.prototypeParse(raw, index);
    if (value == 0) {
      _zero = true;
      // DIVERGES(chartjs): adapt-native-scale-values, NaN for undefined.
      return double.nan;
    }
    return value != null && value.isFinite && value > 0 ? value : null;
  }

  /// scale.logarithmic.js:112 `determineDataLimits()`.
  ///
  /// NaN in [min] and [max] stands for the JS `null` of
  /// scale.logarithmic.js:115-116 until [handleTickRangeOptions] ends.
  /// `this.min !== this._suggestedMin` compares the JS values: Dart `null`
  /// for that `null`, and the parse result in [Scale.suggestedMin].
  @override
  void determineDataLimits() {
    final (:min, :max) = getMinMax(true);

    this.min = isFinite(min) ? math.max(0, min) : double.nan;
    this.max = isFinite(max) ? math.max(0, max) : double.nan;

    if (options.beginAtZero) {
      _zero = true;
    }

    // if data has `0` in it or `beginAtZero` is true, min (non zero) value is
    // at bottom of scale, and it does not equal suggestedMin, lower the min
    // bound by one exp.
    final thisMin = _nullForNaN(this.min);
    if (_zero && thisMin != suggestedMin && !isFinite(userMin)) {
      this.min = min == _changeExponent(thisMin, 0)
          ? _changeExponent(thisMin, -1)
          : _changeExponent(thisMin, 0);
    }

    handleTickRangeOptions();
  }

  /// scale.logarithmic.js:131 `handleTickRangeOptions()`.
  ///
  /// The locals `min` and `max` hold the JS values of [min] and [max]:
  /// Dart `null` for the JS `null` of [determineDataLimits]. `null === null`
  /// is `==`, and `null <= 0` applies `ToNumber` ([jsToNumber]). At the end
  /// both are numbers.
  void handleTickRangeOptions() {
    final (:minDefined, :maxDefined, min: _, max: _) = getUserBounds();
    var min = _nullForNaN(this.min);
    var max = _nullForNaN(this.max);

    void setMin(double v) => min = minDefined ? min : v;
    void setMax(double v) => max = maxDefined ? max : v;

    if (min == max) {
      if (jsToNumber(min) <= 0) {
        // includes null
        setMin(1);
        setMax(10);
      } else {
        setMin(_changeExponent(min, -1));
        setMax(_changeExponent(max, 1));
      }
    }
    if (jsToNumber(min) <= 0) {
      setMin(_changeExponent(max, -1));
    }
    if (jsToNumber(max) <= 0) {
      setMax(_changeExponent(min, 1));
    }

    this.min = min ?? double.nan;
    this.max = max ?? double.nan;
  }

  /// scale.logarithmic.js:160 `buildTicks()`.
  @override
  List<Tick> buildTicks() {
    final opts = options;

    final generationOptions = (min: userMin, max: userMax);
    final ticks = _generateTicks(generationOptions, this);

    // At this point, we need to update our max and min given the tick values,
    // since we probably have expanded the range of the scale
    // DIVERGES(chartjs): adapt-scale-option-enums, the enum value.
    if (opts.bounds == ScaleBounds.ticks) {
      setMinAndMaxByKey(ticks, this, 'value');
    }

    if (opts.reverse) {
      // `Array.prototype.reverse` reverses the list in place.
      ticks.setAll(0, ticks.reversed.toList());

      start = max;
      end = min;
    } else {
      start = min;
      end = max;
    }

    return ticks;
  }

  /// scale.logarithmic.js:192 `getLabelForValue(value)`.
  ///
  /// @param {number} value
  /// @return {string}
  ///
  /// NaN, the parse of a 0, gives `'0'`, as the `undefined` of upstream.
  /// The `ticks.format` option is a `NumberFormat` of package:intl, which
  /// formats the value as it is (Chart.js ADR 0119).
  @override
  String getLabelForValue(double value) {
    // DIVERGES(chartjs): adapt-native-scale-values, NaN for undefined.
    if (value.isNaN) {
      return '0';
    }
    return formatNumber(
      value,
      localeOf(readOption(chart.options, OptionKey.locale)),
      options.ticks.format,
    );
  }

  /// scale.logarithmic.js:201 `configure()`.
  ///
  /// @protected
  @override
  @protected
  void configure() {
    final start = min;

    super.configure();

    _startValue = log10(start);
    _valueRange = log10(max) - log10(start);
  }

  /// scale.logarithmic.js:210 `getPixelForValue(value)`.
  ///
  /// NaN (the parse of a 0, the `undefined` of upstream) and 0 give the
  /// pixel of [min]. A JS `null` value comes as [nullValue] and gives NaN.
  @override
  double getPixelForValue(double value, [int? index]) {
    // DIVERGES(chartjs): adapt-native-scale-values, NaN for undefined.
    if (value.isNaN || value == 0) {
      // Upstream reassigns its parameter.
      // ignore: parameter_assignments
      value = min;
    }
    return getPixelForDecimal(
      value == min ? 0 : (log10(value) - _startValue) / _valueRange,
    );
  }

  /// core.scale.js:906 `getPixelForTick(index)`, for the ticks of this
  /// scale. Upstream has no override.
  ///
  /// A NaN tick value (the ticks of a scale with no data) gives NaN, as
  /// upstream: a tick value is never the NaN of the parse of a 0, which
  /// [getPixelForValue] reads as 0 (row `adapt-native-scale-values`). Dart
  /// `null` stands for the JS `null` of an index out of the range.
  @override
  double? getPixelForTick(int index) {
    final ticks = this.ticks!;
    if (index < 0 || index > ticks.length - 1) {
      return null;
    }
    final value = ticks[index].value;
    // DIVERGES(chartjs): adapt-native-scale-values, NaN is not the parse of 0.
    return value.isNaN ? double.nan : getPixelForValue(value);
  }

  /// scale.logarithmic.js:222 `getValueForPixel(pixel)`.
  @override
  double getValueForPixel(double pixel) {
    final decimal = getDecimalForPixel(pixel);
    return math.pow(10.0, _startValue + decimal * _valueRange).toDouble();
  }
}
