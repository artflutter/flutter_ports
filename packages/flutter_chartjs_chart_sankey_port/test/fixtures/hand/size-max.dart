// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/size-max.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show SankeySize;
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
            <String, Object?>{'flow': 30, 'from': 'a1', 'to': 'b1'},
            <String, Object?>{'flow': 20, 'from': 'b1', 'to': 'c1'},
            <String, Object?>{'flow': 20, 'from': 'b1', 'to': 'c2'},
            <String, Object?>{'flow': 20, 'from': 'b1', 'to': 'c3'},
            <String, Object?>{'flow': 20, 'from': 'a2', 'to': 'b2'},
            <String, Object?>{'flow': 20, 'from': 'a3', 'to': 'b2'},
            <String, Object?>{'flow': 20, 'from': 'a4', 'to': 'b2'},
            <String, Object?>{'flow': 20, 'from': 'a5', 'to': 'b2'},
            <String, Object?>{'flow': 30, 'from': 'b2', 'to': 'c4'},
          ],
          // DIVERGES(sankey): adapt-sankey-option-enums, the enum value.
          'size': SankeySize.max,
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
