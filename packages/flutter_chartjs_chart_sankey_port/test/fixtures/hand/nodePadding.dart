// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/nodePadding.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'colorFrom': const ChartPaint.solid(Color(0xFFFF0000)), // red
          'colorTo': const ChartPaint.solid(Color(0xFF008000)), // green
          'data': <Object?>[
            <String, Object?>{'flow': 20, 'from': 'a', 'to': 'b'},
            <String, Object?>{'flow': 10, 'from': 'c', 'to': 'd'},
            <String, Object?>{'flow': 5, 'from': 'c', 'to': 'e'},
          ],
          'nodePadding': 50,
        },
      ],
    },
    'type': 'sankey',
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
