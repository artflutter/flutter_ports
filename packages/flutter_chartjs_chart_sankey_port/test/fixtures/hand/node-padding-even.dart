// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/node-padding-even.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show SankeyNodePaddingMode;
import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[
    <String, Object?>{'flow': 10, 'from': 'S1', 'to': 'M1'},
    <String, Object?>{'flow': 6, 'from': 'S2', 'to': 'M1'},
    <String, Object?>{'flow': 14, 'from': 'S3', 'to': 'M2'},
    <String, Object?>{'flow': 4, 'from': 'S4', 'to': 'M2'},
    <String, Object?>{'flow': 10, 'from': 'M1', 'to': 'T1'},
    <String, Object?>{'flow': 6, 'from': 'M1', 'to': 'T2'},
    <String, Object?>{'flow': 4, 'from': 'M2', 'to': 'T2'},
    <String, Object?>{'flow': 14, 'from': 'M2', 'to': 'T3'},
  ];

  return <String, Object?>{
    'config': <String, Object?>{
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'colorFrom': const ChartPaint.solid(Color(0xFF708090)), // slategray
            'colorTo': const ChartPaint.solid(Color(0xFFFFA500)), // orange
            'data': data,
            // Four sources feeding two middle nodes is what makes the 'auto'
            // cross-column effect visible: with nodePaddingMode left at the
            // default 'auto', M2 (which only has one real neighbor, M1, in
            // its own column) still has to clear every node stacked above it
            // in column 0, so it ends up with extra "virtual" padding well
            // beyond the requested 20px gap -- and that inflation carries
            // through to the T2/T3 column too. nodePaddingMode: 'even' skips
            // that cross-column requirement entirely: every gap in every
            // column is exactly max(prev.after, next.before), so M2 sits
            // right below M1 with a regular 20px gap, like every other pair.
            'nodePadding': 20,
            // DIVERGES(sankey): adapt-sankey-option-enums, the enum value.
            'nodePaddingMode': SankeyNodePaddingMode.even,
          },
        ],
      },
      'type': 'sankey',
    },
    'description':
        "nodePaddingMode: 'even' lays out each column's nodes back-to-back "
        "with a regular gap, instead of 'auto' inflating a node's gap to "
        'clear nodes stacked above it in earlier columns',
    'options': <String, Object?>{
      'canvas': <String, Object?>{'height': 400, 'width': 700},
      // Node labels are incidental to what this fixture measures (gaps
      // between nodes in a column), not the point of comparison. Draw them
      // from the deterministic bitmap sprite sheet so font rasterization
      // differences between the CI Linux runner and a local macOS run don't
      // blow the 0.1% pixel tolerance (see `grep -l 'spriteText: true'
      // test/fixtures/*.js`).
      'spriteText': true,
    },
  };
}
