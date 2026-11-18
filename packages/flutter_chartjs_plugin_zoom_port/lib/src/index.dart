// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 src/index.ts (MIT, chartjs-plugin-zoom contributors).

/// The entry of the plugin: the plugin object `zoomPlugin`, the functions of
/// the zoom API, and the methods of the zoom API on a chart ([ZoomChart]).
///
/// `declare module 'chart.js'` (index.ts:9-35) adds three things to the
/// types of Chart.js:
///
/// - `PluginOptionsByType.zoom` (:10-12): the options are a
///   `ZoomPluginOptions`, a `PluginOptions` of the host (Chart.js ADR
///   0148). A typed config gives them in `ChartConfig.pluginOptions`, and a
///   raw config holds the object in `options.plugins.zoom`.
/// - `UpdateModeEnum.zoom` (:15-17): the constant [core.zoomUpdateMode], an
///   `UpdateMode` of the host (`chart.update(zoomUpdateMode)`).
/// - The methods of `interface Chart` (:19-34): the extension [ZoomChart].
library;

import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    as core;
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/chartjs.dart' hide Point;

export 'package:flutter_chartjs_plugin_zoom_port/src/core.dart';
export 'package:flutter_chartjs_plugin_zoom_port/src/plugin.dart';

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
  void pan(PanAmount pan, [List<Scale>? scales, UpdateMode? mode]) {
    if (mode == null) {
      core.pan(this, pan, scales);
    } else {
      core.pan(this, pan, scales, mode);
    }
  }

  /// index.ts:25 `zoom(zoom, mode)`: zooms the enabled scales of the chart
  /// by [zoom]. See [core.zoom].
  void zoom(ZoomAmount zoom, [UpdateMode? mode]) {
    if (mode == null) {
      core.zoom(this, zoom);
    } else {
      core.zoom(this, zoom, mode);
    }
  }

  /// index.ts:26 `zoomRect(p0, p1, mode)`: zooms the scales of the chart to
  /// the rectangle of the pixels [p0] and [p1]. See [core.zoomRect].
  void zoomRect(Point p0, Point p1, [UpdateMode? mode]) {
    if (mode == null) {
      core.zoomRect(this, p0, p1);
    } else {
      core.zoomRect(this, p0, p1, mode);
    }
  }

  /// index.ts:27 `zoomScale(id, range, mode)`: zooms the scale [id] of the
  /// chart to [range]. See [core.zoomScale].
  void zoomScale(String id, ScaleRange range, [UpdateMode? mode]) {
    if (mode == null) {
      core.zoomScale(this, id, range);
    } else {
      core.zoomScale(this, id, range, mode);
    }
  }

  /// index.ts:28 `resetZoom(mode)`: puts back the original range of each
  /// scale of the chart. See [core.resetZoom].
  void resetZoom([UpdateMode? mode]) {
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
