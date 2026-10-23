// Ported from Chart.js v4.5.1+7169e651 test/fixtures/plugin.tooltip/box-padding.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

import '../../fixture_events.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The inline `afterDraw` gives the chart event of the raw `mousemove` at
/// each point ([fixtureMouseMove]) to `chart._handleEvent` (the `handleEvent`
/// of [Chart]) and to the tooltip, and draws the tooltip. The canvas of the
/// harness is at the origin of its host: `canvas.getBoundingClientRect()`
/// gives the left and the top 0 (row `harness-fixture-sources`). The
/// tooltip is `chart.tooltip` cast to [Tooltip] (Chart.js ADR 0039, section
/// 1).
Map<String, Object?> fixture() {
  final data = <Object?>[];
  for (var x = 0; x < 3; x++) {
    for (var y = 0; y < 3; y++) {
      data.add(<String, Object?>{'x': x, 'y': y});
    }
  }

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'scatter',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'data': data,
            'backgroundColor': 'red',
            'radius': 1,
            'hoverRadius': 0,
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{'display': false},
          'y': <String, Object?>{'display': false},
        },
        'plugins': <String, Object?>{
          'legend': false,
          'title': false,
          'filler': false,
          'tooltip': <String, Object?>{
            'mode': 'point',
            'intersect': true,
            // spriteText: use white background to hide any gaps between fonts
            'backgroundColor': 'white',
            'borderColor': 'black',
            'borderWidth': 1,
            'callbacks': <String, Object?>{'label': () => 'label'},
            'boxPadding': 30,
          },
        },
      },
      'plugins': <Object?>[
        <String, Object?>{
          'afterDraw': (types.Chart chart) {
            // const canvas = chart.canvas;
            // const rect = canvas.getBoundingClientRect();
            final meta = chart.getDatasetMeta(0);

            for (var i = 0; i < data.length; i++) {
              final point = meta.data[i];
              // DIVERGES(chartjs): harness-fixture-sources, the chart event.
              final event = fixtureMouseMove(point);
              (chart as Chart).handleEvent(event);
              (chart.tooltip! as Tooltip)
                ..handleEvent(event)
                ..draw(chart.ctx!);
            }
          },
        },
      ],
    },
    'options': <String, Object?>{
      'spriteText': true,
      'canvas': <String, Object?>{'height': 400, 'width': 500},
    },
  };
}
