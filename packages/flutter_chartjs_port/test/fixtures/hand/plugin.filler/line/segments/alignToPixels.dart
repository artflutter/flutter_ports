// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/segments/alignToPixels.js (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-native-line-segment-style, a LineSegmentStyle.
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';
import 'package:flutter_chartjs_port/src/types/line_segment_style.dart';

// `ctx.p0` is a point element. `ctx.p0.parsed` is the access by name of the
// element (Chart.js ADR 0017, section 5): `jsGet` gives `undefined` for an
// element.

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[
            <String, Object?>{'x': 0, 'y': 0},
            <String, Object?>{'x': 1, 'y': 20},
            <String, Object?>{'x': 1.00001, 'y': 30},
            <String, Object?>{'x': 2, 'y': 100},
            <String, Object?>{'x': 2.00001, 'y': 100},
          ],
          'backgroundColor': '#FF000070',
          'borderColor': 'black',
          'radius': 0,
          'segment': LineSegmentStyle(
            borderDash: (ctx) =>
                jsToNumber(jsGet((ctx.p0 as Element)['parsed'], 'x')) > 1
                ? <double>[10, 5]
                : null,
          ),
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toOrigin,
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{'legend': false},
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'type': 'linear',
          'alignToPixels': true,
          'display': false,
        },
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'width': 300, 'height': 240},
  },
};
