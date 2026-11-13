// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 docs/samples/pan/toggle.md (MIT, chartjs-plugin-zoom contributors).

import 'dart:ui' as ui;

import 'package:chartjs_gallery/docs/zoom/samples/basic.dart';
import 'package:chartjs_gallery/docs/zoom/scripts/defaults.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show Mode, ZoomChart;
import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart'
    show Chart, ChartPosition, JsObjectFace;

/// The sample `Pan Toggle` of `docs/samples/pan/toggle.md:5-105`: a scatter
/// chart that zooms with a pinch, in the limits of `:53-56`. The pan is off
/// first (`:3`), and the action `Toggle pan` turns it on and off.
///
/// The gallery changes the sample in these items:
/// - The data block (`:6-27`) is the block of `docs/samples/basic.md:4-25`,
///   line for line: [zoomSampleData] gives it, with the seed 2026 and the
///   fixed colors of the sample `Basic`.
/// - `Utils.randomColor(1)` of the grid border (`:32`) is the grey of the
///   Chart.js docs, and `'rgba( 0, 0, 0, 0.1)'` (`:33`) is
///   `Color.fromRGBO(0, 0, 0, 0.1)` (Chart.js ADR 0061).
/// - The options get the docs defaults (`setZoomDocsDefaults`).
///
/// The sample has no `console.log`: [log] gets no line.
ZoomDocsSample zoomPanToggleSample(ZoomDocsLog log) {
  // <block:data:1>
  final data = zoomSampleData();
  // </block:data>

  // <block:scales:2>
  final scaleOpts = <String, Object?>{
    'grid': <String, Object?>{
      'borderColor': const ChartPaint.solid(
        ui.Color.fromRGBO(201, 203, 207, 1),
      ),
      'color': const ChartPaint.solid(ui.Color.fromRGBO(0, 0, 0, 0.1)),
    },
    'title': <String, Object?>{'display': true, 'text': zoomAxisTitle},
  };
  final scales = <String, Object?>{
    'x': <String, Object?>{'position': ChartPosition.top},
    'y': <String, Object?>{'position': ChartPosition.right},
  };
  for (final scale in scales.values) {
    (scale! as Map<String, Object?>).addAll(scaleOpts);
  }
  // </block:scales>

  // <block:zoom:0>
  final zoomOptions = <String, Object?>{
    'limits': <String, Object?>{
      'x': <String, Object?>{'min': -200.0, 'max': 200.0, 'minRange': 50.0},
      'y': <String, Object?>{'min': -200.0, 'max': 200.0, 'minRange': 50.0},
    },
    'pan': <String, Object?>{'enabled': false, 'mode': Mode.xy},
    'zoom': <String, Object?>{
      'wheel': <String, Object?>{'enabled': false},
      'pinch': <String, Object?>{'enabled': true},
    },
  };
  // </block:zoom>

  // <block:config:1>
  final config = <String, Object?>{
    'type': 'scatter',
    'data': data,
    'options': <String, Object?>{
      'scales': scales,
      'plugins': <String, Object?>{'zoom': zoomOptions},
    },
  };
  // </block:config>
  setZoomDocsDefaults(config['options']! as Map<String, Object?>);

  final actions = <ZoomDocsAction>[
    (
      name: 'Toggle pan',
      handler: (chart) {
        final pan = _panOptions(chart);
        pan['enabled'] = pan['enabled'] != true;
        chart.update();
      },
      isOn: (chart) => _panOptions(chart)['enabled'] == true,
    ),
    (
      name: 'Reset zoom',
      handler: (chart) => chart.resetZoom('zoom'),
      isOn: null,
    ),
  ];

  return (actions: actions, config: config, output: null);
}

/// `chart.options.plugins.zoom.pan` (`:89`): the resolved options of the
/// chart, read by name through their face. A write through it goes into
/// the options of the user, as the `set` traps of the Proxies of upstream do
/// (src/helpers/helpers.config.ts:189-193 and :101-106 of Chart.js v4.6.1).
JsObjectFace _panOptions(Chart chart) {
  final plugins = chart.options['plugins']! as JsObjectFace;
  final zoom = plugins['zoom']! as JsObjectFace;
  return zoom['pan']! as JsObjectFace;
}
