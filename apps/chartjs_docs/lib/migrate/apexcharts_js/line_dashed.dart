// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Dashed Line Chart".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-line-dashed
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// tooltip.y[i].title.formatter: the name of each series in the tooltip.
TooltipCallbacks _title(String Function(String name) title) => TooltipCallbacks(
  label: (tooltip, item) => [
    '${title(item.datasetLabel ?? '')}: ${item.formattedValue}',
  ],
);

const List<num> _duration = [45, 52, 38, 24, 33, 26, 21, 20, 6, 8, 15, 10];

final ChartConfig _config = ChartConfig(
  labels: const [
    '01 Jan', '02 Jan', '03 Jan', '04 Jan', '05 Jan', '06 Jan', //
    '07 Jan', '08 Jan', '09 Jan', '10 Jan', '11 Jan', '12 Jan',
  ],
  datasets: [
    // stroke: {width: [5, 7, 5], dashArray: [0, 8, 5]}
    apexJsLine(
      'Session Duration',
      _duration,
      Apex.blue,
    ).copyWith(tooltipCallbacks: _title((name) => '$name (mins)')),
    apexJsLine(
      'Page Views',
      const [35, 41, 62, 42, 13, 18, 29, 37, 36, 51, 32, 35],
      Apex.green,
      width: 7,
      dash: const [8, 8],
    ).copyWith(tooltipCallbacks: _title((name) => '$name per session')),
    apexJsLine(
      'Total Visits',
      const [87, 57, 74, 99, 75, 38, 62, 47, 82, 56, 45, 47],
      Apex.yellow,
      dash: const [5, 5],
    ),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 0, 10, 0),
  title: apexJsTitle('Page Statistics'),
  legend: apexJsLegend(),
  tooltip: apexTooltip(),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  plugins: [apexHover, apexTooltipLook],
  scales: [
    apexJsCategoryAxis(),
    apexJsValueAxis(min: 0, max: 100, stepSize: 20),
  ],
);

class const ApexJsLineDashed({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 350,
    child: ChartView(
      config: _config,
      semanticLabel: 'Line chart of the page statistics, two lines dashed',
    ),
  );
}
// #enddocregion apexjs-line-dashed

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsLineDashed(),
        ),
      ),
    ),
  );
}
