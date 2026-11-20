// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Basic Column Chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-column-basic
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const List<num> _profit = [44, 55, 57, 56, 61, 58, 63, 60, 66];
const List<num> _revenue = [76, 85, 101, 98, 87, 105, 91, 114, 94];
const List<num> _cash = [35, 41, 36, 26, 45, 48, 52, 53, 41];

// plotOptions.bar: {columnWidth: '55%', borderRadius: 5,
// borderRadiusApplication: 'end'}, stroke: {width: 2, colors:
// ['transparent']} and fill: {opacity: 1}. Chart.js rounds the end of a
// bar by default, and a transparent border leaves a gap of 2 px.
BarDataset _series(String name, List<num> values, Color color) => apexJsBar(
  name,
  values,
  color,
  opacity: 1,
  percentage: 0.55,
  radius: 5,
  stroke: 2,
  strokeColor: const Color(0x00000000),
);

// tooltip.y.formatter
String _thousands(num value) => '\$ ${apexNumber(value)} thousands';

final ChartConfig _config = ChartConfig(
  labels: const ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'],
  datasets: [
    _series('Net Profit', _profit, Apex.blue),
    _series('Revenue', _revenue, Apex.green),
    _series('Free Cash Flow', _cash, Apex.yellow),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 30, 10, 0),
  legend: apexJsLegend(square: true),
  tooltip: apexJsBarTooltip(value: _thousands),
  interaction: const ChartInteraction(
    mode: NearestInteractionMode(),
    intersect: true,
  ),
  animation: apexAnimation,
  plugins: [apexJsColumnCrosshair, apexTooltipLook],
  scales: [
    apexJsCategoryAxis(),
    apexJsValueAxis(min: 0, max: 120, stepSize: 20, title: r'$ (thousands)'),
  ],
);

class const ApexJsColumnBasic({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 350,
    child: ChartView(
      config: _config,
      semanticLabel:
          'Column chart of the profit, the revenue and the cash flow',
    ),
  );
}
// #enddocregion apexjs-column-basic

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsColumnBasic(),
        ),
      ),
    ),
  );
}
