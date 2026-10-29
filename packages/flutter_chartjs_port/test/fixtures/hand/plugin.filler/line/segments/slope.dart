// Ported from Chart.js v4.6.1 test/fixtures/plugin.filler/line/segments/slope.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.element.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/js/js_undefined.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() {
  // Upstream: function slope({p0, p1}). `p0` and `p1` are point elements:
  // `x` and `y` are their number properties (Chart.js ADR 0017).
  double slope(Object? ctx) {
    final p0 = jsGet(ctx, 'p0')! as Element;
    final p1 = jsGet(ctx, 'p1')! as Element;
    return (p0.y - p1.y) / (p1.x - p0.x);
  }

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f'],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[1, 2, 3, 3, 2, 1],
            'backgroundColor': 'black',
            'borderColor': 'orange',
            'fill': true,
            'segment': <String, Object?>{
              'backgroundColor': (Object? ctx) => slope(ctx) > 0
                  ? 'green'
                  : slope(ctx) < 0
                  ? 'red'
                  : undefined,
            },
          },
        ],
      },
      'options': <String, Object?>{
        'plugins': <String, Object?>{'legend': false},
        'scales': <String, Object?>{
          'x': <String, Object?>{'display': false},
          'y': <String, Object?>{'display': false},
        },
      },
    },
  };
}
