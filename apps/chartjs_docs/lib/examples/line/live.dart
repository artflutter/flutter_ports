// Ported from Chart.js v4.6.1 docs/charts/line.md (MIT, Chart.js Contributors).
// DIVERGES(chartjs): adapt-direct-colors, native Color inputs and values.
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:chartjs_docs/examples/line_data.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

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
class const LiveLineChart({required final List<DataPoint> points, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ChartView(
    config: liveLine(points),
    updateMode: UpdateMode.none,
    dataOnlyUpdates: true,
  );
}
// #enddocregion live
