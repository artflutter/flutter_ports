// Ported from Chart.js v4.6.1 docs/charts/bubble.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
import 'dart:ui' as ui;

import 'package:flutter_chartjs_port/chartjs.dart' show ChartPaint;

/// The bubble chart of `docs/charts/bubble.md:5-36`, with each key and
/// value of the docs block.
Map<String, Object?> bubbleConfig() => <String, Object?>{
  'type': 'bubble',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'First Dataset',
        'data': <Object?>[
          <String, Object?>{'x': 20.0, 'y': 30.0, 'r': 15.0},
          <String, Object?>{'x': 40.0, 'y': 10.0, 'r': 10.0},
        ],
        'backgroundColor': const ChartPaint.solid(
          ui.Color.fromRGBO(255, 99, 132, 1),
        ),
      },
    ],
  },
  'options': <String, Object?>{},
};
