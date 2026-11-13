// Ported from Chart.js v4.6.1 test/fixtures/controller.line/borderJoinStyle/value.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:ui' show StrokeJoin;

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The upstream config, with native padding values.
// DIVERGES(chartjs): adapt-edge-insets-padding, the native padding value.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0.0, 1.0, 2.0],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[6.0, 18.0, 6.0],
          'borderColor': '#ff0000',
          'borderJoinStyle': StrokeJoin.round,
        },
        <String, Object?>{
          'data': <Object?>[2.0, 14.0, 2.0],
          'borderColor': '#0000ff',
          'borderJoinStyle': StrokeJoin.bevel,
        },
        <String, Object?>{
          'data': <Object?>[-2.0, 10.0, -2.0],
        },
      ],
    },
    'options': <String, Object?>{
      'elements': <String, Object?>{
        'line': <String, Object?>{
          'borderColor': '#00ff00',
          'borderJoinStyle': StrokeJoin.miter,
          'borderWidth': 25.0,
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
          'tension': 0.0,
        },
      },
      'layout': <String, Object?>{'padding': const EdgeInsets.all(32)},
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256.0, 'width': 512.0},
  },
};
