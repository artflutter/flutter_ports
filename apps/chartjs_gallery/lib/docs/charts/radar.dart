// Ported from Chart.js v4.6.1 docs/charts/radar.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
import 'dart:ui';

import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

/// `rgb(255, 99, 132)`.
const ChartPaint _red = ChartPaint.solid(Color.fromRGBO(255, 99, 132, 1));

/// `rgb(54, 162, 235)`.
const ChartPaint _blue = ChartPaint.solid(Color.fromRGBO(54, 162, 235, 1));

/// `rgb(255, 255, 255)`.
const ChartPaint _white = ChartPaint.solid(Color.fromRGBO(255, 255, 255, 1));

/// The radar chart of `docs/charts/radar.md:7-61`, with each key and value
/// of the docs block.
///
/// The datasets have `fill: true` (`radar.md:22`, `:32`), the fill to the
/// origin (Chart.js ADR 0140). The gallery registers the filler plugin of
/// `registerables`. Thus the chart fills the area of each dataset, and
/// `initialize` prints no `fill` warning (core.datasetController.js:287-289).
ChartConfig radarConfig() => const ChartConfig(
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
        ChartPaint.solid(Color.fromRGBO(255, 99, 132, 0.2)),
      ),
      borderColor: ChartValue.constant(_red),
      pointBackgroundColor: ChartValue.constant(_red),
      pointBorderColor: ChartValue.constant(_white),
      pointHoverBackgroundColor: ChartValue.constant(_white),
      pointHoverBorderColor: ChartValue.constant(_red),
    ),
    RadarDataset(
      label: 'My Second Dataset',
      data: [28, 48, 40, 19, 96, 27, 100],
      fill: .toOrigin,
      backgroundColor: ChartValue.constant(
        ChartPaint.solid(Color.fromRGBO(54, 162, 235, 0.2)),
      ),
      borderColor: ChartValue.constant(_blue),
      pointBackgroundColor: ChartValue.constant(_blue),
      pointBorderColor: ChartValue.constant(_white),
      pointHoverBackgroundColor: ChartValue.constant(_white),
      pointHoverBorderColor: ChartValue.constant(_blue),
    ),
  ],
  elements: ChartElements(line: LineElementStyle(borderWidth: 3)),
);
