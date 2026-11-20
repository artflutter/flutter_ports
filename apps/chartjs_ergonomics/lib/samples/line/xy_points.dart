// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
final xyPoints = ChartConfig(
  datasets: [
    LineDataset(
      label: 'An x and a y for each item',
      points: [
        DataPoint(0, 20),
        DataPoint(1.5, 10),
        DataPoint(4, 30),
        DataPoint(4.5, 25),
        DataPoint(9, 40),
      ],
      borderColor: const .constant(.solid(blue)),
    ),
  ],
  scales: const [LinearAxis(.x)],
);
// #enddocregion sample
