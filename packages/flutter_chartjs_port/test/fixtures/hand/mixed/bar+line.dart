// Ported from Chart.js v4.6.1 test/fixtures/mixed/bar+line.js (MIT, Chart.js Contributors).
// ignore_for_file: file_names
/// A hand-ported fixture config (Chart.js ADR 0029, section 4), the
/// hand port of a data fixture with a class value (Chart.js ADR 0115).
library;

import 'package:chartjs_test_utils/flutter.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The config of the upstream file, as tool 4 decoded it. Each call
/// makes new objects.
FixtureConfig fixture() => FixtureConfig.map(
  <String, Object?>{
    'data': <String, Object?>{
      'datasets': <Object?>[
        <String, Object?>{
          'type': 'line',
          'data': <Object?>[6, 16, 3, 19],
          'borderColor': '#0000ff',
          // DIVERGES(chartjs): adapt-fill-target-objects, the target value.
          'fill': FillTarget.none,
        },
        <String, Object?>{
          'type': 'bar',
          'data': <Object?>[5, 20, 1, 10],
          'backgroundColor': '#00ff00',
          'borderColor': '#ff0000',
        },
      ],
    },
    'options': <String, Object?>{
      // DIVERGES(chartjs): adapt-axis-objects, the axis
      // class.
      'indexAxis': const YAxis(),
      'scales': <String, Object?>{
        'x': <String, Object?>{'position': 'top'},
        'y': <String, Object?>{
          // DIVERGES(chartjs): adapt-axis-objects, the axis
          // class.
          'axis': const YAxis(),
          'labels': <Object?>['a', 'b', 'c', 'd'],
        },
      },
    },
  },
  options: const AcquireOptions(canvas: HarnessCanvas(width: 512, height: 256)),
);
