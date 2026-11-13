// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

/// The code of the live charts of the line chart page.
///
/// The app also loads this file as an asset. A code panel shows the lines
/// between `// #docregion <name>` and `// #enddocregion <name>`, so that a
/// panel shows the code that draws its chart.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The labels of `Utils.months({count: 7})`.
const List<Object> months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
];

/// The values of the first docs chart.
const List<num?> values = [65, 59, 80, 81, 56, 55, 40];

/// The line color of the examples.
const Color teal = Color.fromRGBO(75, 192, 192, 1);

/// The fill color that goes with [teal].
const Color tealFill = Color.fromRGBO(75, 192, 192, 0.25);

/// The second line color of the examples.
const Color red = Color.fromRGBO(255, 99, 132, 1);

/// The fill color that goes with [red].
const Color redFill = Color.fromRGBO(255, 99, 132, 0.25);

/// The third line color of the examples.
const Color blue = Color.fromRGBO(54, 162, 235, 1);

/// The fill color that goes with [blue].
const Color blueFill = Color.fromRGBO(54, 162, 235, 0.25);

/// A chart with the one dataset [dataset] over [months].
ChartConfig oneLine(LineDataset dataset) =>
    ChartConfig(type: .line, labels: months, datasets: [dataset]);

/// Registers the chart components, one time for the app.
void registerCharts() {
  // #docregion register
  Chart.register(registerables);
  // #enddocregion register
}

// #docregion basic
const basicLine = ChartConfig(
  type: .line,
  labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
  datasets: [
    LineDataset(
      label: 'My First Dataset',
      data: [65, 59, 80, 81, 56, 55, 40],
      fill: .none,
      borderColor: .constant(.solid(Color.fromRGBO(75, 192, 192, 1))),
      tension: 0.1,
    ),
  ],
);
// #enddocregion basic

// #docregion scopes
const scopedLine = ChartConfig(
  type: .line,
  labels: months,
  // For this dataset only.
  datasets: [
    LineDataset(
      label: 'Sales',
      data: values,
      borderColor: .constant(.solid(teal)),
    ),
  ],
  // For all line elements and all point elements.
  elements: ChartElements(
    line: LineElementStyle(tension: 0.3, borderWidth: 4),
    point: PointElementStyle(radius: 6),
  ),
  // For all line datasets. This scope has no parameter.
  extra: {
    'datasets': {
      'line': {'pointHoverRadius': 10},
    },
  },
);
// #enddocregion scopes

// #docregion scriptable
const scriptableLine = LineDataset(
  label: 'Score',
  data: values,
  borderColor: .constant(.solid(teal)),
  // A typed function for a color.
  backgroundColor: .resolver(pointFill),
  // A list by data index, through extra.
  extra: {
    'pointRadius': [4, 6, 8, 10, 8, 6, 4],
  },
);

ChartPaint pointFill(ChartContext context) {
  final index = context.dataIndex;
  return ChartPaint.solid(index != null && values[index]! >= 60 ? teal : red);
}
// #enddocregion scriptable

/// The point style example, with the style of the selected variant.
// #docregion point-styling
ChartConfig pointStyling(PointStyle style) => ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Visitors',
      data: values,
      borderColor: const .constant(.solid(teal)),
      pointStyle: style,
      pointRadius: 9,
      pointBorderWidth: 2,
      pointBackgroundColor: const .constant(.solid(tealFill)),
      pointBorderColor: const .constant(.solid(teal)),
      extra: const {'pointHitRadius': 14},
    ),
  ],
);
// #enddocregion point-styling

// #docregion line-solid
const solidLine = LineDataset(
  label: 'Solid',
  data: values,
  borderColor: .constant(.solid(teal)),
  borderWidth: 3,
);
// #enddocregion line-solid

// #docregion line-dashed
const dashedLine = LineDataset(
  label: 'Dashed',
  data: values,
  borderColor: .constant(.solid(teal)),
  borderDash: [10, 6],
  borderCapStyle: StrokeCap.round,
  extra: {'borderDashOffset': 2},
);
// #enddocregion line-dashed

// #docregion line-filled
const filledLine = LineDataset(
  label: 'Filled',
  data: values,
  borderColor: .constant(.solid(teal)),
  backgroundColor: .constant(.solid(tealFill)),
  fill: .toOrigin,
  tension: 0.3,
);
// #enddocregion line-filled

// #docregion line-points-only
const pointsOnlyLine = LineDataset(
  label: 'Points only',
  data: values,
  borderColor: .constant(.solid(teal)),
  backgroundColor: .constant(.solid(teal)),
  showLine: false,
);
// #enddocregion line-points-only

// #docregion line-shadow
const shadowLine = LineDataset(
  label: 'Shadow',
  data: values,
  borderColor: .constant(.solid(teal)),
  borderWidth: 3,
  shadow: ChartShadow(color: Color(0x66000000), blur: 10, offset: Offset(0, 6)),
);
// #enddocregion line-shadow

/// The data of the gap examples.
const List<num?> gapValues = [65, 59, null, 81, 56, null, 40];

// #docregion gaps-break
const brokenLine = LineDataset(
  label: 'With gaps',
  data: [65, 59, null, 81, 56, null, 40],
  borderColor: .constant(.solid(teal)),
);
// #enddocregion gaps-break

// #docregion gaps-span
const spannedLine = LineDataset(
  label: 'Spanned gaps',
  data: [65, 59, null, 81, 56, null, 40],
  borderColor: .constant(.solid(teal)),
  spanGaps: true,
);
// #enddocregion gaps-span

// #docregion interactions
const hoverLine = LineDataset(
  label: 'Move the pointer over a point',
  data: values,
  borderColor: .constant(.solid(teal)),
  pointRadius: 5,
  pointHoverRadius: 11,
  pointHoverBackgroundColor: .constant(.solid(red)),
  pointHoverBorderColor: .constant(.solid(redFill)),
  extra: {'pointHoverBorderWidth': 6},
);
// #enddocregion interactions

// #docregion cubic
const cubicLines = ChartConfig(
  type: .line,
  labels: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
  datasets: [
    LineDataset(
      label: 'default',
      data: [0, 20, 20, 60, 60, 120, 180, 120, 125, 105, 110, 170],
      borderColor: .constant(.solid(red)),
      tension: 0.4,
    ),
    LineDataset(
      label: 'monotone',
      data: [0, 20, 20, 60, 60, 120, 180, 120, 125, 105, 110, 170],
      borderColor: .constant(.solid(blue)),
      tension: 0.4,
      cubicInterpolationMode: MonotoneCubicInterpolationMode(),
    ),
  ],
);
// #enddocregion cubic

// #docregion segment
const trend = <num?>[65, 59, 80, 81, null, 55, 40, 62];

const segmentLine = ChartConfig(
  type: .line,
  labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Mon'],
  datasets: [
    LineDataset(
      label: 'Trend',
      data: trend,
      borderColor: .constant(.solid(teal)),
      spanGaps: true,
      segment: LineSegmentStyle(
        borderColor: segmentColor,
        borderDash: segmentDash,
      ),
    ),
  ],
);

// Gray across a gap, red where the line goes down; null keeps the line color.
ChartPaint? segmentColor(ScriptableLineSegmentContext segment) {
  final from = trend[segment.p0DataIndex];
  final to = trend[segment.p1DataIndex];
  if (from == null || to == null) {
    return const ChartPaint.solid(Color.fromRGBO(0, 0, 0, 0.2));
  }
  return from > to ? const ChartPaint.solid(red) : null;
}

// Dashed across a gap.
List<double>? segmentDash(ScriptableLineSegmentContext segment) =>
    trend[segment.p0DataIndex] == null || trend[segment.p1DataIndex] == null
    ? const [6, 6]
    : null;
// #enddocregion segment

/// The data of the stepped examples.
const List<num?> stepValues = [10, 40, 25, 60, 45, 80, 70];

// #docregion stepped-false
const noStep = LineDataset(
  label: 'stepped: false',
  data: stepValues,
  borderColor: .constant(.solid(blue)),
);
// #enddocregion stepped-false

// #docregion stepped-true
const stepTrue = LineDataset(
  label: 'stepped: true',
  data: stepValues,
  borderColor: .constant(.solid(blue)),
  extra: {'stepped': true},
);
// #enddocregion stepped-true

// #docregion stepped-before
const stepBefore = LineDataset(
  label: 'stepped: .before',
  data: stepValues,
  borderColor: .constant(.solid(blue)),
  stepped: SteppedLine.before,
);
// #enddocregion stepped-before

// #docregion stepped-after
const stepAfter = LineDataset(
  label: 'stepped: .after',
  data: stepValues,
  borderColor: .constant(.solid(blue)),
  stepped: SteppedLine.after,
);
// #enddocregion stepped-after

// #docregion stepped-middle
const stepMiddle = LineDataset(
  label: 'stepped: .middle',
  data: stepValues,
  borderColor: .constant(.solid(blue)),
  stepped: SteppedLine.middle,
);
// #enddocregion stepped-middle

/// Sets a default for all line charts that the app creates after this call.
void spanGapsInAllLineCharts() {
  // #docregion defaults
  defaults.override('line', {'spanGaps': true});
  // #enddocregion defaults
}

// #docregion data-values
const valuesLine = ChartConfig(
  type: .line,
  labels: ['Mon', 'Tue', 'Wed', 'Thu'],
  datasets: [
    LineDataset(
      label: 'One value for each label',
      data: [20, 10, 30, 25],
      borderColor: .constant(.solid(teal)),
    ),
  ],
);
// #enddocregion data-values

// #docregion data-points
final pointsLine = ChartConfig(
  type: .line,
  datasets: [
    LineDataset(
      label: 'An x and a y for each item',
      points: [
        DataPoint(10, 20),
        DataPoint(15, 10),
        DataPoint(40, 30),
        DataPoint(45, 25),
      ],
      borderColor: const .constant(.solid(teal)),
    ),
  ],
  scales: const {'x': LinearAxis()},
);
// #enddocregion data-points

// #docregion stacked
const stackedLines = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Mobile',
      data: [30, 35, 28, 40, 45, 42, 50],
      borderColor: .constant(.solid(teal)),
      backgroundColor: .constant(.solid(tealFill)),
      fill: .toStacked,
    ),
    LineDataset(
      label: 'Desktop',
      data: [20, 25, 22, 18, 24, 30, 26],
      borderColor: .constant(.solid(blue)),
      backgroundColor: .constant(.solid(blueFill)),
      fill: .toStacked,
    ),
    LineDataset(
      label: 'Tablet',
      data: [10, 8, 12, 14, 9, 11, 15],
      borderColor: .constant(.solid(red)),
      backgroundColor: .constant(.solid(redFill)),
      fill: .toStacked,
    ),
  ],
  scales: {'y': LinearAxis(stacked: true, beginAtZero: true)},
);
// #enddocregion stacked

// #docregion vertical
const verticalLine = ChartConfig(
  type: .line,
  labels: months,
  indexAxis: YAxis(),
  datasets: [
    LineDataset(
      label: 'My First Dataset',
      data: [65, 59, 80, 81, 56, 55, 40],
      fill: .none,
      backgroundColor: .indexed([
        .solid(Color.fromRGBO(255, 99, 132, 0.2)),
        .solid(Color.fromRGBO(255, 159, 64, 0.2)),
        .solid(Color.fromRGBO(255, 205, 86, 0.2)),
        .solid(Color.fromRGBO(75, 192, 192, 0.2)),
        .solid(Color.fromRGBO(54, 162, 235, 0.2)),
        .solid(Color.fromRGBO(153, 102, 255, 0.2)),
        .solid(Color.fromRGBO(201, 203, 207, 0.2)),
      ]),
      borderColor: .indexed([
        .solid(Color.fromRGBO(255, 99, 132, 1)),
        .solid(Color.fromRGBO(255, 159, 64, 1)),
        .solid(Color.fromRGBO(255, 205, 86, 1)),
        .solid(Color.fromRGBO(75, 192, 192, 1)),
        .solid(Color.fromRGBO(54, 162, 235, 1)),
        .solid(Color.fromRGBO(153, 102, 255, 1)),
        .solid(Color.fromRGBO(201, 203, 207, 1)),
      ]),
      borderWidth: 1,
      extra: {'axis': YAxis()},
    ),
  ],
  scales: {'x': LinearAxis(beginAtZero: true)},
);
// #enddocregion vertical

// #docregion internal-format
final preparedLine = LineDataset(
  label: 'Sorted, with no parse step',
  points: [DataPoint(0, 12), DataPoint(1, 18), DataPoint(2, 9)],
  extra: const {'parsing': false},
);
// #enddocregion internal-format

// #docregion live
ChartConfig liveLine(List<DataPoint> points) => ChartConfig(
  type: .line,
  datasets: [
    LineDataset(
      label: 'Signal',
      points: points,
      borderColor: const .constant(.solid(teal)),
      borderWidth: 1.5,
      pointRadius: 0,
    ),
  ],
  scales: const {
    'x': LinearAxis(min: 0, max: 999),
    'y': LinearAxis(min: -1.5, max: 1.5),
  },
  animation: ChartAnimation.none,
);

// Give a new List in each frame:
Widget liveLineChart(List<DataPoint> points) => ChartView(
  config: liveLine(points),
  updateMode: 'none',
  dataOnlyUpdates: true,
);
// #enddocregion live
