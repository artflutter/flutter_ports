// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Basic Bar Chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-bar-basic
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const List<num> _values = [400, 430, 448, 470, 540, 580, 690, 1100, 1200, 1380];

final ChartConfig _config = ChartConfig(
  labels: const [
    'South Korea', 'Canada', 'United Kingdom', 'Netherlands', 'Italy', //
    'France', 'Japan', 'United States', 'China', 'Germany',
  ],
  // plotOptions.bar.horizontal: true
  indexAxis: .y,
  datasets: [
    // borderRadius: 4 with borderRadiusApplication: 'end'.
    apexJsBar('series-1', _values, Apex.blue, radius: 4),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 30, 16, 0),
  legend: const ChartLegend(display: false),
  tooltip: apexJsBarTooltip(horizontal: true),
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: true,
  ),
  animation: apexAnimation,
  plugins: [apexTooltipLook],
  scales: [
    apexJsCategoryAxis(horizontal: true),
    apexJsValueAxis(min: 0, max: 1500, stepSize: 500, horizontal: true),
  ],
);

class const ApexJsBarBasic({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 350,
    child: ChartView(
      config: _config,
      semanticLabel: 'Horizontal bar chart of ten countries',
    ),
  );
}
// #enddocregion apexjs-bar-basic

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsBarBasic(),
        ),
      ),
    ),
  );
}
