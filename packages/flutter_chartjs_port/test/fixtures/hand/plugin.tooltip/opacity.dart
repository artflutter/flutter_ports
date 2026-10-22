// Ported from Chart.js v4.5.1+7169e651 test/fixtures/plugin.tooltip/opacity.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas.dart';
import 'package:flutter_chartjs_port/src/canvas/canvas_ui.dart';
import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart';
import 'package:flutter_chartjs_port/src/types/basic.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

import '../../fixture_events.dart';

/// `module.exports` of the upstream file. Each call runs the module body:
/// the pattern canvas of the module and the gradient variable.
///
/// `createPattern(patternCanvas, 'repeat')` takes the image source of the
/// canvas layer, read at the place of the upstream call (`toImageSource()`
/// of `UiCanvasElement`). The inline `afterDraw` gives the chart event of
/// the raw `mousemove` at each point ([fixtureMouseMove]) to
/// `chart._handleEvent` (the `handleEvent` of [Chart]) and to the tooltip,
/// writes the opacity of the tooltip, and draws the tooltip. The canvas of
/// the harness is at the origin of its host: `canvas.getBoundingClientRect()`
/// gives the left and the top 0 (row `harness-fixture-sources`).
Map<String, Object?> fixture() {
  final patternCanvas = document.createElement<HTMLCanvasElement>('canvas');
  final patternContext = patternCanvas.getContext('2d')!;

  patternCanvas
    ..width = 6
    ..height = 6;
  patternContext
    ..fillStyle = '#ff0000'
    ..fillRect(0, 0, 6, 6)
    ..fillStyle = '#ffff00'
    ..fillRect(0, 0, 4, 4);

  final pattern = patternContext.createPattern(
    (patternCanvas as UiCanvasElement).toImageSource(),
    'repeat',
  );

  CanvasGradient? gradient;

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[8, 8, 8, 8, 8, 8, 7, 8, 8, 8, 8],
            'pointBorderColor': '#ff0000',
            'pointBackgroundColor': '#00ff00',
            'showLine': false,
          },
          <String, Object?>{
            'label': '',
            'data': <Object?>[4, 4, 4, 4, 4, 5, 3, 4, 4, 4, 4],
            'pointBorderColor': pattern,
            'pointBackgroundColor': pattern,
            'showLine': false,
          },
          <String, Object?>{
            'label': '',
            'data': <Object?>[0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0],
            'showLine': false,
          },
        ],
        'labels': <Object?>['', '', '', '', '', '', '', '', '', '', ''],
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
            'callbacks': <String, Object?>{'label': () => '​'},
          },
        },

        'layout': <String, Object?>{'padding': 15},
      },
      'plugins': <Object?>[
        <String, Object?>{
          'beforeDatasetsUpdate': (types.Chart chart) {
            if (gradient == null) {
              final created = chart.ctx!.createLinearGradient(0, 0, 512, 256);
              gradient = created;
              created
                ..addColorStop(0, '#ff0000')
                ..addColorStop(1, '#0000ff');
            }
            final datasets = chart.config.data['datasets']! as List<Object?>;
            (datasets[2]! as AnyObject)
              ..['pointBorderColor'] = gradient
              ..['pointBackgroundColor'] = gradient;

            return true;
          },
          'afterDraw': (types.Chart chart) {
            // var canvas = chart.canvas;
            // var rect = canvas.getBoundingClientRect();
            for (var i = 0; i < 3; ++i) {
              for (var j = 0; j < 11; ++j) {
                final point = chart.getDatasetMeta(i.toDouble()).data[j];
                final event = fixtureMouseMove(point);
                (chart as Chart).handleEvent(event);
                (chart.tooltip! as Tooltip)
                  ..handleEvent(event)
                  ..opacity = j / 10
                  ..draw(chart.ctx!);
              }
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
