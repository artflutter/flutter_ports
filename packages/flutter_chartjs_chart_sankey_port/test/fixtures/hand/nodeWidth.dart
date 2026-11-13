// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/nodeWidth.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show EdgeInsets;
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
          'nodeWidth': 50,
        },
      ],
    },
    'options': <String, Object?>{
      'layout': <String, Object?>{
        // Upstream gives `{right: 53}`, and the other three sides come
        // from the padding of the sankey overrides (controller.ts:322-329).
        // The padding of the host is an `EdgeInsets`, which replaces all
        // four sides (Chart.js ADR 0123): the value states the three
        // sides of the overrides too.
        // DIVERGES(sankey): adapt-sankey-native-defaults, all four sides.
        'padding': const EdgeInsets.only(bottom: 3, left: 3, right: 53, top: 3),
      },
    },
    'type': 'sankey',
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
    'spriteText': true,
  },
};
