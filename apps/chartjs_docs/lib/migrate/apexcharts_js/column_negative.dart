// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Column with Negative Values".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-column-negative
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const List<num> _cashFlow = [
  1.45, 5.42, 5.9, -0.42, -12.6, -18.1, -18.2, -14.16, -11.1, -6.09, 0.34, //
  3.88, 13.07, 5.8, 2, 7.37, 8.1, 13.57, 15.75, 17.1, 19.8, -27.03, -54.4, //
  -47.2, -43.3, -18.6, -48.6, -41.1, -39.6, -37.6, -29.4, -21.4, -2.4,
];

// xaxis.categories: the first day of each month from January 2011.
const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
final List<String> _labels = [
  for (var i = 0; i < _cashFlow.length; i++)
    '${_months[i % 12]} ${2011 + i ~/ 12}',
];

// plotOptions.bar.colors.ranges: red from -100 to -46, yellow from -45 to
// 0, else the series color. A color for each column.
Color _colorOf(num value) => value <= -46
    ? const Color(0xFFF15B46)
    : value <= 0
    ? Apex.yellow
    : Apex.blue;

// xaxis: {type: 'datetime'}: ApexCharts.js writes the year at January and
// "Jul 'yy" at July, from the first July. The other columns keep their tick
// with no label.
List<String>? _monthTick(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => switch (index % 12) {
  0 when index > 0 => ['${2011 + index ~/ 12}'],
  6 => ["Jul '${(11 + index ~/ 12).toString().padLeft(2, '0')}"],
  _ => [],
};

// yaxis.labels.formatter: y.toFixed(0) + '%'
List<String>? _percentTick(
  Scale scale,
  double value,
  int index,
  List<Tick> ticks,
) => ['${value.toStringAsFixed(0)}%'];

ChartConfig _config(ApexZoom zoom) => ChartConfig(
  labels: _labels,
  datasets: [
    BarDataset(
      label: 'Cash Flow',
      data: _cashFlow,
      backgroundColor: .indexed([
        for (final value in _cashFlow)
          .solid(_colorOf(value).withValues(alpha: 0.85)),
      ]),
      hoverBackgroundColor: .indexed([
        for (final value in _cashFlow) .solid(_colorOf(value)),
      ]),
      borderWidth: 0,
      // plotOptions.bar.columnWidth: '80%'
      categoryPercentage: 0.8,
      barPercentage: 1,
    ),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 36, 10, 0),
  legend: const ChartLegend(display: false),
  tooltip: apexJsBarTooltip(),
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: true,
  ),
  animation: apexAnimation,
  plugins: apexZoomPlugins([apexJsColumnCrosshair, apexTooltipLook]),
  pluginOptions: [zoom.options],
  scales: [
    apexJsCategoryAxis(
      callback: _monthTick,
      maxRotation: 0,
    ).copyWith(grid: const AxisGrid(display: false)),
    apexJsValueAxis(
      min: -60,
      max: 20,
      stepSize: 20,
      callback: _percentTick,
      title: 'Growth',
    ),
  ],
);

class const ApexJsColumnNegative({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ApexZoomChart(
    config: _config,
    height: 350,
    semanticLabel:
        'Column chart of the monthly cash flow, with negative values',
  );
}
// #enddocregion apexjs-column-negative

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsColumnNegative(),
        ),
      ),
    ),
  );
}
