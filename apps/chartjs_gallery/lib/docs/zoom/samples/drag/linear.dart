// Ported from chartjs-plugin-zoom v2.2.0+fb81d331 docs/samples/drag/linear.md (MIT, chartjs-plugin-zoom contributors).

import 'dart:ui' as ui;

import 'package:chartjs_gallery/docs/zoom/samples/basic.dart';
import 'package:chartjs_gallery/docs/zoom/scripts/defaults.dart';
import 'package:flutter_chartjs_plugin_zoom_port/flutter_chartjs_plugin_zoom_port.dart'
    show Mode, ModifierKey, ZoomChart;

/// The sample `Linear Scales` of `docs/samples/drag/linear.md:5-113`: a
/// scatter chart that zooms to the rectangle of a mouse drag, and pans with
/// a drag while `ctrl` is pressed (`:3`).
///
/// The gallery changes the sample in these items:
/// - The data block (`:6-27`) and the scales block (`:29-53`) are the blocks
///   of `docs/samples/basic.md:4-51`, line for line: [zoomSampleData] and
///   [zoomSampleScales] give them, with the seed 2026 and the fixed colors
///   of the sample `Basic`.
/// - The colors of the drag rectangle (`:66-68`) are `Color` values
///   (Chart.js ADR 0061): `'rgb(54, 162, 235)'` is
///   `Color.fromRGBO(54, 162, 235, 1)`.
/// - The options get the docs defaults (`setZoomDocsDefaults`).
///
/// The sample has no `console.log`: [log] gets no line.
ZoomDocsSample zoomDragLinearSample(ZoomDocsLog log) {
  // <block:data:1>
  final data = zoomSampleData();
  // </block:data>

  // <block:scales:2>
  final scales = zoomSampleScales();
  // </block:scales>

  // <block:zoom:0>
  // `zoomOptions.zoom.drag` is a local, so that the actions read and write
  // it as the upstream handlers do.
  final drag = <String, Object?>{
    'enabled': true,
    'borderColor': const ui.Color.fromRGBO(54, 162, 235, 1),
    'borderWidth': 1.0,
    'backgroundColor': const ui.Color.fromRGBO(54, 162, 235, 0.3),
  };
  final zoomOptions = <String, Object?>{
    'pan': <String, Object?>{
      'enabled': true,
      'mode': Mode.xy,
      'modifierKey': ModifierKey.ctrl,
    },
    'zoom': <String, Object?>{'mode': Mode.xy, 'drag': drag},
  };
  // </block:zoom>

  String zoomStatus() => drag['enabled'] == true ? 'enabled' : 'disabled';

  // <block:config:1>
  final config = <String, Object?>{
    'type': 'scatter',
    'data': data,
    'options': <String, Object?>{
      'scales': scales,
      'plugins': <String, Object?>{
        'zoom': zoomOptions,
        'title': <String, Object?>{
          'display': true,
          'position': 'bottom',
          'text': () => 'Zoom: ${zoomStatus()}',
        },
      },
    },
  };
  // </block:config>
  setZoomDocsDefaults(config['options']! as Map<String, Object?>);

  final actions = <ZoomDocsAction>[
    (
      name: 'Toggle zoom',
      handler: (chart) {
        drag['enabled'] = drag['enabled'] != true;
        chart.update();
      },
      isOn: (_) => drag['enabled'] == true,
    ),
    (name: 'Reset zoom', handler: (chart) => chart.resetZoom(), isOn: null),
  ];

  return (actions: actions, config: config, output: null);
}
