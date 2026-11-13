// Ported from chartjs-chart-sankey v0.19.1 test/fixtures/issues/issue99.js (MIT, Jukka Kurkela).
// DIVERGES(sankey): adapt-sankey-native-colors, native paint inputs.
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show Color;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;
import 'package:flutter_chartjs_port/js_semantics.dart'
    show jsGet, jsObjectKeys, jsToString, jsTruthy;

/// `export default` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  const colors2 = <ChartPaint>[
    ChartPaint.solid(Color(0xFFFFF5EB)), // #fff5eb
    ChartPaint.solid(Color(0xFFFEE6CE)), // #fee6ce
    ChartPaint.solid(Color(0xFFFDD0A2)), // #fdd0a2
    ChartPaint.solid(Color(0xFFFDAE6B)), // #fdae6b
    ChartPaint.solid(Color(0xFFFD8D3C)), // #fd8d3c
    ChartPaint.solid(Color(0xFFF16913)), // #f16913
    ChartPaint.solid(Color(0xFFD94801)), // #d94801
    ChartPaint.solid(Color(0xFFA63603)), // #a63603
    ChartPaint.solid(Color(0xFF7F2704)), // #7f2704
  ];
  final assigned = <String, Object?>{};
  Object? c2(Object? name) {
    if (!jsTruthy(jsGet(assigned, name))) {
      assigned[jsToString(name)] =
          colors2[jsObjectKeys(assigned).length.remainder(colors2.length)];
    }
    return jsGet(assigned, name);
  }

  return <String, Object?>{
    'config': <String, Object?>{
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'borderWidth': 0,
            'colorFrom': (Object? c) => c2(
              jsGet(
                jsGet(
                  jsGet(jsGet(c, 'dataset'), 'data'),
                  jsGet(c, 'dataIndex'),
                ),
                'from',
              ),
            ),
            'colorTo': (Object? c) => c2(
              jsGet(
                jsGet(
                  jsGet(jsGet(c, 'dataset'), 'data'),
                  jsGet(c, 'dataIndex'),
                ),
                'to',
              ),
            ),
            'data': <Object?>[
              <String, Object?>{'flow': 5, 'from': 'Brazil', 'to': 'Portugal'},
              <String, Object?>{'flow': 1, 'from': 'Brazil', 'to': 'France'},
              <String, Object?>{'flow': 1, 'from': 'Brazil', 'to': 'Spain'},
              <String, Object?>{'flow': 1, 'from': 'Brazil', 'to': 'England'},
              <String, Object?>{'flow': 1, 'from': 'Canada', 'to': 'Portugal'},
              <String, Object?>{'flow': 5, 'from': 'Canada', 'to': 'France'},
              <String, Object?>{'flow': 1, 'from': 'Canada', 'to': 'England'},
              <String, Object?>{'flow': 1, 'from': 'Mexico', 'to': 'Portugal'},
              <String, Object?>{'flow': 1, 'from': 'Mexico', 'to': 'France'},
              <String, Object?>{'flow': 5, 'from': 'Mexico', 'to': 'Spain'},
              <String, Object?>{'flow': 1, 'from': 'Mexico', 'to': 'England'},
              <String, Object?>{'flow': 1, 'from': 'USA', 'to': 'Portugal'},
              <String, Object?>{'flow': 1, 'from': 'USA', 'to': 'France'},
              <String, Object?>{'flow': 1, 'from': 'USA', 'to': 'Spain'},
              <String, Object?>{'flow': 5, 'from': 'USA', 'to': 'England'},
              <String, Object?>{'flow': 2, 'from': 'Portugal', 'to': 'Angola'},
              <String, Object?>{'flow': 1, 'from': 'Portugal', 'to': 'Senegal'},
              <String, Object?>{'flow': 1, 'from': 'Portugal', 'to': 'Morocco'},
              <String, Object?>{
                'flow': 3,
                'from': 'Portugal',
                'to': 'South Africa',
              },
              <String, Object?>{'flow': 1, 'from': 'France', 'to': 'Angola'},
              <String, Object?>{'flow': 3, 'from': 'France', 'to': 'Senegal'},
              <String, Object?>{'flow': 3, 'from': 'France', 'to': 'Mali'},
              <String, Object?>{'flow': 3, 'from': 'France', 'to': 'Morocco'},
              <String, Object?>{
                'flow': 1,
                'from': 'France',
                'to': 'South Africa',
              },
              <String, Object?>{'flow': 1, 'from': 'Spain', 'to': 'Senegal'},
              <String, Object?>{'flow': 3, 'from': 'Spain', 'to': 'Morocco'},
              <String, Object?>{
                'flow': 1,
                'from': 'Spain',
                'to': 'South Africa',
              },
              <String, Object?>{'flow': 1, 'from': 'England', 'to': 'Angola'},
              <String, Object?>{'flow': 1, 'from': 'England', 'to': 'Senegal'},
              <String, Object?>{'flow': 2, 'from': 'England', 'to': 'Morocco'},
              <String, Object?>{
                'flow': 7,
                'from': 'England',
                'to': 'South Africa',
              },
              <String, Object?>{
                'flow': 5,
                'from': 'South Africa',
                'to': 'China',
              },
              <String, Object?>{
                'flow': 1,
                'from': 'South Africa',
                'to': 'India',
              },
              <String, Object?>{
                'flow': 3,
                'from': 'South Africa',
                'to': 'Japan',
              },
              <String, Object?>{'flow': 5, 'from': 'Angola', 'to': 'China'},
              <String, Object?>{'flow': 1, 'from': 'Angola', 'to': 'India'},
              <String, Object?>{'flow': 3, 'from': 'Angola', 'to': 'Japan'},
              <String, Object?>{'flow': 5, 'from': 'Senegal', 'to': 'China'},
              <String, Object?>{'flow': 1, 'from': 'Senegal', 'to': 'India'},
              <String, Object?>{'flow': 3, 'from': 'Senegal', 'to': 'Japan'},
              <String, Object?>{'flow': 5, 'from': 'Mali', 'to': 'China'},
              <String, Object?>{'flow': 1, 'from': 'Mali', 'to': 'India'},
              <String, Object?>{'flow': 3, 'from': 'Mali', 'to': 'Japan'},
              <String, Object?>{'flow': 5, 'from': 'Morocco', 'to': 'China'},
              <String, Object?>{'flow': 1, 'from': 'Morocco', 'to': 'India'},
              <String, Object?>{'flow': 3, 'from': 'Morocco', 'to': 'Japan'},
            ],
          },
        ],
      },
      'type': 'sankey',
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{'height': 600, 'width': 800},
      'spriteText': true,
    },
  };
}
