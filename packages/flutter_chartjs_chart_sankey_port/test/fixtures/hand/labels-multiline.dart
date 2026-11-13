// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/labels-multiline.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet, jsTruthy;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[
    <String, Object?>{'flow': 100, 'from': 'Oil', 'to': 'Fossil Fuels'},
    <String, Object?>{'flow': 50, 'from': 'Oil', 'to': 'Natural Gas'},
    <String, Object?>{'flow': 50, 'from': 'Natural Gas', 'to': 'Coal'},
    <String, Object?>{'flow': 50, 'from': 'Coal', 'to': 'Electricity'},
    <String, Object?>{'flow': 100, 'from': 'Fossil Fuels', 'to': 'Energy'},
  ];

  const colors = <String, ChartPaint>{
    'Coal': ChartPaint.solid(Color(0xFF808080)), // gray
    'Electricity': ChartPaint.solid(Color(0xFF0000FF)), // blue
    'Energy': ChartPaint.solid(Color(0xFFFFA500)), // orange
    'Fossil Fuels': ChartPaint.solid(Color(0xFF708090)), // slategray
    'Oil': ChartPaint.solid(Color(0xFF000000)), // black
  };

  final labels = <String, Object?>{
    'Coal': 'Coal\nsubtitle 1\nsubtitle 2\nsubtitle 3\nsubtitle 4',
    'Electricity': 'Electricity\nsubtitle 1',
    'Energy': 'Energy\nsubtitle 1\nsubtitle 2\nsubtitle 3',
    'Fossil Fuels': 'Fossil\nsubtitle 1\nsubtitle 2',
    'Natural Gas': 'Nat. gas \nsubtitle 1\nsubtitle 2',
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
      'canvas': <String, Object?>{'height': 512, 'width': 512},
      'spriteText': true,
    },
  };
}
