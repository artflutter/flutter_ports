// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.

/// The shared data of the line chart examples.
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
    ChartConfig(labels: months, datasets: [dataset]);

/// The data of the gap examples.
const List<num?> gapValues = [65, 59, null, 81, 56, null, 40];

/// The data of the stepped examples.
const List<num?> stepValues = [10, 40, 25, 60, 45, 80, 70];
