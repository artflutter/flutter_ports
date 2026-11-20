// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Column with Data Labels".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-column-labels
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const List<num> _inflation = [
  2.3, 3.1, 4.0, 10.1, 4.0, 3.6, 3.2, 2.3, 1.4, 0.8, 0.5, 0.2, //
];

// dataLabels.formatter and yaxis.labels.formatter
String _percent(num value) => '${apexNumber(value)}%';

final ChartConfig _config = ChartConfig(
  labels: const [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ],
  datasets: [
    // plotOptions.bar.borderRadius: 10, with the default
    // borderRadiusApplication 'around': the four corners are round.
    apexJsBar(
      'Inflation',
      _inflation,
      Apex.blue,
      radius: 10,
    ).copyWith(extra: const {'borderSkipped': false}),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
  // title: {floating: true, offsetY: 330, align: 'center'}: under the plot.
  title: apexJsTitle(
    'Monthly Inflation in Argentina, 2002',
    align: .center,
    position: .bottom,
    color: const Color(0xFF444444),
  ),
  legend: const ChartLegend(display: false),
  tooltip: apexJsBarTooltip(value: _percent),
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: true,
  ),
  animation: apexAnimation,
  plugins: [
    apexJsColumnCrosshair,
    // dataLabels: {offsetY: -20, style: {colors: ['#304758']}} with
    // plotOptions.bar.dataLabels.position: 'top': over each column.
    apexJsBarLabels(
      format: _percent,
      color: const Color(0xFF304758),
      at: .outsideEnd,
    ),
    apexTooltipLook,
  ],
  scales: [
    // xaxis: {position: 'top', axisBorder: {show: false}, axisTicks:
    // {show: false}}
    const CategoryAxis(
      .x,
      position: .top,
      grid: AxisGrid(display: false),
      ticks: AxisTicks(
        color: .solid(Apex.text),
        font: TextStyle(fontSize: 12),
        maxRotation: 0,
        autoSkip: false,
      ),
      border: AxisBorder(display: false),
    ),
    // yaxis.labels.show: false: the grid lines stay.
    apexJsValueAxis(
      min: 0,
      max: 12,
      stepSize: 2,
    ).copyWith(ticks: const AxisTicks(display: false)),
  ],
);

class const ApexJsColumnLabels({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 350,
    child: ChartView(
      config: _config,
      semanticLabel: 'Column chart of the monthly inflation with labels',
    ),
  );
}
// #enddocregion apexjs-column-labels

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsColumnLabels(),
        ),
      ),
    ),
  );
}
