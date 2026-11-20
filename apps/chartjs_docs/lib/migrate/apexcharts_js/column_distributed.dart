// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Distributed Columns".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-column-distributed
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// colors: the eight colors of the demo.
const List<Color> _colors = [
  Color(0xFF008FFB),
  Color(0xFF00E396),
  Color(0xFFFEB019),
  Color(0xFFFF4560),
  Color(0xFF775DD0),
  Color(0xFF546E7A),
  Color(0xFF26A69A),
  Color(0xFFD10CE8),
];

final ChartConfig _config = ChartConfig(
  // A category of two lines is a List of two lines, as in ApexCharts.js.
  labels: const [
    ['John', 'Doe'],
    ['Joe', 'Smith'],
    ['Jake', 'Williams'],
    'Amber',
    ['Peter', 'Brown'],
    ['Mary', 'Evans'],
    ['David', 'Wilson'],
    ['Lily', 'Roberts'],
  ],
  datasets: [
    // plotOptions.bar.distributed: true: a color for each column.
    BarDataset(
      label: 'series-1',
      data: const [21, 22, 10, 28, 16, 21, 13, 30],
      backgroundColor: .indexed([
        for (final color in _colors) .solid(color.withValues(alpha: 0.85)),
      ]),
      hoverBackgroundColor: .indexed([
        for (final color in _colors) .solid(color),
      ]),
      borderWidth: 0,
      // plotOptions.bar.columnWidth: '45%'
      categoryPercentage: 0.45,
      barPercentage: 1,
    ),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 30, 10, 0),
  // legend: {show: false}
  legend: const ChartLegend(display: false),
  tooltip: apexJsBarTooltip(),
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: true,
  ),
  animation: apexAnimation,
  plugins: [apexJsColumnCrosshair, apexTooltipLook],
  scales: [
    // xaxis.labels.style.colors: each name in the color of its column.
    apexJsCategoryAxis(labelColors: _colors),
    apexJsValueAxis(min: 0, max: 30, stepSize: 5),
  ],
);

class const ApexJsColumnDistributed({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 350,
    child: ChartView(
      config: _config,
      semanticLabel: 'Column chart with a color for each person',
    ),
  );
}
// #enddocregion apexjs-column-distributed

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsColumnDistributed(),
        ),
      ),
    ),
  );
}
