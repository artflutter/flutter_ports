// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/parsing.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
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
            <String, Object?>{'destination': 'b', 'source': 'a', 'value': 20},
            <String, Object?>{'destination': 'd', 'source': 'c', 'value': 10},
            <String, Object?>{'destination': 'e', 'source': 'c', 'value': 5},
          ],
        },
      ],
    },
    'options': <String, Object?>{
      'parsing': <String, Object?>{
        'flow': 'value',
        'from': 'source',
        'to': 'destination',
      },
    },
    'type': 'sankey',
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
  'threshold': 0.15,
};
