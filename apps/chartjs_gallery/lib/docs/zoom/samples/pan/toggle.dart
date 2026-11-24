// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 docs/samples/pan/toggle.md (MIT, chartjs-plugin-zoom contributors).

import 'dart:ui' as ui;

import 'package:chartjs_gallery/docs/zoom/samples/basic.dart';
import 'package:chartjs_gallery/docs/zoom/scripts/defaults.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The sample `Pan Toggle` of `docs/samples/pan/toggle.md:5-105`: a scatter
/// chart that zooms with a pinch, in the limits of `:53-56`. The pan is off
/// first (`:3`), and the action `Toggle pan` turns it on and off.
///
/// The gallery changes the sample in these items:
/// - The data block (`:6-27`) is the block of `docs/samples/basic.md:4-25`,
///   line for line: [zoomSampleData] gives it, with the seed 2026 and the
///   fixed colors of the sample `Basic`.
/// - `'rgba( 0, 0, 0, 0.1)'` (`:33`) is `Color.fromRGBO(0, 0, 0, 0.1)`
///   (Chart.js ADR 0061). The Chart.js 3 key `grid.borderColor` (`:32`)
///   draws nothing, and the typed `AxisGrid` has no such field: the config
///   leaves it out, as `zoomSampleScales` does. The scriptable title text
///   is the text of each axis ([zoomAxisTitle]).
/// - The config is a typed `ChartConfig` (Chart.js ADR 0195), and the zoom
///   options are one immutable `ZoomPluginOptions` in its `pluginOptions`
///   (Chart.js ADR 0148). The handler of `Toggle pan` (`:88-91`) reads them
///   through the options of the chart and writes the merge with the new
///   `pan.enabled` back (`setZoomSampleOptions`) before `chart.update()`.
/// - `chart.resetZoom('zoom')` (`:96`) gives the update mode
///   `zoomUpdateMode`.
/// - The config gets the docs defaults (`withZoomDocsDefaults`).
///
/// The sample has no `console.log`: [log] gets no line.
ZoomDocsSample zoomPanToggleSample(ZoomDocsLog log) {
  // <block:data:1>
  final data = zoomSampleData();
  // </block:data>

  // <block:scales:2>
  const grid = AxisGrid(
    color: .constant(ChartPaint.solid(ui.Color.fromRGBO(0, 0, 0, 0.1))),
  );
  final scales = <ChartAxis>[
    LinearAxis(
      .x,
      position: ChartPosition.top,
      grid: grid,
      title: zoomAxisTitle(.x),
    ),
    LinearAxis(
      .y,
      position: ChartPosition.right,
      grid: grid,
      title: zoomAxisTitle(.y),
    ),
  ];
  // </block:scales>

  // <block:zoom:0>
  const zoomOptions = ZoomPluginOptions(
    limits: LimitOptions(
      x: ScaleLimits(min: ScaleLimit(-200), max: ScaleLimit(200), minRange: 50),
      y: ScaleLimits(min: ScaleLimit(-200), max: ScaleLimit(200), minRange: 50),
    ),
    pan: PanOptions(enabled: false, mode: Mode.xy),
    zoom: ZoomOptions(
      wheel: WheelOptions(enabled: false),
      pinch: PinchOptions(enabled: true),
    ),
  );
  // </block:zoom>

  // <block:config:1>
  final config = withZoomDocsDefaults(
    ChartConfig(
      datasets: data,
      scales: scales,
      pluginOptions: const [zoomOptions],
    ),
  );
  // </block:config>

  final actions = <ZoomDocsAction>[
    (
      name: 'Toggle pan',
      handler: (chart) {
        final zoom = _zoomOptions(chart);
        setZoomSampleOptions(
          chart,
          zoom.merge(
            ZoomPluginOptions(
              pan: PanOptions(enabled: !(zoom.pan?.enabled ?? false)),
            ),
          ),
        );
        chart.update();
      },
      isOn: (chart) => _zoomOptions(chart).pan?.enabled ?? false,
    ),
    (
      name: 'Reset zoom',
      handler: (chart) => chart.resetZoom(zoomUpdateMode),
      isOn: null,
    ),
  ];

  return (actions: actions, config: config, output: null);
}

/// `chart.options.plugins.zoom` (`:89`): the `ZoomPluginOptions` of the
/// user, the first scope that has the key, read by name through the face of
/// the resolved options.
ZoomPluginOptions _zoomOptions(Chart chart) =>
    (chart.options['plugins']! as JsObjectFace)['zoom']! as ZoomPluginOptions;
