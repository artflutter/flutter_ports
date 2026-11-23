// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Line with Data Labels".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-line-labels
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// chart.dropShadow: {color: '#000', top: 18, left: 7, blur: 10, opacity: 0.5}
const ChartShadow _shadow = ChartShadow(
  color: Color(0x80000000),
  blur: 10,
  offset: Offset(7, 18),
);

// colors: ['#77B6EA', '#545454']
LineDataset _series(String name, List<num> values, Color color) => apexJsLine(
  name,
  values,
  color,
  // stroke: {curve: 'smooth'}
  tension: 0.4,
  // markers: {size: 1}
  markers: 1,
  shadow: _shadow,
);

const List<num> _high = [28, 29, 33, 36, 32, 32, 33];
const List<num> _low = [12, 11, 14, 18, 17, 13, 13];

final ChartConfig _config = ChartConfig(
  labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
  datasets: [
    _series('High - 2013', _high, const Color(0xFF77B6EA)),
    _series('Low - 2013', _low, const Color(0xFF545454)),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
  pluginOptions: [
    apexJsTitle('Average High & Low Temperature'),
    // legend: {position: 'top', horizontalAlign: 'right', floating: true}
    apexJsLegend(position: .top, align: .end),
    apexTooltip(),
  ],
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  plugins: [
    apexJsRowStripes(const [Color(0xFFF3F3F3), Color(0x00000000)]),
    apexHover,
    // dataLabels: {enabled: true}
    apexJsLineLabels,
    apexTooltipLook,
  ],
  scales: [
    apexJsCategoryAxis(title: 'Month'),
    apexJsValueAxis(min: 5, max: 40, stepSize: 5, title: 'Temperature'),
  ],
);

class const ApexJsLineLabels({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 350,
    child: ChartView(
      config: _config,
      semanticLabel: 'Line chart of the average high and low temperature',
    ),
  );
}
// #enddocregion apexjs-line-labels

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsLineLabels(),
        ),
      ),
    ),
  );
}
