// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/issue106.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  const colors = <String, ChartPaint>{
    '29  ': ChartPaint.solid(Color(0xFF000080)), // navy
    '110 ': ChartPaint.solid(Color(0xFFFF00FF)), // magenta
    '115 ': ChartPaint.solid(Color(0xFFA52A2A)), // brown
    'AA': ChartPaint.solid(Color(0xFFFF0000)), // red
    'BB': ChartPaint.solid(Color(0xFF008000)), // green
    'CC': ChartPaint.solid(Color(0xFF0000FF)), // blue
    'DD': ChartPaint.solid(Color(0xFF808080)), // gray
    'EE': ChartPaint.solid(Color(0xFFFFFF00)), // yellow
    'XX': ChartPaint.solid(Color(0xFF000000)), // black
    'YY': ChartPaint.solid(Color(0xFFFFFFFF)), // white
  };

  Object? getColor(Object? key) => jsGet(colors, key);

  return <String, Object?>{
    'config': <String, Object?>{
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'colorFrom': (Object? c) => getColor(
              jsGet(
                jsGet(
                  jsGet(jsGet(c, 'dataset'), 'data'),
                  jsGet(c, 'dataIndex'),
                ),
                'from',
              ),
            ),
            'colorTo': (Object? c) => getColor(
              jsGet(
                jsGet(
                  jsGet(jsGet(c, 'dataset'), 'data'),
                  jsGet(c, 'dataIndex'),
                ),
                'to',
              ),
            ),
            'data': <Object?>[
              <String, Object?>{'flow': 5, 'from': '115 ', 'to': 'AA'},
              <String, Object?>{'flow': 4, 'from': '115 ', 'to': 'BB'},
              <String, Object?>{'flow': 4, 'from': '115 ', 'to': 'CC'},
              <String, Object?>{'flow': 4, 'from': '29  ', 'to': 'DD'},
              <String, Object?>{'flow': 3, 'from': '110 ', 'to': 'EE'},
              <String, Object?>{'flow': 5, 'from': 'AA', 'to': 'XX'},
              <String, Object?>{'flow': 4, 'from': 'BB', 'to': 'XX'},
              <String, Object?>{'flow': 4, 'from': 'CC', 'to': 'YY'},
              <String, Object?>{'flow': 4, 'from': 'DD', 'to': 'XX'},
              <String, Object?>{'flow': 3, 'from': 'EE', 'to': 'XX'},
            ],
          },
        ],
      },
      'type': 'sankey',
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{'height': 256, 'width': 512},
      'spriteText': true,
    },
  };
}
