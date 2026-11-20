// Original code, not ported from Chart.js: a replica of the Graphic demo "Interval Bar Chart".
// ignore_for_file: lines_longer_than_80_chars
// #docregion graphic-bar-interval
import 'package:chartjs_docs/migrate/graphic/graphic_bar_data.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_bar_kit.dart';
import 'package:chartjs_docs/migrate/graphic/graphic_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

final ChartConfig _config = ChartConfig(
  labels: [for (final row in intervalData) row.id],
  datasets: [
    BarDataset(
      backgroundColor: const .constant(.solid(Gx.primary)),
      barThickness: const BarThickness.pixels(barSize),
      // `RectShape(borderRadius: BorderRadius.circular(2))`: all four
      // corners, so no edge is skipped.
      borderRadius: 2,
      extra: {
        // `Varset('min') + Varset('max')`: a floating bar takes the pair
        // `[start, end]`.
        'data': [
          for (final row in intervalData) [row.min, row.max],
        ],
        'borderSkipped': false,
      },
    ),
  ],
  scales: {
    'x': CategoryAxis(
      grid: noGrid,
      ticks: graphicTicks(),
      border: bottomBorder,
      extra: bottomAxis,
    ),
    // `LinearScale(min: 0, max: 160)` of both variables.
    'y': LinearAxis(
      min: 0,
      max: 160,
      grid: lineGrid,
      ticks: graphicTicks(callback: numberLabel, stepSize: 40),
      border: leftBorder,
      extra: leftAxis,
    ),
  },
  padding: regionPadding,
  maintainAspectRatio: false,
  animation: ChartAnimation.none,
  legend: const ChartLegend(display: false),
  // The demo has no selection.
  extra: const {'events': <String>[]},
);

/// The replica of the Graphic demo "Interval Bar Chart".
class const GraphicBarInterval({super.key}) extends StatelessWidget {
  /// Creates the replica.
  this;

  @override
  Widget build(BuildContext context) => GraphicBox(
    child: ChartView(
      config: _config,
      semanticLabel: 'Floating bar chart of a range of values for eight ids',
    ),
  );
}
// #enddocregion graphic-bar-interval

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: GraphicBarInterval(),
        ),
      ),
    ),
  );
}
