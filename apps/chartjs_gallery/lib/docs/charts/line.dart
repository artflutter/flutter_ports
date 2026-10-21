// Ported from Chart.js v4.5.1+7169e651 docs/charts/line.md (MIT, Chart.js Contributors).

// The package exports nothing from lib/src yet; the public API comes in
// phase 9. The gallery imports the ported files directly.
// ignore_for_file: implementation_imports

import 'package:flutter_chartjs/src/types/basic.dart';

/// The line chart of `docs/charts/line.md:5-31`.
///
/// The labels are the strings of `Utils.months({count: 7})`
/// (`docs/scripts/utils.js:91-104`). Each other key and value is the docs
/// block.
AnyObject lineConfig() => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
    ],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 80.0, 81.0, 56.0, 55.0, 40.0],
        'fill': false,
        'borderColor': 'rgb(75, 192, 192)',
        'tension': 0.1,
      },
    ],
  },
};

/// The vertical line chart of `docs/charts/line.md:233-285`.
///
/// The labels are the strings of `Utils.months({count: 7})`
/// (`docs/scripts/utils.js:91-104`). Each other key and value is the docs
/// block.
AnyObject lineVerticalConfig() => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
    ],
    'datasets': <Object?>[
      <String, Object?>{
        'axis': 'y',
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 80.0, 81.0, 56.0, 55.0, 40.0],
        'fill': false,
        'backgroundColor': <Object?>[
          'rgba(255, 99, 132, 0.2)',
          'rgba(255, 159, 64, 0.2)',
          'rgba(255, 205, 86, 0.2)',
          'rgba(75, 192, 192, 0.2)',
          'rgba(54, 162, 235, 0.2)',
          'rgba(153, 102, 255, 0.2)',
          'rgba(201, 203, 207, 0.2)',
        ],
        'borderColor': <Object?>[
          'rgb(255, 99, 132)',
          'rgb(255, 159, 64)',
          'rgb(255, 205, 86)',
          'rgb(75, 192, 192)',
          'rgb(54, 162, 235)',
          'rgb(153, 102, 255)',
          'rgb(201, 203, 207)',
        ],
        'borderWidth': 1.0,
      },
    ],
  },
  'options': <String, Object?>{
    'indexAxis': 'y',
    'scales': <String, Object?>{
      'x': <String, Object?>{'beginAtZero': true},
    },
  },
};
