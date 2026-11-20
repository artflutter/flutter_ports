// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
const indexedColors = ChartConfig(
  type: .line,
  labels: months,
  datasets: [
    LineDataset(
      label: 'Sales',
      data: sales,
      borderColor: .constant(.solid(teal)),
      pointRadius: 7,
      // Item i takes color i; a shorter list repeats.
      pointBackgroundColor: .indexed([
        .solid(red),
        .solid(orange),
        .solid(teal),
        .solid(blue),
      ]),
    ),
  ],
);
// #enddocregion sample
