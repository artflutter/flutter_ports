// Ported from Chart.js v4.6.1 test/fixtures/controller.radar/borderJoinStyle/scriptable.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show StrokeJoin;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'radar',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3],
      'datasets': <Object?>[
        <String, Object?>{
          // option in dataset
          'data': <Object?>[3, 3, null, 3],
          'borderColor': '#ff0000',
          // DIVERGES(chartjs): adapt-flutter-stroke-enums, the Flutter enum.
          'borderJoinStyle': (Object? ctx) {
            final index = jsToNumber(jsGet(ctx, 'datasetIndex')).remainder(3);
            return index == 0
                ? StrokeJoin.round
                : index == 1
                ? StrokeJoin.miter
                : StrokeJoin.bevel;
          },
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[2, 2, null, 2],
          'borderColor': '#0000ff',
        },
        <String, Object?>{
          // option in element (fallback)
          'data': <Object?>[1, 1, null, 1],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': '#00ff00',
          'borderJoinStyle': (Object? ctx) {
            final index = jsToNumber(jsGet(ctx, 'datasetIndex')).remainder(3);
            return index == 0
                ? StrokeJoin.round
                : index == 1
                ? StrokeJoin.miter
                : StrokeJoin.bevel;
          },
          'borderWidth': 25,
          'fill': false,
          'tension': 0,
        },
      },
      'layout': <String, Object?>{
        'padding': const EdgeInsets.all(32),
      },
      'scales': <String, Object?>{
        'r': <String, Object?>{
          'display': false,
          'beginAtZero': true,
        },
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'height': 512,
      'width': 512,
    },
  },
};
