// Ported from Chart.js v4.6.1 docs/charts/scatter.md (MIT, Chart.js Contributors).

/// The scatter chart of `docs/charts/scatter.md:5-47`, with each key and
/// value of the docs block.
Map<String, Object?> scatterConfig() => <String, Object?>{
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
