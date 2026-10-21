// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/stacking/updates.js (MIT, Chart.js Contributors).
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs/src/core/core.controller.dart';
import 'package:flutter_chartjs/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs/src/js/js_array.dart';
import 'package:flutter_chartjs/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/9424',
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 1, 1],
          'stack': 's1',
          'borderColor': '#ff0000',
        },
        <String, Object?>{
          'data': <Object?>[2, 2, 2],
          'stack': 's1',
          'borderColor': '#00ff00',
        },
        <String, Object?>{
          'data': <Object?>[3, 3, 3],
          'stack': 's1',
          'borderColor': '#0000ff',
        },
      ],
    },
    'options': <String, Object?>{
      'borderWidth': 5,
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': true, 'stacked': true},
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'run': (Chart chart) {
      // Upstream: chart.data.datasets.splice(1, 0, {...}). The splice, then
      // the body of the hooked method (differences.md row
      // platform-array-events).
      final datasets = jsGet(chart.data, 'datasets')! as List<Object?>;
      final dataset = <String, Object?>{
        'data': <Object?>[1.5, 1.5, 1.5],
        'stack': 's2',
        'borderColor': '#000000',
      };
      jsSplice(datasets, 1, 0, <Object?>[dataset]);
      notifyArrayListeners(datasets, 'splice', <Object?>[1, 0, dataset]);
      chart.update();
    },
  },
};
