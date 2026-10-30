// Ported from Chart.js v4.6.1 test/fixtures/plugin.tooltip/point-style.js (MIT, Chart.js Contributors).
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
/// the point `i` of the dataset `i` ([fixtureMouseMove]) to
/// `chart._handleEvent` (the `handleEvent` of [Chart]) and to the tooltip,
/// and draws the tooltip. The canvas of the harness is at the origin of its
/// host: `canvas.getBoundingClientRect()` gives the left and the top 0 (row
/// `harness-fixture-sources`).
Map<String, Object?> fixture() {
  const pointStyles = <Object?>[
    'circle',
    'cross',
    'crossRot',
    'dash',
    'line',
    'rect',
    'rectRounded',
    'rectRot',
    'star',
    'triangle',
    false,
  ];

  Map<String, Object?> newDataset(Object? pointStyle, int i) =>
      <String, Object?>{
        'label': '',
        'data': [for (final _ in pointStyles) i],
        'pointStyle': pointStyle,
        'pointBackgroundColor': '#0000ff',
        'pointBorderColor': '#00ff00',
        'showLine': false,
      };

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          for (final (i, pointStyle) in pointStyles.indexed)
            newDataset(pointStyle, i),
        ],
        'labels': <Object?>[for (final _ in pointStyles) ''],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{'display': false},
          'y': <String, Object?>{'display': false},
        },
        'elements': <String, Object?>{
          'line': <String, Object?>{'fill': false},
        },
        'plugins': <String, Object?>{
          'legend': false,
          'title': false,
          'filler': false,
          'tooltip': <String, Object?>{
            'mode': 'nearest',
            'intersect': false,
            'padding': 5,
            'usePointStyle': true,
            'callbacks': <String, Object?>{'label': () => '​'},
          },
        },
        'layout': <String, Object?>{'padding': 15},
      },
      'plugins': <Object?>[
        <String, Object?>{
          'afterDraw': (types.Chart chart) {
            // var canvas = chart.canvas;
            // var rect = canvas.getBoundingClientRect();
            for (var i = 0; i < pointStyles.length; ++i) {
              final point = chart.getDatasetMeta(i).data[i];
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
      'canvas': <String, Object?>{'height': 256, 'width': 512},
    },
  };
}
