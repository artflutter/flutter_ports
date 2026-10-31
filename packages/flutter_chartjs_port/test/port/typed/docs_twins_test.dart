// Original code, not ported from Chart.js: the typed twins of the docs configs.
@TestOn('vm')
library;

import 'package:flutter/painting.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chart_twin.dart';

// Chart.js ADR 0052, section 11: the docs twins. Each typed config of this
// file gives the chart of its raw twin (`expectChartTwin` of
// chart_twin.dart): the same observations (the chart area, the scales, the
// element properties, the resolved element options and active options, the
// hits on a grid) and the same draw calls, before and during a hover, with
// the colors in parsed form. Each twin runs unthemed and under
// `ChartThemeData.light()`.
//
// The group "the docs configs" has the 12 docs configs of the gallery: the
// 11 `chart-editor` blocks of `apps/chartjs_gallery/lib/docs/charts/` and
// the Area sample of `lib/docs/samples/area/line_boundaries.dart` with its 4
// fill variants. The raw twin of each is a copy of the gallery config, with
// each key and value of the docs block; the docs lines are in its comment.
// The typed configs need no `extra`. Three typed forms differ from the docs
// block (Chart.js ADR 0052, section 4):
// - The horizontal bar and the vertical line leave out the dataset keys
//   `axis` and, for the bar, `fill: false`: Chart.js 4.6.1 reads no `axis`
//   key of a dataset, and the filler reads `fill` only for a dataset with a
//   line element.
// - The title of the Area sample is a function of the context
//   (`line-boundaries.md:106`). `ChartTitle.text` is a `String`: the typed
//   text of each variant is the constant of that function.
// - The radar datasets have `fill: true` (`radar.md:22`, `:32`). The typed
//   fill is `ChartFill.origin`: the filler reads `true` as `'origin'`
//   (`parseFillOption`, `src/plugins/plugin.filler/filler.options.js:133`),
//   so the fill and the draw calls are the same. The resolved `fill` option
//   of the line element keeps the value form: the compare maps the raw
//   `true` to `'origin'` (`_fillTrueAsOrigin`).
//
// The group "the chart types" has one chart of each of the 8 chart types
// with more typed keys than the docs: the axes and their ticks, grids and
// titles, the legend, the title and the subtitle, the tooltip with its text
// callbacks, the interaction, the animation, the filler, the elements, the
// padding, the time and logarithmic axes, the scriptable forms of the
// colors in Lists, `ChartLength`, `ChartFill` and the point styles. Each raw
// twin is the raw form of the same chart: the Chart.js option paths with
// the values of the typed lowering (Chart.js ADR 0052, section 7). The
// callbacks of the raw twins read the raw objects and give the same text.
//
// VM only: the twins are `testWidgets` cases with a `ChartView`.

// The colors of the docs (`docs/scripts/utils.js:122-135`).

/// `rgb(255, 99, 132)`.
const Color _red = Color(0xFFFF6384);

/// `rgb(255, 159, 64)`.
const Color _orange = Color(0xFFFF9F40);

/// `rgb(255, 205, 86)`.
const Color _yellow = Color(0xFFFFCD56);

/// `rgb(75, 192, 192)`.
const Color _green = Color(0xFF4BC0C0);

/// `rgb(54, 162, 235)`.
const Color _blue = Color(0xFF36A2EB);

/// `rgb(153, 102, 255)`.
const Color _purple = Color(0xFF9966FF);

/// `rgb(201, 203, 207)`.
const Color _grey = Color(0xFFC9CBCF);

/// `#fff`.
const Color _white = Color(0xFFFFFFFF);

/// `#1b3a5c`, a color of the type charts.
const Color _navy = Color(0xFF1B3A5C);

/// The 7 colors of the bar and line docs blocks at the alpha [alpha].
List<Color> _seven(double alpha) => [
  Color.fromRGBO(255, 99, 132, alpha),
  Color.fromRGBO(255, 159, 64, alpha),
  Color.fromRGBO(255, 205, 86, alpha),
  Color.fromRGBO(75, 192, 192, alpha),
  Color.fromRGBO(54, 162, 235, alpha),
  Color.fromRGBO(153, 102, 255, alpha),
  Color.fromRGBO(201, 203, 207, alpha),
];

/// The 7 background colors of the bar and line docs blocks.
const List<Object?> _sevenBackgrounds = [
  'rgba(255, 99, 132, 0.2)',
  'rgba(255, 159, 64, 0.2)',
  'rgba(255, 205, 86, 0.2)',
  'rgba(75, 192, 192, 0.2)',
  'rgba(54, 162, 235, 0.2)',
  'rgba(153, 102, 255, 0.2)',
  'rgba(201, 203, 207, 0.2)',
];

/// The 7 border colors of the bar and line docs blocks.
const List<Object?> _sevenBorders = [
  'rgb(255, 99, 132)',
  'rgb(255, 159, 64)',
  'rgb(255, 205, 86)',
  'rgb(75, 192, 192)',
  'rgb(54, 162, 235)',
  'rgb(153, 102, 255)',
  'rgb(201, 203, 207)',
];

/// The labels of `Utils.months({count: 7})` (`docs/scripts/utils.js:91-104`).
const List<String> _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
];

/// The data of the bar and line docs blocks.
const List<num?> _docsData = [65, 59, 80, 81, 56, 55, 40];

/// One twin: a typed config and its raw twin.
typedef _Twin = ({
  String name,
  ChartConfig Function() typed,
  Map<String, Object?> Function() raw,
  Object? Function(Object? observation)? rawObservation,
});

// ---------------------------------------------------------------------------
// The docs configs of the gallery.

/// The raw twin of `barVerticalConfig` of the gallery
/// (`docs/charts/bar.md:5-54`).
Map<String, Object?> _barVerticalRaw() => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>[..._months],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 80.0, 81.0, 56.0, 55.0, 40.0],
        'backgroundColor': <Object?>[..._sevenBackgrounds],
        'borderColor': <Object?>[..._sevenBorders],
        'borderWidth': 1.0,
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'y': <String, Object?>{'beginAtZero': true},
    },
  },
};

/// The typed `bar.md:5-54`.
ChartConfig _barVerticalTyped() => ChartConfig(
  type: .bar,
  labels: _months,
  datasets: [
    BarDataset(
      label: 'My First Dataset',
      data: _docsData,
      backgroundColors: _seven(0.2),
      borderColors: _seven(1),
      borderWidth: 1,
    ),
  ],
  scales: const {'y': LinearAxis(beginAtZero: true)},
);

/// The raw twin of `barHorizontalConfig` of the gallery
/// (`docs/charts/bar.md:304-351`).
Map<String, Object?> _barHorizontalRaw() => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>[..._months],
    'datasets': <Object?>[
      <String, Object?>{
        'axis': 'y',
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 80.0, 81.0, 56.0, 55.0, 40.0],
        'fill': false,
        'backgroundColor': <Object?>[..._sevenBackgrounds],
        'borderColor': <Object?>[..._sevenBorders],
        'borderWidth': 1.0,
      },
    ],
  },
  'options': <String, Object?>{'indexAxis': 'y'},
};

/// The typed `bar.md:304-351`, without the keys `axis` and `fill` that
/// Chart.js does not read for a bar dataset.
ChartConfig _barHorizontalTyped() => ChartConfig(
  type: .bar,
  labels: _months,
  datasets: [
    BarDataset(
      label: 'My First Dataset',
      data: _docsData,
      backgroundColors: _seven(0.2),
      borderColors: _seven(1),
      borderWidth: 1,
    ),
  ],
  indexAxis: .y,
);

/// The raw twin of `bubbleConfig` of the gallery
/// (`docs/charts/bubble.md:5-36`).
Map<String, Object?> _bubbleRaw() => <String, Object?>{
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

/// The typed `bubble.md:5-36`.
ChartConfig _bubbleTyped() => ChartConfig(
  type: .bubble,
  datasets: [
    BubbleDataset(
      label: 'First Dataset',
      points: [DataPoint.bubble(20, 30, 15), DataPoint.bubble(40, 10, 10)],
      backgroundColor: _red,
    ),
  ],
);

/// The `data` of the doughnut and pie docs blocks (`doughnut.md:17-33`,
/// `:55-71`).
Map<String, Object?> _doughnutData() => <String, Object?>{
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

/// The raw twin of `doughnutConfig` of the gallery
/// (`docs/charts/doughnut.md:15-47`).
Map<String, Object?> _doughnutRaw() => <String, Object?>{
  'type': 'doughnut',
  'data': _doughnutData(),
};

/// The typed `doughnut.md:15-47`.
ChartConfig _doughnutTyped() => const ChartConfig(
  type: .doughnut,
  labels: ['Red', 'Blue', 'Yellow'],
  datasets: [
    DoughnutDataset(
      label: 'My First Dataset',
      data: [300, 50, 100],
      backgroundColors: [_red, _blue, _yellow],
      hoverOffset: 4,
    ),
  ],
);

/// The raw twin of `pieConfig` of the gallery
/// (`docs/charts/doughnut.md:53-85`).
Map<String, Object?> _pieRaw() => <String, Object?>{
  'type': 'pie',
  'data': _doughnutData(),
};

/// The typed `doughnut.md:53-85`.
ChartConfig _pieTyped() => const ChartConfig(
  type: .pie,
  labels: ['Red', 'Blue', 'Yellow'],
  datasets: [
    PieDataset(
      label: 'My First Dataset',
      data: [300, 50, 100],
      backgroundColors: [_red, _blue, _yellow],
      hoverOffset: 4,
    ),
  ],
);

/// The raw twin of `lineConfig` of the gallery
/// (`docs/charts/line.md:5-31`).
Map<String, Object?> _lineRaw() => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>[..._months],
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

/// The typed `line.md:5-31`.
ChartConfig _lineTyped() => const ChartConfig(
  type: .line,
  labels: _months,
  datasets: [
    LineDataset(
      label: 'My First Dataset',
      data: _docsData,
      fill: .none,
      borderColor: _green,
      tension: 0.1,
    ),
  ],
);

/// The raw twin of `lineVerticalConfig` of the gallery
/// (`docs/charts/line.md:233-285`).
Map<String, Object?> _lineVerticalRaw() => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>[..._months],
    'datasets': <Object?>[
      <String, Object?>{
        'axis': 'y',
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 80.0, 81.0, 56.0, 55.0, 40.0],
        'fill': false,
        'backgroundColor': <Object?>[..._sevenBackgrounds],
        'borderColor': <Object?>[..._sevenBorders],
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

/// The typed `line.md:233-285`, without the key `axis` that Chart.js does
/// not read.
ChartConfig _lineVerticalTyped() => ChartConfig(
  type: .line,
  labels: _months,
  datasets: [
    LineDataset(
      label: 'My First Dataset',
      data: _docsData,
      fill: .none,
      backgroundColors: _seven(0.2),
      borderColors: _seven(1),
      borderWidth: 1,
    ),
  ],
  indexAxis: .y,
  scales: const {'x': LinearAxis(beginAtZero: true)},
);

/// The raw twin of `mixedConfig` of the gallery
/// (`docs/charts/mixed.md:27-70`).
Map<String, Object?> _mixedRaw() => <String, Object?>{
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

/// The typed `mixed.md:27-70`: a scatter chart with a bar and a line
/// dataset.
ChartConfig _mixedTyped() => const ChartConfig(
  type: .scatter,
  labels: ['January', 'February', 'March', 'April'],
  datasets: [
    BarDataset(
      label: 'Bar Dataset',
      data: [10, 20, 30, 40],
      borderColor: _red,
      backgroundColor: Color.fromRGBO(255, 99, 132, 0.2),
    ),
    LineDataset(
      label: 'Line Dataset',
      data: [50, 50, 50, 50],
      fill: .none,
      borderColor: _blue,
    ),
  ],
  scales: {'y': LinearAxis(beginAtZero: true)},
);

/// The raw twin of `polarAreaConfig` of the gallery
/// (`docs/charts/polar.md:7-43`).
Map<String, Object?> _polarAreaRaw() => <String, Object?>{
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

/// The typed `polar.md:7-43`.
ChartConfig _polarAreaTyped() => const ChartConfig(
  type: .polarArea,
  labels: ['Red', 'Green', 'Yellow', 'Grey', 'Blue'],
  datasets: [
    PolarAreaDataset(
      label: 'My First Dataset',
      data: [11, 16, 7, 3, 14],
      backgroundColors: [_red, _green, _yellow, _grey, _blue],
    ),
  ],
);

/// The raw twin of `radarConfig` of the gallery
/// (`docs/charts/radar.md:7-61`).
Map<String, Object?> _radarRaw() => <String, Object?>{
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

/// The typed `radar.md:7-61`, with `ChartFill.origin` for `fill: true`.
ChartConfig _radarTyped() => const ChartConfig(
  type: .radar,
  labels: [
    'Eating',
    'Drinking',
    'Sleeping',
    'Designing',
    'Coding',
    'Cycling',
    'Running',
  ],
  datasets: [
    RadarDataset(
      label: 'My First Dataset',
      data: [65, 59, 90, 81, 56, 55, 40],
      fill: .origin,
      backgroundColor: Color.fromRGBO(255, 99, 132, 0.2),
      borderColor: _red,
      pointBackgroundColor: _red,
      pointBorderColor: _white,
      pointHoverBackgroundColor: _white,
      pointHoverBorderColor: _red,
    ),
    RadarDataset(
      label: 'My Second Dataset',
      data: [28, 48, 40, 19, 96, 27, 100],
      fill: .origin,
      backgroundColor: Color.fromRGBO(54, 162, 235, 0.2),
      borderColor: _blue,
      pointBackgroundColor: _blue,
      pointBorderColor: _white,
      pointHoverBackgroundColor: _white,
      pointHoverBorderColor: _blue,
    ),
  ],
  elements: ChartElements(line: LineElementStyle(borderWidth: 3)),
);

/// [observation] with the value `'origin'` for each `fill: true`: the
/// filler reads `fill: true` as `'origin'` (`filler.options.js:133`).
Object? _fillTrueAsOrigin(Object? observation) => switch (observation) {
  final Map<String, Object?> map => <String, Object?>{
    for (final MapEntry(:key, :value) in map.entries)
      key: key == 'fill' && value == true ? 'origin' : _fillTrueAsOrigin(value),
  },
  final List<Object?> list => [
    for (final item in list) _fillTrueAsOrigin(item),
  ],
  _ => observation,
};

/// The raw twin of `scatterConfig` of the gallery
/// (`docs/charts/scatter.md:5-47`).
Map<String, Object?> _scatterRaw() => <String, Object?>{
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

/// The typed `scatter.md:5-47`.
ChartConfig _scatterTyped() => ChartConfig(
  type: .scatter,
  datasets: [
    ScatterDataset(
      label: 'Scatter Dataset',
      points: [
        DataPoint(-10, 0),
        DataPoint(0, 10),
        DataPoint(10, 5),
        DataPoint(0.5, 5.5),
      ],
      backgroundColor: _red,
    ),
  ],
  scales: const {'x': LinearAxis(position: .bottom)},
);

/// The labels of `Utils.months({count: 8})` of the Area sample.
const List<String> _areaMonths = [..._months, 'August'];

/// The data of the Area sample: `Utils.numbers` with the seed 2026
/// (`line_boundaries.dart` of the gallery).
const List<num?> _areaData = [
  97.81,
  -42.3,
  84.05,
  -46.6,
  -31.77,
  12.48,
  -59.53,
  -0.87,
];

/// The raw twin of the Area config of the gallery at the fill [fill]
/// (`docs/samples/area/line-boundaries.md:3-120`), with the title function
/// of `:106`.
Map<String, Object?> _areaRaw(Object fill) => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>[..._areaMonths],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Dataset',
        'data': <Object?>[..._areaData],
        'borderColor': 'rgb(255, 99, 132)',
        'backgroundColor': 'rgba(255, 99, 132, 0.5)',
        'fill': fill,
      },
    ],
  },
  'options': <String, Object?>{
    'plugins': <String, Object?>{
      'filler': <String, Object?>{'propagate': false},
      'title': <String, Object?>{'display': true, 'text': _areaTitleText},
    },
    'interaction': <String, Object?>{'intersect': false},
  },
};

/// `(ctx) => 'Fill: ' + ctx.chart.data.datasets[0].fill`
/// (`line-boundaries.md:106`), as in the gallery.
Object _areaTitleText(Object? ctx) {
  final chart = _byName(ctx, 'chart')! as Chart;
  final datasets = _byName(chart.data, 'datasets')! as List<Object?>;
  final dataset = datasets.first;
  return 'Fill: ${_byName(dataset, 'fill')}';
}

/// The typed Area config at the fill [fill], with the constant title
/// [title].
ChartConfig _areaTyped(ChartFill fill, String title) => ChartConfig(
  type: .line,
  labels: _areaMonths,
  datasets: [
    LineDataset(
      label: 'Dataset',
      data: _areaData,
      borderColor: _red,
      backgroundColor: const Color.fromRGBO(255, 99, 132, 0.5),
      fill: fill,
    ),
  ],
  filler: const ChartFiller(propagate: false),
  title: ChartTitle(display: true, text: title),
  interaction: const ChartInteraction(intersect: false),
);

/// The twins of the 12 docs configs of the gallery.
final List<_Twin> _docsTwins = [
  (
    name: 'bar.md:5-54, vertical bar',
    typed: _barVerticalTyped,
    raw: _barVerticalRaw,
    rawObservation: null,
  ),
  (
    name: 'bar.md:304-351, horizontal bar',
    typed: _barHorizontalTyped,
    raw: _barHorizontalRaw,
    rawObservation: null,
  ),
  (
    name: 'bubble.md:5-36',
    typed: _bubbleTyped,
    raw: _bubbleRaw,
    rawObservation: null,
  ),
  (
    name: 'doughnut.md:15-47, doughnut',
    typed: _doughnutTyped,
    raw: _doughnutRaw,
    rawObservation: null,
  ),
  (
    name: 'doughnut.md:53-85, pie',
    typed: _pieTyped,
    raw: _pieRaw,
    rawObservation: null,
  ),
  (
    name: 'line.md:5-31',
    typed: _lineTyped,
    raw: _lineRaw,
    rawObservation: null,
  ),
  (
    name: 'line.md:233-285, vertical line',
    typed: _lineVerticalTyped,
    raw: _lineVerticalRaw,
    rawObservation: null,
  ),
  (
    name: 'mixed.md:27-70',
    typed: _mixedTyped,
    raw: _mixedRaw,
    rawObservation: null,
  ),
  (
    name: 'polar.md:7-43',
    typed: _polarAreaTyped,
    raw: _polarAreaRaw,
    rawObservation: null,
  ),
  (
    name: 'radar.md:7-61',
    typed: _radarTyped,
    raw: _radarRaw,
    rawObservation: _fillTrueAsOrigin,
  ),
  (
    name: 'scatter.md:5-47',
    typed: _scatterTyped,
    raw: _scatterRaw,
    rawObservation: null,
  ),
  for (final (fill, raw) in const [
    (ChartFill.origin, 'origin'),
    (ChartFill.start, 'start'),
    (ChartFill.end, 'end'),
    (ChartFill.none, false),
  ])
    (
      name: 'line-boundaries.md:3-120, fill $raw',
      typed: () => _areaTyped(fill, 'Fill: $raw'),
      raw: () => _areaRaw(raw),
      rawObservation: null,
    ),
];

// ---------------------------------------------------------------------------
// The chart types.

/// The tick format of the bar type chart.
String? _units(AxisTickInfo tick) => '${tick.value.round()} u';

/// The raw tick callback of `_units`.
Object? _rawUnits(Object? value, Object? index, Object? ticks) =>
    '${(value! as num).round()} u';

/// The tooltip label of the bar type chart.
String? _barLabel(ChartTooltipItem item) =>
    '${item.datasetLabel}: ${item.formattedValue} units';

/// The raw tooltip label callback of `_barLabel`.
Object? _rawBarLabel(Object? item) {
  final dataset = _byName(item, 'dataset');
  return '${_byName(dataset, 'label')}: ${_byName(item, 'formattedValue')} '
      'units';
}

/// The typed bar chart: stacked bars with the bar keys, a category and a
/// linear axis with ticks, grids, a title and a tick format, the legend,
/// the title, the tooltip with a label text and the padding.
ChartConfig _barTyped() => const ChartConfig(
  type: .bar,
  labels: ['Q1', 'Q2', 'Q3', 'Q4'],
  datasets: [
    BarDataset(
      label: 'North',
      data: [12, 19, 3, 5],
      backgroundColor: _blue,
      borderColor: _navy,
      borderWidth: 2,
      hoverBackgroundColor: _green,
      hoverBorderWidth: 3,
      stack: 'sales',
      borderRadius: 4,
      barPercentage: 0.8,
      categoryPercentage: 0.9,
    ),
    BarDataset(
      label: 'South',
      data: [7, 11, 5, 8],
      backgroundColors: [_red, _orange, _yellow, _green],
      stack: 'sales',
      maxBarThickness: 40,
      minBarLength: 2,
    ),
    BarDataset(
      label: 'Target',
      data: [10, 10, 10, 10],
      borderColors: [_grey, _grey, _purple, _purple],
      borderWidth: 1,
      stack: 'target',
      order: 1,
      barThickness: 12,
      grouped: true,
    ),
  ],
  scales: {
    'x': CategoryAxis(
      stacked: true,
      grid: AxisGrid(display: false),
      ticks: AxisTicks(color: _navy, font: TextStyle(fontSize: 13)),
    ),
    'y': LinearAxis(
      stacked: true,
      beginAtZero: true,
      suggestedMax: 30,
      ticks: AxisTicks(stepSize: 5, padding: 6, format: _units),
      title: AxisTitle(
        display: true,
        text: 'Units',
        color: _navy,
        font: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        padding: EdgeInsets.symmetric(vertical: 4),
      ),
    ),
  },
  padding: EdgeInsets.all(8),
  legend: ChartLegend(
    position: .bottom,
    align: .start,
    boxWidth: 20,
    boxHeight: 10,
    labelPadding: 12,
    labelColor: _navy,
    labelFont: TextStyle(fontSize: 11),
  ),
  title: ChartTitle(
    display: true,
    text: 'Sales by quarter',
    align: .start,
    font: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    padding: EdgeInsets.only(top: 4, bottom: 8),
  ),
  tooltip: ChartTooltip(
    mode: .index,
    intersect: false,
    backgroundColor: Color(0xCC000000),
    padding: EdgeInsets.all(10),
    cornerRadius: 4,
    displayColors: false,
    titleFont: TextStyle(fontSize: 13),
    labelText: _barLabel,
  ),
);

/// The raw twin of `_barTyped`.
Map<String, Object?> _barRaw() => <String, Object?>{
  'type': 'bar',
  'data': <String, Object?>{
    'labels': <Object?>['Q1', 'Q2', 'Q3', 'Q4'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'North',
        'data': <Object?>[12, 19, 3, 5],
        'backgroundColor': 'rgb(54, 162, 235)',
        'borderColor': '#1b3a5c',
        'borderWidth': 2,
        'hoverBackgroundColor': 'rgb(75, 192, 192)',
        'hoverBorderWidth': 3,
        'stack': 'sales',
        'borderRadius': 4,
        'barPercentage': 0.8,
        'categoryPercentage': 0.9,
      },
      <String, Object?>{
        'label': 'South',
        'data': <Object?>[7, 11, 5, 8],
        'backgroundColor': <Object?>[
          'rgb(255, 99, 132)',
          'rgb(255, 159, 64)',
          'rgb(255, 205, 86)',
          'rgb(75, 192, 192)',
        ],
        'stack': 'sales',
        'maxBarThickness': 40,
        'minBarLength': 2,
      },
      <String, Object?>{
        'label': 'Target',
        'data': <Object?>[10, 10, 10, 10],
        'borderColor': <Object?>[
          'rgb(201, 203, 207)',
          'rgb(201, 203, 207)',
          'rgb(153, 102, 255)',
          'rgb(153, 102, 255)',
        ],
        'borderWidth': 1,
        'stack': 'target',
        'order': 1,
        'barThickness': 12,
        'grouped': true,
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': 'category',
        'stacked': true,
        'grid': <String, Object?>{'display': false},
        'ticks': <String, Object?>{
          'color': '#1b3a5c',
          'font': <String, Object?>{'size': 13},
        },
      },
      'y': <String, Object?>{
        'type': 'linear',
        'stacked': true,
        'beginAtZero': true,
        'suggestedMax': 30,
        'ticks': <String, Object?>{
          'stepSize': 5,
          'padding': 6,
          'callback': _rawUnits,
        },
        'title': <String, Object?>{
          'display': true,
          'text': 'Units',
          'color': '#1b3a5c',
          'font': <String, Object?>{'size': 12, 'weight': 700},
          'padding': <String, Object?>{
            'top': 4,
            'right': 0,
            'bottom': 4,
            'left': 0,
          },
        },
      },
    },
    'layout': <String, Object?>{'padding': 8},
    'plugins': <String, Object?>{
      'legend': <String, Object?>{
        'position': 'bottom',
        'align': 'start',
        'labels': <String, Object?>{
          'color': '#1b3a5c',
          'font': <String, Object?>{'size': 11},
          'boxWidth': 20,
          'boxHeight': 10,
          'padding': 12,
        },
      },
      'title': <String, Object?>{
        'display': true,
        'text': 'Sales by quarter',
        'align': 'start',
        'font': <String, Object?>{'size': 16, 'weight': 600},
        'padding': <String, Object?>{'top': 4, 'bottom': 8},
      },
      'tooltip': <String, Object?>{
        'mode': 'index',
        'intersect': false,
        'backgroundColor': 'rgba(0, 0, 0, 0.8)',
        'titleFont': <String, Object?>{'size': 13},
        'padding': 10,
        'cornerRadius': 4,
        'displayColors': false,
        'callbacks': <String, Object?>{'label': _rawBarLabel},
      },
    },
  },
};

/// The typed line chart: two filled lines with the line and point keys, a
/// gap, a stepped line, a category and a linear axis, the interaction, the
/// subtitle, the legend with point styles, the animation, the filler and the
/// aspect ratio.
ChartConfig _lineTypeTyped() => const ChartConfig(
  type: .line,
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  datasets: [
    LineDataset(
      label: 'This week',
      data: [3, 5, null, 8, 6, 9, 7],
      backgroundColor: Color.fromRGBO(255, 99, 132, 0.25),
      borderColor: _red,
      borderWidth: 2,
      fill: .origin,
      tension: 0.3,
      spanGaps: true,
      pointStyle: .rectRot,
      pointRadius: 5,
      pointHoverRadius: 8,
      pointBackgroundColor: _white,
      pointBorderColor: _red,
      pointBorderWidth: 2,
      pointHoverBackgroundColor: _red,
      pointHoverBorderColor: _white,
    ),
    LineDataset(
      label: 'Last week',
      data: [2, 4, 6, 5, 4, 6, 5],
      backgroundColor: Color.fromRGBO(54, 162, 235, 0.25),
      borderColor: _blue,
      fill: ChartFill.relative(-1),
      borderDash: [6, 4],
      stepped: true,
      pointStyle: .triangle,
    ),
  ],
  scales: {
    'x': CategoryAxis(
      grid: AxisGrid(offset: true, drawTicks: false),
      ticks: AxisTicks(maxRotation: 0, autoSkip: false),
    ),
    'y': LinearAxis(
      min: 0,
      max: 12,
      grid: AxisGrid(
        color: Color.fromRGBO(0, 0, 0, 0.1),
        lineWidth: 0.5,
        drawOnChartArea: true,
      ),
      ticks: AxisTicks(stepSize: 2),
    ),
  },
  aspectRatio: 1.5,
  interaction: ChartInteraction(
    mode: .index,
    intersect: false,
    includeInvisible: true,
  ),
  subtitle: ChartTitle(
    display: true,
    text: 'Steps in thousands',
    color: _navy,
    position: .bottom,
  ),
  legend: ChartLegend(usePointStyle: true, reverse: true),
  animation: ChartAnimation(
    duration: Duration(milliseconds: 400),
    easing: .easeOutQuart,
  ),
  filler: ChartFiller(propagate: true),
);

/// The raw twin of `_lineTypeTyped`.
Map<String, Object?> _lineTypeRaw() => <String, Object?>{
  'type': 'line',
  'data': <String, Object?>{
    'labels': <Object?>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'This week',
        'data': <Object?>[3, 5, null, 8, 6, 9, 7],
        'backgroundColor': 'rgba(255, 99, 132, 0.25)',
        'borderColor': 'rgb(255, 99, 132)',
        'borderWidth': 2,
        'fill': 'origin',
        'tension': 0.3,
        'spanGaps': true,
        'pointStyle': 'rectRot',
        'pointRadius': 5,
        'pointHoverRadius': 8,
        'pointBackgroundColor': '#fff',
        'pointBorderColor': 'rgb(255, 99, 132)',
        'pointBorderWidth': 2,
        'pointHoverBackgroundColor': 'rgb(255, 99, 132)',
        'pointHoverBorderColor': '#fff',
      },
      <String, Object?>{
        'label': 'Last week',
        'data': <Object?>[2, 4, 6, 5, 4, 6, 5],
        'backgroundColor': 'rgba(54, 162, 235, 0.25)',
        'borderColor': 'rgb(54, 162, 235)',
        'fill': '-1',
        'borderDash': <Object?>[6, 4],
        'stepped': true,
        'pointStyle': 'triangle',
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': 'category',
        'grid': <String, Object?>{'offset': true, 'drawTicks': false},
        'ticks': <String, Object?>{'maxRotation': 0, 'autoSkip': false},
      },
      'y': <String, Object?>{
        'type': 'linear',
        'min': 0,
        'max': 12,
        'grid': <String, Object?>{
          'color': 'rgba(0, 0, 0, 0.1)',
          'lineWidth': 0.5,
          'drawOnChartArea': true,
        },
        'ticks': <String, Object?>{'stepSize': 2},
      },
    },
    'aspectRatio': 1.5,
    'interaction': <String, Object?>{
      'mode': 'index',
      'intersect': false,
      'includeInvisible': true,
    },
    'animation': <String, Object?>{'duration': 400, 'easing': 'easeOutQuart'},
    'plugins': <String, Object?>{
      'subtitle': <String, Object?>{
        'display': true,
        'text': 'Steps in thousands',
        'color': '#1b3a5c',
        'position': 'bottom',
      },
      'legend': <String, Object?>{
        'reverse': true,
        'labels': <String, Object?>{'usePointStyle': true},
      },
      'filler': <String, Object?>{'propagate': true},
    },
  },
};

/// The typed scatter chart: time points on a time axis and a logarithmic
/// axis, a line with a value fill, a dashed line with no points and the
/// tooltip format.
ChartConfig _scatterTypeTyped() => ChartConfig(
  type: .scatter,
  datasets: [
    ScatterDataset(
      label: 'Readings',
      points: [
        DataPoint.time(DateTime.utc(2026, 3), 3),
        DataPoint.time(DateTime.utc(2026, 3, 2), 12),
        DataPoint.time(DateTime.utc(2026, 3, 4), 40),
        DataPoint.time(DateTime.utc(2026, 3, 5), 25),
      ],
      backgroundColor: const Color.fromRGBO(153, 102, 255, 0.3),
      borderColor: _purple,
      borderWidth: 1,
      showLine: true,
      fill: const ChartFill.value(10),
      pointRadius: 6,
      pointStyle: .rect,
    ),
    ScatterDataset(
      label: 'Limit',
      points: [
        DataPoint.time(DateTime.utc(2026, 3), 50),
        DataPoint.time(DateTime.utc(2026, 3, 6), 50),
      ],
      borderColor: _red,
      showLine: true,
      borderDash: const [2, 2],
      pointStyle: .none,
      pointHoverRadius: 4,
    ),
  ],
  scales: {
    'x': TimeAxis(
      unit: TimeUnit.day,
      min: DateTime.utc(2026, 2, 28),
      max: DateTime.utc(2026, 3, 7),
      tooltipFormat: 'MMM d',
      position: .bottom,
    ),
    'y': const LogarithmicAxis(
      min: 1,
      max: 100,
      title: AxisTitle(display: true, text: 'ppm'),
    ),
  },
);

/// The raw twin of `_scatterTypeTyped`.
Map<String, Object?> _scatterTypeRaw() => <String, Object?>{
  'type': 'scatter',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Readings',
        'data': <Object?>[
          <String, Object?>{'x': DateTime.utc(2026, 3), 'y': 3},
          <String, Object?>{'x': DateTime.utc(2026, 3, 2), 'y': 12},
          <String, Object?>{'x': DateTime.utc(2026, 3, 4), 'y': 40},
          <String, Object?>{'x': DateTime.utc(2026, 3, 5), 'y': 25},
        ],
        'backgroundColor': 'rgba(153, 102, 255, 0.3)',
        'borderColor': 'rgb(153, 102, 255)',
        'borderWidth': 1,
        'showLine': true,
        'fill': <String, Object?>{'value': 10},
        'pointRadius': 6,
        'pointStyle': 'rect',
      },
      <String, Object?>{
        'label': 'Limit',
        'data': <Object?>[
          <String, Object?>{'x': DateTime.utc(2026, 3), 'y': 50},
          <String, Object?>{'x': DateTime.utc(2026, 3, 6), 'y': 50},
        ],
        'borderColor': 'rgb(255, 99, 132)',
        'showLine': true,
        'borderDash': <Object?>[2, 2],
        'pointStyle': false,
        'pointHoverRadius': 4,
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': 'time',
        'position': 'bottom',
        'min': DateTime.utc(2026, 2, 28),
        'max': DateTime.utc(2026, 3, 7),
        'time': <String, Object?>{'unit': 'day', 'tooltipFormat': 'MMM d'},
      },
      'y': <String, Object?>{
        'type': 'logarithmic',
        'min': 1,
        'max': 100,
        'title': <String, Object?>{'display': true, 'text': 'ppm'},
      },
    },
  },
};

/// The typed bubble chart: a bubble dataset with a point style and a
/// dataset whose points take the radius of the dataset, with the Lists of
/// colors and two linear axes.
ChartConfig _bubbleTypeTyped() => ChartConfig(
  type: .bubble,
  datasets: [
    BubbleDataset(
      label: 'Cities',
      points: [
        DataPoint.bubble(10, 20, 8),
        DataPoint.bubble(25, 12, 14),
        DataPoint.bubble(32, 28, 5),
      ],
      backgroundColor: const Color.fromRGBO(75, 192, 192, 0.5),
      borderColor: _green,
      borderWidth: 2,
      hoverRadius: 6,
      pointStyle: .rectRounded,
    ),
    BubbleDataset(
      label: 'Towns',
      points: [DataPoint(15, 8), DataPoint(28, 22)],
      radius: 4,
      backgroundColors: const [_orange, _yellow],
      hoverBackgroundColor: _red,
    ),
  ],
  scales: const {
    'x': LinearAxis(
      suggestedMin: 0,
      suggestedMax: 40,
      ticks: AxisTicks(stepSize: 10),
    ),
    'y': LinearAxis(
      reverse: true,
      title: AxisTitle(display: true, text: 'Score', align: .end),
    ),
  },
  legend: const ChartLegend(display: false),
);

/// The raw twin of `_bubbleTypeTyped`.
Map<String, Object?> _bubbleTypeRaw() => <String, Object?>{
  'type': 'bubble',
  'data': <String, Object?>{
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Cities',
        'data': <Object?>[
          <String, Object?>{'x': 10, 'y': 20, 'r': 8},
          <String, Object?>{'x': 25, 'y': 12, 'r': 14},
          <String, Object?>{'x': 32, 'y': 28, 'r': 5},
        ],
        'backgroundColor': 'rgba(75, 192, 192, 0.5)',
        'borderColor': 'rgb(75, 192, 192)',
        'borderWidth': 2,
        'hoverRadius': 6,
        'pointStyle': 'rectRounded',
      },
      <String, Object?>{
        'label': 'Towns',
        'data': <Object?>[
          <String, Object?>{'x': 15, 'y': 8},
          <String, Object?>{'x': 28, 'y': 22},
        ],
        'radius': 4,
        'backgroundColor': <Object?>['rgb(255, 159, 64)', 'rgb(255, 205, 86)'],
        'hoverBackgroundColor': 'rgb(255, 99, 132)',
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': 'linear',
        'suggestedMin': 0,
        'suggestedMax': 40,
        'ticks': <String, Object?>{'stepSize': 10},
      },
      'y': <String, Object?>{
        'type': 'linear',
        'reverse': true,
        'title': <String, Object?>{
          'display': true,
          'text': 'Score',
          'align': 'end',
        },
      },
    },
    'plugins': <String, Object?>{
      'legend': <String, Object?>{'display': false},
    },
  },
};

/// The tooltip footer of the pie type chart.
String? _budgetFooter(List<ChartTooltipItem> items) => 'Items: ${items.length}';

/// The raw tooltip footer callback of `_budgetFooter`.
Object? _rawBudgetFooter(Object? items) =>
    'Items: ${(items! as List<Object?>).length}';

/// The typed pie chart: the arc keys, a radius in percent, the rotation and
/// the circumference, the legend at the right and the tooltip with a body
/// style and a footer text.
ChartConfig _pieTypeTyped() => const ChartConfig(
  type: .pie,
  labels: ['Rent', 'Food', 'Travel', 'Other'],
  datasets: [
    PieDataset(
      label: 'Budget',
      data: [1200, 450, 300, 150],
      backgroundColors: [_blue, _red, _yellow, _grey],
      borderColor: _white,
      borderWidth: 2,
      offset: 4,
      hoverOffset: 12,
      radius: ChartLength.percent(90),
      rotation: -45,
      circumference: 300,
    ),
  ],
  legend: ChartLegend(
    position: .right,
    labelFont: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
  ),
  tooltip: ChartTooltip(
    bodyColor: _yellow,
    bodyFont: TextStyle(fontSize: 14),
    footerText: _budgetFooter,
  ),
);

/// The raw twin of `_pieTypeTyped`.
Map<String, Object?> _pieTypeRaw() => <String, Object?>{
  'type': 'pie',
  'data': <String, Object?>{
    'labels': <Object?>['Rent', 'Food', 'Travel', 'Other'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Budget',
        'data': <Object?>[1200, 450, 300, 150],
        'backgroundColor': <Object?>[
          'rgb(54, 162, 235)',
          'rgb(255, 99, 132)',
          'rgb(255, 205, 86)',
          'rgb(201, 203, 207)',
        ],
        'borderColor': '#fff',
        'borderWidth': 2,
        'offset': 4,
        'hoverOffset': 12,
        'radius': '90%',
        'rotation': -45,
        'circumference': 300,
      },
    ],
  },
  'options': <String, Object?>{
    'plugins': <String, Object?>{
      'legend': <String, Object?>{
        'position': 'right',
        'labels': <String, Object?>{
          'font': <String, Object?>{'size': 12, 'style': 'italic'},
        },
      },
      'tooltip': <String, Object?>{
        'bodyColor': 'rgb(255, 205, 86)',
        'bodyFont': <String, Object?>{'size': 14},
        'callbacks': <String, Object?>{'footer': _rawBudgetFooter},
      },
    },
  },
};

/// The typed doughnut chart: two rings with weights, a cutout in percent, a
/// radius in pixels, the spacing and the hover border, the title at the
/// bottom, the arc element style and the animation with a delay.
ChartConfig _doughnutTypeTyped() => const ChartConfig(
  type: .doughnut,
  labels: ['Done', 'Open', 'Blocked'],
  datasets: [
    DoughnutDataset(
      label: 'Sprint 1',
      data: [8, 3, 1],
      backgroundColors: [_green, _blue, _red],
      hoverBorderColor: _navy,
      hoverBorderWidth: 3,
      spacing: 2,
      weight: 2,
      cutout: ChartLength.percent(60),
    ),
    DoughnutDataset(
      label: 'Sprint 2',
      data: [5, 6, 2],
      backgroundColors: [_green, _blue, _red],
      weight: 1,
      radius: ChartLength.pixels(150),
    ),
  ],
  title: ChartTitle(
    display: true,
    text: 'Tasks',
    color: _navy,
    position: .bottom,
    fullSize: false,
  ),
  elements: ChartElements(
    arc: ArcElementStyle(borderWidth: 1, borderColor: _white),
  ),
  animation: ChartAnimation(
    duration: Duration(milliseconds: 800),
    delay: Duration(milliseconds: 100),
    easing: .easeInOutCubic,
  ),
);

/// The raw twin of `_doughnutTypeTyped`.
Map<String, Object?> _doughnutTypeRaw() => <String, Object?>{
  'type': 'doughnut',
  'data': <String, Object?>{
    'labels': <Object?>['Done', 'Open', 'Blocked'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Sprint 1',
        'data': <Object?>[8, 3, 1],
        'backgroundColor': <Object?>[
          'rgb(75, 192, 192)',
          'rgb(54, 162, 235)',
          'rgb(255, 99, 132)',
        ],
        'hoverBorderColor': '#1b3a5c',
        'hoverBorderWidth': 3,
        'spacing': 2,
        'weight': 2,
        'cutout': '60%',
      },
      <String, Object?>{
        'label': 'Sprint 2',
        'data': <Object?>[5, 6, 2],
        'backgroundColor': <Object?>[
          'rgb(75, 192, 192)',
          'rgb(54, 162, 235)',
          'rgb(255, 99, 132)',
        ],
        'weight': 1,
        'radius': 150,
      },
    ],
  },
  'options': <String, Object?>{
    'animation': <String, Object?>{
      'duration': 800,
      'delay': 100,
      'easing': 'easeInOutCubic',
    },
    'elements': <String, Object?>{
      'arc': <String, Object?>{'borderColor': '#fff', 'borderWidth': 1},
    },
    'plugins': <String, Object?>{
      'title': <String, Object?>{
        'display': true,
        'text': 'Tasks',
        'color': '#1b3a5c',
        'position': 'bottom',
        'fullSize': false,
      },
    },
  },
};

/// The typed polar area chart: the arc keys and a radial linear axis with a
/// start angle, ticks, a grid and the point labels, and the legend at the
/// left.
ChartConfig _polarAreaTypeTyped() => const ChartConfig(
  type: .polarArea,
  labels: ['N', 'E', 'S', 'W', 'C'],
  datasets: [
    PolarAreaDataset(
      label: 'Wind',
      data: [11, 16, 7, 3, 14],
      backgroundColors: [
        Color.fromRGBO(255, 99, 132, 0.5),
        Color.fromRGBO(75, 192, 192, 0.5),
        Color.fromRGBO(255, 205, 86, 0.5),
        Color.fromRGBO(201, 203, 207, 0.5),
        Color.fromRGBO(54, 162, 235, 0.5),
      ],
      borderColor: _white,
      borderWidth: 1,
      offset: 2,
      hoverOffset: 8,
      spacing: 1,
    ),
  ],
  scales: {
    'r': RadialLinearAxis(
      beginAtZero: true,
      startAngle: 30,
      ticks: AxisTicks(stepSize: 5, color: _navy),
      grid: AxisGrid(color: _grey),
      pointLabelsDisplay: true,
      pointLabelsColor: _navy,
      pointLabelsFont: TextStyle(fontSize: 12),
    ),
  },
  legend: ChartLegend(position: .left, align: .center),
);

/// The raw twin of `_polarAreaTypeTyped`.
Map<String, Object?> _polarAreaTypeRaw() => <String, Object?>{
  'type': 'polarArea',
  'data': <String, Object?>{
    'labels': <Object?>['N', 'E', 'S', 'W', 'C'],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Wind',
        'data': <Object?>[11, 16, 7, 3, 14],
        'backgroundColor': <Object?>[
          'rgba(255, 99, 132, 0.5)',
          'rgba(75, 192, 192, 0.5)',
          'rgba(255, 205, 86, 0.5)',
          'rgba(201, 203, 207, 0.5)',
          'rgba(54, 162, 235, 0.5)',
        ],
        'borderColor': '#fff',
        'borderWidth': 1,
        'offset': 2,
        'hoverOffset': 8,
        'spacing': 1,
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'r': <String, Object?>{
        'type': 'radialLinear',
        'beginAtZero': true,
        'startAngle': 30,
        'ticks': <String, Object?>{'stepSize': 5, 'color': '#1b3a5c'},
        'grid': <String, Object?>{'color': 'rgb(201, 203, 207)'},
        'pointLabels': <String, Object?>{
          'display': true,
          'color': '#1b3a5c',
          'font': <String, Object?>{'size': 12},
        },
      },
    },
    'plugins': <String, Object?>{
      'legend': <String, Object?>{'position': 'left', 'align': 'center'},
    },
  },
};

/// The tooltip title of the radar type chart.
String? _radarTitle(List<ChartTooltipItem> items) =>
    'Axis ${items.first.label}';

/// The raw tooltip title callback of `_radarTitle`.
Object? _rawRadarTitle(Object? items) {
  final first = (items! as List<Object?>).first;
  return 'Axis ${_byName(first, 'label')}';
}

/// The typed radar chart: a filled line with a point style, a line that
/// fills to the dataset 0, a radial linear axis with the suggested range,
/// the angle lines and the point labels, the point and line element styles
/// and the tooltip with a title text.
ChartConfig _radarTypeTyped() => const ChartConfig(
  type: .radar,
  labels: ['Speed', 'Power', 'Range', 'Comfort', 'Price', 'Safety'],
  datasets: [
    RadarDataset(
      label: 'Model A',
      data: [7, 8, 5, 6, 4, 9],
      backgroundColor: Color.fromRGBO(54, 162, 235, 0.2),
      borderColor: _blue,
      fill: .origin,
      tension: 0.1,
      pointStyle: .star,
      pointRadius: 4,
      pointHoverRadius: 7,
    ),
    RadarDataset(
      label: 'Model B',
      data: [5, 6, 8, 7, 7, 6],
      backgroundColor: Color.fromRGBO(255, 159, 64, 0.2),
      borderColor: _orange,
      fill: ChartFill.dataset(0),
      borderDash: [4, 4],
      spanGaps: false,
      pointBackgroundColor: _orange,
    ),
  ],
  scales: {
    'r': RadialLinearAxis(
      suggestedMin: 0,
      suggestedMax: 10,
      ticks: AxisTicks(stepSize: 2),
      angleLinesDisplay: true,
      angleLinesColor: _grey,
      angleLinesLineWidth: 1,
      pointLabelsColor: _navy,
      pointLabelsFont: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      pointLabelsPadding: 8,
    ),
  },
  elements: ChartElements(
    point: PointElementStyle(hitRadius: 6, borderWidth: 1),
    line: LineElementStyle(borderWidth: 2),
  ),
  tooltip: ChartTooltip(titleColor: _yellow, titleText: _radarTitle),
);

/// The raw twin of `_radarTypeTyped`.
Map<String, Object?> _radarTypeRaw() => <String, Object?>{
  'type': 'radar',
  'data': <String, Object?>{
    'labels': <Object?>[
      'Speed',
      'Power',
      'Range',
      'Comfort',
      'Price',
      'Safety',
    ],
    'datasets': <Object?>[
      <String, Object?>{
        'label': 'Model A',
        'data': <Object?>[7, 8, 5, 6, 4, 9],
        'backgroundColor': 'rgba(54, 162, 235, 0.2)',
        'borderColor': 'rgb(54, 162, 235)',
        'fill': 'origin',
        'tension': 0.1,
        'pointStyle': 'star',
        'pointRadius': 4,
        'pointHoverRadius': 7,
      },
      <String, Object?>{
        'label': 'Model B',
        'data': <Object?>[5, 6, 8, 7, 7, 6],
        'backgroundColor': 'rgba(255, 159, 64, 0.2)',
        'borderColor': 'rgb(255, 159, 64)',
        'fill': 0,
        'borderDash': <Object?>[4, 4],
        'spanGaps': false,
        'pointBackgroundColor': 'rgb(255, 159, 64)',
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'r': <String, Object?>{
        'type': 'radialLinear',
        'suggestedMin': 0,
        'suggestedMax': 10,
        'ticks': <String, Object?>{'stepSize': 2},
        'angleLines': <String, Object?>{
          'display': true,
          'color': 'rgb(201, 203, 207)',
          'lineWidth': 1,
        },
        'pointLabels': <String, Object?>{
          'color': '#1b3a5c',
          'font': <String, Object?>{'size': 13, 'weight': 700},
          'padding': 8,
        },
      },
    },
    'elements': <String, Object?>{
      'point': <String, Object?>{'borderWidth': 1, 'hitRadius': 6},
      'line': <String, Object?>{'borderWidth': 2},
    },
    'plugins': <String, Object?>{
      'tooltip': <String, Object?>{
        'titleColor': 'rgb(255, 205, 86)',
        'callbacks': <String, Object?>{'title': _rawRadarTitle},
      },
    },
  },
};

/// The twins of one chart of each of the 8 chart types.
final List<_Twin> _typeTwins = [
  (name: 'bar', typed: _barTyped, raw: _barRaw, rawObservation: null),
  (
    name: 'line',
    typed: _lineTypeTyped,
    raw: _lineTypeRaw,
    rawObservation: null,
  ),
  (
    name: 'scatter',
    typed: _scatterTypeTyped,
    raw: _scatterTypeRaw,
    rawObservation: null,
  ),
  (
    name: 'bubble',
    typed: _bubbleTypeTyped,
    raw: _bubbleTypeRaw,
    rawObservation: null,
  ),
  (name: 'pie', typed: _pieTypeTyped, raw: _pieTypeRaw, rawObservation: null),
  (
    name: 'doughnut',
    typed: _doughnutTypeTyped,
    raw: _doughnutTypeRaw,
    rawObservation: null,
  ),
  (
    name: 'polarArea',
    typed: _polarAreaTypeTyped,
    raw: _polarAreaTypeRaw,
    rawObservation: null,
  ),
  (
    name: 'radar',
    typed: _radarTypeTyped,
    raw: _radarTypeRaw,
    rawObservation: null,
  ),
];

void main() {
  for (final (themeName, theme) in const [
    ('unthemed', null),
    ('light', ChartThemeData.light()),
  ]) {
    group(themeName, () {
      group('the docs configs', () {
        for (final twin in _docsTwins) {
          testWidgets(twin.name, (tester) async {
            await expectChartTwin(
              tester,
              config: twin.typed(),
              raw: twin.raw,
              theme: theme,
              rawObservation: twin.rawObservation,
            );
          });
        }
      });

      group('the chart types', () {
        for (final twin in _typeTwins) {
          testWidgets(twin.name, (tester) async {
            await expectChartTwin(
              tester,
              config: twin.typed(),
              raw: twin.raw,
              theme: theme,
              rawObservation: twin.rawObservation,
            );
          });
        }
      });
    });
  }
}

/// The read by name `object[key]` of an object of a chart: a Map of a raw
/// config, or a typed object through its face (Chart.js ADR 0054 §5).
Object? _byName(Object? object, String key) => switch (object) {
  final Map<Object?, Object?> map => map[key],
  final JsObjectFace face => face[key],
  _ => null,
};
