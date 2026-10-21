// Ported from Chart.js v4.5.1+7169e651 docs/charts/scatter.md (MIT, Chart.js Contributors).

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The gallery imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter_chartjs/src/types/basic.dart';

/// The scatter chart of `docs/charts/scatter.md:5-47`, with each key and
/// value of the docs block.
AnyObject scatterConfig() => <String, Object?>{
  'type': 'scatter',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Scatter Dataset',
        'data': <Object?>[
          <String, Object?>{'x': -10.0, 'y': 0.0},
          <String, Object?>{'x': 0.0, 'y': 10.0},
          <String, Object?>{'x': 10.0, 'y': 5.0},
          <String, Object?>{'x': 0.5, 'y': 5.5},
        ],
        'backgroundColor': 'rgb(255, 99, 132)',
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'x': <String, Object?>{'type': 'linear', 'position': 'bottom'},
    },
  },
};
