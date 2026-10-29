// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/segments/gap.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

// `ctx.p0` and `ctx.p1` are point elements. `ctx.p0.skip` is the access by
// name of the element (Chart.js ADR 0017, section 5): `jsGet` gives
// `undefined` for an element.

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 3, double.nan, double.nan, 2, 1],
          'borderColor': 'transparent',
          'backgroundColor': 'black',
          'fill': true,
          'segment': <String, Object?>{
            'backgroundColor': (Object? ctx) =>
                jsTruthy((jsGet(ctx, 'p0')! as Element)['skip']) ||
                    jsTruthy((jsGet(ctx, 'p1')! as Element)['skip'])
                ? 'red'
                : undefined,
          },
          'spanGaps': true,
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
};
