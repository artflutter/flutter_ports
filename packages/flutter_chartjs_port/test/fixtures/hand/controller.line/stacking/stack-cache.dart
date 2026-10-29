// Ported from Chart.js v4.6.1 test/fixtures/controller.line/stacking/stack-cache.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  Map<String, Object?> makeDs(Object? label, Object? offset) {
    return <String, Object?>{
      'label': label,
      'data':
          <Object?>[
            <Object?>[0, 12],
            <Object?>[1, 19],
            <Object?>[2, 3],
            <Object?>[2, 5],
            <Object?>[3, 2],
            <Object?>[4, 3],
          ].map((item) {
            // Upstream: ([x, y]) => ({x, y: y === null ? null : y + offset})
            final [x, y] = item! as List<Object?>;
            return <String, Object?>{
              'x': x,
              'y': y == null ? null : jsAdd(y, offset),
            };
          }).toList(),
      'showLine': true,
      'spanGaps': false,
      'stack': 'stack${jsToString(label)}',
      'borderColor': label == 'A' ? '#c00' : '#00c',
    };
  }

  final dsA = makeDs('A', 0);
  final dsB = makeDs('B', 1);

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'scatter',
      'data': <String, Object?>{
        'datasets': <Object?>[dsA, dsB],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{'display': false},
          'y': <String, Object?>{'display': false},
        },
        'elements': <String, Object?>{
          'point': <String, Object?>{
            'backgroundColor': '#444',
          },
        },
        'layout': <String, Object?>{
          'padding': <String, Object?>{
            'left': 24,
            'right': 24,
          },
        },
      },
    },
    'options': <String, Object?>{
      'canvas': <String, Object?>{
        'height': 128,
        'width': 256,
      },
      'run': (Chart chart) async {
        chart
          ..data = <String, Object?>{
            'datasets': <Object?>[dsB, dsA],
          }
          ..update();
      },
    },
  };
}
