// Ported from Chart.js v4.6.1 docs/charts/doughnut.md (MIT, Chart.js Contributors).

/// The doughnut chart of `docs/charts/doughnut.md:15-47`, with each key and
/// value of the docs block.
Map<String, Object?> doughnutConfig() => <String, Object?>{
  'type': 'doughnut',
  'data': _data(),
};

/// The pie chart of `docs/charts/doughnut.md:53-85`, with each key and
/// value of the docs block.
Map<String, Object?> pieConfig() => <String, Object?>{
  'type': 'pie',
  'data': _data(),
};

/// The `data` of the two blocks: `doughnut.md:17-33` and `:55-71` are the
/// same.
Map<String, Object?> _data() => <String, Object?>{
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
