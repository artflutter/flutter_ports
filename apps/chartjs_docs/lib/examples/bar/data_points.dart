// Ported from Chart.js v4.6.1 docs/charts/bar.md (MIT, Chart.js Contributors).
// The doc comments would show in the code panels.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';

// #docregion bar-data-points
const pointsBar = ChartConfig(
  datasets: [
    BarDataset(
      label: 'A label and a value for each item',
      data: .labelPoints([
        LabelPoint('Mon', 20),
        LabelPoint('Tue', 10),
        LabelPoint('Wed', 30),
        LabelPoint('Thu', 25),
      ]),
    ),
  ],
);
// #enddocregion bar-data-points

void main() {
  Chart.register(registerables);
  runApp(
    const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFFFFFFF),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: ChartView(config: pointsBar)),
        ),
      ),
    ),
  );
}
