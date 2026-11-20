// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Stacked Bar Chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-bar-stacked
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// stroke: {width: 1, colors: ['#fff']} and fill: {opacity: 1}
BarDataset _series(String name, List<num> values, Color color) =>
    apexJsBar(name, values, color, opacity: 1, stroke: 1);

// xaxis.labels.formatter and tooltip.y.formatter: val + 'K'
String _thousands(num value) => '${apexNumber(value)}K';

List<String>? _thousandsTick(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => [_thousands(value)];

final ChartConfig _config = ChartConfig(
  labels: const ['2008', '2009', '2010', '2011', '2012', '2013', '2014'],
  indexAxis: .y,
  datasets: [
    _series('Marine Sprite', const [44, 55, 41, 37, 22, 43, 21], Apex.blue),
    _series('Striking Calf', const [53, 32, 33, 52, 13, 43, 32], Apex.green),
    _series('Tank Picture', const [12, 17, 11, 9, 15, 11, 20], Apex.yellow),
    _series('Bucket Slope', const [9, 7, 5, 8, 6, 9, 4], Apex.red),
    _series('Reborn Kid', const [25, 12, 19, 32, 25, 24, 10], Apex.purple),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 0, 30, 0),
  title: apexJsTitle('Fiction Books Sales'),
  // legend: {position: 'top', horizontalAlign: 'left'}
  legend: apexJsLegend(position: .top, align: .start, square: true),
  tooltip: apexJsBarTooltip(value: _thousands, horizontal: true),
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: true,
  ),
  animation: apexAnimation,
  plugins: [
    // The default dataLabels, and plotOptions.bar.dataLabels.total.
    apexJsBarLabels(totals: true),
    apexTooltipLook,
  ],
  scales: [
    // chart.stacked: true
    apexJsCategoryAxis(horizontal: true).copyWith(stacked: StackMode.on),
    apexJsValueAxis(
      min: 0,
      max: 150,
      stepSize: 50,
      callback: _thousandsTick,
      stacked: true,
      horizontal: true,
    ),
  ],
);

class const ApexJsBarStacked({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 350,
    child: ChartView(
      config: _config,
      semanticLabel: 'Stacked horizontal bar chart of the book sales',
    ),
  );
}
// #enddocregion apexjs-bar-stacked

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsBarStacked(),
        ),
      ),
    ),
  );
}
