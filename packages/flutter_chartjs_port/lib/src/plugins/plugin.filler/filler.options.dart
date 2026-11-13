// Ported from Chart.js v4.6.1 src/plugins/plugin.filler/filler.options.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-fill-target-objects, no text targets.

/// Port of `src/plugins/plugin.filler/filler.options.js`.
///
/// The fill option of a line is a [FillTarget] (Chart.js ADR 0140, row
/// `adapt-fill-target-objects`), Dart `null` for JS `null`, or the
/// `undefined` sentinel. The decoded fill of a source is a [FillTarget]
/// too: [FillTarget.none] for `false`, a [DatasetFill] for a dataset index,
/// a boundary, or a [ValueFill] for the object `{value}`. The line options
/// (the typed `LineOptions`) and the scale options are read through their
/// typed reads (`optionOf`).
///
/// This library is a pure layer (Chart.js ADR 0038, section 9).
library;

import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsTruthy;
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';
import 'package:flutter_chartjs_port/src/options/option_keys.g.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.filler/index.dart'
    show FillerSource;
import 'package:flutter_chartjs_port/src/plugins/plugin_options.dart'
    show optionOf;
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

/// filler.options.js:10 `_resolveTarget(sources, index, propagate)`.
///
/// [sources] has a [FillerSource] or Dart `null` (JS `null`) for each
/// dataset, and [index] is the index of a source that is not `null`. The
/// result is [FillTarget.none], a [DatasetFill], a boundary or a
/// [ValueFill]. `sources[fill]` of an index out of range is `undefined`,
/// and `!target` returns `false`.
FillTarget resolveTarget(
  List<FillerSource?> sources,
  int index,
  bool propagate,
) {
  final source = sources[index]!;
  var fill = source.fill;
  final visited = <int>[index];
  FillerSource? target;

  if (!propagate) {
    return fill;
  }

  // `visited.indexOf(fill) === -1`: `visited` holds dataset indexes only.
  while (fill is! NoFill &&
      !(fill is DatasetFill && visited.contains(fill.index))) {
    // DIVERGES(chartjs): adapt-fill-target-objects, a dataset index is a class.
    if (fill is! DatasetFill) {
      return fill;
    }

    target = fill.index < sources.length ? sources[fill.index] : null;
    if (target == null) {
      return FillTarget.none;
    }

    if (target.visible) {
      return fill;
    }

    visited.add(fill.index);
    fill = target.fill;
  }

  return FillTarget.none;
}

/// filler.options.js:46 `_decodeFill(line, index, count)`.
///
/// @param {LineElement} line
/// @param {number} index
/// @param {number} count
///
/// The result is [FillTarget.none], a [DatasetFill], a boundary or a
/// [ValueFill].
///
/// Upstream parses the text of `fill` (`parseFloat(fill)` and `fill[0]`).
/// The port has no text: a [RelativeFill] is the relative index, as `'+n'`
/// or `'-n'` upstream, and a [DatasetFill] is the absolute index, a number
/// upstream, whose `fill[0]` is no sign.
FillTarget decodeFill(types.LineElement line, int index, double count) {
  // @type {string | {value: number}}
  final fill = _parseFillOption(line);

  // DIVERGES(chartjs): adapt-fill-target-objects, the object `{value}` is a
  // class.
  if (fill case ValueFill(:final value)) {
    return value.isNaN ? FillTarget.none : fill;
  }

  // DIVERGES(chartjs): adapt-fill-target-objects, a relative index is a class.
  if (fill case RelativeFill(:final offset)) {
    return _decodeTargetIndex('+', index, offset, count);
  }

  if (fill case DatasetFill(index: final target)) {
    return _decodeTargetIndex(null, index, target, count);
  }

  // `indexOf(fill) >= 0 && fill`: a boundary itself, or `false`.
  return fill;
}

/// filler.options.js:63 `decodeTargetIndex(firstCh, index, target, count)`.
/// [firstCh] is `'+'` for a [RelativeFill], else Dart `null` (the
/// `undefined` of `fill[0]` of a number).
FillTarget _decodeTargetIndex(
  String? firstCh,
  int index,
  int target,
  double count,
) {
  var result = target;
  if (firstCh == '-' || firstCh == '+') {
    result = index + result;
  }

  if (result == index || result < 0 || result >= count) {
    return FillTarget.none;
  }

  return FillTarget.toDataset(result);
}

/// filler.options.js:80 `_getTargetPixel(fill, scale)`.
///
/// @param {FillTarget | ComplexFillTarget} fill
/// @param {Scale} scale
/// @returns {number | null}
///
/// Dart `null` for [scale] is the `{}` of `computeLinearBoundary`
/// (filler.target.js:58): `'start'` and `'end'` give Dart `null` for the
/// `undefined` of `{}.bottom` and `{}.top`, which is not finite either. A
/// [ValueFill] throws a [TypeError], as `{}.getPixelForValue(...)` does.
/// Another fill gives Dart `null`, because `{}.getBasePixel` is falsy.
double? getTargetPixel(FillTarget fill, types.Scale? scale) {
  double? pixel;
  if (fill is StartFill) {
    pixel = scale?.bottom;
  } else if (fill is EndFill) {
    pixel = scale?.top;
  } else if (fill is ValueFill) {
    pixel = scale!.getPixelForValue(fill.value);
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
double getTargetValue(FillTarget fill, types.Scale scale, double startValue) {
  double value;

  if (fill is StartFill) {
    value = startValue;
  } else if (fill is EndFill) {
    value = jsTruthy(optionOf(scale.options, OptionKey.reverse))
        ? scale.min
        : scale.max;
  } else if (fill is ValueFill) {
    value = fill.value;
  } else {
    value = scale.getBaseValue();
  }
  return value;
}

/// filler.options.js:120 `parseFillOption(line)`.
///
/// @param {LineElement} line
///
/// `fillOption && fillOption.target` reads `target` of a [SplitFill] only:
/// no other value of `fill` has the key. `valueOrDefault` takes the option
/// itself for `undefined`.
FillTarget _parseFillOption(types.LineElement line) {
  final options = line.options;
  final fillOption = optionOf(options, OptionKey.fill);
  // DIVERGES(chartjs): adapt-fill-target-objects, the object `{target}` is a
  // class.
  var fill = fillOption is SplitFill ? fillOption.target : fillOption;

  if (identical(fill, undefined)) {
    // `!!options.backgroundColor`; `true` gives 'origin' below.
    fill = jsTruthy(optionOf(options, OptionKey.backgroundColor))
        ? FillTarget.toOrigin
        : FillTarget.none;
  }

  // `fill === false || fill === null`: [FillTarget.of] gives Dart `null`
  // for `null`. `fill === true` is [FillTarget.toOrigin] itself.
  return FillTarget.of(fill) ?? FillTarget.none;
}
