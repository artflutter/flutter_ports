// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

/// The code of the live charts of the bar chart page.
///
/// The app also loads this file as an asset. A code panel shows the lines
/// between `// #docregion <name>` and `// #enddocregion <name>`, so that a
/// panel shows the code that draws its chart. Each region name starts with
/// `bar-`: a name is unique over all the source files of the site.
library;

import 'package:chartjs_docs/examples/line_examples.dart'
    show blue, blueFill, months, red, redFill, teal, tealFill, values;
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// The second dataset of the examples with two datasets.
const List<num?> lastYear = [50, 62, 71, 60, 48, 66, 52];

/// The data of the examples with a negative value.
const List<num?> mixedSigns = [65, -30, 80, 81, -20, 55, 40];

// #docregion bar-basic
const barFills = <ChartPaint>[
  .solid(Color.fromRGBO(255, 99, 132, 0.2)),
  .solid(Color.fromRGBO(255, 159, 64, 0.2)),
  .solid(Color.fromRGBO(255, 205, 86, 0.2)),
  .solid(Color.fromRGBO(75, 192, 192, 0.2)),
  .solid(Color.fromRGBO(54, 162, 235, 0.2)),
  .solid(Color.fromRGBO(153, 102, 255, 0.2)),
  .solid(Color.fromRGBO(201, 203, 207, 0.2)),
];

const barBorders = <ChartPaint>[
  .solid(Color.fromRGBO(255, 99, 132, 1)),
  .solid(Color.fromRGBO(255, 159, 64, 1)),
  .solid(Color.fromRGBO(255, 205, 86, 1)),
  .solid(Color.fromRGBO(75, 192, 192, 1)),
  .solid(Color.fromRGBO(54, 162, 235, 1)),
  .solid(Color.fromRGBO(153, 102, 255, 1)),
  .solid(Color.fromRGBO(201, 203, 207, 1)),
];

const basicBar = ChartConfig(
  type: .bar,
  labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
  datasets: [
    BarDataset(
      label: 'My First Dataset',
      data: [65, 59, 80, 81, 56, 55, 40],
      backgroundColor: .indexed(barFills),
      borderColor: .indexed(barBorders),
      borderWidth: 1,
    ),
  ],
  scales: {'y': LinearAxis(beginAtZero: true)},
);
// #enddocregion bar-basic

// #docregion bar-scopes
const scopedBar = ChartConfig(
  type: .bar,
  labels: months,
  // For this dataset only.
  datasets: [
    BarDataset(
      label: 'Sales',
      data: values,
      backgroundColor: .constant(.solid(tealFill)),
      borderColor: .constant(.solid(teal)),
    ),
  ],
  // For all bar elements.
  elements: ChartElements(
    bar: BarElementStyle(borderWidth: 2, borderRadius: 6),
  ),
  // For all bar datasets. This scope has no parameter.
  extra: {
    'datasets': {
      'bar': {'barPercentage': 0.6},
    },
  },
);
// #enddocregion bar-scopes

// #docregion bar-dataset-config
const thinBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Thin bars',
      barPercentage: 0.5,
      barThickness: 6,
      maxBarThickness: 8,
      minBarLength: 2,
      data: [10, 20, 30, 40, 50, 60, 70],
    ),
  ],
);
// #enddocregion bar-dataset-config

// #docregion bar-grouped
const groupedBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'This year',
      data: values,
      backgroundColor: .constant(.solid(teal)),
    ),
    BarDataset(
      label: 'Last year',
      data: lastYear,
      backgroundColor: .constant(.solid(blue)),
    ),
  ],
);
// #enddocregion bar-grouped

// #docregion bar-ungrouped
const ungroupedBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'This year',
      data: values,
      backgroundColor: .constant(.solid(tealFill)),
      borderColor: .constant(.solid(teal)),
      borderWidth: 2,
      grouped: false,
    ),
    BarDataset(
      label: 'Last year',
      data: lastYear,
      backgroundColor: .constant(.solid(blueFill)),
      borderColor: .constant(.solid(blue)),
      borderWidth: 2,
      grouped: false,
    ),
  ],
);
// #enddocregion bar-ungrouped

// #docregion bar-skip-null
const skipNullBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'North',
      data: [65, null, 80, null, 56, 55, null],
      backgroundColor: .constant(.solid(teal)),
      extra: {'skipNull': true},
    ),
    BarDataset(
      label: 'South',
      data: [50, 62, null, 60, null, 66, 52],
      backgroundColor: .constant(.solid(blue)),
      extra: {'skipNull': true},
    ),
  ],
);
// #enddocregion bar-skip-null

// #docregion bar-base
const baseBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Above or below 60',
      data: values,
      backgroundColor: .constant(.solid(tealFill)),
      borderColor: .constant(.solid(teal)),
      borderWidth: 1,
      // A value of the y axis, through extra.
      extra: {'base': 60},
    ),
  ],
);
// #enddocregion bar-base

// #docregion bar-colors
const coloredBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Colors',
      data: values,
      backgroundColor: .constant(.solid(tealFill)),
      borderColor: .constant(.solid(teal)),
      borderWidth: 2,
    ),
  ],
);
// #enddocregion bar-colors

// #docregion bar-min-length
const minLengthBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Small values stay visible',
      data: [65, 0.5, 80, 1, 56, 0, 40],
      backgroundColor: .constant(.solid(teal)),
      minBarLength: 10,
    ),
  ],
);
// #enddocregion bar-min-length

// #docregion bar-shadow
const shadowBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Shadow',
      data: values,
      backgroundColor: .constant(.solid(teal)),
      shadow: ChartShadow(
        color: Color(0x66000000),
        blur: 10,
        offset: Offset(0, 6),
      ),
    ),
  ],
);
// #enddocregion bar-shadow

/// The border skip example, with the value of the selected variant.
// #docregion bar-border-skipped
// A BorderSkippedEdge, false or true.
ChartConfig borderSkipped(Object skipped) => ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Border width 4',
      data: mixedSigns,
      backgroundColor: const .constant(.solid(tealFill)),
      borderColor: const .constant(.solid(teal)),
      borderWidth: 4,
      extra: {'borderSkipped': skipped},
    ),
  ],
);
// #enddocregion bar-border-skipped

// #docregion bar-border-width
const sameBorders = BarDataset(
  label: 'A number',
  data: values,
  backgroundColor: .constant(.solid(tealFill)),
  borderColor: .constant(.solid(teal)),
  borderWidth: 3,
);
// #enddocregion bar-border-width

// #docregion bar-border-width-object
const sideBorders = BarDataset(
  label: 'A width for each side',
  data: values,
  backgroundColor: .constant(.solid(tealFill)),
  borderColor: .constant(.solid(teal)),
  // No bottom border: an omitted side has no border.
  extra: {
    'borderWidth': {'top': 6, 'left': 1, 'right': 1},
  },
);
// #enddocregion bar-border-width-object

// #docregion bar-border-radius
const roundedBars = BarDataset(
  label: 'A number',
  data: mixedSigns,
  backgroundColor: .constant(.solid(teal)),
  borderRadius: 12,
);
// #enddocregion bar-border-radius

// #docregion bar-border-radius-all
const roundBars = BarDataset(
  label: 'All corners',
  data: mixedSigns,
  backgroundColor: .constant(.solid(teal)),
  borderRadius: 12,
  extra: {'borderSkipped': false},
);
// #enddocregion bar-border-radius-all

// #docregion bar-border-radius-object
const cornerBars = BarDataset(
  label: 'A radius for each corner',
  data: mixedSigns,
  backgroundColor: .constant(.solid(teal)),
  extra: {
    'borderRadius': {'topLeft': 16, 'topRight': 2},
  },
);
// #enddocregion bar-border-radius-object

// #docregion bar-border-radius-stacked
const roundedStack = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Mobile',
      data: [30, 35, 28, 40, 45, 42, 50],
      backgroundColor: .constant(.solid(teal)),
      borderRadius: 10,
    ),
    BarDataset(
      label: 'Desktop',
      data: [20, 25, 22, 18, 24, 30, 26],
      backgroundColor: .constant(.solid(blue)),
      borderRadius: 10,
    ),
  ],
  scales: {'x': CategoryAxis(stacked: true), 'y': LinearAxis(stacked: true)},
);
// #enddocregion bar-border-radius-stacked

// #docregion bar-interactions
const hoverBars = BarDataset(
  label: 'Move the pointer over a bar',
  data: values,
  backgroundColor: .constant(.solid(tealFill)),
  borderColor: .constant(.solid(teal)),
  borderWidth: 1,
  hoverBackgroundColor: .constant(.solid(redFill)),
  hoverBorderColor: .constant(.solid(red)),
  hoverBorderWidth: 3,
  extra: {'hoverBorderRadius': 8},
);
// #enddocregion bar-interactions

// #docregion bar-thickness-default
// Bars on a linear x axis, with uneven spaces between the x values.
final unevenPoints = [
  DataPoint(1, 20),
  DataPoint(2, 35),
  DataPoint(4, 30),
  DataPoint(8, 45),
  DataPoint(9, 25),
];

final fitBars = ChartConfig(
  type: .bar,
  datasets: [
    BarDataset(
      label: 'Equal widths',
      points: unevenPoints,
      backgroundColor: const .constant(.solid(teal)),
    ),
  ],
  scales: const {'x': LinearAxis()},
);
// #enddocregion bar-thickness-default

// #docregion bar-thickness-number
final fixedBars = ChartConfig(
  type: .bar,
  datasets: [
    BarDataset(
      label: '12 pixels',
      points: unevenPoints,
      backgroundColor: const .constant(.solid(teal)),
      barThickness: 12,
    ),
  ],
  scales: const {'x': LinearAxis()},
);
// #enddocregion bar-thickness-number

// #docregion bar-thickness-flex
final flexBars = ChartConfig(
  type: .bar,
  datasets: [
    BarDataset(
      label: 'Widths from the spaces',
      points: unevenPoints,
      backgroundColor: const .constant(.solid(teal)),
      extra: const {'barThickness': 'flex'},
    ),
  ],
  scales: const {'x': LinearAxis()},
);
// #enddocregion bar-thickness-flex

// #docregion bar-grid-offset
const offsetGrid = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [BarDataset(label: 'Visitors', data: values)],
  scales: {'x': CategoryAxis(grid: AxisGrid(offset: true))},
);
// #enddocregion bar-grid-offset

// #docregion bar-grid-centered
const centeredGrid = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [BarDataset(label: 'Visitors', data: values)],
  scales: {'x': CategoryAxis(grid: AxisGrid(offset: false))},
);
// #enddocregion bar-grid-centered

/// Sets a default for all bar charts that the app creates after this call.
void skipNullInAllBarCharts() {
  // #docregion bar-defaults
  defaults.override('bar', {'skipNull': true});
  // #enddocregion bar-defaults
}

/// The percentage example, with the values of the selected variant.
// #docregion bar-percentages
ChartConfig percentages({required double category, required double bar}) =>
    ChartConfig(
      type: .bar,
      labels: const ['Q1', 'Q2', 'Q3'],
      datasets: [
        for (final (label, data, color) in const [
          ('A', [30, 50, 40], teal),
          ('B', [45, 35, 55], blue),
        ])
          BarDataset(
            label: label,
            data: data,
            backgroundColor: .constant(.solid(color)),
            categoryPercentage: category,
            barPercentage: bar,
          ),
      ],
    );
// #enddocregion bar-percentages

// #docregion bar-data-values
const valuesBar = ChartConfig(
  type: .bar,
  labels: ['Mon', 'Tue', 'Wed', 'Thu'],
  datasets: [
    BarDataset(label: 'One value for each label', data: [20, 10, 30, 25]),
  ],
);
// #enddocregion bar-data-values

// #docregion bar-data-points
final pointsBar = ChartConfig(
  type: .bar,
  datasets: [
    BarDataset(
      label: 'A label and a value for each item',
      points: [
        DataPoint.label('Mon', 20),
        DataPoint.label('Tue', 10),
        DataPoint.label('Wed', 30),
        DataPoint.label('Thu', 25),
      ],
    ),
  ],
);
// #enddocregion bar-data-points

// #docregion bar-stacked
const stackedBars = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Mobile',
      data: [30, 35, 28, 40, 45, 42, 50],
      backgroundColor: .constant(.solid(teal)),
    ),
    BarDataset(
      label: 'Desktop',
      data: [20, 25, 22, 18, 24, 30, 26],
      backgroundColor: .constant(.solid(blue)),
    ),
    BarDataset(
      label: 'Tablet',
      data: [10, 8, 12, 14, 9, 11, 15],
      backgroundColor: .constant(.solid(red)),
    ),
  ],
  scales: {'x': CategoryAxis(stacked: true), 'y': LinearAxis(stacked: true)},
);
// #enddocregion bar-stacked

// #docregion bar-stack-groups
const groupedStacks = ChartConfig(
  type: .bar,
  labels: months,
  datasets: [
    BarDataset(
      label: 'Mobile 2026',
      data: [30, 35, 28, 40, 45, 42, 50],
      backgroundColor: .constant(.solid(teal)),
      stack: '2026',
    ),
    BarDataset(
      label: 'Desktop 2026',
      data: [20, 25, 22, 18, 24, 30, 26],
      backgroundColor: .constant(.solid(blue)),
      stack: '2026',
    ),
    BarDataset(
      label: 'Mobile 2025',
      data: [25, 28, 30, 33, 36, 38, 41],
      backgroundColor: .constant(.solid(tealFill)),
      stack: '2025',
    ),
    BarDataset(
      label: 'Desktop 2025',
      data: [24, 26, 25, 21, 27, 29, 28],
      backgroundColor: .constant(.solid(blueFill)),
      stack: '2025',
    ),
  ],
  scales: {'x': CategoryAxis(stacked: true), 'y': LinearAxis(stacked: true)},
);
// #enddocregion bar-stack-groups

// #docregion bar-horizontal
const horizontalBar = ChartConfig(
  type: .bar,
  labels: months,
  indexAxis: YAxis(),
  datasets: [
    BarDataset(
      label: 'My First Dataset',
      data: [65, 59, 80, 81, 56, 55, 40],
      backgroundColor: .indexed(barFills),
      borderColor: .indexed(barBorders),
      borderWidth: 1,
    ),
  ],
);
// #enddocregion bar-horizontal
