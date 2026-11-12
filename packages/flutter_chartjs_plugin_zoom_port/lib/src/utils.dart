// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/utils.ts (MIT, chartjs-plugin-zoom contributors).

/// The helpers of the plugin: the modifier keys, the directions of a mode,
/// the debounce of the wheel zoom and the scales of a zoom or a pan.
///
/// The library also has [callUser], the JavaScript call of a user function
/// (Zoom ADR 0003, item 9). The public library does not export it.
library;

import 'dart:async';

import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show Chart, NativeEvent, Scale, undefined;
import 'package:flutter_chartjs_port/helpers.dart'
    show isNullOrUndef, valueOrDefault;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsCall, jsGet, jsObjectKeys, jsTruthy;

/// The call `f?.(context)` of a user function [f] with the one argument
/// [context], in the form of JavaScript: [f] is called with as many
/// arguments as it takes (`jsCall`). `null` and `undefined` skip the call
/// and give `undefined`.
///
/// A call site first tests [f] for the type of its typedef (`ModeFn`,
/// `ZoomCallback`, ...) and calls it directly. This function is the
/// fallback for a function of another type, for example a spy or a closure
/// with no parameter. A value that is not a function throws, as the
/// JavaScript call does.
Object? callUser(Object? f, Object context) =>
    isNullOrUndef(f) ? undefined : jsCall(f, [context]);

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

/// The result of a `ModeFn` [mode] for [chart]: a typed call for a [ModeFn],
/// else [callUser].
Object? _callMode(Function mode, Chart chart) =>
    mode is ModeFn ? mode((chart: chart)) : callUser(mode, (chart: chart));

/// utils.ts:14 `directionEnabled(mode, dir, chart)`: whether the [Mode] or
/// the `ModeFn` [mode] has the direction [dir] (`'x'` or `'y'`).
///
/// `undefined` enables each direction. A function gets `{ chart }`, and its
/// result must be a [Mode]: JavaScript calls `indexOf` on it, so another
/// value throws a `TypeError`. Another value of [mode] enables nothing.
// DIVERGES(zoom): adapt-zoom-option-enums, the fields of the mode.
bool directionEnabled(Object? mode, String dir, Chart chart) {
  if (identical(mode, undefined)) {
    return true;
  } else if (mode is Function) {
    final value = Mode.of(_callMode(mode, chart)) ?? (throw TypeError());
    return value.hasAxis(dir);
  }

  return Mode.of(mode)?.hasAxis(dir) ?? false;
}

/// utils.ts:58 `EnabledDirections`: the enabled state of the `x` and `y`
/// directions. `convertOverScaleMode` changes it.
final class _Directions {
  _Directions({required this.x, required this.y});

  bool x;
  bool y;

  /// `enabled[axis]` for the `axis` of a scale. Another axis (`'r'`) gives
  /// `undefined` upstream, which is false.
  bool operator [](String axis) => switch (axis) {
    'x' => x,
    'y' => y,
    _ => false,
  };

  /// `enabled[axis] = value` for `'x'` and `'y'`.
  void operator []=(String axis, bool value) {
    if (axis == 'x') {
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
  final value = Mode.of(mode is Function ? _callMode(mode, chart) : mode);
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
  for (final axis in const ['x', 'y']) {
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
