// Ported from Chart.js v4.5.1 src/core/core.scale.autoskip.js (MIT, Chart.js Contributors).

/// Port of `src/core/core.scale.autoskip.js`.
///
/// Upstream imports the scale class only for its JSDoc type
/// (core.scale.autoskip.js:12). Thus this library reads the scale through
/// `types.Scale` (Chart.js ADR 0003): its options, `tickSize()` (upstream
/// `_tickSize`), `length` (`_length`) and `maxLength` (`_maxLength`). A tick
/// is the [Tick] of `core.scale.dart`, the port of the typedef `Tick`
/// (core.scale.autoskip.js:7, core.scale.js:15). The two libraries import
/// each other, as the two upstream files name each other.
///
/// Numbers are `double` (Chart.js ADR 0010). The indexes of the major ticks
/// are numbers that `skip` and `skipMajors` compare with the loop index and
/// use in arithmetic. Thus they are `double` too, and the loops convert an
/// index to an `int` only to read a list. A read of a list at an index that
/// is not an integer in range gives JS `undefined`. Here it gives Dart
/// `null`, which equals no index.
///
/// `core.scale.dart` imports `helpers.extras`. Thus this library is not a
/// pure layer.
library;

import 'package:flutter_chartjs/src/core/core.scale.dart' show Tick;
import 'package:flutter_chartjs/src/helpers/helpers.core.dart'
    show isNullOrUndef;
import 'package:flutter_chartjs/src/helpers/helpers.math.dart' show factorize;
import 'package:flutter_chartjs/src/js/js_math.dart';
import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';
import 'package:flutter_chartjs/src/types/index.dart' as types;

/// core.scale.autoskip.js:17 `autoSkip`.
///
/// Returns a subset of ticks to be plotted to avoid overlapping labels.
/// @param {import('./core.scale.js').default} scale
/// @param {Tick[]} ticks
/// @return {Tick[]}
/// @private
///
/// The result is a new list of the same tick objects.
List<Tick> autoSkip(types.Scale scale, List<Tick> ticks) {
  final tickOpts = scale.options['ticks'];
  final determinedMaxTicks = _determineMaxTicks(scale);
  final maxTicksLimit = jsGet(tickOpts, 'maxTicksLimit');
  final ticksLimit = jsMin(
    jsTruthy(maxTicksLimit) ? jsToNumber(maxTicksLimit) : determinedMaxTicks,
    determinedMaxTicks,
  );
  final majorIndices = jsTruthy(jsGet(jsGet(tickOpts, 'major'), 'enabled'))
      ? _getMajorIndices(ticks)
      : <double>[];
  final numMajorIndices = majorIndices.length;
  final first = _at(majorIndices, 0);
  final last = _at(majorIndices, numMajorIndices - 1.0);
  final newTicks = <Tick>[];

  // If there are too many major ticks to display them all
  if (numMajorIndices > ticksLimit) {
    _skipMajors(ticks, newTicks, majorIndices, numMajorIndices / ticksLimit);
    return newTicks;
  }

  final spacing = _calculateSpacing(majorIndices, ticks, ticksLimit);

  if (numMajorIndices > 0) {
    // `first` and `last` are numbers when the list has an item.
    final avgMajorSpacing = numMajorIndices > 1
        ? jsRound((last! - first!) / (numMajorIndices - 1))
        : null;
    _skip(
      ticks,
      newTicks,
      spacing,
      isNullOrUndef(avgMajorSpacing) ? 0 : first! - avgMajorSpacing!,
      first,
    );
    for (var i = 0, ilen = numMajorIndices - 1; i < ilen; i++) {
      _skip(ticks, newTicks, spacing, majorIndices[i], majorIndices[i + 1]);
    }
    _skip(
      ticks,
      newTicks,
      spacing,
      last,
      isNullOrUndef(avgMajorSpacing)
          ? ticks.length.toDouble()
          : last! + avgMajorSpacing!,
    );
    return newTicks;
  }
  _skip(ticks, newTicks, spacing);
  return newTicks;
}

/// core.scale.autoskip.js:49 `determineMaxTicks`.
double _determineMaxTicks(types.Scale scale) {
  final offset = scale.options['offset'];
  final tickLength = scale.tickSize();
  final maxScale = scale.length / tickLength + (jsTruthy(offset) ? 0 : 1);
  final maxChart = scale.maxLength / tickLength;
  return jsMin(maxScale, maxChart).floorToDouble();
}

/// core.scale.autoskip.js:62 `calculateSpacing`.
///
/// @param {number[]} majorIndices
/// @param {Tick[]} ticks
/// @param {number} ticksLimit
double _calculateSpacing(
  List<double> majorIndices,
  List<Tick> ticks,
  double ticksLimit,
) {
  final evenMajorSpacing = _getEvenSpacing(majorIndices);
  final spacing = ticks.length / ticksLimit;

  // If the major ticks are evenly spaced apart, place the minor ticks
  // so that they divide the major ticks into even chunks
  if (!jsTruthy(evenMajorSpacing)) {
    return jsMax(spacing, 1);
  }

  final factors = factorize(evenMajorSpacing as double);
  for (var i = 0, ilen = factors.length - 1; i < ilen; i++) {
    final factor = factors[i];
    if (factor > spacing) {
      return factor;
    }
  }
  return jsMax(spacing, 1);
}

/// core.scale.autoskip.js:85 `getMajorIndices`.
///
/// @param {Tick[]} ticks
///
/// The indexes are numbers (see the library documentation).
List<double> _getMajorIndices(List<Tick> ticks) {
  final result = <double>[];
  for (var i = 0, ilen = ticks.length; i < ilen; i++) {
    if (ticks[i].major ?? false) {
      result.add(i.toDouble());
    }
  }
  return result;
}

/// core.scale.autoskip.js:102 `skipMajors`.
///
/// @param {Tick[]} ticks
/// @param {Tick[]} newTicks
/// @param {number[]} majorIndices
/// @param {number} spacing
void _skipMajors(
  List<Tick> ticks,
  List<Tick> newTicks,
  List<double> majorIndices,
  double spacing,
) {
  var count = 0;
  var next = _at(majorIndices, 0);
  int i;

  // Upstream reassigns its parameter.
  // ignore: parameter_assignments
  spacing = spacing.ceilToDouble();
  for (i = 0; i < ticks.length; i++) {
    if (i == next) {
      newTicks.add(ticks[i]);
      count++;
      next = _at(majorIndices, count * spacing);
    }
  }
}

/// core.scale.autoskip.js:124 `skip`.
///
/// @param {Tick[]} ticks
/// @param {Tick[]} newTicks
/// @param {number} spacing
/// @param {number} [majorStart]
/// @param {number} [majorEnd]
///
/// Dart `null` stands for an absent [majorStart] or [majorEnd], JS
/// `undefined`. JS `null` never reaches them. Thus `valueOrDefault(x, d)`
/// of `helpers.core` (core.scale.autoskip.js:125-126) is `x ?? d`.
void _skip(
  List<Tick> ticks,
  List<Tick> newTicks,
  double spacing, [
  double? majorStart,
  double? majorEnd,
]) {
  final start = majorStart ?? 0;
  final end = jsMin(
    majorEnd ?? ticks.length.toDouble(),
    ticks.length.toDouble(),
  );
  var count = 0;
  double length;
  double i;
  double next;

  // Upstream reassigns its parameter.
  // ignore: parameter_assignments
  spacing = spacing.ceilToDouble();
  // `if (majorEnd)`: a major end of 0 is falsy.
  if (majorEnd != null && jsTruthy(majorEnd)) {
    // `majorStart` is a number when `majorEnd` is truthy: autoSkip passes
    // both or neither.
    length = majorEnd - majorStart!;
    // Upstream reassigns its parameter.
    // ignore: parameter_assignments
    spacing = length / (length / spacing).floorToDouble();
  }

  next = start;

  while (next < 0) {
    count++;
    next = jsRound(start + count * spacing);
  }

  for (i = jsMax(start, 0); i < end; i++) {
    if (i == next) {
      // `i === next` and `next` is an integer: `i` is an index in range.
      newTicks.add(ticks[i.toInt()]);
      count++;
      next = jsRound(start + count * spacing);
    }
  }
}

/// core.scale.autoskip.js:156 `getEvenSpacing`.
///
/// @param {number[]} arr
///
/// It returns `false` or the spacing, a number, as upstream does.
Object _getEvenSpacing(List<double> arr) {
  final len = arr.length;

  if (len < 2) {
    return false;
  }

  final diff = arr[0];
  for (var i = 1; i < len; ++i) {
    if (arr[i] - arr[i - 1] != diff) {
      return false;
    }
  }
  return diff;
}

/// The JS read `arr[index]` of a number [index]: the item at an integer
/// index in range, else Dart `null` for JS `undefined`.
double? _at(List<double> arr, double index) =>
    index >= 0 && index < arr.length && index == index.floorToDouble()
    ? arr[index.toInt()]
    : null;
