// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/discussion108.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show SankeyModeX;
import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'colorFrom': (Object? ctx) =>
              (jsGet(jsGet(ctx, 'raw'), 'from')! as String).startsWith('Source')
              ? const ChartPaint.solid(Color(0xFF808080)) // gray
              : const ChartPaint.solid(Color(0xFF008000)), // green
          'colorTo': (Object? ctx) {
            final to = jsGet(jsGet(ctx, 'raw'), 'to')! as String;
            // `to.slice(0, 2)`.
            final start = to.substring(0, to.length < 2 ? to.length : 2);
            return const ['Un', 'Fr'].contains(start)
                ? const ChartPaint.solid(Color(0xFFFF0000)) // red
                : const ChartPaint.solid(Color(0xFF008000)); // green
          },
          'data': <Object?>[
            <String, Object?>{'flow': 70, 'from': 'Source 1', 'to': 'Total'},
            <String, Object?>{'flow': 52, 'from': 'Source 2', 'to': 'Total'},
            <String, Object?>{'flow': 38, 'from': 'Source 3', 'to': 'Total'},
            <String, Object?>{'flow': 29, 'from': 'Source 4', 'to': 'Total'},
            <String, Object?>{'flow': 15, 'from': 'Source 5', 'to': 'Total'},
            <String, Object?>{'flow': 14, 'from': 'Source 6', 'to': 'Total'},
            <String, Object?>{'flow': 12, 'from': 'Source 7', 'to': 'Total'},
            <String, Object?>{'flow': 73, 'from': 'Total', 'to': 'Free'},
            <String, Object?>{'flow': 45, 'from': 'Total', 'to': 'Reseller 1'},
            <String, Object?>{'flow': 19, 'from': 'Reseller 1', 'to': 'Sold'},
            <String, Object?>{'flow': 26, 'from': 'Reseller 1', 'to': 'Unsold'},
            <String, Object?>{'flow': 40, 'from': 'Total', 'to': 'Reseller 2'},
            <String, Object?>{'flow': 30, 'from': 'Reseller 2', 'to': 'Sold 2'},
            <String, Object?>{
              'flow': 10,
              'from': 'Reseller 2',
              'to': 'Unsold 2',
            },
            <String, Object?>{'flow': 38, 'from': 'Total', 'to': 'Reseller 3'},
            <String, Object?>{'flow': 30, 'from': 'Reseller 3', 'to': 'Sold 3'},
            <String, Object?>{
              'flow': 8,
              'from': 'Reseller 3',
              'to': 'Unsold 3',
            },
            <String, Object?>{'flow': 34, 'from': 'Total', 'to': 'Reseller 4'},
            <String, Object?>{'flow': 30, 'from': 'Reseller 4', 'to': 'Sold 4'},
            <String, Object?>{
              'flow': 4,
              'from': 'Reseller 4',
              'to': 'Unsold 4',
            },
            <String, Object?>{'flow': 10, 'from': 'Sold', 'to': 'Used'},
            <String, Object?>{'flow': 9, 'from': 'Sold', 'to': 'Unused'},
            <String, Object?>{'flow': 20, 'from': 'Sold 2', 'to': 'Used 2'},
            <String, Object?>{'flow': 10, 'from': 'Sold 2', 'to': 'Unused 2'},
            <String, Object?>{'flow': 15, 'from': 'Sold 3', 'to': 'Used 3'},
            <String, Object?>{'flow': 15, 'from': 'Sold 3', 'to': 'Unused 3'},
            <String, Object?>{'flow': 5, 'from': 'Sold 4', 'to': 'Used 4'},
            <String, Object?>{'flow': 25, 'from': 'Sold 4', 'to': 'Unused 4'},
          ],
          // DIVERGES(sankey): adapt-sankey-option-enums, the enum value.
          'modeX': SankeyModeX.even,
        },
      ],
    },
    'type': 'sankey',
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 320, 'width': 600},
    'spriteText': true,
  },
  'tolerance': 0.02,
};
