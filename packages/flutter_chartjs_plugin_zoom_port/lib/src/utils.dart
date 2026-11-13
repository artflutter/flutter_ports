// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/utils.ts (MIT, chartjs-plugin-zoom contributors).

/// The helpers of the plugin: the modifier keys, the directions of a mode,
/// the debounce of the wheel zoom and the scales of a zoom or a pan.
///
/// A user function of the options has its typedef type and gets a direct
/// call (Zoom ADR 0004).
library;

import 'dart:async';

import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show
        CartesianAxis,
        Chart,
        NativeEvent,
        Scale,
        ScaleAxis,
        XAxis,
        YAxis,
        undefined;
import 'package:flutter_chartjs_port/helpers.dart'
    show isNullOrUndef, valueOrDefault;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsGet, jsObjectKeys, jsTruthy;

/// utils.ts:5 `eventKey(key)`: the flag ``event[`${key}Key`]`` of the
/// modifier [key] of [event]: the field of the [ModifierKey].
///
/// Another value names no property of the event: its `undefined` is false.
// DIVERGES(zoom): adapt-zoom-option-enums, the enum value.
bool _eventKey(Object? key, NativeEvent event) =>
    ModifierKey.of(key)?.pressedIn(event) ?? false;

/// utils.ts:7 `getModifierKey(opts)`: the `modifierKey` of the drag or pan
/// options [opts] when they are enabled, else `undefined`.
Object? getModifierKey(Object? opts) =>
    !isNullOrUndef(opts) &&
        jsTruthy(jsGet(opts, 'enabled')) &&
        jsTruthy(jsGet(opts, 'modifierKey'))
    ? jsGet(opts, 'modifierKey')
    : undefined;

/// utils.ts:9 `keyPressed(key, event)`: whether a modifier [key] is set and
/// pressed in [event].
///
/// Upstream gives `key && event[...]`, and each caller tests its truthiness.
bool keyPressed(Object? key, NativeEvent event) =>
    jsTruthy(key) && _eventKey(key, event);

/// utils.ts:11 `keyNotPressed(key, event)`: whether a modifier [key] is set
/// and not pressed in [event].
///
/// Upstream gives `key && !event[...]`, and each caller tests its
/// truthiness.
bool keyNotPressed(Object? key, NativeEvent event) =>
    jsTruthy(key) && !_eventKey(key, event);

/// utils.ts:14 `directionEnabled(mode, dir, chart)`: whether the [Mode] or
/// the `ModeFn` [mode] has the direction [dir] (`'x'` or `'y'`).
///
/// `undefined` enables each direction. A [ModeFn] gets `{ chart }` and
/// gives a [Mode] (Zoom ADR 0004). Another value of [mode] enables nothing.
// DIVERGES(zoom): adapt-zoom-option-enums, the fields of the mode.
bool directionEnabled(Object? mode, String dir, Chart chart) {
  if (identical(mode, undefined)) {
    return true;
  } else if (mode is ModeFn) {
    // DIVERGES(zoom): adapt-native-callbacks, a direct call of the ModeFn.
    return mode((chart: chart)).hasAxis(dir);
  }

  return Mode.of(mode)?.hasAxis(dir) ?? false;
}

/// utils.ts:58 `EnabledDirections`: the enabled state of the `x` and `y`
/// directions. `convertOverScaleMode` changes it.
final class _Directions({required var bool x, required var bool y}) {
  /// `enabled[axis]` for the `axis` of a scale, a class of the host (row
  /// `adapt-axis-classes`). Another axis (`RAxis`) gives `undefined`
  /// upstream, which is false.
  bool operator [](ScaleAxis axis) => switch (axis) {
    XAxis() => x,
    YAxis() => y,
    _ => false,
  };

  /// `enabled[axis] = value` for [XAxis] and [YAxis].
  void operator []=(CartesianAxis axis, bool value) {
    if (axis is XAxis) {
      x = value;
    } else {
      y = value;
    }
  }
}

/// utils.ts:26 `directionsEnabled(mode, chart)`: the directions of the
/// [Mode] or the `ModeFn` [mode].
// DIVERGES(zoom): adapt-zoom-option-enums, the fields of the mode.
_Directions _directionsEnabled(Object? mode, Chart chart) {
  // DIVERGES(zoom): adapt-native-callbacks, a direct call of the ModeFn.
  final value = mode is ModeFn ? mode((chart: chart)) : Mode.of(mode);
  if (value != null) {
    return _Directions(x: value.usesX, y: value.usesY);
  }

  return _Directions(x: false, y: false);
}

/// utils.ts:37 `debounce(fn, delay)`: a function that runs [fn] [delay]
/// milliseconds after its last call.
///
/// The `setTimeout` of upstream is a [Timer]. `setTimeout` converts the
/// delay to a WebIDL `long`: its integer part, and 0 for `undefined`, NaN,
/// an infinity or a negative delay. Upstream also gives `delay` as the
/// result of the debounced function, which no caller reads.
void Function() debounce(void Function() fn, double? delay) {
  Timer? timeout;
  final milliseconds = delay == null || !delay.isFinite || delay < 0
      ? 0
      : delay.truncateToDouble().toInt();
  return () {
    timeout?.cancel();
    timeout = Timer(Duration(milliseconds: milliseconds), fn);
  };
}

/// The values of [scales] in the order of `Object.values`: the order of
/// `Object.keys` (seam H26), with the array index keys first.
List<Scale> _values(Map<String, Scale> scales) => [
  for (final id in jsObjectKeys(scales)) scales[id]!,
];

/// utils.ts:46 `getScaleUnderPoint({ x, y }, chart)`: the first scale of
/// [chart] whose box holds [point], or `null`.
Scale? getScaleUnderPoint(Point point, Chart chart) {
  final (:x, :y) = point;
  final scales = chart.scales;
  final scaleIds = jsObjectKeys(scales);
  for (var i = 0; i < scaleIds.length; i++) {
    final scale = scales[scaleIds[i]]!;
    if (y >= scale.top &&
        y <= scale.bottom &&
        x >= scale.left &&
        x <= scale.right) {
      return scale;
    }
  }
  return null;
}

/// utils.ts:60 `convertOverScaleMode(chart, overScaleMode, scaleEnabled,
/// enabled)`: the deprecated `overScaleMode` as a `scaleMode`.
void _convertOverScaleMode(
  Chart chart,
  Object? overScaleMode,
  _Directions scaleEnabled,
  _Directions enabled,
) {
  if (!jsTruthy(overScaleMode)) {
    return;
  }

  final overScaleEnabled = _directionsEnabled(overScaleMode, chart);
  // DIVERGES(zoom): adapt-axis-classes, the axis classes of the host.
  for (final axis in const <CartesianAxis>[XAxis(), YAxis()]) {
    if (overScaleEnabled[axis]) {
      scaleEnabled[axis] = enabled[axis];
      enabled[axis] = false;
    }
  }
}

/// utils.ts:79 `getEnabledScales(chart, enabled)`: the scales of [chart]
/// whose axis is [enabled].
List<Scale> _getEnabledScales(Chart chart, _Directions enabled) {
  final enabledScales = <Scale>[];

  for (final scaleItem in _values(chart.scales)) {
    if (enabled[scaleItem.axis]) {
      enabledScales.add(scaleItem);
    }
  }

  // `enabledScales || Object.values(chart.scales)`: an array is truthy, so
  // upstream gives `enabledScales`.
  return enabledScales;
}

/// utils.ts:96 `getEnabledScalesByPoint(options, point, chart)`.
///
/// Evaluate the chart's mode, scaleMode, and overScaleMode properties to
/// determine which axes are eligible for scaling.
/// options.overScaleMode can be a function if user want zoom only one scale
/// of many for example.
///
/// [options] is the raw value of the zoom or the pan options.
List<Scale> getEnabledScalesByPoint(Object? options, Point point, Chart chart) {
  // const { mode = 'xy', scaleMode, overScaleMode } = options || {}
  final object = jsTruthy(options) ? options : emptyObject;
  final mode = valueOrDefault<Object?>(jsGet(object, 'mode'), Mode.xy);
  final scaleMode = jsGet(object, 'scaleMode');
  final overScaleMode = jsGet(object, 'overScaleMode');
  final scale = getScaleUnderPoint(point, chart);

  final enabled = _directionsEnabled(mode, chart);
  final scaleEnabled = _directionsEnabled(scaleMode, chart);

  // Convert deprecated overScaleEnabled to new scaleEnabled.
  _convertOverScaleMode(chart, overScaleMode, scaleEnabled, enabled);

  if (scale != null && scaleEnabled[scale.axis]) {
    return [scale];
  }

  return _getEnabledScales(chart, enabled);
}
