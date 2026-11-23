// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Basic Line Chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-line-basic
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

const List<num> _desktops = [10, 41, 35, 51, 49, 62, 69, 91, 148];

final ChartConfig _config = ChartConfig(
  // xaxis.categories
  labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep'],
  datasets: [
    // stroke: {curve: 'straight'}: no tension.
    apexJsLine('Desktops', _desktops, Apex.blue),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
  title: apexJsTitle('Product Trends by Month'),
  // One series: ApexCharts.js shows no legend.
  legend: const ChartLegend(display: false),
  pluginOptions: [apexTooltip()],
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  plugins: [
    // grid.row: {colors: ['#f3f3f3', 'transparent'], opacity: 0.5}
    apexJsRowStripes(const [Color(0xFFF3F3F3), Color(0x00000000)]),
    apexHover,
    apexTooltipLook,
  ],
  scales: [
    apexJsCategoryAxis(),
    apexJsValueAxis(min: 0, max: 150, stepSize: 50),
  ],
);

class const ApexJsLineBasic({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 350,
    child: ChartView(
      config: _config,
      semanticLabel: 'Line chart of the product trends by month',
    ),
  );
}
// #enddocregion apexjs-line-basic

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsLineBasic(),
        ),
      ),
    ),
  );
}
