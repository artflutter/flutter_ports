// Ported from Chart.js v4.5.1+7169e651 test/fixtures/plugin.colors/dynamic-datasets-default.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart';
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// `chart.data.datasets.push({...})` is [List.add], then
/// [notifyArrayListeners], the body of the hooked method (differences.md
/// row platform-array-events). The datasets array has no listeners, so the
/// notification does nothing, as upstream.
Map<String, Object?> fixture() {
  return <String, Object?>{
    'config': <String, Object?>{
      'type': 'bar',
      'data': <String, Object?>{
        'labels': <Object?>[0, 1, 2, 3, 4, 5],
        'datasets': <Object?>[
          <String, Object?>{
            'data': <Object?>[5, 5, 5, 5, 5, 5],
          },
        ],
      },
      'options': <String, Object?>{
        'scales': <String, Object?>{
          'x': <String, Object?>{
            'ticks': <String, Object?>{'display': false},
          },
          'y': <String, Object?>{
            'ticks': <String, Object?>{'display': false},
          },
        },
        'plugins': <String, Object?>{
          'legend': false,
          'colors': <String, Object?>{'enabled': true},
        },
      },
    },
    'options': <String, Object?>{
      'run': (Chart chart) {
        final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
        final item = <String, Object?>{
          'data': <Object?>[5, 5, 5, 5, 5, 5],
        };
        datasets.add(item);
        notifyArrayListeners(datasets, 'push', <Object?>[item]);

        chart.update();
      },
    },
  };
}
