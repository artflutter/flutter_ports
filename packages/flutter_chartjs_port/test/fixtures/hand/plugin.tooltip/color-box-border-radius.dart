// Ported from Chart.js v4.5.1+7169e651 test/fixtures/plugin.tooltip/color-box-border-radius.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart' show jsToNumber;
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/plugins/plugin.tooltip.dart';
import 'package:flutter_chartjs_port/src/types/index.dart' as types;

import '../../fixture_events.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The callback `labelColor` reads `tooltipItem.chart` through
/// `types.Chart`, and the style of the element with `jsGet`. The inline
/// `afterDraw` gives the chart event of the raw `mousemove` at the point
/// ([fixtureMouseMove]) to `chart._handleEvent` (the `handleEvent` of
/// [Chart]) and to the tooltip, and draws the tooltip. The canvas of the
/// harness is at the origin of its host: `canvas.getBoundingClientRect()`
/// gives the left and the top 0 (row `harness-fixture-sources`).
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[8, 7, 6, 5],
          'pointBorderColor': '#ff0000',
          'pointBackgroundColor': '#00ff00',
          'showLine': false,
        },
      ],
      'labels': <Object?>['', '', '', ''],
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
          'callbacks': <String, Object?>{
            'label': () => '​',
            'labelColor': (Object? tooltipItem) {
              final meta = (jsGet(tooltipItem, 'chart')! as types.Chart)
                  .getDatasetMeta(
                    jsToNumber(jsGet(tooltipItem, 'datasetIndex')),
                  );
              final options = meta.controller!.getStyle(
                jsToNumber(jsGet(tooltipItem, 'dataIndex')),
              );
              return <String, Object?>{
                'borderColor': jsGet(options, 'borderColor'),
                'backgroundColor': jsGet(options, 'backgroundColor'),
                'borderWidth': 2,
                'borderRadius': <String, Object?>{
                  'topRight': 5,
                  'bottomRight': 5,
                },
              };
            },
          },
        },
      },

      'layout': <String, Object?>{'padding': 15},
    },
    'plugins': <Object?>[
      <String, Object?>{
        'afterDraw': (types.Chart chart) {
          // const canvas = chart.canvas;
          // const rect = canvas.getBoundingClientRect();
          final point = chart.getDatasetMeta(0).data[1];
          final event = fixtureMouseMove(point);
          (chart as Chart).handleEvent(event);
          (chart.tooltip! as Tooltip)
            ..handleEvent(event)
            ..draw(chart.ctx!);
        },
      },
    ],
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
