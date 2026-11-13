// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/cash.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show SankeyModeX;
import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'colorFrom': const ChartPaint.solid(Color(0xFF008000)), // green
          'colorTo': const ChartPaint.solid(Color(0xFF808080)), // gray
          'data': <Object?>[
            <String, Object?>{
              'flow': 1150,
              'from': 'division a',
              'to': 'revenue',
            },
            <String, Object?>{
              'flow': 650,
              'from': 'dibision b',
              'to': 'revenue',
            },
            <String, Object?>{
              'flow': 800,
              'from': 'revenue',
              'to': 'cost of sales',
            },
            <String, Object?>{
              'flow': 1000,
              'from': 'revenue',
              'to': 'cross profit',
            },
            <String, Object?>{
              'flow': 650,
              'from': 'cross profit',
              'to': 'operating expenses',
            },
            <String, Object?>{
              'flow': 350,
              'from': 'cross profit',
              'to': 'operating profit',
            },
          ],
          // DIVERGES(sankey): adapt-sankey-option-enums, the enum value.
          'modeX': SankeyModeX.even,
          'nodePadding': 100,
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
