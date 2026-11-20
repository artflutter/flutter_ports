// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Bar with Negative Values".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-bar-pyramid
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const List<num> _males = [
  0.4, 0.65, 0.76, 0.88, 1.5, 2.1, 2.9, 3.8, 3.9, //
  4.2, 4, 4.3, 4.1, 4.2, 4.5, 3.9, 3.5, 3,
];
const List<num> _females = [
  -0.8, -1.05, -1.06, -1.18, -1.4, -2.2, -2.85, -3.7, -3.96, //
  -4.22, -4.3, -4.4, -4.1, -4, -4.1, -3.4, -3.1, -2.8,
];

// plotOptions.bar: {borderRadius: 5, borderRadiusApplication: 'end',
// barHeight: '80%'} and stroke: {width: 1, colors: ['#fff']}. Chart.js
// rounds the end of a bar on both sides of zero.
BarDataset _series(String name, List<num> values, Color color) =>
    apexJsBar(name, values, color, percentage: 0.8, radius: 5, stroke: 1);

// tooltip.y.formatter: Math.abs(val) + '%'
String _percent(num value) => '${apexNumber(value.abs())}%';

// xaxis.labels.formatter: Math.abs(Math.round(val)) + '%'
List<String>? _percentTick(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => ['${value.round().abs()}%'];

final ChartConfig _config = ChartConfig(
  labels: const [
    '85+', '80-84', '75-79', '70-74', '65-69', '60-64', '55-59', '50-54', //
    '45-49', '40-44', '35-39', '30-34', '25-29', '20-24', '15-19', '10-14', //
    '5-9', '0-4',
  ],
  indexAxis: .y,
  datasets: [
    // colors: ['#008FFB', '#FF4560']
    _series('Males', _males, Apex.blue),
    _series('Females', _females, Apex.red),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
  title: apexJsTitle('Mauritius population pyramid 2011'),
  legend: apexJsLegend(square: true),
  tooltip: apexJsBarTooltip(value: _percent, horizontal: true),
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: true,
  ),
  animation: apexAnimation,
  plugins: [apexTooltipLook],
  scales: [
    // chart.stacked: true: the two bars of an age group share a row.
    apexJsCategoryAxis(horizontal: true).copyWith(stacked: StackMode.on),
    apexJsValueAxis(
      min: -6,
      max: 6,
      stepSize: 2,
      callback: _percentTick,
      title: 'Percent',
      stacked: true,
      horizontal: true,
    ),
  ],
);

class const ApexJsBarPyramid({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    // chart.height: 440
    height: 440,
    child: ChartView(
      config: _config,
      semanticLabel: 'Population pyramid of Mauritius in 2011',
    ),
  );
}
// #enddocregion apexjs-bar-pyramid

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsBarPyramid(),
        ),
      ),
    ),
  );
}
