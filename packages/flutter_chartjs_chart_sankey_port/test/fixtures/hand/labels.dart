// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/labels.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet, jsTruthy;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[
    <String, Object?>{'flow': 15, 'from': 'Oil', 'to': 'Fossil Fuels'},
    <String, Object?>{'flow': 20, 'from': 'Natural Gas', 'to': 'Fossil Fuels'},
    <String, Object?>{'flow': 25, 'from': 'Coal', 'to': 'Fossil Fuels'},
    <String, Object?>{'flow': 25, 'from': 'Coal', 'to': 'Electricity'},
    <String, Object?>{'flow': 60, 'from': 'Fossil Fuels', 'to': 'Energy'},
    <String, Object?>{'flow': 25, 'from': 'Electricity', 'to': 'Energy'},
  ];

  const colors = <String, ChartPaint>{
    'Coal': ChartPaint.solid(Color(0xFF808080)), // gray
    'Electricity': ChartPaint.solid(Color(0xFF0000FF)), // blue
    'Energy': ChartPaint.solid(Color(0xFFFFA500)), // orange
    'Fossil Fuels': ChartPaint.solid(Color(0xFF708090)), // slategray
    'Oil': ChartPaint.solid(Color(0xFF000000)), // black
  };

  final labels = <String, Object?>{
    'Fossil Fuels': 'Fossil',
    'Natural Gas': 'Nat. gas',
  };

  Object? getColor(Object? name) {
    final color = jsGet(colors, name);
    return jsTruthy(color)
        ? color
        : const ChartPaint.solid(Color(0xFF008000)); // green
  }

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
            'data': data,
            'labels': labels,
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
