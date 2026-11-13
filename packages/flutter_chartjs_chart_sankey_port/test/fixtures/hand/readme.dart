// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/readme.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart'
    show SankeyColorMode, SankeySize;
import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/js_semantics.dart' show jsGet;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  const colors = <String, ChartPaint>{
    'a': ChartPaint.solid(Color(0xFFFF0000)), // red
    'b': ChartPaint.solid(Color(0xFF008000)), // green
    'c': ChartPaint.solid(Color(0xFF0000FF)), // blue
    'd': ChartPaint.solid(Color(0xFF808080)), // gray
  };

  Object? getColor(Object? key) => jsGet(colors, key);

  return <String, Object?>{
    'config': <String, Object?>{
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'colorFrom': (Object? c) => getColor(
              jsGet(
                jsGet(
                  jsGet(jsGet(c, 'dataset'), 'data'),
                  jsGet(c, 'dataIndex'),
                ),
                'from',
              ),
            ),
            // DIVERGES(sankey): adapt-sankey-option-enums, the enum value.
            'colorMode': SankeyColorMode.gradient, // or 'from' or 'to'
            'colorTo': (Object? c) => getColor(
              jsGet(
                jsGet(
                  jsGet(jsGet(c, 'dataset'), 'data'),
                  jsGet(c, 'dataIndex'),
                ),
                'to',
              ),
            ),
            /* optional column overrides */
            'column': <String, Object?>{'d': 1},
            'data': <Object?>[
              <String, Object?>{'flow': 10, 'from': 'a', 'to': 'b'},
              <String, Object?>{'flow': 5, 'from': 'a', 'to': 'c'},
              <String, Object?>{'flow': 10, 'from': 'b', 'to': 'c'},
              <String, Object?>{'flow': 7, 'from': 'd', 'to': 'c'},
            ],
            'label': 'My sankey',
            /* optional labels */
            'labels': <String, Object?>{
              'a': 'Label A',
              'b': 'Label B',
              'c': 'Label C',
              'd': 'Label D',
            },
            /* optional priority */
            'priority': <String, Object?>{'b': 1, 'd': 0},
            // DIVERGES(sankey): adapt-sankey-option-enums, the enum value.
            'size': SankeySize.max, // or 'min' if flow overlap is preferred
          },
        ],
      },
      'type': 'sankey',
    },
    'options': <String, Object?>{'spriteText': true},
  };
}
