// Original code, not ported from Chart.js: the typed twins of the docs configs.
@TestOn('vm')
library;

import 'dart:ui' as native_ui;

import 'package:flutter/animation.dart' show Curves;
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
// - The radar datasets have `fill: true` (`radar.md:22`, `:32`). The fill
//   of the port is `FillTarget.toOrigin` in both twins (Chart.js ADR 0140):
//   the filler reads `true` as `'origin'` (`parseFillOption`,
//   `src/plugins/plugin.filler/filler.options.js:133`).
//
// The group "the chart types" has one chart of each of the 8 chart types
// with more typed keys than the docs: the axes and their ticks, grids and
// titles, the legend, the title and the subtitle, the tooltip with its text
// callbacks, the interaction, the animation, the filler, the elements, the
// padding, the time and logarithmic axes, the scriptable forms of the
// colors in Lists, the radius lengths, `FillTarget` and the point styles.
// Each raw twin is the raw form of the same chart: the Chart.js option
// paths with the values of the typed lowering (Chart.js ADR 0052, section
// 7). The callbacks of the raw twins read the raw objects and give the same
// text.
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
  ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 0.2)),
  ChartPaint.solid(native_ui.Color.fromRGBO(255, 159, 64, 0.2)),
  ChartPaint.solid(native_ui.Color.fromRGBO(255, 205, 86, 0.2)),
  ChartPaint.solid(native_ui.Color.fromRGBO(75, 192, 192, 0.2)),
  ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 0.2)),
  ChartPaint.solid(native_ui.Color.fromRGBO(153, 102, 255, 0.2)),
  ChartPaint.solid(native_ui.Color.fromRGBO(201, 203, 207, 0.2)),
];

/// The 7 border colors of the bar and line docs blocks.
const List<Object?> _sevenBorders = [
  ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 1)),
  ChartPaint.solid(native_ui.Color.fromRGBO(255, 159, 64, 1)),
  ChartPaint.solid(native_ui.Color.fromRGBO(255, 205, 86, 1)),
  ChartPaint.solid(native_ui.Color.fromRGBO(75, 192, 192, 1)),
  ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
  ChartPaint.solid(native_ui.Color.fromRGBO(153, 102, 255, 1)),
  ChartPaint.solid(native_ui.Color.fromRGBO(201, 203, 207, 1)),
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
      backgroundColor: ChartValue.indexed(
        _seven(0.2).map(ChartPaint.solid).toList(),
      ),
      borderColor: ChartValue.indexed(_seven(1).map(ChartPaint.solid).toList()),
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
        'axis': const YAxis(),
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 80.0, 81.0, 56.0, 55.0, 40.0],
        'fill': FillTarget.none,
        'backgroundColor': <Object?>[..._sevenBackgrounds],
        'borderColor': <Object?>[..._sevenBorders],
        'borderWidth': 1.0,
      },
    ],
  },
  'options': <String, Object?>{'indexAxis': const YAxis()},
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
      backgroundColor: ChartValue.indexed(
        _seven(0.2).map(ChartPaint.solid).toList(),
      ),
      borderColor: ChartValue.indexed(_seven(1).map(ChartPaint.solid).toList()),
      borderWidth: 1,
    ),
  ],
  indexAxis: const YAxis(),
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
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
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
      backgroundColor: const ChartValue.constant(.solid(_red)),
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
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 1)),
        const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
        const ChartPaint.solid(native_ui.Color.fromRGBO(255, 205, 86, 1)),
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
      backgroundColor: ChartValue.indexed([
        ChartPaint.solid(_red),
        ChartPaint.solid(_blue),
        ChartPaint.solid(_yellow),
      ]),
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
      backgroundColor: ChartValue.indexed([
        ChartPaint.solid(_red),
        ChartPaint.solid(_blue),
        ChartPaint.solid(_yellow),
      ]),
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
        'fill': FillTarget.none,
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(75, 192, 192, 1),
        ),
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
      borderColor: ChartValue.constant(.solid(_green)),
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
        'axis': const YAxis(),
        'label': 'My First Dataset',
        'data': <Object?>[65.0, 59.0, 80.0, 81.0, 56.0, 55.0, 40.0],
        'fill': FillTarget.none,
        'backgroundColor': <Object?>[..._sevenBackgrounds],
        'borderColor': <Object?>[..._sevenBorders],
        'borderWidth': 1.0,
      },
    ],
  },
  'options': <String, Object?>{
    'indexAxis': const YAxis(),
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
      backgroundColor: ChartValue.indexed(
        _seven(0.2).map(ChartPaint.solid).toList(),
      ),
      borderColor: ChartValue.indexed(_seven(1).map(ChartPaint.solid).toList()),
      borderWidth: 1,
    ),
  ],
  indexAxis: const YAxis(),
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
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 0.2),
        ),
      },
      <String, Object?>{
        'type': 'line',
        'label': 'Line Dataset',
        'data': <Object?>[50.0, 50.0, 50.0, 50.0],
        'fill': FillTarget.none,
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(54, 162, 235, 1),
        ),
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
      borderColor: ChartValue.constant(.solid(_red)),
      backgroundColor: ChartValue.constant(
        .solid(Color.fromRGBO(255, 99, 132, 0.2)),
      ),
    ),
    LineDataset(
      label: 'Line Dataset',
      data: [50, 50, 50, 50],
      fill: .none,
      borderColor: ChartValue.constant(.solid(_blue)),
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
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(75, 192, 192, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 205, 86, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(201, 203, 207, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
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
      backgroundColor: ChartValue.indexed([
        ChartPaint.solid(_red),
        ChartPaint.solid(_green),
        ChartPaint.solid(_yellow),
        ChartPaint.solid(_grey),
        ChartPaint.solid(_blue),
      ]),
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
        'fill': FillTarget.toOrigin,
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 0.2),
        ),
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
        'pointBackgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
        'pointBorderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 255, 255, 1),
        ),
        'pointHoverBackgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 255, 255, 1),
        ),
        'pointHoverBorderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
      },
      <String, Object?>{
        'label': 'My Second Dataset',
        'data': <Object?>[28.0, 48.0, 40.0, 19.0, 96.0, 27.0, 100.0],
        'fill': FillTarget.toOrigin,
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(54, 162, 235, 0.2),
        ),
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(54, 162, 235, 1),
        ),
        'pointBackgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(54, 162, 235, 1),
        ),
        'pointBorderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 255, 255, 1),
        ),
        'pointHoverBackgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 255, 255, 1),
        ),
        'pointHoverBorderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(54, 162, 235, 1),
        ),
      },
    ],
  },
  'options': <String, Object?>{
    'elements': <String, Object?>{
      'line': <String, Object?>{'borderWidth': 3.0},
    },
  },
};

/// The typed `radar.md:7-61`, with `FillTarget.toOrigin` for `fill: true`.
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
      fill: .toOrigin,
      backgroundColor: ChartValue.constant(
        .solid(Color.fromRGBO(255, 99, 132, 0.2)),
      ),
      borderColor: ChartValue.constant(.solid(_red)),
      pointBackgroundColor: .constant(.solid(_red)),
      pointBorderColor: .constant(.solid(_white)),
      pointHoverBackgroundColor: .constant(.solid(_white)),
      pointHoverBorderColor: .constant(.solid(_red)),
    ),
    RadarDataset(
      label: 'My Second Dataset',
      data: [28, 48, 40, 19, 96, 27, 100],
      fill: .toOrigin,
      backgroundColor: ChartValue.constant(
        .solid(Color.fromRGBO(54, 162, 235, 0.2)),
      ),
      borderColor: ChartValue.constant(.solid(_blue)),
      pointBackgroundColor: .constant(.solid(_blue)),
      pointBorderColor: .constant(.solid(_white)),
      pointHoverBackgroundColor: .constant(.solid(_white)),
      pointHoverBorderColor: .constant(.solid(_blue)),
    ),
  ],
  elements: ChartElements(line: LineElementStyle(borderWidth: 3)),
);

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
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
      },
    ],
  },
  'options': <String, Object?>{
    'scales': <String, Object?>{
      'x': <String, Object?>{
        'type': 'linear',
        'position': ChartPosition.bottom,
      },
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
      backgroundColor: const ChartValue.constant(.solid(_red)),
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
/// of `:106` for the text [name] of the fill.
Map<String, Object?> _areaRaw(FillTarget fill, String name) =>
    <String, Object?>{
      'type': 'line',
      'data': <String, Object?>{
        'labels': <Object?>[..._areaMonths],
        'datasets': <Object?>[
          <String, Object?>{
            'label': 'Dataset',
            'data': <Object?>[..._areaData],
            'borderColor': const ChartPaint.solid(
              native_ui.Color.fromRGBO(255, 99, 132, 1),
            ),
            'backgroundColor': const ChartPaint.solid(
              native_ui.Color.fromRGBO(255, 99, 132, 0.5),
            ),
            'fill': fill,
          },
        ],
      },
      'options': <String, Object?>{
        'plugins': <String, Object?>{
          'filler': <String, Object?>{'propagate': false},
          'title': <String, Object?>{
            'display': true,
            'text': (Object? ctx) => _areaTitleText(name),
          },
        },
        'interaction': <String, Object?>{'intersect': false},
      },
    };

/// `(ctx) => 'Fill: ' + ctx.chart.data.datasets[0].fill`
/// (`line-boundaries.md:106`), as in the gallery: a `FillTarget` has no
/// text, so the title takes the [name] of the fill.
Object _areaTitleText(String name) => 'Fill: $name';

/// The typed Area config at the fill [fill], with the constant title
/// [title].
ChartConfig _areaTyped(FillTarget fill, String title) => ChartConfig(
  type: .line,
  labels: _areaMonths,
  datasets: [
    LineDataset(
      label: 'Dataset',
      data: _areaData,
      borderColor: const ChartValue.constant(.solid(_red)),
      backgroundColor: const ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 0.5)),
      ),
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
    rawObservation: null,
  ),
  (
    name: 'scatter.md:5-47',
    typed: _scatterTyped,
    raw: _scatterRaw,
    rawObservation: null,
  ),
  for (final (fill, text) in const [
    (FillTarget.toOrigin, 'origin'),
    (FillTarget.toStart, 'start'),
    (FillTarget.toEnd, 'end'),
    (FillTarget.none, 'false'),
  ])
    (
      name: 'line-boundaries.md:3-120, fill $text',
      typed: () => _areaTyped(fill, 'Fill: $text'),
      raw: () => _areaRaw(fill, text),
      rawObservation: null,
    ),
];

// ---------------------------------------------------------------------------
// The chart types.

/// The tick callback of the bar type chart and of its raw twin.
List<String>? _units(Scale scale, double value, int index, List<Tick> ticks) =>
    ['${value.round()} u'];

/// The tooltip label of the bar type chart.
String? _barLabel(TooltipItem item) =>
    '${item.datasetLabel}: ${item.formattedValue} units';

/// The raw tooltip label callback of `_barLabel`.
Object? _rawBarLabel(TooltipItem item) =>
    '${_byName(item.dataset, 'label')}: ${item.formattedValue} units';

/// The typed bar chart: stacked bars with the bar keys, a category and a
/// linear axis with ticks, grids, a title and a tick format, the legend,
/// the title, the tooltip with a label text and the padding.
ChartConfig _barTyped() => ChartConfig(
  type: .bar,
  labels: const ['Q1', 'Q2', 'Q3', 'Q4'],
  datasets: const [
    BarDataset(
      label: 'North',
      data: [12, 19, 3, 5],
      backgroundColor: ChartValue.constant(.solid(_blue)),
      borderColor: ChartValue.constant(.solid(_navy)),
      borderWidth: 2,
      hoverBackgroundColor: .constant(.solid(_green)),
      hoverBorderWidth: 3,
      stack: 'sales',
      borderRadius: 4,
      barPercentage: 0.8,
      categoryPercentage: 0.9,
    ),
    BarDataset(
      label: 'South',
      data: [7, 11, 5, 8],
      backgroundColor: ChartValue.indexed([
        ChartPaint.solid(_red),
        ChartPaint.solid(_orange),
        ChartPaint.solid(_yellow),
        ChartPaint.solid(_green),
      ]),
      stack: 'sales',
      maxBarThickness: 40,
      minBarLength: 2,
    ),
    BarDataset(
      label: 'Target',
      data: [10, 10, 10, 10],
      borderColor: ChartValue.indexed([
        ChartPaint.solid(_grey),
        ChartPaint.solid(_grey),
        ChartPaint.solid(_purple),
        ChartPaint.solid(_purple),
      ]),
      borderWidth: 1,
      stack: 'target',
      order: 1,
      barThickness: 12,
      grouped: true,
    ),
  ],
  scales: const {
    'x': CategoryAxis(
      stacked: true,
      grid: AxisGrid(display: false),
      ticks: AxisTicks(
        color: ChartPaint.solid(_navy),
        font: TextStyle(fontSize: 13),
      ),
    ),
    'y': LinearAxis(
      stacked: true,
      beginAtZero: true,
      suggestedMax: 30,
      ticks: AxisTicks(stepSize: 5, padding: 6, callback: _units),
      title: AxisTitle(
        display: true,
        text: 'Units',
        color: ChartPaint.solid(_navy),
        font: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        padding: EdgeInsets.symmetric(vertical: 4),
      ),
    ),
  },
  padding: const EdgeInsets.all(8),
  legend: const ChartLegend(
    position: .bottom,
    align: .start,
    boxWidth: 20,
    boxHeight: 10,
    labelPadding: 12,
    labelColor: ChartPaint.solid(_navy),
    labelFont: TextStyle(fontSize: 11),
  ),
  title: const ChartTitle(
    display: true,
    text: 'Sales by quarter',
    align: .start,
    font: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    padding: EdgeInsets.only(top: 4, bottom: 8),
  ),
  tooltip: ChartTooltip(
    mode: const IndexInteractionMode(),
    intersect: false,
    backgroundColor: const ChartPaint.solid(Color(0xCC000000)),
    padding: const EdgeInsets.all(10),
    cornerRadius: 4,
    displayColors: false,
    titleFont: const TextStyle(fontSize: 13),
    callbacks: TooltipCallbacks(
      label: (tooltip, arg) {
        final text = _barLabel(arg);
        return text == null
            ? null
            : text.isEmpty
            ? <String>[]
            : [text];
      },
    ),
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
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(54, 162, 235, 1),
        ),
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(27, 58, 92, 1),
        ),
        'borderWidth': 2,
        'hoverBackgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(75, 192, 192, 1),
        ),
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
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 159, 64, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 205, 86, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(75, 192, 192, 1)),
        ],
        'stack': 'sales',
        'maxBarThickness': 40,
        'minBarLength': 2,
      },
      <String, Object?>{
        'label': 'Target',
        'data': <Object?>[10, 10, 10, 10],
        'borderColor': <Object?>[
          const ChartPaint.solid(native_ui.Color.fromRGBO(201, 203, 207, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(201, 203, 207, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(153, 102, 255, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(153, 102, 255, 1)),
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
          'color': const ChartPaint.solid(
            native_ui.Color.fromRGBO(27, 58, 92, 1),
          ),
          'font': const ChartTextStyle(fontSize: 13),
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
          'callback': _units,
        },
        'title': <String, Object?>{
          'display': true,
          'text': 'Units',
          'color': const ChartPaint.solid(
            native_ui.Color.fromRGBO(27, 58, 92, 1),
          ),
          'font': const ChartTextStyle(
            fontSize: 12,
            fontWeight: native_ui.FontWeight.bold,
          ),
          'padding': const EdgeInsets.only(
            left: 0,
            top: 4,
            right: 0,
            bottom: 4,
          ),
        },
      },
    },
    'layout': <String, Object?>{'padding': const EdgeInsets.all(8)},
    'plugins': <String, Object?>{
      'legend': <String, Object?>{
        'position': ChartPosition.bottom,
        'align': ChartAlign.start,
        'labels': <String, Object?>{
          'color': const ChartPaint.solid(
            native_ui.Color.fromRGBO(27, 58, 92, 1),
          ),
          'font': const ChartTextStyle(fontSize: 11),
          'boxWidth': 20,
          'boxHeight': 10,
          'padding': 12,
        },
      },
      'title': <String, Object?>{
        'display': true,
        'text': 'Sales by quarter',
        'align': ChartAlign.start,
        'font': const ChartTextStyle(
          fontSize: 16,
          fontWeight: native_ui.FontWeight.w600,
        ),
        'padding': const EdgeInsets.only(top: 4, bottom: 8),
      },
      'tooltip': <String, Object?>{
        'mode': const IndexInteractionMode(),
        'intersect': false,
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(0, 0, 0, 0.8),
        ),
        'titleFont': const ChartTextStyle(fontSize: 13),
        'padding': const EdgeInsets.all(10),
        'cornerRadius': 4,
        'displayColors': false,
        'callbacks': TooltipCallbacks(
          label: (tooltip, arg) => [jsToString(_rawBarLabel(arg))],
        ),
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
      backgroundColor: ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 0.25)),
      ),
      borderColor: ChartValue.constant(.solid(_red)),
      borderWidth: 2,
      fill: .toOrigin,
      tension: 0.3,
      spanGaps: true,
      pointStyle: RectRotPointStyle(),
      pointRadius: 5,
      pointHoverRadius: 8,
      pointBackgroundColor: .constant(.solid(_white)),
      pointBorderColor: .constant(.solid(_red)),
      pointBorderWidth: 2,
      pointHoverBackgroundColor: .constant(.solid(_red)),
      pointHoverBorderColor: .constant(.solid(_white)),
    ),
    LineDataset(
      label: 'Last week',
      data: [2, 4, 6, 5, 4, 6, 5],
      backgroundColor: ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(54, 162, 235, 0.25)),
      ),
      borderColor: ChartValue.constant(.solid(_blue)),
      fill: FillTarget.toPrevious,
      borderDash: [6, 4],
      stepped: SteppedLine.before,
      pointStyle: TrianglePointStyle(),
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
        color: ChartPaint.solid(Color.fromRGBO(0, 0, 0, 0.1)),
        lineWidth: 0.5,
        drawOnChartArea: true,
      ),
      ticks: AxisTicks(stepSize: 2),
    ),
  },
  aspectRatio: 1.5,
  interaction: ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
    includeInvisible: true,
  ),
  subtitle: ChartTitle(
    display: true,
    text: 'Steps in thousands',
    color: ChartPaint.solid(_navy),
    position: .bottom,
  ),
  legend: ChartLegend(usePointStyle: true, reverse: true),
  animation: ChartAnimation(
    duration: Duration(milliseconds: 400),
    easing: Curves.easeOutQuart,
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
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 0.25),
        ),
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
        'borderWidth': 2,
        'fill': FillTarget.toOrigin,
        'tension': 0.3,
        'spanGaps': true,
        'pointStyle': const RectRotPointStyle(),
        'pointRadius': 5,
        'pointHoverRadius': 8,
        'pointBackgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 255, 255, 1),
        ),
        'pointBorderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
        'pointBorderWidth': 2,
        'pointHoverBackgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
        'pointHoverBorderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 255, 255, 1),
        ),
      },
      <String, Object?>{
        'label': 'Last week',
        'data': <Object?>[2, 4, 6, 5, 4, 6, 5],
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(54, 162, 235, 0.25),
        ),
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(54, 162, 235, 1),
        ),
        'fill': FillTarget.toPrevious,
        'borderDash': <Object?>[6, 4],
        'stepped': SteppedLine.before,
        'pointStyle': const TrianglePointStyle(),
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
          'color': const ChartPaint.solid(
            native_ui.Color.fromRGBO(0, 0, 0, 0.1),
          ),
          'lineWidth': 0.5,
          'drawOnChartArea': true,
        },
        'ticks': <String, Object?>{'stepSize': 2},
      },
    },
    'aspectRatio': 1.5,
    'interaction': <String, Object?>{
      'mode': const IndexInteractionMode(),
      'intersect': false,
      'includeInvisible': true,
    },
    'animation': <String, Object?>{
      'duration': 400,
      'easing': Curves.easeOutQuart,
    },
    'plugins': <String, Object?>{
      'subtitle': <String, Object?>{
        'display': true,
        'text': 'Steps in thousands',
        'color': const ChartPaint.solid(
          native_ui.Color.fromRGBO(27, 58, 92, 1),
        ),
        'position': ChartPosition.bottom,
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
      backgroundColor: const ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(153, 102, 255, 0.3)),
      ),
      borderColor: const ChartValue.constant(.solid(_purple)),
      borderWidth: 1,
      showLine: true,
      fill: const FillTarget.toValue(10),
      pointRadius: 6,
      pointStyle: const RectPointStyle(),
    ),
    ScatterDataset(
      label: 'Limit',
      points: [
        DataPoint.time(DateTime.utc(2026, 3), 50),
        DataPoint.time(DateTime.utc(2026, 3, 6), 50),
      ],
      borderColor: const ChartValue.constant(.solid(_red)),
      showLine: true,
      borderDash: const [2, 2],
      pointHoverRadius: 4,
      extra: const {'pointStyle': false},
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
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(153, 102, 255, 0.3),
        ),
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(153, 102, 255, 1),
        ),
        'borderWidth': 1,
        'showLine': true,
        'fill': const FillTarget.toValue(10),
        'pointRadius': 6,
        'pointStyle': const RectPointStyle(),
      },
      <String, Object?>{
        'label': 'Limit',
        'data': <Object?>[
          <String, Object?>{'x': DateTime.utc(2026, 3), 'y': 50},
          <String, Object?>{'x': DateTime.utc(2026, 3, 6), 'y': 50},
        ],
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
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
        'position': ChartPosition.bottom,
        'min': DateTime.utc(2026, 2, 28),
        'max': DateTime.utc(2026, 3, 7),
        'time': <String, Object?>{
          'unit': TimeUnit.day,
          'tooltipFormat': 'MMM d',
        },
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
      backgroundColor: const ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(75, 192, 192, 0.5)),
      ),
      borderColor: const ChartValue.constant(.solid(_green)),
      borderWidth: 2,
      hoverRadius: 6,
      pointStyle: const RectRoundedPointStyle(),
    ),
    BubbleDataset(
      label: 'Towns',
      points: [DataPoint(15, 8), DataPoint(28, 22)],
      radius: 4,
      backgroundColor: const ChartValue.indexed([
        ChartPaint.solid(_orange),
        ChartPaint.solid(_yellow),
      ]),
      hoverBackgroundColor: const .constant(.solid(_red)),
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
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(75, 192, 192, 0.5),
        ),
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(75, 192, 192, 1),
        ),
        'borderWidth': 2,
        'hoverRadius': 6,
        'pointStyle': const RectRoundedPointStyle(),
      },
      <String, Object?>{
        'label': 'Towns',
        'data': <Object?>[
          <String, Object?>{'x': 15, 'y': 8},
          <String, Object?>{'x': 28, 'y': 22},
        ],
        'radius': 4,
        'backgroundColor': <Object?>[
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 159, 64, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 205, 86, 1)),
        ],
        'hoverBackgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 99, 132, 1),
        ),
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
          'align': ChartAlign.end,
        },
      },
    },
    'plugins': <String, Object?>{
      'legend': <String, Object?>{'display': false},
    },
  },
};

/// The tooltip footer of the pie type chart.
String? _budgetFooter(List<TooltipItem> items) => 'Items: ${items.length}';

/// The raw tooltip footer callback of `_budgetFooter`.
Object? _rawBudgetFooter(Object? items) =>
    'Items: ${(items! as List<Object?>).length}';

/// The typed pie chart: the arc keys, a radius in percent, the rotation and
/// the circumference, the legend at the right and the tooltip with a body
/// style and a footer text.
ChartConfig _pieTypeTyped() => ChartConfig(
  type: .pie,
  labels: const ['Rent', 'Food', 'Travel', 'Other'],
  datasets: const [
    PieDataset(
      label: 'Budget',
      data: [1200, 450, 300, 150],
      backgroundColor: ChartValue.indexed([
        ChartPaint.solid(_blue),
        ChartPaint.solid(_red),
        ChartPaint.solid(_yellow),
        ChartPaint.solid(_grey),
      ]),
      borderColor: ChartValue.constant(.solid(_white)),
      borderWidth: 2,
      offset: 4,
      hoverOffset: 12,
      radius: PercentRadius(90),
      rotation: -45,
      circumference: 300,
    ),
  ],
  legend: const ChartLegend(
    position: .right,
    labelFont: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
  ),
  tooltip: ChartTooltip(
    bodyColor: const ChartPaint.solid(_yellow),
    bodyFont: const TextStyle(fontSize: 14),
    callbacks: TooltipCallbacks(
      footer: (tooltip, arg) {
        final text = _budgetFooter(arg);
        return text == null
            ? null
            : text.isEmpty
            ? <String>[]
            : [text];
      },
    ),
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
          const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 205, 86, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(201, 203, 207, 1)),
        ],
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 255, 255, 1),
        ),
        'borderWidth': 2,
        'offset': 4,
        'hoverOffset': 12,
        'radius': const PercentRadius(90),
        'rotation': -45,
        'circumference': 300,
      },
    ],
  },
  'options': <String, Object?>{
    'plugins': <String, Object?>{
      'legend': <String, Object?>{
        'position': ChartPosition.right,
        'labels': <String, Object?>{
          'font': const ChartTextStyle(
            fontSize: 12,
            fontStyle: native_ui.FontStyle.italic,
          ),
        },
      },
      'tooltip': <String, Object?>{
        'bodyColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 205, 86, 1),
        ),
        'bodyFont': const ChartTextStyle(fontSize: 14),
        'callbacks': TooltipCallbacks(
          footer: (tooltip, arg) => [jsToString(_rawBudgetFooter(arg))],
        ),
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
      backgroundColor: ChartValue.indexed([
        ChartPaint.solid(_green),
        ChartPaint.solid(_blue),
        ChartPaint.solid(_red),
      ]),
      hoverBorderColor: .constant(.solid(_navy)),
      hoverBorderWidth: 3,
      spacing: 2,
      weight: 2,
      cutout: PercentRadius(60),
    ),
    DoughnutDataset(
      label: 'Sprint 2',
      data: [5, 6, 2],
      backgroundColor: ChartValue.indexed([
        ChartPaint.solid(_green),
        ChartPaint.solid(_blue),
        ChartPaint.solid(_red),
      ]),
      weight: 1,
      radius: PixelRadius(150),
    ),
  ],
  title: ChartTitle(
    display: true,
    text: 'Tasks',
    color: ChartPaint.solid(_navy),
    position: .bottom,
    fullSize: false,
  ),
  elements: ChartElements(
    arc: ArcElementStyle(borderWidth: 1, borderColor: ChartPaint.solid(_white)),
  ),
  animation: ChartAnimation(
    duration: Duration(milliseconds: 800),
    delay: Duration(milliseconds: 100),
    easing: Curves.easeInOutCubic,
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
          const ChartPaint.solid(native_ui.Color.fromRGBO(75, 192, 192, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 1)),
        ],
        'hoverBorderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(27, 58, 92, 1),
        ),
        'hoverBorderWidth': 3,
        'spacing': 2,
        'weight': 2,
        'cutout': const PercentRadius(60),
      },
      <String, Object?>{
        'label': 'Sprint 2',
        'data': <Object?>[5, 6, 2],
        'backgroundColor': <Object?>[
          const ChartPaint.solid(native_ui.Color.fromRGBO(75, 192, 192, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 1)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 1)),
        ],
        'weight': 1,
        'radius': const PixelRadius(150),
      },
    ],
  },
  'options': <String, Object?>{
    'animation': <String, Object?>{
      'duration': 800,
      'delay': 100,
      'easing': Curves.easeInOutCubic,
    },
    'elements': <String, Object?>{
      'arc': <String, Object?>{
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 255, 255, 1),
        ),
        'borderWidth': 1,
      },
    },
    'plugins': <String, Object?>{
      'title': <String, Object?>{
        'display': true,
        'text': 'Tasks',
        'color': const ChartPaint.solid(
          native_ui.Color.fromRGBO(27, 58, 92, 1),
        ),
        'position': ChartPosition.bottom,
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
      backgroundColor: ChartValue.indexed([
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 0.5)),
        ChartPaint.solid(Color.fromRGBO(75, 192, 192, 0.5)),
        ChartPaint.solid(Color.fromRGBO(255, 205, 86, 0.5)),
        ChartPaint.solid(Color.fromRGBO(201, 203, 207, 0.5)),
        ChartPaint.solid(Color.fromRGBO(54, 162, 235, 0.5)),
      ]),
      borderColor: ChartValue.constant(.solid(_white)),
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
      ticks: AxisTicks(stepSize: 5, color: ChartPaint.solid(_navy)),
      grid: AxisGrid(color: ChartPaint.solid(_grey)),
      pointLabelsDisplay: true,
      pointLabelsColor: ChartPaint.solid(_navy),
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
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 99, 132, 0.5)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(75, 192, 192, 0.5)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(255, 205, 86, 0.5)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(201, 203, 207, 0.5)),
          const ChartPaint.solid(native_ui.Color.fromRGBO(54, 162, 235, 0.5)),
        ],
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 255, 255, 1),
        ),
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
        'ticks': <String, Object?>{
          'stepSize': 5,
          'color': const ChartPaint.solid(
            native_ui.Color.fromRGBO(27, 58, 92, 1),
          ),
        },
        'grid': <String, Object?>{
          'color': const ChartPaint.solid(
            native_ui.Color.fromRGBO(201, 203, 207, 1),
          ),
        },
        'pointLabels': <String, Object?>{
          'display': true,
          'color': const ChartPaint.solid(
            native_ui.Color.fromRGBO(27, 58, 92, 1),
          ),
          'font': const ChartTextStyle(fontSize: 12),
        },
      },
    },
    'plugins': <String, Object?>{
      'legend': <String, Object?>{
        'position': ChartPosition.left,
        'align': ChartAlign.center,
      },
    },
  },
};

/// The tooltip title of the radar type chart.
String? _radarTitle(List<TooltipItem> items) =>
    'Axis ${items.first.label.join(' ')}';

/// The raw tooltip title callback of `_radarTitle`.
Object? _rawRadarTitle(List<TooltipItem> items) =>
    'Axis ${items.first.label.join(' ')}';

/// The typed radar chart: a filled line with a point style, a line that
/// fills to the dataset 0, a radial linear axis with the suggested range,
/// the angle lines and the point labels, the point and line element styles
/// and the tooltip with a title text.
ChartConfig _radarTypeTyped() => ChartConfig(
  type: .radar,
  labels: const ['Speed', 'Power', 'Range', 'Comfort', 'Price', 'Safety'],
  datasets: const [
    RadarDataset(
      label: 'Model A',
      data: [7, 8, 5, 6, 4, 9],
      backgroundColor: ChartValue.constant(
        .solid(Color.fromRGBO(54, 162, 235, 0.2)),
      ),
      borderColor: ChartValue.constant(.solid(_blue)),
      fill: .toOrigin,
      tension: 0.1,
      pointStyle: StarPointStyle(),
      pointRadius: 4,
      pointHoverRadius: 7,
    ),
    RadarDataset(
      label: 'Model B',
      data: [5, 6, 8, 7, 7, 6],
      backgroundColor: ChartValue.constant(
        .solid(Color.fromRGBO(255, 159, 64, 0.2)),
      ),
      borderColor: ChartValue.constant(.solid(_orange)),
      fill: FillTarget.toDataset(0),
      borderDash: [4, 4],
      spanGaps: false,
      pointBackgroundColor: .constant(.solid(_orange)),
    ),
  ],
  scales: const {
    'r': RadialLinearAxis(
      suggestedMin: 0,
      suggestedMax: 10,
      ticks: AxisTicks(stepSize: 2),
      angleLinesDisplay: true,
      angleLinesColor: ChartPaint.solid(_grey),
      angleLinesLineWidth: 1,
      pointLabelsColor: ChartPaint.solid(_navy),
      pointLabelsFont: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      pointLabelsPadding: 8,
    ),
  },
  elements: const ChartElements(
    point: PointElementStyle(hitRadius: 6, borderWidth: 1),
    line: LineElementStyle(borderWidth: 2),
  ),
  tooltip: ChartTooltip(
    titleColor: const ChartPaint.solid(_yellow),
    callbacks: TooltipCallbacks(
      title: (tooltip, arg) {
        final text = _radarTitle(arg);
        return text == null
            ? null
            : text.isEmpty
            ? <String>[]
            : [text];
      },
    ),
  ),
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
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(54, 162, 235, 0.2),
        ),
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(54, 162, 235, 1),
        ),
        'fill': FillTarget.toOrigin,
        'tension': 0.1,
        'pointStyle': const StarPointStyle(),
        'pointRadius': 4,
        'pointHoverRadius': 7,
      },
      <String, Object?>{
        'label': 'Model B',
        'data': <Object?>[5, 6, 8, 7, 7, 6],
        'backgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 159, 64, 0.2),
        ),
        'borderColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 159, 64, 1),
        ),
        'fill': const FillTarget.toDataset(0),
        'borderDash': <Object?>[4, 4],
        'spanGaps': false,
        'pointBackgroundColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 159, 64, 1),
        ),
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
          'color': const ChartPaint.solid(
            native_ui.Color.fromRGBO(201, 203, 207, 1),
          ),
          'lineWidth': 1,
        },
        'pointLabels': <String, Object?>{
          'color': const ChartPaint.solid(
            native_ui.Color.fromRGBO(27, 58, 92, 1),
          ),
          'font': const ChartTextStyle(
            fontSize: 13,
            fontWeight: native_ui.FontWeight.bold,
          ),
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
        'titleColor': const ChartPaint.solid(
          native_ui.Color.fromRGBO(255, 205, 86, 1),
        ),
        'callbacks': TooltipCallbacks(
          title: (tooltip, arg) => [jsToString(_rawRadarTitle(arg))],
        ),
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
