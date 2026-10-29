// Ported from Chart.js v4.6.1 src/plugins/plugin.filler/filler.options.js (MIT, Chart.js Contributors).

/// Port of `src/plugins/plugin.filler/filler.options.js`.
///
/// The fill option of a line is any option value (Chart.js ADR 0043):
/// `false`, `true`, a number, a String, an option object (`{value}`,
/// `{target, above, below}`), Dart `null` for JS `null`, or the
/// `undefined` sentinel. The JS operators keep their JS meaning through the
/// runtime of `lib/src/js/` (`jsTruthy`, `jsParseFloat`, `jsGet`).
///
/// This library is a pure layer (Chart.js ADR 0038, section 9).
library;

import 'package:flutter_chartjs_port/src/helpers/helpers.core.dart'
    show isFinite, isObject, valueOrDefault;
import 'package:flutter_chartjs_port/src/js/js_number.dart'
    show jsParseFloat, jsToNumber, jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_object.dart'
    show jsGet, jsGetIndex;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart'
    show FillerSource;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// filler.options.js:10 `_resolveTarget(sources, index, propagate)`.
///
/// [sources] has a [FillerSource] or Dart `null` (JS `null`) for each
/// dataset, and [index] is the index of a source that is not `null`. The
/// result is `false`, a `double` dataset index, a `String` mode or the
/// option object `{value}`. `sources[fill]` is `jsGetIndex`: an index out of
/// range gives `undefined`, and `!target` returns `false`.
Object resolveTarget(
  List<FillerSource?> sources,
  int index,
  // The upstream signature.
  // ignore: avoid_positional_boolean_parameters
  bool propagate,
) {
  final source = sources[index]!;
  var fill = source.fill;
  final visited = <Object>[index.toDouble()];
  Object? target;

  if (!propagate) {
    return fill;
  }

  while (fill != false && !visited.contains(fill)) {
    if (!isFinite(fill)) {
      return fill;
    }

    target = jsGetIndex(sources, (fill as num).toDouble());
    if (target is! FillerSource) {
      return false;
    }

    if (target.visible) {
      return fill;
    }

    visited.add(fill);
    fill = target.fill;
  }

  return false;
}

/// filler.options.js:46 `_decodeFill(line, index, count)`.
///
/// @param {LineElement} line
/// @param {number} index
/// @param {number} count
///
/// The result is `false`, a `double` dataset index, a `String` mode or the
/// option object `{value}`. It is never Dart `null`.
Object decodeFill(types.LineElement line, double index, double count) {
  // @type {string | {value: number}}
  final fill = _parseFillOption(line);

  if (isObject(fill)) {
    return jsToNumber(jsGet(fill, 'value')).isNaN ? false : fill;
  }

  final target = jsParseFloat(fill);

  if (target.isFinite && target.floorToDouble() == target) {
    return _decodeTargetIndex(jsGet(fill, '0'), index, target, count);
  }

  // `indexOf(fill) >= 0 && fill`: the mode itself, or `false`.
  return const ['origin', 'start', 'end', 'stack', 'shape'].contains(fill)
      ? fill
      : false;
}

/// filler.options.js:63 `decodeTargetIndex(firstCh, index, target, count)`.
/// [firstCh] is `fill[0]`: the first character of a String, else
/// `undefined`.
Object _decodeTargetIndex(
  Object? firstCh,
  double index,
  double target,
  double count,
) {
  var result = target;
  if (firstCh == '-' || firstCh == '+') {
    result = index + result;
  }

  if (result == index || result < 0 || result >= count) {
    return false;
  }

  return result;
}

/// filler.options.js:80 `_getTargetPixel(fill, scale)`.
///
/// @param {FillTarget | ComplexFillTarget} fill
/// @param {Scale} scale
/// @returns {number | null}
///
/// Dart `null` for [scale] is the `{}` of `computeLinearBoundary`
/// (filler.target.js:58): `'start'` and `'end'` give Dart `null` for the
/// `undefined` of `{}.bottom` and `{}.top`, which is not finite either. An
/// option object throws a [TypeError], as `{}.getPixelForValue(...)` does.
/// Another fill gives Dart `null`, because `{}.getBasePixel` is falsy.
double? getTargetPixel(Object fill, types.Scale? scale) {
  double? pixel;
  if (fill == 'start') {
    pixel = scale?.bottom;
  } else if (fill == 'end') {
    pixel = scale?.top;
  } else if (isObject(fill)) {
    pixel = scale!.getPixelForValue(jsGet(fill, 'value'));
  } else if (scale != null) {
    pixel = scale.getBasePixel();
  }
  return pixel;
}

/// filler.options.js:101 `_getTargetValue(fill, scale, startValue)`.
///
/// @param {FillTarget | ComplexFillTarget} fill
/// @param {Scale} scale
/// @param {number} startValue
/// @returns {number | undefined}
///
/// The result is any JS value: `fill.value` is a raw option value.
Object? getTargetValue(Object fill, types.Scale scale, double startValue) {
  Object? value;

  if (fill == 'start') {
    value = startValue;
  } else if (fill == 'end') {
    value = jsTruthy(jsGet(scale.options, 'reverse')) ? scale.min : scale.max;
  } else if (isObject(fill)) {
    value = jsGet(fill, 'value');
  } else {
    value = scale.getBaseValue();
  }
  return value;
}

/// filler.options.js:120 `parseFillOption(line)`.
///
/// @param {LineElement} line
///
/// `fillOption && fillOption.target` reads `target` of a truthy option
/// only. `valueOrDefault` takes the option itself for `undefined`.
Object _parseFillOption(types.LineElement line) {
  final options = line.options;
  final fillOption = jsGet(options, 'fill');
  var fill = valueOrDefault(
    jsTruthy(fillOption) ? jsGet(fillOption, 'target') : fillOption,
    fillOption,
  );

  if (identical(fill, undefined)) {
    fill = jsTruthy(jsGet(options, 'backgroundColor'));
  }

  if (fill == false || fill == null) {
    return false;
  }

  if (fill == true) {
    return 'origin';
  }
  return fill;
}
