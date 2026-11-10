// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/index.ts (MIT, chartjs-plugin-zoom contributors).

/// The entry of the plugin: the plugin object `zoomPlugin`, the functions of
/// the zoom API, and the methods of the zoom API on a chart ([ZoomChart]).
///
/// `declare module 'chart.js'` (index.ts:9-35) adds three things to the
/// types of Chart.js:
///
/// - `PluginOptionsByType.zoom` (:10-12) has no Dart form yet: the host has
///   no typed options slot for a plugin of another package. An app gives the
///   options in the raw config, or in `ChartConfig.extra` as
///   `{'plugins': {'zoom': {...}}}`.
/// - `UpdateModeEnum.zoom` (:15-17): the update mode is the String `'zoom'`
///   (`chart.update('zoom')`), which the host takes as any other mode.
/// - The methods of `interface Chart` (:19-34): the extension [ZoomChart].
library;

import 'package:flutter_chartjs_plugin_zoom_port/src/core.dart' as core;
import 'package:flutter_chartjs_plugin_zoom_port/src/types.dart';
import 'package:flutter_chartjs_port/chartjs.dart' show Chart, Scale;

export 'package:flutter_chartjs_plugin_zoom_port/src/core.dart'
    show pan, resetZoom, zoom, zoomRect, zoomScale;
export 'package:flutter_chartjs_plugin_zoom_port/src/plugin.dart'
    show zoomPlugin;

/// index.ts:19 the methods of the zoom API on a chart.
///
/// Upstream writes the methods into each chart at the `start` of the plugin
/// (`bindApi`, src/plugin.ts:51-62). A Dart object gets no new member at run
/// time, so the methods are an extension: they exist on each chart, also
/// before the plugin starts and without the plugin. Each method calls the
/// function of the zoom API with the chart, as `bindApi` does. An absent
/// update `mode` takes the default of that function, as `undefined` does.
// DIVERGES(zoom): adapt-chart-methods-extension, methods of an extension.
extension ZoomChart on Chart {
  /// index.ts:24 `pan(pan, scales, mode)`: pans the [scales] of the chart
  /// (each scale for `null`) by [pan] pixels. See [core.pan].
  void pan(PanAmount pan, [List<Scale>? scales, String? mode]) {
    if (mode == null) {
      core.pan(this, pan, scales);
    } else {
      core.pan(this, pan, scales, mode);
    }
  }

  /// index.ts:25 `zoom(zoom, mode)`: zooms the enabled scales of the chart
  /// by [zoom]. See [core.zoom].
  void zoom(ZoomAmount zoom, [String? mode]) {
    if (mode == null) {
      core.zoom(this, zoom);
    } else {
      core.zoom(this, zoom, mode);
    }
  }

  /// index.ts:26 `zoomRect(p0, p1, mode)`: zooms the scales of the chart to
  /// the rectangle of the pixels [p0] and [p1]. See [core.zoomRect].
  void zoomRect(Point p0, Point p1, [String? mode]) {
    if (mode == null) {
      core.zoomRect(this, p0, p1);
    } else {
      core.zoomRect(this, p0, p1, mode);
    }
  }

  /// index.ts:27 `zoomScale(id, range, mode)`: zooms the scale [id] of the
  /// chart to [range]. See [core.zoomScale].
  void zoomScale(String id, ScaleRange range, [String? mode]) {
    if (mode == null) {
      core.zoomScale(this, id, range);
    } else {
      core.zoomScale(this, id, range, mode);
    }
  }

  /// index.ts:28 `resetZoom(mode)`: puts back the original range of each
  /// scale of the chart. See [core.resetZoom].
  void resetZoom([String? mode]) {
    if (mode == null) {
      core.resetZoom(this);
    } else {
      core.resetZoom(this, mode);
    }
  }

  /// index.ts:29 `getZoomLevel()`: the zoom level of the chart. See
  /// [core.getZoomLevel].
  double getZoomLevel() => core.getZoomLevel(this);

  /// index.ts:30 `getInitialScaleBounds()`: the original `min` and `max` of
  /// each scale, by scale id. See [core.getInitialScaleBounds].
  Map<String, ({double? min, double? max})> getInitialScaleBounds() =>
      core.getInitialScaleBounds(this);

  /// index.ts:31 `getZoomedScaleBounds()`: the range that the plugin wrote
  /// into each scale, by scale id. See [core.getZoomedScaleBounds].
  Map<String, ScaleRange?> getZoomedScaleBounds() =>
      core.getZoomedScaleBounds(this);

  /// index.ts:32 `isZoomedOrPanned()`: whether a scale of the chart has
  /// another range than its original range. See [core.isZoomedOrPanned].
  bool isZoomedOrPanned() => core.isZoomedOrPanned(this);

  /// index.ts:33 `isZoomingOrPanning()`: whether a pan or a drag of the
  /// chart runs. See [core.isZoomingOrPanning].
  bool isZoomingOrPanning() => core.isZoomingOrPanning(this);
}
