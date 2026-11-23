// Original code, not ported from Chart.js: a replica of the apexcharts_flutter demo "Bar — horizontal".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apex-bar-horizontal
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

final ChartConfig _config = ChartConfig(
  // plotOptions.bar.horizontal: true.
  indexAxis: const YAxis(),
  labels: const ['A', 'B', 'C', 'D', 'E', 'F'],
  datasets: const [
    BarDataset(
      label: 'Score',
      data: .values([44, 55, 41, 67, 22, 43]),
      backgroundColor: .constant(.solid(Apex.red)),
      hoverBackgroundColor: .constant(.solid(Apex.red)),
      borderWidth: 0,
      // columnWidth: '70%': each bar takes 70 % of its band.
      categoryPercentage: 0.7,
      barPercentage: 1,
    ),
  ],
  maintainAspectRatio: false,
  padding: apexPadding,
  legend: const ChartLegend(display: false),
  pluginOptions: [apexTooltip(horizontal: true)],
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
    axis: .y,
  ),
  animation: apexAnimation,
  plugins: [apexHover, apexTooltipLook],
  scales: [
    // The values under the plot, with a grid line at each value, and the
    // categories on the left.
    apexValueAxis(min: 0, max: 80, stepSize: 20, horizontal: true),
    apexCategoryAxis(horizontal: true),
  ],
);

class const ApexBarHorizontal({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 320,
    child: ChartView(
      config: _config,
      semanticLabel: 'Horizontal bar chart of six scores',
    ),
  );
}
// #enddocregion apex-bar-horizontal

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexBarHorizontal(),
        ),
      ),
    ),
  );
}
