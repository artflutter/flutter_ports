// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/plugin.ts (MIT, chartjs-plugin-zoom contributors).

/// The plugin object [zoomPlugin]: its hooks start and stop the gestures and
/// the listeners of a chart, cancel the chart events of a drag or a pan, and
/// draw the drag rectangle.
///
/// The plugin object is a typed `Plugin` of the host (Chart.js ADR 0108, Zoom
/// ADR 0003 item 9), with the upstream keys in the upstream order. Each hook
/// is a private function of the hook type `(chart, args, options)`: it takes
/// the chart as an `Object`, because the hook type names the internal chart
/// interface of the host, and narrows it once with `chart as Chart`. The
/// options of a hook are the plugin options resolver of the host, read
/// through the facade [ZoomPluginOptions].
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_plugin_zoom_port/src/core.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/defaults.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/gestures.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/handlers.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/options.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/scale.types.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/upstream.dart';
import 'package:flutter_chartjs_port/chartjs.dart'
    show
        CancelableHookArgs,
        Chart,
        EventHookArgs,
        JsObjectFace,
        Plugin,
        PluginHookArgs,
        UpdateHookArgs,
        undefined;
import 'package:flutter_chartjs_port/helpers.dart' show isNullOrUndef;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsToNumber, jsTruthy;

/// The CSS color `rgba(225,225,225,0.3)` of plugin.ts:40: the default fill
/// of the drag rectangle.
// DIVERGES(zoom): adapt-native-colors, Color values, not CSS strings.
const Color _defaultBackgroundColor = Color.fromRGBO(225, 225, 225, 0.3);

/// The CSS color `rgba(225,225,225)` of plugin.ts:45: the default border of
/// the drag rectangle.
const Color _defaultBorderColor = Color.fromRGBO(225, 225, 225, 1);

/// plugin.ts:23 `draw(chart, caller, options)`: draws the drag rectangle of
/// [chart] when [caller] is the hook of the `drawTime` of the drag options
/// and a drag runs.
///
/// The colors pass to the canvas as they are: a CSS string or a `Color`.
/// `lineWidth` takes the number of the border width (`jsToNumber`): the
/// value reaches only the pixels (Chart.js ADR 0034).
void draw(Chart chart, String caller, ZoomPluginOptions options) {
  // options.zoom?.drag
  final zoomOptions = options.zoom;
  final dragOptions = zoomOptions.isNullish
      ? const DragOptions(undefined)
      : zoomOptions.drag;
  final state = getState(chart);
  final dragStart = state.dragStart;
  final dragEnd = state.dragEnd;

  // dragOptions?.drawTime !== caller
  final drawTime = dragOptions.isNullish ? undefined : dragOptions.drawTime;
  if (drawTime != caller || dragStart == null || dragEnd == null) {
    return;
  }
  final DragRect(:left, :top, :width, :height) = computeDragRect(
    chart,
    zoomOptions.isNullish ? undefined : zoomOptions.mode,
    (dragStart: dragStart, dragEnd: dragEnd),
    dragOptions.maintainAspectRatio,
  );
  final ctx = chart.ctx!;

  final backgroundColor = dragOptions.backgroundColor;
  ctx
    ..save()
    ..beginPath()
    ..fillStyle = jsTruthy(backgroundColor)
        ? backgroundColor
        : _defaultBackgroundColor
    ..fillRect(left, top, width, height);

  if (jsTruthy(dragOptions.borderWidth)) {
    final borderColor = dragOptions.borderColor;
    ctx
      ..lineWidth = jsToNumber(dragOptions.borderWidth)
      ..strokeStyle = jsTruthy(borderColor) ? borderColor : _defaultBorderColor
      ..strokeRect(left, top, width, height);
  }
  ctx.restore();
}

// plugin.ts:51 `bindApi(chart)` writes the ten methods of the zoom API into
// the chart at `start`. Dart cannot add a member to an object: the extension
// `ZoomChart` of index.dart gives the methods, as `declare module` of
// src/index.ts:19-34 types them.
// DIVERGES(zoom): adapt-chart-methods-extension, an extension, no bindApi.

/// `Object.prototype.hasOwnProperty.call(object, key)`: whether [object]
/// owns the property [key]. A resolver and a typed object answer through
/// their face. `null` and `undefined` throw the `TypeError` of `ToObject`,
/// and another primitive owns no property.
bool _hasOwnProperty(Object? object, String key) => switch (object) {
  final JsObjectFace face => face.jsHas(key),
  final Map<Object?, Object?> map => map.containsKey(key),
  _ when isNullOrUndef(object) => throw TypeError(),
  _ => false,
};

/// plugin.ts:71 `start(chart, _args, options)`: keeps the options in the
/// state of [chart], warns about the removed options and starts the
/// gestures.
void _start(Object chart, PluginHookArgs _, Object options) {
  chart as Chart;
  final pluginOptions = ZoomPluginOptions(options);
  getState(chart).options = pluginOptions;

  // console.warn of upstream: the host writes its warnings with print too
  // (seam H12).
  if (_hasOwnProperty(pluginOptions.zoom.raw, 'enabled')) {
    // A warning to the developer, as console.warn.
    // ignore: avoid_print
    print(
      'The option `zoom.enabled` is no longer supported. Please use '
      '`zoom.wheel.enabled`, `zoom.drag.enabled`, or `zoom.pinch.enabled`.',
    );
  }
  if (_hasOwnProperty(pluginOptions.zoom.raw, 'overScaleMode') ||
      _hasOwnProperty(pluginOptions.pan.raw, 'overScaleMode')) {
    // A warning to the developer, as console.warn.
    // ignore: avoid_print
    print(
      'The option `overScaleMode` is deprecated. Please use `scaleMode` '
      'instead (and update `mode` as desired).',
    );
  }

  startGestures(chart, pluginOptions);

  // bindApi(chart): the extension ZoomChart of index.dart.
}

/// plugin.ts:94 `beforeEvent(chart, {event})`: cancels each chart event
/// while a pan or a drag runs, and the next `click` or `mouseup` after a
/// drag or a pan. The result `false` cancels the event, Dart `null` is the
/// `undefined` of upstream.
bool? _beforeEvent(Object chart, EventHookArgs args, Object _) {
  final event = args.event;
  final state = getState(chart);
  if (isZoomingOrPanningState(state)) {
    // cancel any event handling while panning or dragging
    return false;
  }
  // cancel the next click or mouseup after drag or pan
  if (event!.type == 'click' || event.type == 'mouseup') {
    if (state.filterNextClick) {
      state.filterNextClick = false;
      return false;
    }
  }
  return null;
}

/// plugin.ts:112 `beforeUpdate(chart, _args, options)`: keeps the new
/// options, restarts the gestures when their options changed, and adds the
/// listeners.
void _beforeUpdate(Object chart, UpdateHookArgs _, Object options) {
  chart as Chart;
  final pluginOptions = ZoomPluginOptions(options);
  final state = getState(chart);
  final previousOptions = state.options;
  state.options = pluginOptions;

  // Gesture handling needs to be restarted when certain options change.
  if (gestureOptionsChanged(previousOptions, pluginOptions)) {
    stopGestures(chart);
    startGestures(chart, pluginOptions);
  }

  addListeners(chart, pluginOptions);
}

/// plugin.ts:126 `beforeDatasetsDraw(chart, _args, options)`.
void _beforeDatasetsDraw(Object chart, CancelableHookArgs _, Object options) {
  draw(chart as Chart, 'beforeDatasetsDraw', ZoomPluginOptions(options));
}

/// plugin.ts:130 `afterDatasetsDraw(chart, _args, options)`.
void _afterDatasetsDraw(Object chart, PluginHookArgs _, Object options) {
  draw(chart as Chart, 'afterDatasetsDraw', ZoomPluginOptions(options));
}

/// plugin.ts:134 `beforeDraw(chart, _args, options)`.
void _beforeDraw(Object chart, CancelableHookArgs _, Object options) {
  draw(chart as Chart, 'beforeDraw', ZoomPluginOptions(options));
}

/// plugin.ts:138 `afterDraw(chart, _args, options)`.
void _afterDraw(Object chart, PluginHookArgs _, Object options) {
  draw(chart as Chart, 'afterDraw', ZoomPluginOptions(options));
}

/// plugin.ts:142 `stop(chart)`: removes the listeners, the gestures and the
/// state of [chart].
void _stop(Object chart, PluginHookArgs _, Object _) {
  chart as Chart;
  removeListeners(chart);

  stopGestures(chart);
  removeState(chart);
}

/// plugin.ts:64 the default export: the plugin `zoom`.
///
/// Register it for all charts with `Chart.register([zoomPlugin])`, or give
/// it to one chart in the `plugins` list of its raw config. The options of a
/// chart are `options.plugins.zoom` ([ZoomPluginOptions]).
///
/// The keys are those of upstream, in the upstream order. `version` (the
/// `version` of the upstream `package.json`,
/// [chartjsPluginZoomPackageVersion]), `panFunctions`, `zoomFunctions` and
/// `zoomRectFunctions` are extras of the typed plugin. `defaults` is the
/// mutable Map of the zoom defaults. The plugin opts into the data-only
/// updates of the host (`supportsDataUpdates`): its hooks change no option
/// and no data.
// DIVERGES(zoom): adapt-typed-plugin-object, a typed Plugin with extras.
final Plugin zoomPlugin = Plugin(supportsDataUpdates: true)
  ..id = 'zoom'
  ..jsWrite('version', chartjsPluginZoomPackageVersion)
  ..defaults = defaults
  ..start = _start
  ..beforeEvent = _beforeEvent
  ..beforeUpdate = _beforeUpdate
  ..beforeDatasetsDraw = _beforeDatasetsDraw
  ..afterDatasetsDraw = _afterDatasetsDraw
  ..beforeDraw = _beforeDraw
  ..afterDraw = _afterDraw
  ..stop = _stop
  ..jsWrite('panFunctions', panFunctions)
  ..jsWrite('zoomFunctions', zoomFunctions)
  ..jsWrite('zoomRectFunctions', zoomRectFunctions);
