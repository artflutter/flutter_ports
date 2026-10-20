// Ported from Chart.js v4.5.1 src/core/core.ticks.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.ticks.js`.
///
/// The formatters `numeric` and `logarithmic` read `this`, the scale whose
/// labels they make (index.d.ts:1552, :1560). Thus they are [JsFunction]
/// values (`lib/src/js/js_function.dart`). A caller gives the scale as the
/// `thisArg` of [jsCall], as `core.scale.js` calls the tick `callback`. The
/// formatter `values` does not read `this`. It is a Dart function.
/// [formatters] and [ticks] are Maps, as the JavaScript objects can change.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs/src/helpers/helpers.core.dart' show isArray;
import 'package:flutter_chartjs/src/helpers/helpers.intl.dart';
import 'package:flutter_chartjs/src/helpers/helpers.math.dart' show log10;
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_function.dart';
import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/js/js_undefined.dart';
import 'package:flutter_chartjs/src/types/index.dart';

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
///
/// - `'values'` is a Dart function `Object? Function(Object? value)`. It
///   does not read `this`.
/// - `'numeric'` and `'logarithmic'` are [JsFunction] values, because they
///   read `this`. The closure takes `this` (a [Scale]), `tickValue` (a
///   `double`), `index` (a `double`) and `ticks` (a `List<Tick>`), as
///   index.d.ts:1552 and :1560 declare. Call it with [jsCall] and the scale
///   as `thisArg`.
final Map<String, Object?> formatters = {
  'values': _values,
  'numeric': const JsFunction(_numeric),
  'logarithmic': const JsFunction(_logarithmic),
};

/// core.ticks.js:16 `values`.
///
/// Formatter for value labels
/// @method Chart.Ticks.formatters.values
/// @param value the value to display
/// @return {string|string[]} the label to display
///
/// `'' + value` is [jsToString].
Object? _values(Object? value) {
  return isArray(value) ? value : jsToString(value);
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
String _numeric(Scale self, double tickValue, double index, List<Tick> ticks) {
  if (tickValue == 0) {
    return '0'; // never show decimal places for 0
  }

  final locale = jsGet(self.chart.options, 'locale');
  Object? notation = undefined;
  // This is used when there are less than 2 ticks as the tick interval.
  var delta = tickValue;

  if (ticks.length > 1) {
    // all ticks are small or there huge numbers; use scientific notation
    final maxTick = jsMax(
      ticks[0].value.abs(),
      ticks[ticks.length - 1].value.abs(),
    );
    if (maxTick < 1e-4 || maxTick > 1e+15) {
      notation = 'scientific';
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
      : jsMax(
          jsMin(-1 * logDelta.floorToDouble(), 20),
          0,
        );

  final options = <String, Object?>{
    'notation': notation,
    'minimumFractionDigits': numDecimal,
    'maximumFractionDigits': numDecimal,
  };
  _assign(options, jsGet(jsGet(self.options, 'ticks'), 'format'));

  return formatNumber(tickValue, locale, options);
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
/// Returns the result of `formatters['numeric']` or `''`.
Object? _logarithmic(
  Scale self,
  double tickValue,
  double index,
  List<Tick> ticks,
) {
  if (tickValue == 0) {
    return '0';
  }
  // `ticks[index]` is undefined unless index is an array index of ticks.
  // Then the read of `significand` throws a TypeError.
  if (!index.isFinite ||
      index != index.truncateToDouble() ||
      index < 0 ||
      index >= ticks.length) {
    throw TypeError();
  }
  final significand = ticks[index.toInt()].significand;
  final remain = jsTruthy(significand)
      ? significand!
      // js-ok: double operands, dart:math pow (Chart.js ADR 0010).
      : (tickValue / (math.pow(10.0, log10(tickValue).floorToDouble())));
  if (const <double>[1, 2, 3, 5, 10, 15].contains(remain) ||
      index > 0.8 * ticks.length) {
    final args = <Object?>[tickValue, index, ticks];
    return jsCall(formatters['numeric'], args, thisArg: self);
  }
  return '';
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
final Map<String, Object?> ticks = {'formatters': formatters};

/// `Object.assign(target, source)` with one source, at core.ticks.js:57.
///
/// A Map source copies its keys in the [jsObjectKeys] order, also a key with
/// the value [undefined]. `null` and [undefined] copy nothing, as in
/// JavaScript. A String or a List source copies its indices in JavaScript.
/// [formatNumber] ignores such keys. Thus the port copies nothing for them.
void _assign(Map<String, Object?> target, Object? source) {
  if (source is Map<String, Object?>) {
    for (final key in jsObjectKeys(source)) {
      target[key] = source[key];
    }
  }
}
