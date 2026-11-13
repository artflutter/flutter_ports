// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/core.ts (MIT, chartjs-plugin-zoom contributors).

/// The zoom and pan API: [zoom], [zoomRect], [zoomScale], [resetZoom],
/// [pan], and the reads of the zoom state.
///
/// Each loop over the scales of a chart takes the order of `Object.keys`
/// (`jsObjectKeys`, seam H26): JavaScript puts the array index keys first,
/// and a Dart `Map` keeps the insertion order. The `min` and `max` options of
/// a scale are written and deleted through the face of the scale options
/// (`scale.options['min'] = value`, `jsDelete`, seam H14).
library;

import 'dart:math' as math;

import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/scale.types.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/utils.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Chart, Scale;
import 'package:flutter_chartjs_port/helpers.dart'
    show isNumber, sign, valueOrDefault;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsObjectKeys, jsRound, jsToNumber, jsTruthy;

/// The values of [scales] in the order of `Object.values`: the order of
/// `Object.keys`, with the array index keys first.
List<Scale> _values(Map<String, Scale> scales) => [
  for (final id in jsObjectKeys(scales)) scales[id]!,
];

/// core.ts:9 `shouldUpdateScaleLimits(scale, originalScaleLimits,
/// updatedScaleLimits)`: whether the plugin did not write the range of
/// [scale], so that its limits are the original limits.
bool _shouldUpdateScaleLimits(
  Scale scale,
  OriginalScaleLimits originalScaleLimits,
  UpdatedScaleLimits updatedScaleLimits,
) {
  final id = scale.id;
  final options = scale.options;
  final min = options.min;
  final max = options.max;
  if (!originalScaleLimits.containsKey(id) ||
      !updatedScaleLimits.containsKey(id)) {
    return true;
  }
  final previous = updatedScaleLimits[id]!;
  return previous.min != min || previous.max != max;
}

/// core.ts:25 `removeMissingScales(limits, scales)`: deletes the entries of
/// the scales that [scales] no longer has.
void _removeMissingScales(
  Map<String, Object> limits,
  Map<String, Scale> scales,
) {
  limits.removeWhere((key, _) => !scales.containsKey(key));
}

/// core.ts:33 `storeOriginalScaleLimits(chart, state)`.
OriginalScaleLimits _storeOriginalScaleLimits(Chart chart, State state) {
  final scales = chart.scales;
  final originalScaleLimits = state.originalScaleLimits;
  final updatedScaleLimits = state.updatedScaleLimits;

  for (final scale in _values(scales)) {
    if (_shouldUpdateScaleLimits(
      scale,
      originalScaleLimits,
      updatedScaleLimits,
    )) {
      originalScaleLimits[scale.id] = (
        min: OriginalLimit(scale: scale.min, options: scale.options.min),
        max: OriginalLimit(scale: scale.max, options: scale.options.max),
      );
    }
  }

  _removeMissingScales(originalScaleLimits, scales);
  _removeMissingScales(updatedScaleLimits, scales);
  return originalScaleLimits;
}

/// `chart.update(transition)` of the five update calls of core.ts (:90,
/// :120, :136, :156, :233): `chart.updateRanges(transition)` of the host when
/// the option `rangeOnlyUpdates` is on (Chart.js ADR 0111). The zoom
/// functions write only `min` and `max` through the views of the scale
/// options, and the fields `min` and `max` of a category scale, which the
/// layout of both paths computes again. The host takes `update` when one of
/// its checks fails. [state] has the options of the last `beforeUpdate`: the
/// read is a cache hit of the view.
// DIVERGES(zoom): adapt-range-only-updates, the opt-in range update.
void _updateChart(Chart chart, State state, String transition) {
  if (state.options.rangeOnlyUpdates) {
    chart.updateRanges(transition);
  } else {
    chart.update(transition);
  }
}

/// core.ts:51 `doZoom(scale, amount, center, limits)`.
void _doZoom(Scale scale, double amount, Point center, LimitOptions limits) {
  final fn = zoomFunctions[scale.type] ?? zoomFunctions['default'];
  fn?.call(scale, amount, center, limits);
}

/// core.ts:56 `doZoomRect(scale, from, to, limits)`.
void _doZoomRect(Scale scale, double from, double to, LimitOptions limits) {
  final fn = zoomRectFunctions[scale.type] ?? zoomRectFunctions['default'];
  fn?.call(scale, from, to, limits);
}

/// core.ts:61 `getCenter(chart)`: the center of the chart area.
Point _getCenter(Chart chart) {
  final ca = chart.chartArea!;
  return (x: (ca.left + ca.right) / 2, y: (ca.top + ca.bottom) / 2);
}

/// core.ts:69 `zoom(chart, amount, transition, trigger)`: zooms the enabled
/// scales of [chart] by [amount] around its focal point, then updates the
/// chart with the mode [transition] and calls `onZoom`.
void zoom(
  Chart chart,
  ZoomAmount amount, [
  String transition = 'none',
  ZoomTrigger trigger = ZoomTrigger.api,
]) {
  // DIVERGES(zoom): adapt-amount-classes, no typeof amount === 'number'.
  final x = amount.x;
  final y = amount.y;
  final focalPoint = amount.focalPoint ?? _getCenter(chart);
  final state = getState(chart);
  // const { options: { limits = {}, zoom: zoomOptions } } = state
  final options = state.options;
  final limits = LimitOptions(valueOrDefault(options.limits.raw, emptyObject));
  final zoomOptions = options.zoom;

  _storeOriginalScaleLimits(chart, state);

  final xEnabled = x != 1;
  final yEnabled = y != 1;
  final enabledScales = getEnabledScalesByPoint(zoomOptions, focalPoint, chart);

  for (final scale in enabledScales) {
    if (scale.isHorizontal() && xEnabled) {
      _doZoom(scale, x, focalPoint, limits);
    } else if (!scale.isHorizontal() && yEnabled) {
      _doZoom(scale, y, focalPoint, limits);
    }
  }

  _updateChart(chart, state, transition);

  // zoomOptions?.onZoom?.({ chart, trigger })
  if (!zoomOptions.isNullish) {
    zoomOptions.onZoom?.call((chart: chart, trigger: trigger));
  }
}

/// core.ts:95 `zoomRect(chart, p0, p1, transition, trigger)`: zooms the
/// scales of [chart] to the rectangle of the pixels [p0] and [p1].
void zoomRect(
  Chart chart,
  Point p0,
  Point p1, [
  String transition = 'none',
  ZoomTrigger trigger = ZoomTrigger.api,
]) {
  final state = getState(chart);
  // const { options: { limits = {}, zoom: zoomOptions = {} } } = state
  final options = state.options;
  final limits = LimitOptions(valueOrDefault(options.limits.raw, emptyObject));
  final zoomOptions = ZoomOptions(
    valueOrDefault(options.zoom.raw, emptyObject),
  );
  // const { mode = 'xy' } = zoomOptions
  final mode = valueOrDefault<Object?>(zoomOptions.mode, Mode.xy);

  _storeOriginalScaleLimits(chart, state);
  final xEnabled = directionEnabled(mode, 'x', chart);
  final yEnabled = directionEnabled(mode, 'y', chart);

  for (final scale in _values(chart.scales)) {
    if (scale.isHorizontal() && xEnabled) {
      _doZoomRect(scale, p0.x, p1.x, limits);
    } else if (!scale.isHorizontal() && yEnabled) {
      _doZoomRect(scale, p0.y, p1.y, limits);
    }
  }

  _updateChart(chart, state, transition);

  // zoomOptions.onZoom?.({ chart, trigger })
  zoomOptions.onZoom?.call((chart: chart, trigger: trigger));
}

/// core.ts:125 `zoomScale(chart, scaleId, range, transition, trigger)`:
/// zooms the scale [scaleId] of [chart] to [range].
///
/// An unknown [scaleId] throws a `TypeError`, as upstream reads a property
/// of `undefined`.
void zoomScale(
  Chart chart,
  String scaleId,
  ScaleRange range, [
  String transition = 'none',
  ZoomTrigger trigger = ZoomTrigger.api,
]) {
  final state = getState(chart);
  _storeOriginalScaleLimits(chart, state);
  final scale = chart.scales[scaleId]!;
  updateRange(scale, range, null, true);
  _updateChart(chart, state, transition);

  // state.options.zoom?.onZoom?.({ chart, trigger })
  final zoomOptions = state.options.zoom;
  if (!zoomOptions.isNullish) {
    zoomOptions.onZoom?.call((chart: chart, trigger: trigger));
  }
}

/// core.ts:141 `resetZoom(chart, transition)`: puts back the original `min`
/// and `max` options of each scale of [chart], then calls `onZoomComplete`.
void resetZoom(Chart chart, [String transition = 'default']) {
  final state = getState(chart);
  final originalScaleLimits = _storeOriginalScaleLimits(chart, state);

  for (final scale in _values(chart.scales)) {
    final scaleOptions = scale.options;
    final original = originalScaleLimits[scale.id];
    if (original != null) {
      scaleOptions['min'] = original.min.options;
      scaleOptions['max'] = original.max.options;
    } else {
      scaleOptions
        ..jsDelete('min')
        ..jsDelete('max');
    }
    state.updatedScaleLimits.remove(scale.id);
  }
  _updateChart(chart, state, transition);

  // state.options.zoom?.onZoomComplete?.({ chart })
  final zoomOptions = state.options.zoom;
  if (!zoomOptions.isNullish) {
    zoomOptions.onZoomComplete?.call((chart: chart));
  }
}

/// core.ts:161 `getOriginalRange(state, scaleId)`: the width of the original
/// range of the scale [scaleId], or `null` for `undefined`.
///
/// The JavaScript `-` converts a numeric string option, as `jsToNumber`
/// does.
double? _getOriginalRange(State state, String scaleId) {
  final original = state.originalScaleLimits[scaleId];
  if (original == null) {
    return null;
  }
  final (:min, :max) = original;
  if (isNumber(max.options) && isNumber(min.options)) {
    return jsToNumber(max.options) - jsToNumber(min.options);
  }
  if (isNumber(max.scale) && isNumber(min.scale)) {
    return max.scale! - min.scale!;
  }
  return null;
}

/// core.ts:176 `getZoomLevel(chart)`: the zoom level of [chart], the
/// smallest level below 1, else the largest level, rounded to 2 decimals.
double getZoomLevel(Chart chart) {
  final state = getState(chart);
  var min = 1.0;
  var max = 1.0;
  for (final scale in _values(chart.scales)) {
    final origRange = _getOriginalRange(state, scale.id);
    if (jsTruthy(origRange)) {
      final level = jsRound((origRange! / (scale.max - scale.min)) * 100) / 100;
      min = math.min(min, level);
      max = math.max(max, level);
    }
  }
  return min < 1 ? min : max;
}

/// core.ts:191 `panScale(scale, delta, limits, state)`.
void _panScale(Scale scale, double delta, LimitOptions limits, State state) {
  final panDelta = state.panDelta;
  // Add possible cumulative delta from previous pan attempts where scale did
  // not change
  final stored = panDelta[scale.id];
  final storedDelta = jsTruthy(stored) ? stored! : 0.0;
  final total = sign(storedDelta) == sign(delta) ? delta + storedDelta : delta;
  final fn = panFunctions[scale.type] ?? panFunctions['default'];
  if (fn?.call(scale, total, limits) ?? false) {
    // The scale changed, reset cumulative delta
    panDelta[scale.id] = 0;
  } else {
    // The scale did not change, store cumulative delta
    panDelta[scale.id] = total;
  }
}

/// core.ts:210 `pan(chart, delta, enabledScales, transition)`: pans the
/// [enabledScales] of [chart] (each scale for `null`) by [delta] pixels,
/// then updates the chart with the mode [transition] and calls `onPan`.
void pan(
  Chart chart,
  PanAmount delta, [
  List<Scale>? enabledScales,
  String transition = 'none',
]) {
  // DIVERGES(zoom): adapt-amount-classes, no typeof delta === 'number'.
  final x = delta.x;
  final y = delta.y;
  final state = getState(chart);
  // const { options: { pan: panOptions, limits = {} } } = state
  final options = state.options;
  final panOptions = options.pan;
  final limits = LimitOptions(valueOrDefault(options.limits.raw, emptyObject));
  // const { onPan } = panOptions || {}
  final onPan = PanOptions(
    jsTruthy(panOptions.raw) ? panOptions.raw : emptyObject,
  ).onPan;

  _storeOriginalScaleLimits(chart, state);

  final xEnabled = x != 0;
  final yEnabled = y != 0;

  // `enabledScales || Object.values(chart.scales)`: an empty array is
  // truthy, so only an absent list takes the scales of the chart.
  final scales = enabledScales ?? _values(chart.scales);

  for (final scale in scales) {
    if (scale.isHorizontal() && xEnabled) {
      _panScale(scale, x, limits, state);
    } else if (!scale.isHorizontal() && yEnabled) {
      _panScale(scale, y, limits, state);
    }
  }

  _updateChart(chart, state, transition);

  // onPan?.({ chart })
  onPan?.call((chart: chart));
}

/// core.ts:238 `getInitialScaleBounds(chart)`: the original `min` and `max`
/// of each scale of [chart], by scale id. `null` is the `undefined` of an
/// absent bound.
Map<String, ({double? min, double? max})> getInitialScaleBounds(Chart chart) {
  final state = getState(chart);
  _storeOriginalScaleLimits(chart, state);
  final scaleBounds = <String, ({double? min, double? max})>{};
  for (final scaleId in jsObjectKeys(chart.scales)) {
    final (:min, :max) =
        state.originalScaleLimits[scaleId] ??
        (min: const OriginalLimit(), max: const OriginalLimit());
    scaleBounds[scaleId] = (min: min.scale, max: max.scale);
  }

  return scaleBounds;
}

/// core.ts:250 `getZoomedScaleBounds(chart)`: the range that the plugin
/// wrote into each scale of [chart], by scale id, or `null` (the
/// `undefined` of upstream) for a scale with no zoom.
Map<String, ScaleRange?> getZoomedScaleBounds(Chart chart) {
  final state = getState(chart);
  final scaleBounds = <String, ScaleRange?>{};
  for (final scaleId in jsObjectKeys(chart.scales)) {
    scaleBounds[scaleId] = state.updatedScaleLimits[scaleId];
  }

  return scaleBounds;
}

/// core.ts:260 `isZoomedOrPanned(chart)`: whether a scale of [chart] has
/// another range than its original range.
bool isZoomedOrPanned(Chart chart) {
  final scaleBounds = getInitialScaleBounds(chart);
  for (final scaleId in jsObjectKeys(chart.scales)) {
    final (min: originalMin, max: originalMax) = scaleBounds[scaleId]!;

    if (originalMin != null && chart.scales[scaleId]!.min != originalMin) {
      return true;
    }

    if (originalMax != null && chart.scales[scaleId]!.max != originalMax) {
      return true;
    }
  }

  return false;
}

/// core.ts:277 `isZoomingOrPanningState(state)`: whether a pan or a drag
/// runs.
bool isZoomingOrPanningState(State state) {
  return state.panning || state.dragging;
}

/// core.ts:281 `isZoomingOrPanning(chart)`: whether a pan or a drag of
/// [chart] runs.
bool isZoomingOrPanning(Chart chart) {
  final state = getState(chart);
  // From the perspective of outside callers, zooming and panning are still
  // active if we haven't yet cleared the next click.
  return isZoomingOrPanningState(state) || state.filterNextClick;
}
