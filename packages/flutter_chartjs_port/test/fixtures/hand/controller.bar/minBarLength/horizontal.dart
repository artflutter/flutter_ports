// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/minBarLength/horizontal.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/types/bar_option_enums.dart';
import 'package:flutter_chartjs_port/src/types/chart_axis.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'bar',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[0, -0.01, 0.01, 30, -30],
          'backgroundColor': '#00ff00',
          'borderColor': '#000',
          // DIVERGES(chartjs): adapt-border-skipped-enum, the enum value.
          'borderSkipped': (Object? ctx) =>
              jsGet(ctx, 'raw') == 0 ? false : BorderSkippedEdge.start,
          'borderWidth': 4,
          'minBarLength': 20,
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        'x': <String, Object?>{
          'ticks': <String, Object?>{'display': false},
        },
        'y': <String, Object?>{'display': false},
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{'height': 512, 'width': 512},
  },
};
