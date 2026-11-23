// Original code, not ported from Chart.js: a replica of the ApexCharts.js demo "Spline Area".
// ignore_for_file: lines_longer_than_80_chars, public_member_api_docs
// #docregion apexjs-area-spline
import 'package:chartjs_docs/migrate/apexcharts/apex_kit.dart';
import 'package:chartjs_docs/migrate/apexcharts_js/apexjs_kit.dart';
import 'package:flutter_chartjs_port/flutter_chartjs_port.dart';
import 'package:material_ui/material_ui.dart';

// xaxis.categories: the times of the demo. ApexCharts.js writes them in
// UTC (xaxis.labels.datetimeUTC). Local times give the same labels here.
final List<DateTime> _times = [
  DateTime(2018, 9, 19),
  DateTime(2018, 9, 19, 1, 30),
  DateTime(2018, 9, 19, 2, 30),
  DateTime(2018, 9, 19, 3, 30),
  DateTime(2018, 9, 19, 4, 30),
  DateTime(2018, 9, 19, 5, 30),
  DateTime(2018, 9, 19, 6, 30),
];

// chart: {type: 'area'}: a LineDataset that fills to the bottom, with the
// gradient of an ApexCharts.js area and a line of 4 px.
LineDataset _area(String name, List<num> values, Color color) => LineDataset(
  label: name,
  data: .points([
    for (final (i, value) in values.indexed) DataPoint.time(_times[i], value),
  ]),
  fill: .toStart,
  backgroundColor: apexAreaFill(color),
  borderColor: .constant(.solid(color)),
  borderWidth: 4,
  // stroke: {curve: 'smooth'}
  tension: 0.4,
  pointRadius: const .constant(0),
  pointHoverRadius: const .constant(0),
);

ChartConfig _config(ApexZoom zoom) => ChartConfig(
  datasets: [
    _area('series1', const [31, 40, 28, 51, 42, 109, 100], Apex.blue),
    _area('series2', const [11, 32, 45, 32, 34, 52, 41], Apex.green),
  ],
  maintainAspectRatio: false,
  padding: const EdgeInsets.fromLTRB(4, 36, 10, 0),
  interaction: const ChartInteraction(
    mode: IndexInteractionMode(),
    intersect: false,
  ),
  animation: apexAnimation,
  plugins: apexZoomPlugins([apexHover, apexTooltipLook]),
  pluginOptions: [
    apexJsLegend(),
    apexTooltip(),
    zoom.options,
    // ApexCharts.js draws the areas under all lines. Chart.js fills each
    // area just before its dataset by default: the first area would cover
    // the second line.
    const FillerOptions(drawTime: .beforeDatasetsDraw),
  ],
  scales: [
    // xaxis: {type: 'datetime'}, and tooltip.x.format: 'dd/MM/yy HH:mm'.
    const TimeAxis(
      .x,
      unit: .hour,
      tooltipFormat: 'dd/MM/yy HH:mm',
      displayFormats: TimeDisplayFormats(hour: 'HH:mm'),
      grid: AxisGrid(
        color: .solid(apexJsGrid),
        drawOnChartArea: false,
        tickLength: 6,
      ),
      ticks: AxisTicks(
        color: .solid(Apex.text),
        font: TextStyle(fontSize: 12),
        padding: 4,
        maxRotation: 0,
      ),
      border: AxisBorder(color: .solid(apexJsGrid)),
    ),
    apexJsValueAxis(min: 0, max: 120, stepSize: 20),
  ],
);

class const ApexJsAreaSpline({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const ApexZoomChart(
    config: _config,
    height: 350,
    semanticLabel: 'Area chart of two series over seven hours',
  );
}
// #enddocregion apexjs-area-spline

void main() {
  Chart.register(registerables);
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(12),
          child: ApexJsAreaSpline(),
        ),
      ),
    ),
  );
}
