// Ported from Chart.js v4.6.1 test/fixtures/plugin.legend/borderRadius/legend-border-radius.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'package:flutter_chartjs_port/src/core/core.controller.dart';
import 'package:flutter_chartjs_port/src/js/js_function.dart' show jsCall;
import 'package:flutter_chartjs_port/src/js/js_object.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>['Red', 'Blue', 'Yellow', 'Green', 'Purple', 'Orange'],
      'datasets': <Object?>[
        <String, Object?>{
          'label': '# of Votes',
          'data': <Object?>[12, 19, 3, 5, 2, 3],
          'borderWidth': 1,
          'borderColor': '#FF0000',
          'backgroundColor': '#00FF00',
        },
        <String, Object?>{
          'label': '# of Points',
          'data': <Object?>[7, 11, 5, 8, 3, 7],
          'borderWidth': 2,
          'borderColor': '#FF00FF',
          'backgroundColor': '#0000FF',
        },
      ],
    },
    'options': <String, Object?>{
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'plugins': <String, Object?>{
        'title': false,
        'tooltip': false,
        'filler': false,
        'legend': <String, Object?>{
          'labels': <String, Object?>{
            'generateLabels': (Object? chart) {
              // Chart.defaults.plugins.legend.labels.generateLabels(chart)
              final items =
                  jsCall(
                        jsGet(
                          jsGet(
                            jsGet(jsGet(Chart.defaults, 'plugins'), 'legend'),
                            'labels',
                          ),
                          'generateLabels',
                        ),
                        [chart],
                      )!
                      as List<Object?>;

              for (final item in items) {
                (item! as Map<String, Object?>)['borderRadius'] = 5;
              }

              return items;
            },
          },
        },
      },
    },
  },
  'options': <String, Object?>{
    'spriteText': true,
    'canvas': <String, Object?>{'width': 512, 'height': 256},
  },
};
