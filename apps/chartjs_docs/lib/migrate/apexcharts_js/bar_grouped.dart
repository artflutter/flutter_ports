// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Grouped Bar Chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-bar-grouped
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// stroke: {width: 1, colors: ['#fff']}: a white line around each bar.
BarDataset _series(String name, List<num> values, Color color) =>
    apexJsBar(name, values, color, stroke: 1);

final ChartConfig _config = ChartConfig(
  labels: const ['2001', '2002', '2003', '2004', '2005', '2006', '2007'],
  indexAxis: .y,
  datasets: [
    _series('series-1', const [44, 55, 41, 64, 22, 43, 21], Apex.blue),
    _series('series-2', const [53, 32, 33, 52, 13, 44, 32], Apex.green),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 30, 16, 0),
  legend: apexJsLegend(square: true),
  // tooltip: {shared: true, intersect: false}: one row for each series of
  // the hovered year.
  tooltip: apexTooltip(horizontal: true),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
    axis: .y,
  ),
  animation: apexAnimation,
  plugins: [
    // dataLabels: {offsetX: -6, style: {colors: ['#fff']}} with
    // plotOptions.bar.dataLabels.position: 'top': inside the end of a bar.
    apexJsBarLabels(at: .insideEnd),
    apexTooltipLook,
  ],
  scales: [
    apexJsCategoryAxis(horizontal: true),
    apexJsValueAxis(min: 0, max: 80, stepSize: 20, horizontal: true),
  ],
);

class const ApexJsBarGrouped({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    // chart.height: 430
    height: 430,
    child: ChartView(
      config: _config,
      semanticLabel: 'Grouped horizontal bar chart of two series by year',
    ),
  );
}
// #enddocregion apexjs-bar-grouped

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsBarGrouped(),
        ),
      ),
    ),
  );
}
