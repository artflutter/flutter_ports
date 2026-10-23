// Ported from Chart.js v4.5.1+7169e651 test/fixtures/controller.line/fill/no-border.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4).
library;

import 'dart:async';

import 'package:chartjs_test_utils/flutter.dart';

/// `module.exports` of the upstream file. Each call runs the module body.
///
/// The `run` hook (:37-39) gives the Promise of a `setTimeout` of 50 ms. The
/// port is a `Future` that the harness task of `setTimeout` completes
/// (Chart.js ADR 0022, section 7, and Chart.js ADR 0041, section 10 item 5).
/// The runner pumps frames of 16 ms until the `Future` completes: the
/// animation of 1 ms ends in the first frame.
Map<String, Object?> fixture() => <String, Object?>{
  'config': <String, Object?>{
    'type': 'line',
    'data': <String, Object?>{
      'labels': <Object?>[0, 1, 2, 3, 4, 5],
      'datasets': <Object?>[
        <String, Object?>{
          'data': <Object?>[12, 19, 3, 5, 2, 3],
          'backgroundColor': '#ff0000',
          'borderWidth': 0,
          'tension': 0.4,
          'fill': true,
        },
      ],
    },
    'options': <String, Object?>{
      'animation': <String, Object?>{
        'duration': 1,
      },
      'scales': <String, Object?>{
        'x': <String, Object?>{'display': false},
        'y': <String, Object?>{'display': false},
      },
      'plugins': <String, Object?>{
        'legend': false,
        'title': false,
        'tooltip': false,
        'filler': true,
      },
    },
  },
  'options': <String, Object?>{
    'canvas': <String, Object?>{
      'height': 256,
      'width': 512,
    },
    'run': () {
      final resolve = Completer<void>();
      setTimeout(resolve.complete, 50);
      return resolve.future;
    },
  },
};
