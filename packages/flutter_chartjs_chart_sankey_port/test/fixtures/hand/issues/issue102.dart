// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/issue102.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show SankeyColorMode;
import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  const colors = <String, ChartPaint>{
    'a': ChartPaint.solid(Color(0xFFFF0000)), // red
    'b': ChartPaint.solid(Color(0xFF008000)), // green
    'c': ChartPaint.solid(Color(0xFF0000FF)), // blue
    'd': ChartPaint.solid(Color(0xFF808080)), // gray
    'e': ChartPaint.solid(Color(0xFFFFFF00)), // yellow
    'f': ChartPaint.solid(Color(0xFF000000)), // black
    'g': ChartPaint.solid(Color(0xFFFFFFFF)), // white
    'h': ChartPaint.solid(Color(0xFFA52A2A)), // brown
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
            // DIVERGES(sankey): adapt-sankey-option-enums, the enum value.
            'colorMode': SankeyColorMode.gradient,
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
              // { from: 'a', to: 'b', flow: 10 },
              <String, Object?>{'flow': 5, 'from': 'a', 'to': 'c'},
              // { from: 'a', to: 'd', flow: 10 },
              <String, Object?>{'flow': 5, 'from': 'd', 'to': 'e'},
              // { from: 'd', to: 'f', flow: 5 },
              // { from: 'a', to: 'g', flow: 0.0001 },
              <String, Object?>{'flow': 0, 'from': 'a', 'to': 'h'},
            ],

            'labels': <String, Object?>{
              'a': 'A',
              'b': 'B',
              'c': 'C',
              'd': 'D',
              'e': 'DA',
              'f': 'DB',
              'g': 'NOTOVERLAPPING',
              'h': 'BUG',
            },
            'nodePadding': 50,
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
