// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/node-min-size.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  // Same shape as issue 87: one huge node and several nearly-invisible ones
  // (flows of 0.37, 0.5, 0.9 against 85024) landing in the same column.
  // Without nodeMinSize, the tiny nodes' bars are a fraction of a pixel tall.
  final data = <Object?>[
    <String, Object?>{'flow': 85024, 'from': 'Huge', 'to': 'Sink'},
    <String, Object?>{'flow': 0.37, 'from': 'Tiny A', 'to': 'Sink'},
    <String, Object?>{'flow': 0.5, 'from': 'Tiny B', 'to': 'Sink'},
    <String, Object?>{'flow': 0.9, 'from': 'Tiny C', 'to': 'Sink'},
  ];

  return <String, Object?>{
    'config': <String, Object?>{
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'colorFrom': const ChartPaint.solid(Color(0xFF708090)), // slategray
            'colorTo': const ChartPaint.solid(Color(0xFFFFA500)), // orange
            'data': data,
            'nodeMinSize': 6,
          },
        ],
      },
      'type': 'sankey',
    },
    'description':
        'nodeMinSize stretches the three tiny node bars (flows 0.37, 0.5, 0.9 '
        'against a Huge 85024) to a visible 6px, centered on their natural '
        'position, while the Huge node and all flows keep their exact '
        'proportions',
    'options': <String, Object?>{
      'canvas': <String, Object?>{'height': 500, 'width': 900},
      // Real font rasterization differs between the CI Linux runner and a
      // local macOS run enough to blow the 0.1% pixel tolerance on labels, so
      // draw them from the deterministic bitmap sprite sheet instead, like the
      // other fixtures with sizeable text (see `grep -l 'spriteText: true'
      // test/fixtures/*.js`).
      'spriteText': true,
    },
  };
}
