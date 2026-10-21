// Ported from Chart.js v4.5.1+7169e651 docs/charts/polar.md (MIT, Chart.js Contributors).

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The gallery imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter_chartjs/src/types/basic.dart';

/// The polar area chart of `docs/charts/polar.md:7-43`, with each key and
/// value of the docs block.
AnyObject polarAreaConfig() => <String, Object?>{
  'type': 'polarArea',
  'data': <String, Object?>{
    'labels': <Object?>['Red', 'Green', 'Yellow', 'Grey', 'Blue'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'My First Dataset',
        'data': <Object?>[11.0, 16.0, 7.0, 3.0, 14.0],
        'backgroundColor': <Object?>[
          'rgb(255, 99, 132)',
          'rgb(75, 192, 192)',
          'rgb(255, 205, 86)',
          'rgb(201, 203, 207)',
          'rgb(54, 162, 235)',
        ],
      },
    ],
  },
  'options': <String, Object?>{},
};
