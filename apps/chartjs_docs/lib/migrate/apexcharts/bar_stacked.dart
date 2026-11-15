// Original code, not ported from Chart.js: a replica of the apexcharts_flutter demo "Bar — stacked".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apex-bar-stacked
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

BarDataset _series(String name, Color color, List<num> values) => BarDataset(
  label: name,
  data: values,
  backgroundColor: .constant(.solid(color)),
  hoverBackgroundColor: .constant(.solid(color)),
  borderWidth: 0,
  // plotOptions.bar.columnWidth: '60%'.
  categoryPercentage: 0.6,
  barPercentage: 1,
);

final ChartConfig _config = ChartConfig(
  type: .bar,
  labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
  datasets: [
    _series('Q1', Apex.blue, const [20, 30, 25, 40, 32, 28]),
    _series('Q2', Apex.green, const [15, 25, 20, 18, 22, 30]),
    _series('Q3', Apex.yellow, const [10, 12, 18, 22, 15, 20]),
  ],
  maintainAspectRatio: false,
  padding: apexPadding.copyWith(bottom: 0),
  legend: apexLegend,
  tooltip: apexTooltip(),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  plugins: [apexHover, apexTooltipLook],
  scales: {
    // chart.stacked: true: both axes stack. The value axis takes the sums.
    'x': apexCategoryAxis().copyWith(stacked: true),
    'y': apexValueAxis(min: 0, max: 80, stepSize: 20, stacked: true),
  },
);

class const ApexBarStacked({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 320,
    child: ChartView(
      config: _config,
      semanticLabel: 'Stacked column chart of three quarters',
    ),
  );
}
// #enddocregion apex-bar-stacked

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexBarStacked(),
        ),
      ),
    ),
  );
}
