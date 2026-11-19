// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/plugin.ts (MIT, chartjs-plugin-zoom contributors).

/// The plugin object [zoomPlugin]: its hooks start and stop the gestures and
/// the listeners of a chart, cancel the chart events of a drag or a pan, and
/// draw the drag rectangle.
///
/// The plugin object is a native `ChartPlugin` of the host (Chart.js ADRs
/// 0144 and 0148), with the upstream keys in the upstream order. Each hook
/// is a private function of the hook type `(chart, args, options)`: it gets
/// the public `Chart` of the host and the merged [ZoomPluginOptions] of the
/// chart, with no cast and no read by name.
library;

import 'dart:ui';

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_plugin_zoom_port/src/state.dart';
import 'package:flutter_chartjs_port/chartjs.dart' hide defaults;

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
/// The colors are the `ChartPaint` values of the options, or the default
/// `Color` values.
void draw(Chart chart, DrawTime caller, ZoomPluginOptions options) {
  final dragOptions = options.zoom?.drag;
  final State(:dragStart, :dragEnd) = getState(chart);

  if (dragOptions?.drawTime != caller || dragStart == null || dragEnd == null) {
    return;
  }
  // `dragOptions` is not null: its drawTime is the caller.
  final drag = dragOptions!;
  final DragRect(:left, :top, :width, :height) = computeDragRect(
    chart,
    options.zoom?.mode,
    (dragStart: dragStart, dragEnd: dragEnd),
    drag.maintainAspectRatio,
  );
  final ctx = chart.ctx!
    ..save()
    ..beginPath()
    ..fillStyle = drag.backgroundColor ?? _defaultBackgroundColor
    ..fillRect(left, top, width, height);

  // `if (dragOptions.borderWidth)`: 0, NaN and an absent width draw no
  // border.
  final borderWidth = drag.borderWidth;
  if (borderWidth != null && borderWidth != 0 && !borderWidth.isNaN) {
    ctx
      ..lineWidth = borderWidth
      ..strokeStyle = drag.borderColor ?? _defaultBorderColor
      ..strokeRect(left, top, width, height);
  }
  ctx.restore();
}

// plugin.ts:51 `bindApi(chart)` writes the ten methods of the zoom API into
// the chart at `start`. Dart cannot add a member to an object: the extension
// `ZoomChart` of index.dart gives the methods, as `declare module` of
// src/index.ts:19-34 types them.
// DIVERGES(zoom): adapt-chart-methods-extension, an extension, no bindApi.

/// plugin.ts:71 `start(chart, _args, options)`: keeps the options in the
/// state of [chart], warns about the removed options and starts the
/// gestures.
void _start(Chart chart, PluginHookArgs _, ZoomPluginOptions options) {
  getState(chart).options = options;

  // `Object.prototype.hasOwnProperty.call(options.zoom, 'enabled')`: the
  // removed option `zoom.enabled` has no field of `ZoomOptions`, so a config
  // cannot give it, and the warning of upstream never prints.
  // DIVERGES(zoom): adapt-native-zoom-options, no field of a removed option.

  // `hasOwnProperty(options.zoom, 'overScaleMode') ||
  // hasOwnProperty(options.pan, 'overScaleMode')`: a set field. console.warn
  // of upstream: the host writes its warnings with print too (seam H12).
  if (options.zoom?.overScaleMode != null ||
      options.pan?.overScaleMode != null) {
    // A warning to the developer, as console.warn.
    // ignore: avoid_print
    print(
      'The option `overScaleMode` is deprecated. Please use `scaleMode` '
      'instead (and update `mode` as desired).',
    );
  }

  startGestures(chart, options);

  // bindApi(chart): the extension ZoomChart of index.dart.
}

/// plugin.ts:94 `beforeEvent(chart, {event})`: cancels each chart event
/// while a pan or a drag runs, and the next `click` or `mouseup` after a
/// drag or a pan. The result `false` cancels the event, and `true` is the
/// `undefined` of upstream: the event continues.
bool _beforeEvent(Chart chart, EventHookArgs args, ZoomPluginOptions _) {
  final event = args.event;
  final state = getState(chart);
  if (isZoomingOrPanningState(state)) {
    // cancel any event handling while panning or dragging
    return false;
  }
  // cancel the next click or mouseup after drag or pan
  if (event.type == 'click' || event.type == 'mouseup') {
    if (state.filterNextClick) {
      state.filterNextClick = false;
      return false;
    }
  }
  return true;
}

/// plugin.ts:112 `beforeUpdate(chart, _args, options)`: keeps the new
/// options, restarts the gestures when their options changed, and adds the
/// listeners.
bool _beforeUpdate(Chart chart, UpdateHookArgs _, ZoomPluginOptions options) {
  final state = getState(chart);
  final previousOptions = state.options;
  state.options = options;

  // Gesture handling needs to be restarted when certain options change.
  if (gestureOptionsChanged(previousOptions, options)) {
    stopGestures(chart);
    startGestures(chart, options);
  }

  addListeners(chart, options);
  return true;
}

/// plugin.ts:126 `beforeDatasetsDraw(chart, _args, options)`.
bool _beforeDatasetsDraw(
  Chart chart,
  PluginHookArgs _,
  ZoomPluginOptions options,
) {
  draw(chart, DrawTime.beforeDatasetsDraw, options);
  return true;
}

/// plugin.ts:130 `afterDatasetsDraw(chart, _args, options)`.
void _afterDatasetsDraw(
  Chart chart,
  PluginHookArgs _,
  ZoomPluginOptions options,
) {
  draw(chart, DrawTime.afterDatasetsDraw, options);
}

/// plugin.ts:134 `beforeDraw(chart, _args, options)`.
bool _beforeDraw(Chart chart, PluginHookArgs _, ZoomPluginOptions options) {
  draw(chart, DrawTime.beforeDraw, options);
  return true;
}

/// plugin.ts:138 `afterDraw(chart, _args, options)`.
void _afterDraw(Chart chart, PluginHookArgs _, ZoomPluginOptions options) {
  draw(chart, DrawTime.afterDraw, options);
}

/// plugin.ts:142 `stop(chart)`: removes the listeners, the gestures and the
/// state of [chart].
void _stop(Chart chart, PluginHookArgs _, ZoomPluginOptions _) {
  removeListeners(chart);

  stopGestures(chart);
  removeState(chart);
}

/// plugin.ts:64 the default export: the plugin `zoom`.
///
/// Register it for all charts with `Chart.register([zoomPlugin])`, or give
/// it to one chart in `ChartConfig.plugins` or in the `plugins` list of a
/// raw config. The options of a chart are a [ZoomPluginOptions] in
/// `ChartConfig.pluginOptions`, or in `options.plugins.zoom` of a raw
/// config.
///
/// A native `ChartPlugin` of the host (Chart.js ADRs 0144 and 0148) with
/// the hooks of upstream, in the upstream order. Its hooks get the public
/// `Chart` and the merged [ZoomPluginOptions]. `defaults` is the const
/// [ZoomPluginOptions] of `lib/src/defaults.dart`. The keys `version`,
/// `panFunctions`, `zoomFunctions` and `zoomRectFunctions` of upstream are
/// top-level names of the library: [chartjsPluginZoomPackageVersion] and the
/// three function tables. The plugin opts into the data-only updates of the
/// host (`supportsDataUpdates`): its hooks change no option and no data.
// DIVERGES(zoom): adapt-typed-plugin-object, a native ChartPlugin.
final zoomPlugin = ZoomPlugin();

/// The zoom plugin: a class of its own, so `registry.getPlugin<ZoomPlugin>()`
/// finds it by its type.
// DIVERGES(zoom): adapt-typed-plugin-object, a class of its own.
final class ZoomPlugin() extends ChartPlugin<ZoomPluginOptions> {
  /// The zoom plugin.
  this
    : super(
        id: 'zoom',
        defaults: defaults,
        start: _start,
        beforeEvent: _beforeEvent,
        beforeUpdate: _beforeUpdate,
        beforeDatasetsDraw: _beforeDatasetsDraw,
        afterDatasetsDraw: _afterDatasetsDraw,
        beforeDraw: _beforeDraw,
        afterDraw: _afterDraw,
        stop: _stop,
        supportsDataUpdates: true,
      );
}
