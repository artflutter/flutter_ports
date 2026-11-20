// Original code, not ported from Chart.js: an API ergonomics sample.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_ergonomics/samples/line/data.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion sample
final timeAxis = ChartConfig(
  type: .line,
  datasets: [
    LineDataset(
      label: 'Visits',
      points: [
        DataPoint.time(DateTime(2026, 11, 2), 120),
        DataPoint.time(DateTime(2026, 11, 3), 150),
        DataPoint.time(DateTime(2026, 11, 4), 90),
        DataPoint.time(DateTime(2026, 11, 6), 170),
        DataPoint.time(DateTime(2026, 11, 9), 140),
      ],
      borderColor: const .constant(.solid(blue)),
    ),
  ],
  scales: const {'x': TimeAxis(unit: .day)},
);
// #enddocregion sample
