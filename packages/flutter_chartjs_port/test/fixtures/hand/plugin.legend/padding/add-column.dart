// Ported from Chart.js v4.5.1+7169e651 test/fixtures/plugin.legend/padding/add-column.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/helpers/helpers.collection.dart'
    show notifyArrayListeners;
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'description': 'https://github.com/chartjs/Chart.js/issues/9278',
  'config': <String, Object?>{
    'type': 'pie',
    'data': <String, Object?>{
      'labels': <Object?>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
          'backgroundColor': 'red',
        },
      ],
    },
    'options': <String, Object?>{
      'plugins': <String, Object?>{
        'legend': <String, Object?>{'position': 'left'},
      },
      'layout': <String, Object?>{
        'padding': <String, Object?>{'top': 55, 'left': 30, 'right': 30},
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 400, 'height': 300},
    'run': (Chart chart) {
      // Upstream: chart.data.labels.push('k'). The chart does not listen to
      // the labels array.
      (jsGet(chart.data, 'labels')! as List<Object?>).add('k');
      // Upstream: chart.data.datasets[0].data.push(11). The push, then the
      // body of the hooked method (differences.md row
      // platform-array-events).
      final data =
          jsGet(jsGetIndex(jsGet(chart.data, 'datasets'), 0), 'data')!
                as List<Object?>
            ..add(11);
      notifyArrayListeners(data, 'push', <Object?>[11]);
      chart.update();
    },
  },
};
