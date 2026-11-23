// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Stepline Chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-line-stepline
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

ChartConfig _config(ApexZoom zoom) => ChartConfig(
  // No xaxis.categories: ApexCharts.js numbers the points from 1.
  labels: const ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11'],
  datasets: [
    // stroke: {curve: 'stepline'}: the line goes across, then up or down.
    // A series with no name is 'series-1'.
    apexJsLine(
      'series-1',
      const [34, 44, 54, 21, 12, 43, 33, 23, 66, 66, 58],
      Apex.blue,
      stepped: SteppedLine.before,
    ),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
  title: apexJsTitle('Stepline Chart'),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  // chart.zoom is on by default: the zoom toolbar of the kit.
  plugins: apexZoomPlugins([apexHover, apexTooltipLook]),
  pluginOptions: [
    const LegendOptions(display: false),
    apexTooltip(),
    zoom.options,
  ],
  scales: [
    apexJsCategoryAxis(),
    apexJsValueAxis(min: 10, max: 70, stepSize: 10),
  ],
);

class const ApexJsLineStepline({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ApexZoomChart(
    config: _config,
    height: 350,
    semanticLabel: 'Stepped line chart of eleven values',
  );
}
// #enddocregion apexjs-line-stepline

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsLineStepline(),
        ),
      ),
    ),
  );
}
