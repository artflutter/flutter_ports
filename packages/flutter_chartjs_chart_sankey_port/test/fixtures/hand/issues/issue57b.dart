// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/issue57b.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[
    <String, Object?>{'flow': 6, 'from': 'trailer-2', 'to': 'trailer-3'},
    <String, Object?>{'flow': 39, 'from': 'film-1', 'to': 'tv_show-2'},
    <String, Object?>{'flow': 12, 'from': 'trailer-1', 'to': 'tv_show-2'},
    <String, Object?>{'flow': 14, 'from': 'trailer-2', 'to': 'film-3'},
    <String, Object?>{'flow': 13, 'from': 'tv_show-1', 'to': 'trailer-2'},
    <String, Object?>{'flow': 12, 'from': 'film-2', 'to': 'trailer-3'},
    <String, Object?>{'flow': 27, 'from': 'film-2', 'to': 'film-3'},
    <String, Object?>{'flow': 12, 'from': 'tv_show-2', 'to': 'trailer-3'},
    <String, Object?>{'flow': 35, 'from': 'tv_show-1', 'to': 'film-2'},
    <String, Object?>{'flow': 12, 'from': 'trailer-2', 'to': 'tv_show-3'},
    <String, Object?>{'flow': 33, 'from': 'tv_show-2', 'to': 'film-3'},
    <String, Object?>{'flow': 13, 'from': 'film-1', 'to': 'trailer-2'},
    <String, Object?>{'flow': 8, 'from': 'trailer-1', 'to': 'trailer-2'},
    <String, Object?>{'flow': 43, 'from': 'film-2', 'to': 'tv_show-3'},
    <String, Object?>{'flow': 30, 'from': 'tv_show-1', 'to': 'tv_show-2'},
    <String, Object?>{'flow': 14, 'from': 'trailer-1', 'to': 'film-2'},
    <String, Object?>{'flow': 33, 'from': 'tv_show-2', 'to': 'tv_show-3'},
    <String, Object?>{'flow': 37, 'from': 'film-1', 'to': 'film-2'},
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
