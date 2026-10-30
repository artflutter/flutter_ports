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
/// - Numbers are `double` (Chart.js ADR 0045). A property that starts JS
///   `undefined` and holds a number starts as NaN. `log10` is the fdlibm
///   port of helpers.math, which gives the bits of V8. `Math.pow` is
///   `dart:math` `pow` with `double` operands.
/// - [LogarithmicScale.parse] gives the [undefined] sentinel for a 0, and
///   JS `null` (Dart `null`) for a value that is not a positive finite
///   number (scale.logarithmic.js:103-110).
/// - `determineDataLimits` can store JS `null` in `this.min` and `this.max`
///   (scale.logarithmic.js:115-116), and `handleTickRangeOptions` reads that
///   `null` (:133-134). [Scale.min] and [Scale.max] are `double` fields.
///   Between the two methods, NaN in them stands for that JS `null`:
///   upstream stores no NaN there. `handleTickRangeOptions` reads NaN as
///   Dart `null` and applies `ToNumber` to it ([jsToNumber]) where
///   JavaScript does: in `<=` and in `log10`.
/// - The value methods take any JS value (Chart.js ADR 0025).
///   [LogarithmicScale.getPixelForValue] starts with the port-only fast path
///   for a `double` of Chart.js ADR 0025, section 3.
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

import 'package:flutter_chartjs_port/src/core/core.scale.dart';
import 'package:flutter_chartjs_port/src/core/core.ticks.dart' show formatters;
import 'package:flutter_chartjs_port/src/core/scale_options.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show finiteOrDefault, isFinite;
import 'package:flutter_chartjs_port/src/helpers/helpers.intl.dart'
    show formatNumber;
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart'
    show MinMax, log10, setMinAndMaxByKey;
import 'package:flutter_chartjs_port/src/js/js_class.dart';
import 'package:flutter_chartjs_port/src/js/js_math.dart'
    show jsMax, jsMin, jsRound;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/options/scopes.g.dart'
    show MajorTickOptionsScope, ScaleOptionsScope, TickOptionsScope;
import 'package:flutter_chartjs_port/src/scales/scale.linearbase.dart'
    show LinearScaleBase;
import 'package:meta/meta.dart';

/// scale.logarithmic.js:8 `log10Floor`.
double _log10Floor(double v) => log10(v).floorToDouble();

/// scale.logarithmic.js:9 `changeExponent`.
///
/// Dart `null` for [v] is the JS `null` of `this.min` or `this.max`
/// (scale.logarithmic.js:115-116). `log10` applies `ToNumber` to it
/// ([jsToNumber]): `log10(0)` is -Infinity, and the result is 0.
double _changeExponent(double? v, double m) =>
    // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
    math.pow(10.0, _log10Floor(jsToNumber(v)) + m).toDouble();

/// scale.logarithmic.js:11 `isMajor`.
bool _isMajor(double tickVal) {
  // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
  final remain = tickVal / (math.pow(10.0, _log10Floor(tickVal)));
  return remain == 1;
}

/// scale.logarithmic.js:16 `steps`.
double _steps(double min, double max, double rangeExp) {
  // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
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
  return jsMin(rangeExp, _log10Floor(min));
}

/// The object `generationOptions` of [_generateTicks]
/// (scale.logarithmic.js:163-166): `_userMin` and `_userMax`, the results of
/// [LogarithmicScale.parse] for the `min` and `max` options. Each one is a
/// number, Dart `null` (JS `null`) or the [undefined] sentinel.
typedef _GenerationOptions = ({Object? min, Object? max});

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
  // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
  var precision = exp < 0 ? math.pow(10.0, exp.abs()).toDouble() : 1.0;
  // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
  final stepSize = math.pow(10.0, exp).toDouble();
  // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
  final base = minExp > exp ? math.pow(10.0, minExp).toDouble() : 0.0;
  final start = jsRound((min - base) * precision) / precision;
  final offset = ((min - base) / stepSize / 10).floorToDouble() * stepSize * 10;
  // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
  var significand = ((start - offset) / math.pow(10.0, exp)).floorToDouble();
  var value = finiteOrDefault(
    generationOptions.min,
    // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
    jsRound((base + offset + significand * math.pow(10.0, exp)) * precision) /
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
        jsRound(
          // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
          (base + offset + significand * math.pow(10.0, exp)) * precision,
        ) /
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
class LogarithmicScale extends Scale {
  /// scale.logarithmic.js:91 `constructor(cfg)`.
  ///
  /// [cfg] is the object `{id, type, ctx, chart}` of [Scale.new]. The
  /// fields `start`, `end`, `_startValue` and `_valueRange` get their start
  /// values in their declarations (scale.logarithmic.js:94-100).
  LogarithmicScale(super.cfg);

  // scale.logarithmic.js:76 `static id = 'logarithmic'`. Scale has the
  // instance field `id`. Thus the value is only in the statics of jsClass.

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

  /// scale.logarithmic.js:74 `class LogarithmicScale extends Scale` as a
  /// value (Chart.js ADR 0020, section 3).
  ///
  /// It extends [Scale.jsClass]. Its statics are `id` (`'logarithmic'`) and
  /// [defaults], in the upstream order of declaration
  /// (scale.logarithmic.js:76-88). Its `construct` calls
  /// `LogarithmicScale(cfg)` with the `cfg` of [scaleCfgArg].
  static final JsClass jsClass = JsClass(
    'LogarithmicScale',
    superclass: Scale.jsClass,
    statics: {'id': 'logarithmic', 'defaults': defaults},
    construct: (newTarget, args) => LogarithmicScale(scaleCfgArg(args)),
  );

  /// The options of the scale, through the facade of the logarithmic scale
  /// options (index.d.ts:3405).
  @override
  LogarithmicScaleOptions get options => LogarithmicScaleOptions(super.options);

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

  /// scale.logarithmic.js:103 `parse(raw, index)`.
  ///
  /// The parse of `LinearScaleBase` gives a number or JS `null`
  /// ([LinearScaleBase.prototypeParse]). A 0 sets `_zero` and gives the
  /// [undefined] sentinel. A positive finite number gives that number.
  /// Another value gives Dart `null` (JS `null`).
  @override
  Object? parse(Object? raw, [double? index]) {
    final value = LinearScaleBase.prototypeParse(raw, index);
    if (value == 0) {
      _zero = true;
      return undefined;
    }
    return isFinite(value) && (value! as num) > 0 ? value : null;
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

    this.min = isFinite(min) ? jsMax(0, min) : double.nan;
    this.max = isFinite(max) ? jsMax(0, max) : double.nan;

    if (jsTruthy(options.beginAtZero)) {
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
    if (opts.bounds == 'ticks') {
      setMinAndMaxByKey(ticks, this, 'value');
    }

    if (jsTruthy(opts.reverse)) {
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
  /// [value] is any JS value. [undefined], the parse of a 0, gives `'0'`.
  /// Upstream gives another value without a change to
  /// `Intl.NumberFormat.prototype.format`. `format` applies
  /// `ToIntlMathematicalValue`: `ToPrimitive`, and then `ToNumber`, but not
  /// to a String or a BigInt primitive. V8 keeps the exact decimal of such a
  /// primitive. The port applies [jsToNumber] to [value]. Thus a string whose
  /// decimal is not the shortest round-trip form of its double gets other
  /// digits. For example, `'9007199254740993'` gives `9,007,199,254,740,993`
  /// in V8 and `9,007,199,254,740,992` in the port. Only the digits of the
  /// label change (Chart.js ADR 0034). The `ticks.format` option is a Map of
  /// the number format options, or another value, which gives no options.
  @override
  Object? getLabelForValue(Object? value) {
    if (identical(value, undefined)) {
      return '0';
    }
    final format = options.ticks.format;
    return formatNumber(
      jsToNumber(value),
      readOption(chart.options, OptionKey.locale),
      format is Map<String, Object?> ? format : null,
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
  /// [value] is any JS value. `undefined` (the parse of a 0) and 0 give the
  /// pixel of [min]. `null` and NaN give NaN (Chart.js ADR 0025).
  @override
  double getPixelForValue(Object? value, [double? index]) {
    if (value is double) {
      // Port-only fast path for a number (Chart.js ADR 0025, section 3).
      final number = value == 0 ? min : value;
      if (number.isNaN) {
        return double.nan;
      }
      return getPixelForDecimal(
        number == min ? 0 : (log10(number) - _startValue) / _valueRange,
      );
    }
    if (identical(value, undefined) || value == 0) {
      // Upstream reassigns its parameter.
      // ignore: parameter_assignments
      value = min;
    }
    if (value == null || jsIsNaN(value)) {
      return double.nan;
    }
    return getPixelForDecimal(
      value == min ? 0 : (log10(jsToNumber(value)) - _startValue) / _valueRange,
    );
  }

  /// scale.logarithmic.js:222 `getValueForPixel(pixel)`.
  @override
  double getValueForPixel(double pixel) {
    final decimal = getDecimalForPixel(pixel);
    // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
    return math.pow(10.0, _startValue + decimal * _valueRange).toDouble();
  }
}
