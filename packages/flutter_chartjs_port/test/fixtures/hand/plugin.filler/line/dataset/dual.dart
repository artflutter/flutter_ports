// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/dataset/dual.json (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/pure.dart' show nativeFixturePaint;
import 'package:flutter_chartjs_port/src/plugins/fill_target.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['0', '1', '2', '3', '4', '5', '6', '7', '8'],
      'datasets': <Object?>[
        <String, Object?>{
          'backgroundColor': 'rgba(255, 0, 0, 0.25)',
          'data': <Object?>[0, 1, 2, -1, 0, 2, 1, -1, -2],
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.toNext.split(
            above: nativeFixturePaint('rgba(255, 0, 0, 0.25)'),
            below: nativeFixturePaint('rgba(0, 0, 255, 0.25)'),
          ),
        },
        <String, Object?>{
          'data': <Object?>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        },
      ],
    },
    'options': <String, Object?>{
      'responsive': false,
      'spanGaps': true,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'elements': <String, Object?>{
        'point': <String, Object?>{'radius': 0},
        'line': <String, Object?>{'borderColor': 'transparent', 'tension': 0},
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 256, 'width': 512},
  },
};
