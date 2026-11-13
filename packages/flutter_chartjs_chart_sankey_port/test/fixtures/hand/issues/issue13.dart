// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/issue13.js (MIT, Jukka Kurkela).
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
            <String, Object?>{'flow': 1, 'from': '1', 'to': 'Alpha'},
            <String, Object?>{'flow': 1, 'from': '2', 'to': 'Beta'},
            <String, Object?>{'flow': 1, 'from': '3', 'to': 'Gamma'},
            <String, Object?>{'flow': 1, 'from': '4', 'to': 'Delta'},
            <String, Object?>{'flow': 1, 'from': '5', 'to': 'Gamma'},
          ],
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
