// Original code, not ported from chartjs-chart-sankey: the example app.

/// A sankey chart of energy flows: each node has its color, and each flow
/// fades from the color of its source to the color of its target.
///
/// Run it from a Flutter app of your own: copy this file to `lib/main.dart`
/// and add `flutter_chartjs_port` and `flutter_chartjs_chart_sankey_port` to
/// the dependencies.
library;

import 'package:flutter_chartjs_chart_sankey_port/flutter_chartjs_chart_sankey_port.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  // Register the chart components and the sankey chart before the first
  // chart.
  Chart.register(registerables);
  Chart.register(sankeyRegisterables);
  runApp(const SankeyExampleApp());
}

/// The example app: one sankey chart.
class const SankeyExampleApp({super.key}) extends StatelessWidget {
  /// Creates the example app.
  this;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'flutter_chartjs_chart_sankey_port',
    home: Scaffold(
      appBar: AppBar(title: const Text('Energy flows')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: ChartView(
          config: ChartConfig(
            datasets: [
              SankeyDataset(
                data: [
                  SankeyDataPoint(from: 'Coal', to: 'Energy', flow: 25),
                  SankeyDataPoint(from: 'Gas', to: 'Energy', flow: 20),
                  SankeyDataPoint(from: 'Solar', to: 'Energy', flow: 10),
                  SankeyDataPoint(from: 'Energy', to: 'Heat', flow: 30),
                  SankeyDataPoint(from: 'Energy', to: 'Power', flow: 25),
                ],
                colorFrom: .byNode(nodeColor),
                colorTo: .byNode(nodeColor),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The color of the node [node].
Color nodeColor(String node) => switch (node) {
  'Coal' => const Color(0xFF59595B),
  'Gas' => const Color(0xFF4E79A7),
  'Solar' => const Color(0xFFEDC948),
  'Energy' => const Color(0xFFF28E2B),
  _ => const Color(0xFFE15759),
};
