// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/node-padding-per-node.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show SankeyNodeGap;
import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[
    <String, Object?>{'flow': 15, 'from': 'Oil', 'to': 'Fossil fuels'},
    <String, Object?>{'flow': 20, 'from': 'Natural gas', 'to': 'Fossil fuels'},
    <String, Object?>{'flow': 25, 'from': 'Coal', 'to': 'Fossil fuels'},
    <String, Object?>{'flow': 60, 'from': 'Fossil fuels', 'to': 'Energy'},
    <String, Object?>{'flow': 10, 'from': 'Nuclear', 'to': 'Energy'},
    <String, Object?>{'flow': 30, 'from': 'Renewables', 'to': 'Energy'},
    <String, Object?>{'flow': 40, 'from': 'Energy', 'to': 'Electricity'},
    <String, Object?>{'flow': 35, 'from': 'Energy', 'to': 'Heat'},
    <String, Object?>{'flow': 25, 'from': 'Energy', 'to': 'Lost'},
  ];

  return <String, Object?>{
    'config': <String, Object?>{
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'colorFrom': const ChartPaint.solid(Color(0xFF708090)), // slategray
            'colorTo': const ChartPaint.solid(Color(0xFFFFA500)), // orange
            'data': data,
            // A Record of per-node gaps: only Natural gas gets a wide gap
            // below it (widening the Natural gas -> Oil gap, the last column-0
            // pair; Coal above Natural gas is unaffected), and Heat gets a
            // wide gap above it (widening the Electricity -> Heat gap in the
            // last column). Everything else uses the default 10px symmetric
            // gap.
            // DIVERGES(sankey): adapt-sankey-node-option, the gap class.
            'nodePadding': <String, Object?>{
              'Heat': const SankeyNodeGap(before: 40),
              'Natural gas': const SankeyNodeGap(after: 40),
            },
          },
        ],
      },
      'type': 'sankey',
    },
    'description':
        'per-node nodePadding: a Record of before/after gaps widens the gap '
        'below "Natural gas" and above "Heat" only, leaving the other gaps at '
        'the 10px default',
    'options': <String, Object?>{
      'canvas': <String, Object?>{'height': 500, 'width': 900},
      // Node labels are incidental to what this fixture measures (gaps between
      // nodes), not the point of comparison. Real font rasterization differs
      // between the CI Linux runner and a local macOS run enough to blow the
      // 0.1% pixel tolerance on nine long labels, so draw them from the
      // deterministic bitmap sprite sheet instead, like the other fixtures
      // with sizeable text (see `grep -l 'spriteText: true' test/fixtures/*.js`).
      'spriteText': true,
    },
  };
}
