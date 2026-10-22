// Ported from Chart.js v4.5.1+7169e651 docs/charts/bubble.md (MIT, Chart.js Contributors).

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The gallery imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The bubble chart of `docs/charts/bubble.md:5-36`, with each key and
/// value of the docs block.
AnyObject bubbleConfig() => <String, Object?>{
  'type': 'bubble',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'First Dataset',
        'data': <Object?>[
          <String, Object?>{'x': 20.0, 'y': 30.0, 'r': 15.0},
          <String, Object?>{'x': 40.0, 'y': 10.0, 'r': 10.0},
        ],
        'backgroundColor': 'rgb(255, 99, 132)',
      },
    ],
  },
  'options': <String, Object?>{},
};
