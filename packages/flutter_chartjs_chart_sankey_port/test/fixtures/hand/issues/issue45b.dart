// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/issue45b.js (MIT, Jukka Kurkela).
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
            <String, Object?>{'flow': 15, 'from': 'TEST1', 'to': 'TEST2'},
            <String, Object?>{'flow': 20, 'from': 'TEST3', 'to': 'TEST2'},
            <String, Object?>{'flow': 25, 'from': 'TEST4', 'to': 'TEST2'},
            <String, Object?>{'flow': 25, 'from': 'TEST4', 'to': 'TEST5'},
            <String, Object?>{'flow': 60, 'from': 'TEST2', 'to': 'TEST6'},
            <String, Object?>{'flow': 25, 'from': 'TEST5', 'to': 'TEST6'},
            <String, Object?>{'flow': 25, 'from': 'TEST7', 'to': 'TEST6'},
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
