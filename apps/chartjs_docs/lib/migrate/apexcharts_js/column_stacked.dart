// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Stacked Columns".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-column-stacked
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// fill: {opacity: 1}
BarDataset _series(
  String name,
  List<num> values,
  Color color, {
  double? radius,
}) => apexJsBar(name, values, color, opacity: 1, radius: radius);

ChartConfig _config(ApexZoom zoom) => ChartConfig(
  // xaxis: {type: 'datetime'}: the labels of ApexCharts.js for the first
  // six days of January 2011.
  labels: const ["Jan '11", '02 Jan', '03 Jan', '04 Jan', '05 Jan', '06 Jan'],
  datasets: [
    _series('PRODUCT A', const [44, 55, 41, 67, 22, 43], Apex.blue),
    _series('PRODUCT B', const [13, 23, 20, 8, 13, 27], Apex.green),
    _series('PRODUCT C', const [11, 17, 15, 15, 21, 14], Apex.yellow),
    // borderRadius: 10 with borderRadiusWhenStacked: 'last': only the top
    // series of each stack has round corners.
    _series('PRODUCT D', const [21, 7, 25, 13, 22, 8], Apex.red, radius: 10),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 36, 10, 0),
  // legend: {position: 'right', offsetY: 40}
  legend: apexJsLegend(position: .right, align: .start, square: true),
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: true,
  ),
  animation: apexAnimation,
  plugins: apexZoomPlugins([
    apexJsColumnCrosshair,
    // The default dataLabels of a bar chart, and
    // plotOptions.bar.dataLabels.total: {enabled: true}.
    apexJsBarLabels(totals: true),
    apexTooltipLook,
  ]),
  pluginOptions: [apexJsBarTooltip(), zoom.options],
  scales: [
    // chart.stacked: true: both axes stack.
    apexJsCategoryAxis().copyWith(stacked: StackMode.on),
    apexJsValueAxis(min: 0, max: 120, stepSize: 20, stacked: true),
  ],
);

class const ApexJsColumnStacked({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ApexZoomChart(
    config: _config,
    height: 350,
    semanticLabel: 'Stacked column chart of four products',
  );
}
// #enddocregion apexjs-column-stacked

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsColumnStacked(),
        ),
      ),
    ),
  );
}
