// Ported from Chart.js v4.6.1 src/core/core.ticks.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.ticks.js`.
///
/// The formatters `numeric` and `logarithmic` read `this`, the scale whose
/// labels they make (index.d.ts:1552, :1560). Each formatter is a
/// [TickFormatter]: the scale is its first parameter, as for each tick
/// callback (row `adapt-native-tick`), and the result is the lines of the
/// label. [formatters] and [ticks] are Maps, as the JavaScript objects can
/// change.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_port/src/core/scale_options.dart'
    show TickOptions;
import 'package:flutter_chartjs_port/src/helpers/helpers.config.dart'
    show readOption;
import 'package:flutter_chartjs_port/src/helpers/helpers.intl.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.math.dart' show log10;
import 'package:flutter_chartjs_port/src/js/js_math.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart'
    show OptionKey;
import 'package:flutter_chartjs_port/src/types/index.dart';

/// A tick formatter: a function of [formatters].
///
/// It is a `TickCallback` of `core.scale.dart`, the value of the option
/// `ticks.callback`: the scale, where upstream gives it as `this`, then the
/// arguments `tickValue`, `index` and `ticks` of index.d.ts:1552. The
/// result is the lines of the label.
typedef TickFormatter = List<String>? Function(
  Scale scale,
  double tickValue,
  int index,
  List<Tick> ticks,
);

/// core.ticks.js:9 `formatters`.
///
/// Namespace to hold formatters for different types of ticks
/// @namespace Chart.Ticks.formatters
///
/// Upstream is an object literal with the three methods `values`, `numeric`
/// and `logarithmic`. The Dart map literal keeps the same key order. The map
/// can change, as the JavaScript object can. `logarithmic` reads
/// `formatters['numeric']` when it runs, as core.ticks.js:77 does. Thus a
/// replaced `numeric` also formats the logarithmic labels.
// DIVERGES(chartjs): adapt-native-tick, each formatter is a TickFormatter.
final Map<String, TickFormatter> formatters = {
  'values': _values,
  'numeric': _numeric,
  'logarithmic': _logarithmic,
};

/// core.ticks.js:16 `values`.
///
/// Formatter for value labels
/// @method Chart.Ticks.formatters.values
/// @param value the value to display
/// @return {string|string[]} the label to display
///
/// `'' + value` is [jsNumberToString]: the value of a tick is a number.
List<String>? _values(Scale scale, double value, int index, List<Tick> ticks) {
  return <String>[jsNumberToString(value)];
}

/// core.ticks.js:28 `numeric`.
///
/// Formatter for numeric ticks
/// @method Chart.Ticks.formatters.numeric
/// @param tickValue {number} the value to be formatted
/// @param index {number} the position of the tickValue parameter in the ticks
/// array
/// @param ticks {object[]} the list of ticks being converted
/// @return {string} string representation of the tickValue parameter
List<String>? _numeric(
  Scale self,
  double tickValue,
  int index,
  List<Tick> ticks,
) {
  if (tickValue == 0) {
    return const <String>['0']; // never show decimal places for 0
  }

  final locale = localeOf(readOption(self.chart.options, OptionKey.locale));
  var scientific = false;
  // This is used when there are less than 2 ticks as the tick interval.
  var delta = tickValue;

  if (ticks.length > 1) {
    // all ticks are small or there huge numbers; use scientific notation
    final maxTick = jsMax(
      ticks[0].value.abs(),
      ticks[ticks.length - 1].value.abs(),
    );
    if (maxTick < 1e-4 || maxTick > 1e+15) {
      scientific = true;
    }

    delta = _calculateDelta(tickValue, ticks);
  }

  final logDelta = log10(delta.abs());

  // When datasets have values approaching Number.MAX_VALUE, the tick
  // calculations might result in infinity and eventually NaN. Passing NaN for
  // minimumFractionDigits or maximumFractionDigits will make the number
  // formatter throw. So instead we check for isNaN and use a fallback value.
  //
  // toFixed has a max of 20 decimal places
  final numDecimal = logDelta.isNaN
      ? 1.0
      : jsMax(jsMin(-1 * logDelta.floorToDouble(), 20), 0);

  // DIVERGES(chartjs): adapt-intl-number-format, a NumberFormat formats the
  // tick as it is: Dart cannot copy it to merge the digits of the tick.
  final format = TickOptions(readOption(self.options, OptionKey.ticks)).format;
  if (format != null) return <String>[format.format(tickValue)];
  return <String>[
    formatNumberDigits(
      tickValue,
      locale,
      scientific: scientific,
      fractionDigits: numDecimal.toInt(),
    ),
  ];
}

/// core.ticks.js:71 `logarithmic`.
///
/// Formatter for logarithmic ticks
/// @method Chart.Ticks.formatters.logarithmic
/// @param tickValue {number} the value to be formatted
/// @param index {number} the position of the tickValue parameter in the ticks
/// array
/// @param ticks {object[]} the list of ticks being converted
/// @return {string} string representation of the tickValue parameter
///
/// Returns the result of `formatters['numeric']` or the empty line.
List<String>? _logarithmic(
  Scale self,
  double tickValue,
  int index,
  List<Tick> ticks,
) {
  if (tickValue == 0) {
    return const <String>['0'];
  }
  // `ticks[index]` is undefined unless index is an array index of ticks.
  // Then the read of `significand` throws a TypeError.
  if (index < 0 || index >= ticks.length) {
    throw TypeError();
  }
  final significand = ticks[index].significand;
  final remain = jsTruthy(significand)
      ? significand!
      // js-ok: double operands, dart:math pow (Chart.js ADR 0045).
      : (tickValue / (math.pow(10.0, log10(tickValue).floorToDouble())));
  if (const <double>[1, 2, 3, 5, 10, 15].contains(remain) ||
      index > 0.8 * ticks.length) {
    return formatters['numeric']!(self, tickValue, index, ticks);
  }
  return const <String>[''];
}

/// core.ticks.js:85 `calculateDelta`.
double _calculateDelta(double tickValue, List<Tick> ticks) {
  // Figure out how many digits to show
  // The space between the first two ticks might be smaller than normal spacing
  var delta = ticks.length > 3
      ? ticks[2].value - ticks[1].value
      : ticks[1].value - ticks[0].value;

  // If we have a number like 2.5 as the delta, figure out how many decimal
  // places we need
  if (delta.abs() >= 1 && tickValue != tickValue.floorToDouble()) {
    // not an integer
    delta = tickValue - tickValue.floorToDouble();
  }
  return delta;
}

/// core.ticks.js:102 the default export `{formatters}`.
///
/// Namespace to hold static tick generation functions
/// @namespace Chart.Ticks
///
/// `src/core/index.ts:15` exports it as `Ticks`. Dart has no default export,
/// and a Dart variable has a lowerCamelCase name (Chart.js ADR 0012). Thus
/// the port names it `ticks`. It is an object literal: a Map that can change.
final Map<String, Map<String, TickFormatter>> ticks = {
  'formatters': formatters,
};
