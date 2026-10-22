// Ported from Chart.js v4.5.1+7169e651 docs/charts/doughnut.md (MIT, Chart.js Contributors).

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The gallery imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter_chartjs_port/src/types/basic.dart';

/// The doughnut chart of `docs/charts/doughnut.md:15-47`, with each key and
/// value of the docs block.
AnyObject doughnutConfig() => <String, Object?>{
  'type': 'doughnut',
  'data': _data(),
};

/// The pie chart of `docs/charts/doughnut.md:53-85`, with each key and
/// value of the docs block.
AnyObject pieConfig() => <String, Object?>{'type': 'pie', 'data': _data()};

/// The `data` of the two blocks: `doughnut.md:17-33` and `:55-71` are the
/// same.
AnyObject _data() => <String, Object?>{
  'labels': <Object?>['Red', 'Blue', 'Yellow'],
  'datasets': <Object?>[
    <String, Object?>{
      'label': 'My First Dataset',
      'data': <Object?>[300.0, 50.0, 100.0],
      'backgroundColor': <Object?>[
        'rgb(255, 99, 132)',
        'rgb(54, 162, 235)',
        'rgb(255, 205, 86)',
      ],
      'hoverOffset': 4.0,
    },
  ],
};
