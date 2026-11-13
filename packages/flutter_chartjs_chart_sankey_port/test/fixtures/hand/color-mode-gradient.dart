// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/color-mode-gradient.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
// ignore_for_file: file_names
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
    'a': ChartPaint.solid(Color(0xFF0000FF)), // blue
    'b': ChartPaint.solid(Color(0xFF008000)), // green
    'c': ChartPaint.solid(Color(0xFFFFA500)), // orange
    'd': ChartPaint.solid(Color(0xFFFF0000)), // red
    'e': ChartPaint.solid(Color(0xFFEE82EE)), // violet
  };

  return <String, Object?>{
    'config': <String, Object?>{
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'colorFrom': (Object? c) => jsGet(
              colors,
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
            'colorTo': (Object? c) => jsGet(
              colors,
              jsGet(
                jsGet(
                  jsGet(jsGet(c, 'dataset'), 'data'),
                  jsGet(c, 'dataIndex'),
                ),
                'to',
              ),
            ),
            'data': <Object?>[
              <String, Object?>{'flow': 20, 'from': 'a', 'to': 'b'},
              <String, Object?>{'flow': 10, 'from': 'b', 'to': 'c'},
              <String, Object?>{'flow': 10, 'from': 'a', 'to': 'c'},
              <String, Object?>{'flow': 10, 'from': 'b', 'to': 'd'},
              <String, Object?>{'flow': 20, 'from': 'c', 'to': 'e'},
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
