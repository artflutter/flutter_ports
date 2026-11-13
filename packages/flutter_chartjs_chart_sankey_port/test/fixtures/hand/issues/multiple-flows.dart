// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/multiple-flows.js (MIT, Jukka Kurkela).
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
          'colorFrom': const ChartPaint.solid(Color(0xFF0000FF)), // blue
          'colorTo': const ChartPaint.solid(Color(0xFFFF0000)), // red
          'data': <Object?>[
            <String, Object?>{'flow': 516, 'from': 'A', 'to': 'B'},
            <String, Object?>{'flow': 220, 'from': 'A', 'to': 'C'},
            <String, Object?>{'flow': 64, 'from': 'A', 'to': 'D'},
            <String, Object?>{'flow': 50, 'from': 'A', 'to': 'B'},
          ],
        },
      ],
    },
    'type': 'sankey',
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 256},
    'spriteText': true,
  },
};
