// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/segments/spanGaps.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/js/js_number.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

// `ctx.p1` is a point element. `ctx.p1.parsed` is the access by name of the
// element (Chart.js ADR 0017, section 5): `jsGet` gives `undefined` for an
// element.

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 3, null, null, 2, 1],
          'segment': <String, Object?>{
            'borderColor': (Object? ctx) =>
                jsToNumber(
                      jsGet((jsGet(ctx, 'p1')! as Element)['parsed'], 'x'),
                    ) >
                    2
                ? 'red'
                : undefined,
            'borderDash': (Object? ctx) =>
                jsToNumber(
                      jsGet((jsGet(ctx, 'p1')! as Element)['parsed'], 'x'),
                    ) >
                    3
                ? <Object?>[6, 6]
                : undefined,
          },
          'spanGaps': true,
        },
        <String, Object?>{
          'data': <Object?>[0, 2, null, null, 1, 0],
          'segment': <String, Object?>{
            'borderColor': (Object? ctx) =>
                jsToNumber(
                      jsGet((jsGet(ctx, 'p1')! as Element)['parsed'], 'x'),
                    ) >
                    2
                ? 'red'
                : undefined,
            'borderDash': (Object? ctx) =>
                jsToNumber(
                      jsGet((jsGet(ctx, 'p1')! as Element)['parsed'], 'x'),
                    ) >
                    3
                ? <Object?>[6, 6]
                : undefined,
          },
          'spanGaps': false,
        },
      ],
    },
    'options': <String, Object?>{
      'borderColor': 'black',
      'radius': 0,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
    },
  },
};
