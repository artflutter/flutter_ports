// Ported from Chart.js v4.5.1+7169e651 docs/charts/mixed.md (MIT, Chart.js Contributors).

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The gallery imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The mixed chart of `docs/charts/mixed.md:27-70`: a `scatter` chart with
/// a `bar` and a `line` dataset, with each key and value of the docs block.
AnyObject mixedConfig() => <String, Object?>{
  'type': 'scatter',
  'data': <String, Object?>{
    'labels': <Object?>['January', 'February', 'March', 'April'],
    'datasets': <Object?>[
      <String, Object?>{
        'type': 'bar',
        'label': 'Bar Dataset',
        'data': <Object?>[10.0, 20.0, 30.0, 40.0],
        'borderColor': 'rgb(255, 99, 132)',
        'backgroundColor': 'rgba(255, 99, 132, 0.2)',
      },
      <String, Object?>{
        'type': 'line',
        'label': 'Line Dataset',
        'data': <Object?>[50.0, 50.0, 50.0, 50.0],
        'fill': false,
        'borderColor': 'rgb(54, 162, 235)',
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'y': <String, Object?>{'beginAtZero': true},
    },
  },
};
