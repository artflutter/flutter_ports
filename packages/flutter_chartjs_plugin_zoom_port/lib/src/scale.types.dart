// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/scale.types.ts (MIT, chartjs-plugin-zoom contributors).

/// The zoom and pan functions of each scale type, and the range update with
/// the limits.
///
/// The three tables [zoomFunctions], [zoomRectFunctions] and [panFunctions]
/// are the extension point of upstream: an app adds a function for a custom
/// scale type. They keep the upstream key order.
///
/// `Math.round` is `roundToDouble()` (Chart.js ADR 0146 §7). `Math.min` and
/// `Math.max` are
/// `dart:math` `min` and `max` with `double` operands (Chart.js ADR 0146 §4).
/// `Math.log10` is `log10` of the helpers. `Math.pow(10, x)` is
/// `dart:math` `pow` with double operands, the rule of Chart.js ADR 0146.
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show RAxis, Scale, TimeUnit, XAxis, YAxis, undefined;
import 'package:flutter_chartjs_port/helpers.dart'
    show almostEquals, isNullOrUndef, isNumber, log10, valueOrDefault;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsGet, jsToNumber, jsTruthy;

/// scale.types.ts:7 `ZoomFunction`: zooms [scale] by the factor [zoom]
/// around [center], within [limits]. The result is true if the range
/// changed.
typedef ZoomFunction = bool Function(
  Scale scale,
  double zoom,
  Point center,
  LimitOptions limits,
);

/// scale.types.ts:8 `ZoomRectFunction`: zooms [scale] to the pixels [from]
/// to [to], within [limits]. The result is true if the range changed.
typedef ZoomRectFunction = bool Function(
  Scale scale,
  double from,
  double to,
  LimitOptions limits,
);

/// scale.types.ts:9 `PanFunction`: pans [scale] by [delta] pixels, within
/// [limits]. The result is true if the range changed, or if the pan stops at
/// a limit.
typedef PanFunction = bool Function(
  Scale scale,
  double delta,
  LimitOptions limits,
);

/// scale.types.ts:11 `isTimeScale(scale)`: `scale.type === 'time'`.
bool _isTimeScale(Scale scale) => scale.type == 'time';

/// scale.types.ts:13 `isNotNumber(value)`: `undefined` (`null`) or NaN.
bool _isNotNumber(double? value) => value == null || value.isNaN;

/// scale.types.ts:15 `zoomDelta(val, min, range, newRange)`: the parts of
/// [newRange] below and above the value [val], in the proportion of [val]
/// in the range that starts at [min].
///
/// A `null` [val] or [min] is the `undefined` of upstream. A falsy [range]
/// (0 or NaN) puts [newRange] above the value.
ScaleRange zoomDelta(double? val, double? min, double range, double newRange) {
  final minPercent = jsTruthy(range) && isNumber(val) && isNumber(min)
      ? math.max<double>(0, math.min<double>(1, (val! - min!) / range))
      : 0.0;
  final maxPercent = 1 - minPercent;

  return (min: newRange * minPercent, max: newRange * maxPercent);
}

/// scale.types.ts:30 `getValueAtPoint(scale, point)`.
double? _getValueAtPoint(Scale scale, Point point) {
  final pixel = scale.isHorizontal() ? point.x : point.y;

  return scale.getValueForPixel(pixel);
}

/// scale.types.ts:36 `linearZoomDelta(scale, zoom, center)`.
ScaleRange _linearZoomDelta(Scale scale, double zoom, Point center) {
  final range = scale.max - scale.min;
  final newRange = range * (zoom - 1);
  final centerValue = _getValueAtPoint(scale, center);

  return zoomDelta(centerValue, scale.min, range, newRange);
}

/// scale.types.ts:44 `logarithmicZoomRange(scale, zoom, center)`.
ScaleRange _logarithmicZoomRange(Scale scale, double zoom, Point center) {
  final centerValue = _getValueAtPoint(scale, center);

  // Return the original range, if value could not be determined.
  if (centerValue == null) {
    return (min: scale.min, max: scale.max);
  }

  final logMin = log10(scale.min);
  final logMax = log10(scale.max);
  final logCenter = log10(centerValue);
  final logRange = logMax - logMin;
  final newLogRange = logRange * (zoom - 1);
  final delta = zoomDelta(logCenter, logMin, logRange, newLogRange);

  return (
    // js-ok: Math.pow with double operands (Chart.js ADR 0146).
    min: math.pow(10.0, logMin + delta.min).toDouble(),
    // js-ok: Math.pow with double operands (Chart.js ADR 0146).
    max: math.pow(10.0, logMax - delta.max).toDouble(),
  );
}

/// scale.types.ts:65 `getScaleLimits(scale, limits)`: the limits of the id
/// of [scale], else of its axis, else `{}`.
ScaleLimits _getScaleLimits(Scale scale, LimitOptions? limits) {
  final byId = limits == null || limits.isNullish
      ? undefined
      : limits[scale.id].raw;
  if (jsTruthy(byId)) return ScaleLimits(byId);
  // `limits[scale.axis]`: the key of the axis class of the host (row
  // `adapt-axis-classes`).
  final axisKey = switch (scale.axis) {
    XAxis() => 'x',
    YAxis() => 'y',
    RAxis() => 'r',
    _ => null,
  };
  // DIVERGES(zoom): adapt-axis-classes, the key of the axis class.
  final byAxis = limits == null || limits.isNullish || axisKey == null
      ? undefined
      : limits[axisKey].raw;
  if (jsTruthy(byAxis)) return ScaleLimits(byAxis);
  return const ScaleLimits(emptyObject);
}

/// scale.types.ts:69 `getLimit(state, scale, scaleLimits, prop, fallback)`:
/// the limit [prop] (`'min'` or `'max'`) of [scaleLimits], the original
/// limit for `'original'`, or [fallback].
///
/// The result is a number: `jsToNumber` converts a numeric string, which
/// upstream gives as it is.
// DIVERGES(zoom): js-semantics-numeric-limits, a double limit.
double _getLimit(
  State state,
  Scale scale,
  ScaleLimits scaleLimits,
  String prop,
  double fallback,
) {
  var limit = jsGet(scaleLimits.raw, prop);
  if (limit == 'original') {
    final limits = state.originalScaleLimits[scale.id]!;
    final original = prop == 'min' ? limits.min : limits.max;
    if (isNumber(original.options)) {
      return jsToNumber(original.options);
    }

    if (!isNullOrUndef(original.options)) {
      final parsed = scale.parse(original.options);
      if (isNumber(parsed)) {
        return jsToNumber(parsed);
      }
    }

    // A null scale is the absent property of upstream: undefined.
    limit = original.scale ?? undefined;
  }
  return jsToNumber(valueOrDefault(limit, fallback));
}

/// scale.types.ts:89 `linearRange(scale, pixel0, pixel1)`.
ScaleRange _linearRange(Scale scale, double pixel0, double pixel1) {
  final v0 = scale.getValueForPixel(pixel0) ?? scale.min;
  final v1 = scale.getValueForPixel(pixel1) ?? scale.max;
  return (min: math.min(v0, v1), max: math.max(v0, v1));
}

/// The limits `{ min: 'original', max: 'original' }` of
/// scale.types.ts:109. Nothing writes into them.
const ScaleLimits _origLimits = ScaleLimits(<String, Object?>{
  'min': 'original',
  'max': 'original',
});

/// scale.types.ts:98 `fixRange(range, { min, max, minLimit, maxLimit },
/// state, scale)`.
ScaleRange _fixRange(
  double range,
  ({double min, double max, double minLimit, double maxLimit}) bounds,
  State state,
  Scale scale,
) {
  var (:min, :max, :minLimit, :maxLimit) = bounds;
  final offset = (range - max + min) / 2;
  min -= offset;
  max += offset;

  // In case the values are really close to the original values, use the
  // original values.
  final origMin = _getLimit(
    state,
    scale,
    _origLimits,
    'min',
    double.negativeInfinity,
  );
  final origMax = _getLimit(state, scale, _origLimits, 'max', double.infinity);

  final epsilon = range / 1e6;
  if (almostEquals(min, origMin, epsilon)) {
    min = origMin;
  }
  if (almostEquals(max, origMax, epsilon)) {
    max = origMax;
  }

  // Apply limits
  if (min < minLimit) {
    min = minLimit;
    max = math.min(minLimit + range, maxLimit);
  } else if (max > maxLimit) {
    max = maxLimit;
    min = math.max(maxLimit - range, minLimit);
  }

  return (min: min, max: max);
}

/// scale.types.ts:133 `updateRange(scale, { min, max }, limits, zoom,
/// pan)`: writes the range [minMax] into the `min` and `max` options of
/// [scale], within the [limits]. [zoom] keeps the width of [minMax] (at
/// least `minRange`), else the width of the scale stays. [pan] stops at a
/// limit.
///
/// The result is true if the range of the scale changes, and true with no
/// change when the range is at a limit.
bool updateRange(
  Scale scale,
  ScaleRange minMax, [
  LimitOptions? limits,
  bool zoom = false,
  // The positional flags of the upstream signature: the zoom and pan
  // functions of an app call it as upstream does.
  // ignore: avoid_positional_boolean_parameters
  bool pan = false,
]) {
  final (:min, :max) = minMax;
  final state = getState(scale.chart);
  final scaleOpts = scale.options;

  final scaleLimits = _getScaleLimits(scale, limits);
  // DIVERGES(zoom): js-semantics-numeric-limits, a double minRange.
  final minRange = jsToNumber(valueOrDefault(scaleLimits.minRange, 0.0));
  final minLimit = _getLimit(
    state,
    scale,
    scaleLimits,
    'min',
    double.negativeInfinity,
  );
  final maxLimit = _getLimit(state, scale, scaleLimits, 'max', double.infinity);

  if (pan && (min < minLimit || max > maxLimit)) {
    // At limit: No change but return true to indicate no need to store the
    // delta.
    return true;
  }

  final scaleRange = scale.max - scale.min;
  final range = zoom ? math.max(max - min, minRange) : scaleRange;

  if (zoom && range == minRange && scaleRange <= minRange) {
    // At range limit: No change but return true to indicate no need to store
    // the delta.
    return true;
  }

  final newRange = _fixRange(
    range,
    (min: min, max: max, minLimit: minLimit, maxLimit: maxLimit),
    state,
    scale,
  );

  scaleOpts['min'] = newRange.min;
  scaleOpts['max'] = newRange.max;

  state.updatedScaleLimits[scale.id] = newRange;

  // return true if the scale range is changed
  return scale.parse(newRange.min) != scale.min ||
      scale.parse(newRange.max) != scale.max;
}

/// scale.types.ts:172 `zoomNumericalScale(scale, zoom, center, limits)`.
bool _zoomNumericalScale(
  Scale scale,
  double zoom,
  Point center,
  LimitOptions limits,
) {
  final delta = _linearZoomDelta(scale, zoom, center);
  final newRange = (min: scale.min + delta.min, max: scale.max - delta.max);
  return updateRange(scale, newRange, limits, true);
}

/// scale.types.ts:178 `zoomLogarithmicScale(scale, zoom, center, limits)`.
bool _zoomLogarithmicScale(
  Scale scale,
  double zoom,
  Point center,
  LimitOptions limits,
) {
  final newRange = _logarithmicZoomRange(scale, zoom, center);
  return updateRange(scale, newRange, limits, true);
}

/// scale.types.ts:183 `zoomRectNumericalScale(scale, from, to, limits)`.
bool _zoomRectNumericalScale(
  Scale scale,
  double from,
  double to,
  LimitOptions limits,
) {
  return updateRange(scale, _linearRange(scale, from, to), limits, true);
}

/// scale.types.ts:187 `integerChange(v)`: [v] rounded to a whole step of
/// at least one category, or 0.
double _integerChange(double v) => v == 0 || v.isNaN
    ? 0
    : v < 0
    ? math.min(v.roundToDouble(), -1)
    : math.max(v.roundToDouble(), 1);

/// scale.types.ts:190 `existCategoryFromMaxZoom(scale)`.
void _existCategoryFromMaxZoom(Scale scale) {
  final labels = scale.getLabels();
  final maxIndex = labels.length - 1;

  if (scale.min > 0) {
    scale.min -= 1;
  }
  if (scale.max < maxIndex) {
    scale.max += 1;
  }
}

/// scale.types.ts:202 `zoomCategoryScale(scale, zoom, center, limits)`.
bool _zoomCategoryScale(
  Scale scale,
  double zoom,
  Point center,
  LimitOptions limits,
) {
  final delta = _linearZoomDelta(scale, zoom, center);
  if (scale.min == scale.max && zoom < 1) {
    _existCategoryFromMaxZoom(scale);
  }
  final newRange = (
    min: scale.min + _integerChange(delta.min),
    max: scale.max - _integerChange(delta.max),
  );

  return updateRange(scale, newRange, limits, true);
}

/// scale.types.ts:212 `scaleLength(scale)`.
double _scaleLength(Scale scale) {
  return scale.isHorizontal() ? scale.width : scale.height;
}

/// scale.types.ts:216 `panCategoryScale(scale, delta, limits)`.
bool _panCategoryScale(Scale scale, double delta, LimitOptions limits) {
  final labels = scale.getLabels();
  final lastLabelIndex = (labels.length - 1).toDouble();
  var min = scale.min;
  var max = scale.max;
  // The visible range. Ticks can be skipped, and thus not reliable.
  final range = math.max<double>(max - min, 1);
  // How many pixels of delta is required before making a step. stepSize, but
  // limited to max 1/10 of the scale length.
  // Intentionally kept fractional.
  final stepDelta = _scaleLength(scale) / math.max<double>(range, 10);
  final stepSize = (delta / stepDelta).abs().roundToDouble();
  // `let applied`: `Boolean(undefined)` is false.
  var applied = false;
  if (delta < -stepDelta) {
    max = math.min(max + stepSize, lastLabelIndex);
    min = range == 1 ? max : max - range;
    applied = max == lastLabelIndex;
  } else if (delta > stepDelta) {
    min = math.max(0, min - stepSize);
    max = range == 1 ? min : min + range;
    applied = min == 0;
  }

  return updateRange(scale, (min: min, max: max), limits) || applied;
}

/// scale.types.ts:240 `OFFSETS`: the pan offset of the `round` unit of a
/// time scale, in milliseconds.
///
/// The host holds the unit as the enum `TimeUnit` (row
/// `adapt-host-time-unit`). A value that is not a unit reads `undefined`,
/// so the sum with the scale bound is NaN.
// DIVERGES(zoom): adapt-host-time-unit, the enum of the host.
double _offsets(Object? round) => switch (round) {
  TimeUnit.millisecond => 0,
  TimeUnit.second => 500, // 500 ms
  TimeUnit.minute => 30 * 1000.0, // 30 s
  TimeUnit.hour => 30 * 60 * 1000.0, // 30 m
  TimeUnit.day => 12 * 60 * 60 * 1000.0, // 12 h
  TimeUnit.week => 3.5 * 24 * 60 * 60 * 1000, // 3.5 d
  TimeUnit.month => 15 * 24 * 60 * 60 * 1000.0, // 15 d
  TimeUnit.quarter => 60 * 24 * 60 * 60 * 1000.0, // 60 d
  TimeUnit.year => 182 * 24 * 60 * 60 * 1000.0, // 182 d
  _ => double.nan,
};

/// scale.types.ts:252 `panNumericalScale(scale, delta, limits, canZoom)`.
bool _panNumericalScale(
  Scale scale,
  double delta,
  LimitOptions limits, [
  bool canZoom = false,
]) {
  final prevStart = scale.min;
  final prevEnd = scale.max;
  var offset = 0.0;
  if (_isTimeScale(scale)) {
    // scale.options.time?.round
    final time = scale.options['time'];
    final round = isNullOrUndef(time) ? undefined : jsGet(time, 'round');
    offset = jsTruthy(round) ? _offsets(round) : 0;
  }
  final newMin = scale.getValueForPixel(
    scale.getPixelForValue(prevStart + offset) - delta,
  );
  final newMax = scale.getValueForPixel(
    scale.getPixelForValue(prevEnd + offset) - delta,
  );
  if (_isNotNumber(newMin) || _isNotNumber(newMax)) {
    // NaN can happen for 0-dimension scales (either because they were
    // configured with min === max or because the chart has 0 plottable area).
    return true;
  }
  return updateRange(
    scale,
    (min: newMin!, max: newMax!),
    limits,
    canZoom,
    true,
  );
}

/// scale.types.ts:269 `panNonLinearScale(scale, delta, limits)`.
bool _panNonLinearScale(Scale scale, double delta, LimitOptions limits) {
  return _panNumericalScale(scale, delta, limits, true);
}

/// scale.types.ts:273 `zoomFunctions`: the [ZoomFunction] of each scale
/// type. `default` serves a type without an entry.
final Map<String, ZoomFunction> zoomFunctions = {
  'category': _zoomCategoryScale,
  'default': _zoomNumericalScale,
  'logarithmic': _zoomLogarithmicScale,
};

/// scale.types.ts:279 `zoomRectFunctions`: the [ZoomRectFunction] of each
/// scale type. `default` serves a type without an entry.
final Map<String, ZoomRectFunction> zoomRectFunctions = {
  'default': _zoomRectNumericalScale,
};

/// scale.types.ts:283 `panFunctions`: the [PanFunction] of each scale type.
/// `default` serves a type without an entry.
final Map<String, PanFunction> panFunctions = {
  'category': _panCategoryScale,
  'default': _panNumericalScale,
  'logarithmic': _panNonLinearScale,
  'timeseries': _panNonLinearScale,
};
