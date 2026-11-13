// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/issue57.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[
    <String, Object?>{'flow': 19, 'from': 'trailer-2', 'to': 'trailer-3'},
    <String, Object?>{'flow': 93, 'from': 'film-1', 'to': 'tv_show-2'},
    <String, Object?>{'flow': 44, 'from': 'trailer-1', 'to': 'tv_show-2'},
    <String, Object?>{'flow': 36, 'from': 'trailer-2', 'to': 'film-3'},
    <String, Object?>{'flow': 32, 'from': 'tv_show-1', 'to': 'trailer-2'},
    <String, Object?>{'flow': 41, 'from': 'film-2', 'to': 'trailer-3'},
    <String, Object?>{'flow': 83, 'from': 'film-2', 'to': 'film-3'},
    <String, Object?>{'flow': 44, 'from': 'tv_show-2', 'to': 'trailer-3'},
    <String, Object?>{'flow': 87, 'from': 'tv_show-1', 'to': 'film-2'},
    <String, Object?>{'flow': 30, 'from': 'trailer-2', 'to': 'tv_show-3'},
    <String, Object?>{'flow': 37, 'from': 'film-1', 'to': 'trailer-2'},
    <String, Object?>{'flow': 78, 'from': 'tv_show-2', 'to': 'film-3'},
    <String, Object?>{'flow': 18, 'from': 'trailer-1', 'to': 'trailer-2'},
    <String, Object?>{'flow': 93, 'from': 'film-2', 'to': 'tv_show-3'},
    <String, Object?>{'flow': 76, 'from': 'tv_show-1', 'to': 'tv_show-2'},
    <String, Object?>{'flow': 46, 'from': 'trailer-1', 'to': 'film-2'},
    <String, Object?>{'flow': 88, 'from': 'tv_show-2', 'to': 'tv_show-3'},
    <String, Object?>{'flow': 88, 'from': 'film-1', 'to': 'film-2'},
  ];

  return <String, Object?>{
    'config': <String, Object?>{
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'colorFrom': const ChartPaint.solid(Color(0xFF0000FF)), // blue
            'colorTo': const ChartPaint.solid(Color(0xFF008000)), // green
            'data': data,
          },
        ],
      },
      'type': 'sankey',
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{'height': 256, 'width': 512},
      'spriteText': true,
    },
    'tolerance': 0.02,
  };
}
