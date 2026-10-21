// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/clip/false.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/js/js_number.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  final data = <Object?>[];
  for (var x = 0.95; x < 1.15; x += 0.002) {
    data.add(<String, Object?>{'x': x, 'y': x});
  }

  for (var x = 0.95; x < 1.15; x += 0.001) {
    data.add(<String, Object?>{'x': x, 'y': 2.1 - x});
  }

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'scatter',
      'data': <String, Object?>{
        'datasets': <Object?>[
          <String, Object?>{
            'clip': false,
            'radius': 8,
            'borderWidth': 0,
            'backgroundColor': (Object? ctx) =>
                jsGet(ctx, 'type') != 'data' ||
                    jsToNumber(jsGet(jsGet(ctx, 'raw'), 'x')) < 1 ||
                    jsToNumber(jsGet(jsGet(ctx, 'raw'), 'x')) > 1.1
                ? 'rgba(255,0,0,0.7)'
                : 'rgba(0,0,255,0.05)',
            'data': data,
          },
        ],
      },
      'options': <String, Object?>{
        'plugins': false,
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'min': 1,
            'max': 1.1,
          },
          'y': <String, Object?>{
            'min': 1,
            'max': 1.1,
          },
        },
        'layout': <String, Object?>{
          'padding': 32,
        },
      },
    },
    'options': <String, Object?>{
      'spriteText': true,
      'canvas': <String, Object?>{
        'height': 240,
        'width': 320,
      },
    },
  };
}
