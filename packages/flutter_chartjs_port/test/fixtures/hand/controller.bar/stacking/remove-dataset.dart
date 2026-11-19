// Ported from Chart.js v4.6.1 test/fixtures/controller.bar/stacking/remove-dataset.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/core/scale_option_enums.dart'
    show ScaleDisplay;
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';
import 'package:flutter_chartjs_port/src/types/chart_meta.dart' show StackMode;

import '../../../../support/list_splice.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `chart.data.datasets.splice(0, 1)` is [spliceList], then
/// [notifyArrayListeners], the body of the hooked method (differences.md
/// row platform-array-events). The datasets array has no listeners, so the
/// notification does nothing, as upstream.
Map<String, Object?> fixture() {
  final barChartData = <String, Object?>{
    'labels': <Object?>[0, 1, 2, 3, 4, 5, 6],
    'datasets': <Object?>[
      <String, Object?>{
        'backgroundColor': 'red',
        'data': <Object?>[
          // { x: 0, y: 0 },
          <String, Object?>{'x': 1, 'y': 5},
          <String, Object?>{'x': 2, 'y': 5},
          <String, Object?>{'x': 3, 'y': 5},
          <String, Object?>{'x': 4, 'y': 5},
          <String, Object?>{'x': 5, 'y': 5},
          <String, Object?>{'x': 6, 'y': 5},
        ],
      },
      <String, Object?>{
        'backgroundColor': 'blue',
        'data': <Object?>[
          <String, Object?>{'x': 0, 'y': 5},
          // { x: 1, y: 0 },
          <String, Object?>{'x': 2, 'y': 5},
          <String, Object?>{'x': 3, 'y': 5},
          <String, Object?>{'x': 4, 'y': 5},
          <String, Object?>{'x': 5, 'y': 5},
          <String, Object?>{'x': 6, 'y': 5},
        ],
      },
      <String, Object?>{
        'backgroundColor': 'green',
        'data': <Object?>[
          <String, Object?>{'x': 0, 'y': 5},
          <String, Object?>{'x': 1, 'y': 5},
          // { x: 2, y: 0 },
          <String, Object?>{'x': 3, 'y': 5},
          <String, Object?>{'x': 4, 'y': 5},
          <String, Object?>{'x': 5, 'y': 5},
          <String, Object?>{'x': 6, 'y': 5},
        ],
      },
      <String, Object?>{
        'backgroundColor': 'yellow',
        'data': <Object?>[
          <String, Object?>{'x': 0, 'y': 5},
          <String, Object?>{'x': 1, 'y': 5},
          <String, Object?>{'x': 2, 'y': 5},
          // {x: 3, y: 0 },
          <String, Object?>{'x': 4, 'y': 5},
          <String, Object?>{'x': 5, 'y': 5},
          <String, Object?>{'x': 6, 'y': 5},
        ],
      },
      <String, Object?>{
        'backgroundColor': 'purple',
        'data': <Object?>[
          <String, Object?>{'x': 0, 'y': 5},
          <String, Object?>{'x': 1, 'y': 5},
          <String, Object?>{'x': 2, 'y': 5},
          <String, Object?>{'x': 3, 'y': 5},
          // { x: 4, y: 0 },
          <String, Object?>{'x': 5, 'y': 5},
          <String, Object?>{'x': 6, 'y': 5},
        ],
      },
      <String, Object?>{
        'backgroundColor': 'grey',
        'data': <Object?>[
          <String, Object?>{'x': 0, 'y': 5},
          <String, Object?>{'x': 1, 'y': 5},
          <String, Object?>{'x': 2, 'y': 5},
          <String, Object?>{'x': 3, 'y': 5},
          <String, Object?>{'x': 4, 'y': 5},
          // { x: 5, y: 0 },
          <String, Object?>{'x': 6, 'y': 5},
        ],
      },
    ],
  };

  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'bar',
      'data': barChartData,
      'options': <String, Object?>{
        'scales': <String, Object?>{
          // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'x': <String, Object?>{
            'display': ScaleDisplay.off,
            'stacked': StackMode.on,
          },
          // DIVERGES(chartjs): adapt-stacked-option-enum, the enum value.
          // DIVERGES(chartjs): adapt-scale-display-enum, the enum value.
          'y': <String, Object?>{
            'display': ScaleDisplay.off,
            'stacked': StackMode.on,
          },
        },
      },
    },
    'options': <String, Object?>{
      'run': (Chart chart) {
        final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
        spliceList(datasets, 0, 1);
        notifyArrayListeners(datasets, 'splice', <Object?>[0, 1]);
        chart.update();
      },
    },
  };
}
