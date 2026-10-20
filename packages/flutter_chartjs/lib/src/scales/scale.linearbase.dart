// Ported from Chart.js v4.5.1+7169e651 src/scales/scale.linearbase.js (MIT, Chart.js Contributors).

/// Port of `src/scales/scale.linearbase.js`.
///
/// [LinearScaleBase] is the base class of the linear scale and of the radial
/// linear scale. It parses numbers, applies the range options, makes the
/// numeric ticks and maps the value range. `scales/index.js` does not export
/// it, and it has no `id`. Thus the registry never registers it as a
/// component.
///
/// - Options are the resolvers of `helpers.config` (Chart.js ADR 0006). The
///   scale reads an option with `options[key]` or [jsGet], tests it with
///   [jsTruthy], and applies [jsToNumber] before arithmetic.
/// - Numbers are `double` (Chart.js ADR 0010). A property that starts JS
///   `undefined` and holds a number starts as NaN.
/// - The `_` members that other modules read drop the underscore and carry
///   `@internal` (Chart.js ADR 0012, Chart.js ADR 0025, section 6):
///   [LinearScaleBase.startValue], [LinearScaleBase.endValue] and
///   [LinearScaleBase.valueRange].
/// - `scale.logarithmic.js:104` calls the parse of this class with
///   `LinearScaleBase.prototype.parse.apply(this, [raw, index])`. The
///   logarithmic scale does not extend this class. Thus the body of
///   [LinearScaleBase.parse] is the static [LinearScaleBase.prototypeParse].
///
/// `core.scale` is not a pure layer. Thus this library is not a pure layer.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs/src/core/core.scale.dart';
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs/src/helpers/helpers.intl.dart'
    show formatNumber;
import 'package:flutter_chartjs/src/helpers/helpers.math.dart'
    show
        almostEquals,
        almostWhole,
        decimalPlaces,
        niceNum,
        setMinAndMaxByKey,
        sign,
        toRadians;
import 'package:flutter_chartjs/src/js/js_class.dart';
import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart' show jsGet;
import 'package:meta/meta.dart';

/// The object `generationOptions` of [_generateTicks]
/// (scale.linearbase.js:255-267).
///
/// `min`, `max`, `precision`, `step` and `count` are the raw option values.
/// [_generateTicks] tests them with `isNullOrUndef` and with `===`, as
/// upstream does.
typedef _GenerationOptions = ({
  double maxTicks,
  Object? bounds,
  Object? min,
  Object? max,
  Object? precision,
  Object? step,
  Object? count,
  double maxDigits,
  bool horizontal,
  double minRotation,
  bool includeBounds,
});

/// scale.linearbase.js:31 `MIN_SPACING`, a local of `generateTicks`.
///
/// The Dart-cased name collides with the local `minSpacing` of :39. Thus
/// the constant is a library constant.
const double _minSpacing = 1e-14;

/// scale.linearbase.js:25 `generateTicks(generationOptions, dataRange)`.
///
/// Generate a set of linear ticks for an axis
/// 1. If generationOptions.min, generationOptions.max, and
///    generationOptions.step are defined:
///    if (max - min) / step is an integer, ticks are generated as [min, min +
///    step, ..., max]
///    Note that the generationOptions.maxCount setting is respected in this
///    scenario
///
/// 2. If generationOptions.min, generationOptions.max, and
///    generationOptions.count is defined
///    spacing = (max - min) / count
///    Ticks are generated as [min, min + spacing, ..., max]
///
/// 3. If generationOptions.count is defined
///    spacing = (niceMax - niceMin) / count
///
/// 4. Compute optimal spacing of ticks using niceNum algorithm
///
/// @param generationOptions the options used to generate the ticks
/// @param dataRange the range of the data
/// @returns {object[]} array of tick objects
///
/// In the cases 1 and 2, upstream assigns the raw `min` and `max` options to
/// `niceMin` and `niceMax`. Thus the two locals are `Object?`, and the
/// arithmetic and the relational compares apply [jsToNumber], as the JS
/// operators apply `ToNumber`. A raw value that is not a number gives
/// `undefined` from `_decimalPlaces`, as upstream gives. The `!==` and `===`
/// compares with `min` and `max` compare the values as they are. After the
/// rounding (:105-106), both locals hold numbers.
List<Tick> _generateTicks(
  _GenerationOptions generationOptions,
  ({double min, double max}) dataRange,
) {
  final ticks = <Tick>[];
  // To get a "nice" value for the tick spacing, we will use the appropriately
  // named "nice number" algorithm. See
  // https://stackoverflow.com/questions/8506881/nice-label-algorithm-for-charts-with-minimum-ticks
  // for details.

  final (
    :bounds,
    :step,
    :min,
    :max,
    :precision,
    :count,
    :maxTicks,
    :maxDigits,
    :includeBounds,
    horizontal: _,
    minRotation: _,
  ) = generationOptions;
  final unit = jsTruthy(step) ? jsToNumber(step) : 1.0;
  final maxSpaces = maxTicks - 1;
  final (min: rmin, max: rmax) = dataRange;
  final minDefined = !isNullOrUndef(min);
  final maxDefined = !isNullOrUndef(max);
  final countDefined = !isNullOrUndef(count);
  final minSpacing = (rmax - rmin) / (maxDigits + 1);
  var spacing = niceNum((rmax - rmin) / maxSpaces / unit) * unit;
  double factor;
  double numSpaces;
  Object? niceMin;
  Object? niceMax;

  // Beyond MIN_SPACING floating point numbers being to lose precision
  // such that we can't do the math necessary to generate ticks
  if (spacing < _minSpacing && !minDefined && !maxDefined) {
    return [Tick(value: rmin), Tick(value: rmax)];
  }

  numSpaces =
      (rmax / spacing).ceilToDouble() - (rmin / spacing).floorToDouble();
  if (numSpaces > maxSpaces) {
    // If the calculated num of spaces exceeds maxNumSpaces, recalculate it
    spacing = niceNum(numSpaces * spacing / maxSpaces / unit) * unit;
  }

  if (!isNullOrUndef(precision)) {
    // If the user specified a precision, round to that number of decimal
    // places
    // js-ok: integer exponent, V8 bits for -340..320 (Chart.js ADR 0010).
    factor = math.pow(10.0, jsToNumber(precision)).toDouble();
    spacing = (spacing * factor).ceilToDouble() / factor;
  }

  if (bounds == 'ticks') {
    niceMin = (rmin / spacing).floorToDouble() * spacing;
    niceMax = (rmax / spacing).ceilToDouble() * spacing;
  } else {
    niceMin = rmin;
    niceMax = rmax;
  }

  if (minDefined &&
      maxDefined &&
      jsTruthy(step) &&
      almostWhole(
        (jsToNumber(max) - jsToNumber(min)) / jsToNumber(step),
        spacing / 1000,
      )) {
    // Case 1: If min, max and stepSize are set and they make an evenly spaced
    // scale use it.
    // spacing = step;
    // numSpaces = (max - min) / spacing;
    // Note that we round here to handle the case where almostWhole translated
    // an FP error
    numSpaces = jsRound(
      jsMin((jsToNumber(max) - jsToNumber(min)) / spacing, maxTicks),
    );
    spacing = (jsToNumber(max) - jsToNumber(min)) / numSpaces;
    niceMin = min;
    niceMax = max;
  } else if (countDefined) {
    // Cases 2 & 3, we have a count specified. Handle optional user defined
    // edges to the range.
    // Sometimes these are no-ops, but it makes the code a lot clearer
    // and when a user defined range is specified, we want the correct ticks
    niceMin = minDefined ? min : niceMin;
    niceMax = maxDefined ? max : niceMax;
    numSpaces = jsToNumber(count) - 1;
    spacing = (jsToNumber(niceMax) - jsToNumber(niceMin)) / numSpaces;
  } else {
    // Case 4
    numSpaces = (jsToNumber(niceMax) - jsToNumber(niceMin)) / spacing;

    // If very close to our rounded value, use it.
    if (almostEquals(numSpaces, jsRound(numSpaces), spacing / 1000)) {
      numSpaces = jsRound(numSpaces);
    } else {
      numSpaces = numSpaces.ceilToDouble();
    }
  }

  // The spacing will have changed in cases 1, 2, and 3 so the factor cannot
  // be computed until this point
  // The upstream name of the local is the name of the function
  // `decimalPlaces` of helpers.math. `Math.max(undefined, n)` is NaN.
  final decimalPlaces_ = jsMax(
    decimalPlaces(spacing) ?? double.nan,
    decimalPlaces(niceMin) ?? double.nan,
  );
  final exponent = isNullOrUndef(precision)
      ? decimalPlaces_
      : jsToNumber(precision);
  // js-ok: integer exponent, V8 bits for -340..320 (Chart.js ADR 0010).
  factor = math.pow(10.0, exponent).toDouble();
  niceMin = jsRound(jsToNumber(niceMin) * factor) / factor;
  niceMax = jsRound(jsToNumber(niceMax) * factor) / factor;

  var j = 0.0;
  if (minDefined) {
    if (includeBounds && niceMin != min) {
      // DIVERGES(chartjs): adapt-linearbase-tick-bounds, ToNumber of min.
      ticks.add(Tick(value: jsToNumber(min)));

      if (jsToNumber(niceMin) < jsToNumber(min)) {
        j++; // Skip niceMin
      }
      // If the next nice tick is close to min, skip it
      if (almostEquals(
        jsRound((jsToNumber(niceMin) + j * spacing) * factor) / factor,
        jsToNumber(min),
        _relativeLabelSize(min, minSpacing, generationOptions),
      )) {
        j++;
      }
    } else if (jsToNumber(niceMin) < jsToNumber(min)) {
      j++;
    }
  }

  for (; j < numSpaces; ++j) {
    final tickValue =
        jsRound((jsToNumber(niceMin) + j * spacing) * factor) / factor;
    if (maxDefined && tickValue > jsToNumber(max)) {
      break;
    }
    ticks.add(Tick(value: tickValue));
  }

  if (maxDefined && includeBounds && niceMax != max) {
    // If the previous tick is too close to max, replace it with max, else add
    // max
    if (ticks.isNotEmpty &&
        almostEquals(
          ticks[ticks.length - 1].value,
          jsToNumber(max),
          _relativeLabelSize(max, minSpacing, generationOptions),
        )) {
      // DIVERGES(chartjs): adapt-linearbase-tick-bounds, ToNumber of max.
      ticks[ticks.length - 1].value = jsToNumber(max);
    } else {
      // DIVERGES(chartjs): adapt-linearbase-tick-bounds, ToNumber of max.
      ticks.add(Tick(value: jsToNumber(max)));
    }
  } else if (!maxDefined || niceMax == max) {
    ticks.add(Tick(value: jsToNumber(niceMax)));
  }

  return ticks;
}

/// scale.linearbase.js:147 `relativeLabelSize(value, minSpacing,
/// {horizontal, minRotation})`.
///
/// [value] is the raw `min` or `max` option. `'' + value` is [jsToString].
double _relativeLabelSize(
  Object? value,
  double minSpacing,
  _GenerationOptions generationOptions,
) {
  final horizontal = generationOptions.horizontal;
  final minRotation = generationOptions.minRotation;
  final rad = toRadians(minRotation);
  final sinOrCos = horizontal ? math.sin(rad) : math.cos(rad);
  final ratio = jsTruthy(sinOrCos) ? sinOrCos : 0.001;
  final length = 0.75 * minSpacing * jsToString(value).length;
  return jsMin(minSpacing / ratio, length);
}

/// `console.warn(message)`.
void _consoleWarn(String message) {
  // console.warn has no other counterpart in this layer.
  // ignore: avoid_print
  print(message);
}

/// scale.linearbase.js:154 `LinearScaleBase extends Scale`.
class LinearScaleBase extends Scale {
  /// scale.linearbase.js:156 `constructor(cfg)`.
  ///
  /// [cfg] is the object `{id, type, ctx, chart}` of [Scale.new].
  LinearScaleBase(super.cfg);

  /// scale.linearbase.js:154 `class LinearScaleBase` as a value (Chart.js
  /// ADR 0020, section 3).
  ///
  /// It extends [Scale.jsClass]. It has no own statics: upstream declares
  /// none. Thus `'id' in LinearScaleBase` is false, and the registry does
  /// not register it as a component. The linear and the radial linear
  /// scales give it as their superclass.
  static final JsClass jsClass = JsClass(
    'LinearScaleBase',
    superclass: Scale.jsClass,
    construct: (newTarget, args) => LinearScaleBase(scaleCfgArg(args)),
  );

  /// scale.linearbase.js:160 `start`. NaN stands for JS `undefined`, the
  /// start value.
  double start = double.nan;

  /// scale.linearbase.js:162 `end`. NaN stands for JS `undefined`.
  double end = double.nan;

  /// scale.linearbase.js:164 `_startValue`. NaN stands for JS `undefined`.
  /// scale.linear.js:45, :49 read it.
  @internal
  double startValue = double.nan;

  /// scale.linearbase.js:166 `_endValue`. NaN stands for JS `undefined`.
  /// scale.radialLinear.js:556 reads it.
  @internal
  double endValue = double.nan;

  /// scale.linearbase.js:167 `_valueRange`. scale.linear.js:45, :49 read
  /// it.
  @internal
  double valueRange = 0;

  /// scale.linearbase.js:170 `parse(raw, index)`.
  ///
  /// The body is [prototypeParse].
  @override
  Object? parse(Object? raw, [double? index]) {
    // eslint-disable-line no-unused-vars
    return prototypeParse(raw, index);
  }

  /// scale.linearbase.js:170 `LinearScaleBase.prototype.parse`, the body of
  /// [parse] as a static function. scale.logarithmic.js:104 calls it with
  /// `apply`. The body does not read `this`.
  ///
  /// Dart `null` for the result is JS `null`: `null`, `undefined` and a
  /// number that is not finite give it. Another value gives its `ToNumber`
  /// ([jsToNumber]), also NaN for a string that is not a number. Dart has
  /// no `Number` wrapper objects, so `raw instanceof Number` has no
  /// counterpart.
  @internal
  static Object? prototypeParse(Object? raw, [double? index]) {
    if (isNullOrUndef(raw)) {
      return null;
    }
    if (raw is num && !raw.isFinite) {
      return null;
    }

    return jsToNumber(raw);
  }

  /// scale.linearbase.js:181 `handleTickRangeOptions()`.
  void handleTickRangeOptions() {
    final beginAtZero = options['beginAtZero'];
    final (:minDefined, :maxDefined, min: _, max: _) = getUserBounds();
    var min = this.min;
    var max = this.max;

    void setMin(double v) => min = minDefined ? min : v;
    void setMax(double v) => max = maxDefined ? max : v;

    if (jsTruthy(beginAtZero)) {
      final minSign = sign(min);
      final maxSign = sign(max);

      if (minSign < 0 && maxSign < 0) {
        setMax(0);
      } else if (minSign > 0 && maxSign > 0) {
        setMin(0);
      }
    }

    if (min == max) {
      final offset = max == 0 ? 1.0 : (max * 0.05).abs();

      setMax(max + offset);

      if (!jsTruthy(beginAtZero)) {
        setMin(min - offset);
      }
    }
    this.min = min;
    this.max = max;
  }

  /// scale.linearbase.js:213 `getTickLimit()`.
  ///
  /// `maxTicksLimit` and `stepSize` are the raw option values. The
  /// arithmetic applies [jsToNumber].
  double getTickLimit() {
    final tickOpts = options['ticks'];
    // eslint-disable-next-line prefer-const
    var maxTicksLimit = jsGet(tickOpts, 'maxTicksLimit');
    final stepSize = jsGet(tickOpts, 'stepSize');
    double maxTicks;

    if (jsTruthy(stepSize)) {
      maxTicks =
          (max / jsToNumber(stepSize)).ceilToDouble() -
          (min / jsToNumber(stepSize)).floorToDouble() +
          1;
      if (maxTicks > 1000) {
        _consoleWarn(
          'scales.$id.ticks.stepSize: ${jsToString(stepSize)} would result '
          'generating up to ${jsNumberToString(maxTicks)} ticks. Limiting to '
          '1000.',
        );
        maxTicks = 1000;
      }
    } else {
      maxTicks = computeTickLimit();
      maxTicksLimit = jsTruthy(maxTicksLimit) ? maxTicksLimit : 11.0;
    }

    if (jsTruthy(maxTicksLimit)) {
      maxTicks = jsMin(jsToNumber(maxTicksLimit), maxTicks);
    }

    return maxTicks;
  }

  /// scale.linearbase.js:240 `computeTickLimit()`.
  ///
  /// @protected
  @protected
  double computeTickLimit() {
    return double.infinity;
  }

  /// scale.linearbase.js:244 `buildTicks()`.
  @override
  List<Tick> buildTicks() {
    final opts = options;
    final tickOpts = opts['ticks'];

    // Figure out what the max number of ticks we can support it is based on
    // the size of the axis area. For now, we say that the minimum tick
    // spacing in pixels must be 40
    // We also limit the maximum number of ticks to 11 which gives a nice 10
    // squares on the graph. Make sure we always have at least 2 ticks
    var maxTicks = getTickLimit();
    maxTicks = jsMax(2, maxTicks);

    final numericGeneratorOptions = (
      maxTicks: maxTicks,
      bounds: opts['bounds'],
      min: opts['min'],
      max: opts['max'],
      precision: jsGet(tickOpts, 'precision'),
      step: jsGet(tickOpts, 'stepSize'),
      count: jsGet(tickOpts, 'count'),
      maxDigits: maxDigits(),
      horizontal: isHorizontal(),
      minRotation: jsOrZero(jsGet(tickOpts, 'minRotation')),
      includeBounds: jsGet(tickOpts, 'includeBounds') != false,
    );
    final dataRange = range ?? (min: min, max: max);
    final ticks = _generateTicks(numericGeneratorOptions, dataRange);

    // At this point, we need to update our max and min given the tick values,
    // since we probably have expanded the range of the scale
    if (opts['bounds'] == 'ticks') {
      setMinAndMaxByKey(ticks, this, 'value');
    }

    if (jsTruthy(opts['reverse'])) {
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

  /// scale.linearbase.js:293 `configure()`.
  ///
  /// @protected
  ///
  /// [Scale.ticks] is a list here: the update builds the ticks before the
  /// configure. A Dart `null` throws a [TypeError] at the read of the
  /// length, as JavaScript throws for `null.length`.
  @override
  @protected
  void configure() {
    final ticks = this.ticks;
    var start = min;
    var end = max;

    super.configure();

    if (jsTruthy(options['offset']) && ticks!.isNotEmpty) {
      final offset = (end - start) / jsMax(ticks.length - 1.0, 1) / 2;
      start -= offset;
      end += offset;
    }
    startValue = start;
    endValue = end;
    valueRange = end - start;
  }

  /// scale.linearbase.js:310 `getLabelForValue(value)`.
  ///
  /// [value] is any JS value. Upstream gives it without a change to
  /// `Intl.NumberFormat.prototype.format`. `format` applies
  /// `ToIntlMathematicalValue`: `ToPrimitive`, and then `ToNumber`, but not
  /// to a String or a BigInt primitive. V8 keeps the exact decimal of such a
  /// primitive. The port applies [jsToNumber] to [value]. Thus a string whose
  /// decimal is not the shortest round-trip form of its double gets other
  /// digits. For example, `'9007199254740993'` gives `9,007,199,254,740,993`
  /// in V8 and `9,007,199,254,740,992` in the port. Only the digits of the
  /// label change (Chart.js ADR 0009). The `ticks.format` option is a Map of
  /// the number format options, or another value, which gives no options:
  /// `new Intl.NumberFormat(locale, options)` reads no option from it.
  @override
  Object? getLabelForValue(Object? value) {
    final format = jsGet(options['ticks'], 'format');
    return formatNumber(
      jsToNumber(value),
      jsGet(chart.options, 'locale'),
      format is Map<String, Object?> ? format : null,
    );
  }
}
