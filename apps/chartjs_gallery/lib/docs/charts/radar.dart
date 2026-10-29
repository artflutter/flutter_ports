// Ported from Chart.js v4.6.1 docs/charts/radar.md (MIT, Chart.js Contributors).

/// The radar chart of `docs/charts/radar.md:7-61`, with each key and value
/// of the docs block.
///
/// The datasets have `fill: true` (`radar.md:22`, `:32`). The gallery
/// registers the filler plugin of `registerables`. Thus the chart fills the
/// area of each dataset, and `initialize` prints no `fill` warning
/// (core.datasetController.js:287-289).
Map<String, Object?> radarConfig() => <String, Object?>{
  'type': 'radar',
  'data': <String, Object?>{
    'labels': <Object?>[
      'Eating',
      'Drinking',
      'Sleeping',
      'Designing',
      'Coding',
      'Cycling',
      'Running',
    ],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 90.0, 81.0, 56.0, 55.0, 40.0],
        'fill': true,
        'backgroundColor': 'rgba(255, 99, 132, 0.2)',
        'borderColor': 'rgb(255, 99, 132)',
        'pointBackgroundColor': 'rgb(255, 99, 132)',
        'pointBorderColor': '#fff',
        'pointHoverBackgroundColor': '#fff',
        'pointHoverBorderColor': 'rgb(255, 99, 132)',
      },
      <String, Object?>{
        'label': 'My Second Dataset',
        'data': <Object?>[28.0, 48.0, 40.0, 19.0, 96.0, 27.0, 100.0],
        'fill': true,
        'backgroundColor': 'rgba(54, 162, 235, 0.2)',
        'borderColor': 'rgb(54, 162, 235)',
        'pointBackgroundColor': 'rgb(54, 162, 235)',
        'pointBorderColor': '#fff',
        'pointHoverBackgroundColor': '#fff',
        'pointHoverBorderColor': 'rgb(54, 162, 235)',
      },
    ],
  },
  'options': <String, Object?>{
    'elements': <String, Object?>{
      'line': <String, Object?>{'borderWidth': 3.0},
    },
  },
};
